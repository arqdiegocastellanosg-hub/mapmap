<#
  Verifica que la carpeta desplegada de MapMap para Windows sea autosuficiente.

  1. Comprueba que existan los componentes esperados (Qt, plugins, FFmpeg, runtime MinGW).
  2. Recorre TODOS los .exe/.dll con objdump y comprueba que cada DLL importada
     este en la carpeta, en la misma subcarpeta o en System32 (DLL del sistema).
  Falla (exit 1) si falta algo.
#>
param(
  [Parameter(Mandatory)] [string] $Dir,
  [Parameter(Mandatory)] [string] $Report
)
$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Force (Split-Path $Report) | Out-Null
$lines = New-Object System.Collections.Generic.List[string]
$fail = $false

function Need($pattern, $what) {
  $hit = Get-ChildItem -Path $Dir -Recurse -File -Filter $pattern -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($hit) { $script:lines.Add("OK      $what -> $($hit.FullName.Substring($Dir.Length + 1))") }
  else      { $script:lines.Add("FALTA   $what ($pattern)"); $script:fail = $true }
}

$lines.Add("== Componentes esperados ==")
Need 'MapMap.exe'               'Ejecutable'
Need 'Qt6Core.dll'              'Qt Core'
Need 'Qt6Gui.dll'               'Qt Gui'
Need 'Qt6Widgets.dll'           'Qt Widgets'
Need 'Qt6OpenGL.dll'            'Qt OpenGL'
Need 'Qt6OpenGLWidgets.dll'     'Qt OpenGL Widgets'
Need 'Qt6Network.dll'           'Qt Network'
Need 'Qt6Multimedia.dll'        'Qt Multimedia'
Need 'Qt6MultimediaWidgets.dll' 'Qt Multimedia Widgets'
Need 'qwindows.dll'             'Plugin de plataforma Windows'
Need 'ffmpegmediaplugin.dll'    'Plugin multimedia FFmpeg'
Need 'avcodec-*.dll'            'FFmpeg avcodec'
Need 'avformat-*.dll'           'FFmpeg avformat'
Need 'avutil-*.dll'             'FFmpeg avutil'
Need 'swresample-*.dll'         'FFmpeg swresample'
Need 'swscale-*.dll'            'FFmpeg swscale'
Need 'libstdc++-6.dll'          'Runtime MinGW libstdc++'
Need 'libgcc_s_seh-1.dll'       'Runtime MinGW libgcc'
Need 'libwinpthread-1.dll'      'Runtime MinGW winpthread'
Need 'opengl32sw.dll'           'OpenGL por software (equipos/VM sin GPU)'

$lines.Add("")
$lines.Add("== Importaciones DLL (objdump) ==")
$sys32 = Join-Path $env:SystemRoot 'System32'
$bundled = @{}
Get-ChildItem -Path $Dir -Recurse -File -Include *.dll, *.exe | ForEach-Object { $bundled[$_.Name.ToLower()] = $true }
$missing = @{}
Get-ChildItem -Path $Dir -Recurse -File -Include *.dll, *.exe | ForEach-Object {
  $file = $_
  $imports = & objdump -p $file.FullName 2>$null | Select-String -Pattern 'DLL Name:\s*(\S+)' | ForEach-Object { $_.Matches[0].Groups[1].Value }
  foreach ($imp in $imports) {
    $n = $imp.ToLower()
    if ($n -like 'api-ms-win-*' -or $n -like 'ext-ms-*') { continue }
    if ($bundled.ContainsKey($n)) { continue }
    if (Test-Path (Join-Path $sys32 $imp)) { continue }
    $missing["$n  (requerida por $($file.Name))"] = $true
  }
}
if ($missing.Count -eq 0) { $lines.Add("OK      Todas las DLL importadas estan incluidas o son del sistema") }
else { $fail = $true; $missing.Keys | Sort-Object | ForEach-Object { $lines.Add("FALTA   $_") } }

$lines.Add("")
$lines.Add("== Contenido (tamano total) ==")
$size = (Get-ChildItem $Dir -Recurse -File | Measure-Object Length -Sum).Sum
$lines.Add(("{0:N1} MB en {1} archivos" -f ($size / 1MB), (Get-ChildItem $Dir -Recurse -File).Count))
Get-ChildItem $Dir -Recurse -File | ForEach-Object { $lines.Add("  " + $_.FullName.Substring($Dir.Length + 1)) }

$lines | Out-File -Encoding utf8 $Report
$lines | Select-Object -First 40 | ForEach-Object { Write-Host $_ }
if ($fail) { Write-Error "Faltan dependencias. Ver $Report"; exit 1 }
