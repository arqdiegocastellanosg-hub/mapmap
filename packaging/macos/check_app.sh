#!/bin/bash
# Verifica que MapMap.app sea Universal y autosuficiente, ARQUITECTURA POR ARQUITECTURA.
#
# Para cada binario Mach-O del bundle (ejecutable, frameworks de Qt, plugins,
# FFmpeg, Syphon) y para cada arquitectura (x86_64 y arm64) por separado:
#   1. la arquitectura esta presente (x86_64h cuenta como x86_64: Qt publica asi su parte Intel)
#   2. las dependencias de ESA arquitectura (otool -arch X -L) son solo del sistema
#      (/System, /usr/lib) o relativas (@rpath, @executable_path, @loader_path)
#   3. el sistema minimo de ESA arquitectura (LC_BUILD_VERSION minos) es <= el objetivo
# Ademas comprueba que esten Qt, el plugin FFmpeg, las bibliotecas FFmpeg y Syphon,
# y que el Info.plist declare el sistema minimo objetivo.
#
# No ejecuta nada: es analisis estatico, valido en un runner Intel o ARM64.
#
# Uso: check_app.sh <MapMap.app> <informe_detallado.txt> <resumen.md> [macos_minimo=12.0]
set -uo pipefail
APP="${1%/}"; DETAIL="$2"; SUMMARY="$3"; TARGET_MIN="${4:-12.0}"
ARCHS=(x86_64 arm64)
mkdir -p "$(dirname "$DETAIL")" "$(dirname "$SUMMARY")"
FAIL=0
N_BIN=0; N_ARCH_FAIL=0; N_DEP_FAIL=0; N_MIN_FAIL=0
MAX_MIN_x86_64="0"; MAX_MIN_arm64="0"

# Devuelve el nombre de la parte en el binario que corresponde a la arquitectura pedida.
slice_for() {  # $1=archivo $2=x86_64|arm64
  local archs; archs=" $(lipo -archs "$1" 2>/dev/null) "
  if [ "$2" = "x86_64" ]; then
    [[ "$archs" == *" x86_64 "* ]] && { echo x86_64; return; }
    [[ "$archs" == *" x86_64h "* ]] && { echo x86_64h; return; }
  else
    [[ "$archs" == *" arm64 "* ]] && { echo arm64; return; }
  fi
  echo ""
}

# Sistema minimo de una parte: LC_BUILD_VERSION (minos) o LC_VERSION_MIN_MACOSX (version).
minos_for() {  # $1=archivo $2=slice
  otool -arch "$2" -l "$1" 2>/dev/null | awk '
    /cmd LC_BUILD_VERSION/      {m=1; next}
    /cmd LC_VERSION_MIN_MACOSX/ {v=1; next}
    m && $1=="minos"   {print $2; exit}
    v && $1=="version" {print $2; exit}'
}

ver_gt() { [ "$1" != "$2" ] && [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | tail -1)" = "$1" ]; }

{
  echo "Verificacion Universal de $APP (objetivo: x86_64 + arm64, macOS >= $TARGET_MIN)"
  echo "Analisis realizado en: $(uname -m), macOS $(sw_vers -productVersion)"
  echo
  echo "== Binarios Mach-O: arquitectura | sistema minimo | dependencias, por arquitectura =="
  while IFS= read -r -d '' f; do
    file -b "$f" | grep -q 'Mach-O' || continue
    N_BIN=$((N_BIN+1))
    rel="${f#$APP/}"
    echo
    echo "$rel  [$(lipo -archs "$f" 2>/dev/null)]"
    for a in "${ARCHS[@]}"; do
      s="$(slice_for "$f" "$a")"
      if [ -z "$s" ]; then
        echo "   $a: FALTA LA ARQUITECTURA"; N_ARCH_FAIL=$((N_ARCH_FAIL+1)); FAIL=1; continue
      fi
      mn="$(minos_for "$f" "$s")"; mn="${mn:-desconocido}"
      st="OK"
      if [ "$mn" = "desconocido" ]; then
        st="SIN DATO"
      elif ver_gt "$mn" "$TARGET_MIN"; then
        st="REQUIERE macOS $mn > $TARGET_MIN"; N_MIN_FAIL=$((N_MIN_FAIL+1)); FAIL=1
      fi
      if [ "$mn" != "desconocido" ]; then
        varname="MAX_MIN_$a"
        ver_gt "$mn" "${!varname}" && printf -v "$varname" '%s' "$mn"
      fi
      bad=""
      while read -r dep; do
        case "$dep" in
          /System/*|/usr/lib/*|@rpath/*|@executable_path/*|@loader_path/*|"") ;;
          *) bad="$bad $dep" ;;
        esac
      done < <(otool -arch "$s" -L "$f" 2>/dev/null | tail -n +2 | awk '{print $1}')
      if [ -n "$bad" ]; then
        echo "   $a ($s): minos $mn [$st] | DEPENDENCIAS EXTERNAS:$bad"; N_DEP_FAIL=$((N_DEP_FAIL+1)); FAIL=1
      else
        echo "   $a ($s): minos $mn [$st] | dependencias OK"
      fi
    done
  done < <(find "$APP/Contents" -type f -print0 | sort -z)

  echo
  echo "== Componentes obligatorios (presencia + ambas arquitecturas) =="
  for pat in 'MapMap' 'QtCore' 'QtGui' 'QtWidgets' 'QtOpenGL' 'QtOpenGLWidgets' 'QtNetwork' \
             'QtMultimedia' 'QtMultimediaWidgets' 'libqcocoa.dylib' 'libffmpegmediaplugin.dylib' \
             'libavcodec*.dylib' 'libavformat*.dylib' 'libavutil*.dylib' 'libswresample*.dylib' \
             'libswscale*.dylib' 'Syphon'; do
    hit=$(find "$APP/Contents" -type f -name "$pat" -print -quit)
    if [ -z "$hit" ]; then
      echo "FALTA      $pat"; FAIL=1; continue
    fi
    x="$(slice_for "$hit" x86_64)"; r="$(slice_for "$hit" arm64)"
    if [ -n "$x" ] && [ -n "$r" ]; then echo "OK         $pat [$(lipo -archs "$hit")] -> ${hit#$APP/}"
    else echo "NO-UNIV    $pat [$(lipo -archs "$hit")] -> ${hit#$APP/}"; FAIL=1; fi
  done

  echo
  echo "== Info.plist =="
  PL="$APP/Contents/Info.plist"
  for k in CFBundleIdentifier CFBundleShortVersionString LSMinimumSystemVersion MapMapBuildVersion; do
    echo "$k = $(/usr/libexec/PlistBuddy -c "Print :$k" "$PL" 2>/dev/null)"
  done
  PLMIN="$(/usr/libexec/PlistBuddy -c 'Print :LSMinimumSystemVersion' "$PL" 2>/dev/null)"
  [ "$PLMIN" = "$TARGET_MIN" ] || { echo "ERROR: LSMinimumSystemVersion=$PLMIN, se esperaba $TARGET_MIN"; FAIL=1; }

  echo
  echo "== Firma (ad hoc) =="
  codesign --verify --deep --strict "$APP" 2>&1 && echo "codesign --verify: OK" || { echo "codesign --verify: FALLO"; FAIL=1; }
  codesign -dv "$APP" 2>&1 | grep -E 'Signature|Identifier|Format'
  echo
  echo "Tamano del bundle: $(du -sh "$APP" | cut -f1)"
} > "$DETAIL" 2>&1

res() { [ "$1" -eq 0 ] && echo "OK" || echo "FALLO ($1)"; }
{
  echo "# Verificación Universal de MapMap.app (análisis estático)"
  echo
  echo "Realizado en GitHub Actions: $(uname -m), macOS $(sw_vers -productVersion). Esta verificación no ejecuta la app."
  echo
  echo "| Comprobación | Resultado |"
  echo "|---|---|"
  echo "| Binarios Mach-O analizados | $N_BIN |"
  echo "| Todos contienen x86_64 y arm64 | $(res $N_ARCH_FAIL) |"
  echo "| Dependencias de cada arquitectura solo del sistema o del bundle | $(res $N_DEP_FAIL) |"
  echo "| Sistema mínimo de cada arquitectura ≤ macOS $TARGET_MIN | $(res $N_MIN_FAIL) |"
  echo "| Máximo sistema mínimo encontrado (x86_64 / arm64) | $MAX_MIN_x86_64 / $MAX_MIN_arm64 |"
  echo "| Qt, plugin FFmpeg, bibliotecas FFmpeg y Syphon presentes y universales | $(grep -qE '^(FALTA|NO-UNIV)' "$DETAIL" && echo FALLO || echo OK) |"
  echo "| Info.plist LSMinimumSystemVersion = $TARGET_MIN | $([ "$(/usr/libexec/PlistBuddy -c 'Print :LSMinimumSystemVersion' "$APP/Contents/Info.plist" 2>/dev/null)" = "$TARGET_MIN" ] && echo OK || echo FALLO) |"
  echo "| Firma ad hoc válida (codesign --verify) | $(grep -q 'codesign --verify: OK' "$DETAIL" && echo OK || echo FALLO) |"
  echo
  echo "Detalle completo, binario por binario: \`macos_dependencias.txt\`."
} > "$SUMMARY"

cat "$SUMMARY"
echo
grep -E 'FALTA|NO-UNIV|EXTERNAS|REQUIERE|ERROR|FALLO' "$DETAIL" | head -40
if [ "$FAIL" -ne 0 ]; then echo "::error::Verificacion Universal fallida. Ver $DETAIL"; exit 1; fi
echo "Verificacion Universal: OK ($N_BIN binarios, x86_64 + arm64, macOS >= $TARGET_MIN)"
