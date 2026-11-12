<#
  Pruebas automaticas del instalador y de la version portable de MapMap en el runner de
  GitHub (Windows Server, sin GPU, sin pantalla fisica):

    INSTALADOR
    1. Instalacion silenciosa en una carpeta nueva.
    2. Archivos: MapMap.exe, licencias, desinstalador y, ademas, que se instalen
       EXACTAMENTE los mismos archivos que contiene la carpeta desplegada (-Dist).
    3. Accesos directos de escritorio y menu Inicio.
    4. Arranque de MapMap instalado en un ENTORNO AISLADO (ver Start-Isolated).
    5. Desinstalacion silenciosa y comprobacion de limpieza.

    VERSION PORTABLE (-Zip)
    6. Descompresion en una carpeta nueva y estructura MapMap\MapMap.exe.
    7. Mismos archivos que la carpeta desplegada.
    8. Arranque desde la carpeta descomprimida en el mismo entorno aislado.

  Entorno aislado: PATH solo con carpetas de Windows y SIN variables QT_*/QML* (la accion
  install-qt-action define QT_PLUGIN_PATH, QT_ROOT_DIR, etc. a nivel global). Con
  QT_DEBUG_PLUGINS=1 se registra de donde carga Qt sus plugins; la prueba FALLA si el
  registro menciona la carpeta de Qt del runner. Asi se verifica que MapMap no depende
  de Qt ni de herramientas de desarrollo instaladas.

  Escribe un informe Markdown distinguiendo lo verificado de lo no verificable aqui.
#>
param(
  [Parameter(Mandatory)] [string] $Setup,
  [Parameter(Mandatory)] [string] $Report,
  [Parameter(Mandatory)] [string] $Dist,
  [Parameter(Mandatory)] [string] $Zip
)
$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Force (Split-Path $Report) | Out-Null
$ReportDir = (Resolve-Path (Split-Path $Report)).Path
$Dist = (Resolve-Path -LiteralPath $Dist).Path.TrimEnd('\')
$Zip = (Resolve-Path -LiteralPath $Zip).Path
$dir = 'C:\MapMap_PruebaInstalacion'
$portableRoot = 'C:\MapMap_PruebaPortable'

# Carpeta de Qt del runner (p. ej. D:\a\mapmap\Qt), que MapMap NO debe usar.
$QtRoot = $env:QT_ROOT_DIR
$QtBase = if ($QtRoot) { Split-Path (Split-Path $QtRoot) } else { '' }
$QtBaseFwd = if ($QtBase) { $QtBase.Replace('\', '/').TrimEnd('/') } else { '' }

$r = New-Object System.Collections.Generic.List[string]
$r.Add("# Pruebas automaticas de Windows: instalador y version portable")
$r.Add("")
$r.Add("Entorno: GitHub Actions $env:ImageOS $env:ImageVersion (Windows Server, sin GPU, sin pantalla fisica).")
$r.Add("Carpeta de Qt del runner que MapMap NO debe usar: ``$QtBase``")
$r.Add("")
$r.Add("| Prueba | Resultado |")
$r.Add("|---|---|")
$fail = $false
function Res($name, $ok, $detail = '') {
  $script:r.Add("| $name | $(if ($ok) {'OK'} else {'FALLO'}) $detail |")
  if (-not $ok) { $script:fail = $true }
}

function Get-RelFiles($root, [string[]]$exclude = @()) {
  Get-ChildItem -LiteralPath $root -Recurse -File | ForEach-Object { $_.FullName.Substring($root.Length + 1) } |
    Where-Object { $rel = $_; -not ($exclude | Where-Object { $rel -like $_ }) } | Sort-Object
}

function Compare-Files($label, $root, [string[]]$exclude = @()) {
  $expected = @(Get-RelFiles $Dist)
  $actual = @(Get-RelFiles $root $exclude)
  $missing = @($expected | Where-Object { $_ -notin $actual })
  $extra = @($actual | Where-Object { $_ -notin $expected })
  $detail = "($($actual.Count) de $($expected.Count) archivos"
  if ($missing.Count) { $detail += "; faltan: " + (($missing | Select-Object -First 8) -join ', ') }
  if ($extra.Count) { $detail += "; sobran: " + (($extra | Select-Object -First 8) -join ', ') }
  $detail += ")"
  Res $label (($missing.Count -eq 0) -and ($extra.Count -eq 0)) $detail
}

# Arranca un exe en un entorno aislado (sin Qt), comprueba que siga vivo tras 20 s
# y analiza el registro de plugins de Qt.
function Start-Isolated($label, $exe, $workdir, $logName) {
  $saved = @{}
  Get-ChildItem Env: | Where-Object { $_.Name -like 'QT_*' -or $_.Name -like 'QML*' -or $_.Name -in 'QTDIR', 'IQTA_TOOLS' } |
    ForEach-Object { $saved[$_.Name] = $_.Value }
  foreach ($k in $saved.Keys) { Remove-Item "Env:$k" }
  $savedPath = $env:PATH
  $env:PATH = "$env:SystemRoot\System32;$env:SystemRoot;$env:SystemRoot\System32\Wbem"
  $env:QT_OPENGL = 'software'
  $env:QT_DEBUG_PLUGINS = '1'
  # MapMap es una aplicacion grafica (sin consola): sin esto Qt envia sus mensajes a
  # OutputDebugString y el registro quedaria vacio. MapMap instala su propio gestor de
  # mensajes despues de crear la aplicacion; la carga del plugin de plataforma ocurre antes.
  $env:QT_FORCE_STDERR_LOGGING = '1'
  $log = Join-Path $ReportDir $logName
  $alive = $false; $code = ''
  try {
    $app = Start-Process -FilePath $exe -WorkingDirectory $workdir -PassThru -RedirectStandardError $log
    Start-Sleep -Seconds 20
    $alive = -not $app.HasExited
    if ($alive) { Stop-Process -Id $app.Id -Force; Start-Sleep -Seconds 2 }
    else { $code = "(salio con codigo $($app.ExitCode); ver $logName)" }
  } finally {
    Remove-Item Env:QT_OPENGL, Env:QT_DEBUG_PLUGINS, Env:QT_FORCE_STDERR_LOGGING -ErrorAction SilentlyContinue
    $env:PATH = $savedPath
    foreach ($k in $saved.Keys) { Set-Item "Env:$k" $saved[$k] }
  }
  Res "$label`: arranque en entorno aislado (20 s sin cerrarse; sin Qt en PATH ni variables QT_*)" $alive $code

  $text = if (Test-Path $log) { [string](Get-Content $log -Raw) } else { '' }
  $lines = if ($text) { @($text -split "`r?`n" | Where-Object { $_ -match 'qt\.core' }).Count } else { 0 }
  # La verificacion solo cuenta si el registro tiene contenido de Qt: un registro vacio es FALLO.
  $usesQt = [bool]$QtBase -and (($text -match [regex]::Escape($QtBaseFwd)) -or ($text -match [regex]::Escape($QtBase)))
  $okNoQt = ($lines -gt 0) -and (-not $usesQt)
  $why = if ($lines -eq 0) { '(registro vacio: no se pudo verificar)' } elseif ($usesQt) { "(el registro menciona $QtBase)" } else { "($lines lineas de qt.core analizadas)" }
  Res "$label`: no usa la instalacion de Qt del runner (registro QT_DEBUG_PLUGINS)" $okNoQt $why

  $wdFwd = $workdir.Replace('\', '/').TrimEnd('/')
  $fromApp = ($text -match ([regex]::Escape($wdFwd) + '/platforms/qwindows\.dll')) -or ($text -match ([regex]::Escape($workdir) + '\\platforms\\qwindows\.dll'))
  Res "$label`: plugin qwindows.dll cargado desde la carpeta de MapMap" $fromApp $(if ($fromApp) { '' } else { "(no aparece en $logName)" })
}

# ---------------- INSTALADOR ----------------
$p = Start-Process -FilePath $Setup -ArgumentList '/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART', "/DIR=$dir", '/TASKS=desktopicon', "/LOG=$ReportDir\windows_install.log" -Wait -PassThru
Res 'Instalacion silenciosa' ($p.ExitCode -eq 0) "(codigo $($p.ExitCode))"
Res 'MapMap.exe instalado' (Test-Path "$dir\MapMap.exe")
Res 'Licencias instaladas' (Test-Path "$dir\licencias\MapMap_GPL-3.0.txt")
Res 'Desinstalador presente' (Test-Path "$dir\unins000.exe")
if (Test-Path $dir) { Compare-Files 'Instalador: mismos archivos que la carpeta desplegada' $dir @('unins000.*') }
$lnk = Get-ChildItem "$env:PUBLIC\Desktop", "$env:USERPROFILE\Desktop" -Filter 'MapMap*.lnk' -ErrorAction SilentlyContinue
Res 'Acceso directo en el escritorio' ($null -ne $lnk)
$menu = Get-ChildItem "$env:ProgramData\Microsoft\Windows\Start Menu\Programs", "$env:APPDATA\Microsoft\Windows\Start Menu\Programs" -Recurse -Filter 'MapMap*.lnk' -ErrorAction SilentlyContinue
Res 'Acceso directo en el menu Inicio' ($null -ne $menu)

if (Test-Path "$dir\MapMap.exe") { Start-Isolated 'Instalado' "$dir\MapMap.exe" $dir 'windows_arranque_instalado.log' }
else { Res 'Instalado: arranque en entorno aislado' $false '(no hay MapMap.exe instalado)' }

$u = Start-Process -FilePath "$dir\unins000.exe" -ArgumentList '/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART' -Wait -PassThru
# El desinstalador de Inno Setup continua desde una copia temporal: se espera hasta 60 s.
$deadline = (Get-Date).AddSeconds(60)
while ((Test-Path "$dir\MapMap.exe") -and ((Get-Date) -lt $deadline)) { Start-Sleep -Seconds 2 }
Res 'Desinstalacion silenciosa' ($u.ExitCode -eq 0) "(codigo $($u.ExitCode))"
Res 'MapMap.exe eliminado tras desinstalar' (-not (Test-Path "$dir\MapMap.exe"))
$left = if (Test-Path $dir) { @(Get-ChildItem $dir -Recurse -File).Count } else { 0 }
Res 'Ningun archivo queda en la carpeta de instalacion' ($left -eq 0) "($left archivos restantes)"
$lnkAfter = Get-ChildItem "$env:PUBLIC\Desktop", "$env:USERPROFILE\Desktop" -Filter 'MapMap*.lnk' -ErrorAction SilentlyContinue
Res 'Acceso directo del escritorio eliminado' ($null -eq $lnkAfter)

# ---------------- VERSION PORTABLE ----------------
if (Test-Path $portableRoot) { Remove-Item $portableRoot -Recurse -Force }
Expand-Archive -LiteralPath $Zip -DestinationPath $portableRoot
$pdir = Join-Path $portableRoot 'MapMap'
Res 'ZIP portable: estructura MapMap\MapMap.exe' (Test-Path "$pdir\MapMap.exe")
Res 'ZIP portable: incluye licencias y LEEME' ((Test-Path "$pdir\licencias\MapMap_GPL-3.0.txt") -and (Test-Path "$pdir\LEEME.txt"))
if (Test-Path $pdir) { Compare-Files 'ZIP portable: mismos archivos que la carpeta desplegada' $pdir }
if (Test-Path "$pdir\MapMap.exe") { Start-Isolated 'Portable' "$pdir\MapMap.exe" $pdir 'windows_arranque_portable.log' }
else { Res 'Portable: arranque en entorno aislado' $false '(no hay MapMap.exe en el ZIP)' }

# ---------------- INFORME ----------------
$r.Add("")
$r.Add("## No verificable en este entorno (requiere prueba manual en un PC con Windows 10/11)")
$r.Add("- Interfaz grafica interactiva, importacion de imagenes y videos, reproduccion de audio.")
$r.Add("- Creacion y deformacion de superficies; guardar y abrir proyectos.")
$r.Add("- Varias pantallas y salida a proyector.")
$r.Add("- Rendimiento con GPU real (el runner usa OpenGL por software).")
$r.Add("- Windows 10 y Windows 11 de escritorio (el runner es Windows Server).")
$r.Add("")
$r.Add("Registros completos de arranque (QT_DEBUG_PLUGINS): windows_arranque_instalado.log, windows_arranque_portable.log")
$r | Out-File -Encoding utf8 $Report
$r | ForEach-Object { Write-Host $_ }
foreach ($l in 'windows_arranque_instalado.log', 'windows_arranque_portable.log') {
  $f = Join-Path $ReportDir $l
  if (Test-Path $f) {
    Write-Host "---- $l (plugins de plataforma y multimedia, errores) ----"
    Select-String -Path $f -Pattern 'qwindows|ffmpegmediaplugin|loaded library|Cannot|Could not|[Ee]rror' | Select-Object -First 25 | ForEach-Object { Write-Host $_.Line }
  }
}
if ($fail) { Write-Error "Alguna prueba fallo. Ver $Report"; exit 1 }
