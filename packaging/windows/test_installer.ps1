<#
  Prueba automatica del instalador en el runner de GitHub (Windows Server, sin GPU):
    1. Instalacion silenciosa en una carpeta nueva.
    2. Comprobacion de archivos y accesos directos.
    3. Arranque de MapMap.exe con un PATH minimo (sin Qt ni MinGW), para detectar
       dependencias ocultas del entorno de compilacion. Usa OpenGL por software.
    4. Desinstalacion silenciosa y comprobacion de limpieza.
  Escribe un informe Markdown distinguiendo lo verificado de lo no verificable aqui.
#>
param(
  [Parameter(Mandatory)] [string] $Setup,
  [Parameter(Mandatory)] [string] $Report
)
$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Force (Split-Path $Report) | Out-Null
$dir = 'C:\MapMap_PruebaInstalacion'
$r = New-Object System.Collections.Generic.List[string]
$r.Add("# Pruebas automaticas del instalador de Windows")
$r.Add("")
$r.Add("Entorno: GitHub Actions $env:ImageOS $env:ImageVersion (Windows Server, sin GPU, sin pantalla fisica).")
$r.Add("")
$r.Add("| Prueba | Resultado |")
$r.Add("|---|---|")
$fail = $false
function Res($name, $ok, $detail = '') {
  $script:r.Add("| $name | $(if ($ok) {'OK'} else {'FALLO'}) $detail |")
  if (-not $ok) { $script:fail = $true }
}

# 1. Instalacion
$p = Start-Process -FilePath $Setup -ArgumentList '/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART', "/DIR=$dir", '/TASKS=desktopicon', '/LOG=install.log' -Wait -PassThru
Res 'Instalacion silenciosa' ($p.ExitCode -eq 0) "(codigo $($p.ExitCode))"
Res 'MapMap.exe instalado' (Test-Path "$dir\MapMap.exe")
Res 'Licencias instaladas' (Test-Path "$dir\licencias\MapMap_GPL-3.0.txt")
Res 'Desinstalador presente' (Test-Path "$dir\unins000.exe")
$lnk = Get-ChildItem "$env:PUBLIC\Desktop", "$env:USERPROFILE\Desktop" -Filter 'MapMap*.lnk' -ErrorAction SilentlyContinue
Res 'Acceso directo en el escritorio' ($null -ne $lnk)
$menu = Get-ChildItem "$env:ProgramData\Microsoft\Windows\Start Menu\Programs", "$env:APPDATA\Microsoft\Windows\Start Menu\Programs" -Recurse -Filter 'MapMap*.lnk' -ErrorAction SilentlyContinue
Res 'Acceso directo en el menu Inicio' ($null -ne $menu)

# 2. Arranque con PATH minimo
$oldPath = $env:PATH
$env:PATH = "$env:SystemRoot\System32;$env:SystemRoot;$env:SystemRoot\System32\Wbem"
$env:QT_OPENGL = 'software'
$app = Start-Process -FilePath "$dir\MapMap.exe" -WorkingDirectory $dir -PassThru -RedirectStandardError mapmap_stderr.txt
Start-Sleep -Seconds 20
$alive = -not $app.HasExited
if ($alive) { Stop-Process -Id $app.Id -Force; Res 'Arranque de MapMap (20 s sin cerrarse, PATH sin Qt)' $true }
else { Res 'Arranque de MapMap (20 s sin cerrarse, PATH sin Qt)' $false "(salio con codigo $($app.ExitCode); ver mapmap_stderr.txt)" }
$env:PATH = $oldPath
Remove-Item Env:QT_OPENGL

# 3. Desinstalacion
$u = Start-Process -FilePath "$dir\unins000.exe" -ArgumentList '/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART' -Wait -PassThru
# El desinstalador de Inno Setup continua desde una copia temporal: se espera hasta 60 s
# a que termine de borrar los archivos (la comprobacion sigue siendo la misma).
$deadline = (Get-Date).AddSeconds(60)
while ((Test-Path "$dir\MapMap.exe") -and ((Get-Date) -lt $deadline)) { Start-Sleep -Seconds 2 }
Res 'Desinstalacion silenciosa' ($u.ExitCode -eq 0) "(codigo $($u.ExitCode))"
Res 'MapMap.exe eliminado tras desinstalar' (-not (Test-Path "$dir\MapMap.exe"))

$r.Add("")
$r.Add("## No verificable en este entorno (requiere prueba manual)")
$r.Add("- Interfaz grafica interactiva, importacion de imagenes y videos, reproduccion de audio.")
$r.Add("- Creacion y deformacion de superficies; guardar y abrir proyectos.")
$r.Add("- Varias pantallas y salida a proyector.")
$r.Add("- Windows 10 y Windows 11 de escritorio (el runner es Windows Server).")
$r.Add("")
if (Test-Path mapmap_stderr.txt) { $r.Add("## Salida de error de MapMap"); $r.Add('```'); Get-Content mapmap_stderr.txt -TotalCount 60 | ForEach-Object { $r.Add($_) }; $r.Add('```') }
$r | Out-File -Encoding utf8 $Report
$r | ForEach-Object { Write-Host $_ }
Copy-Item install.log (Join-Path (Split-Path $Report) 'windows_install.log') -ErrorAction SilentlyContinue
if ($fail) { Write-Error "Alguna prueba del instalador fallo. Ver $Report"; exit 1 }
