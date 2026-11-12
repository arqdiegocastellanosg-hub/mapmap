#!/bin/bash
# Verifica que MapMap.app sea Universal y autosuficiente:
#   - cada binario Mach-O del bundle contiene x86_64 Y arm64
#   - ninguna biblioteca apunta a rutas del equipo de compilacion
#     (Homebrew, /usr/local, carpeta de Qt del runner); solo se permiten
#     /System, /usr/lib y rutas relativas (@rpath, @executable_path, @loader_path)
#   - estan Qt Multimedia, el plugin FFmpeg, las bibliotecas FFmpeg y Syphon
# Uso: check_app.sh <MapMap.app> <informe.txt>
set -uo pipefail
APP="$1"; REPORT="$2"
mkdir -p "$(dirname "$REPORT")"
FAIL=0
{
  echo "== Arquitecturas de cada binario Mach-O =="
  while IFS= read -r -d '' f; do
    if file -b "$f" | grep -q 'Mach-O'; then
      archs=$(lipo -archs "$f" 2>/dev/null || echo "?")
      rel="${f#$APP/}"
      # Qt publica la parte Intel de sus bibliotecas como x86_64h (Haswell+); se acepta.
      if [[ ( " $archs " == *" x86_64 "* || " $archs " == *" x86_64h "* ) && " $archs " == *" arm64 "* ]]; then
        echo "OK      [$archs] $rel"
      else
        echo "NO-UNIV [$archs] $rel"; FAIL=1
      fi
      while read -r dep; do
        case "$dep" in
          /System/*|/usr/lib/*|@rpath/*|@executable_path/*|@loader_path/*|"") ;;
          *) echo "RUTA EXTERNA en $rel -> $dep"; FAIL=1 ;;
        esac
      done < <(otool -L "$f" 2>/dev/null | tail -n +2 | awk '{print $1}')
    fi
  done < <(find "$APP/Contents" -type f -print0)

  echo
  echo "== Componentes esperados =="
  for pat in 'QtMultimedia.framework' 'QtOpenGLWidgets.framework' 'libqcocoa.dylib' \
             'libffmpegmediaplugin.dylib' 'libavcodec*' 'libavformat*' 'libavutil*' \
             'libswresample*' 'libswscale*' 'Syphon.framework'; do
    hit=$(find "$APP/Contents" -name "$pat" -print -quit)
    if [ -n "$hit" ]; then echo "OK      $pat -> ${hit#$APP/}"; else echo "FALTA   $pat"; FAIL=1; fi
  done

  echo
  echo "== Info.plist =="
  for k in CFBundleIdentifier CFBundleShortVersionString LSMinimumSystemVersion MapMapBuildVersion; do
    echo "$k = $(/usr/libexec/PlistBuddy -c "Print :$k" "$APP/Contents/Info.plist" 2>/dev/null)"
  done
  echo
  echo "== Firma =="
  codesign -dv "$APP" 2>&1
  echo
  echo "Tamano del bundle: $(du -sh "$APP" | cut -f1)"
} > "$REPORT" 2>&1
cat "$REPORT"
if [ "$FAIL" -ne 0 ]; then echo "::error::La app no es Universal o tiene dependencias externas. Ver $REPORT"; exit 1; fi
