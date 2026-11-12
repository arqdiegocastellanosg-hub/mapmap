#!/bin/bash
# Prueba de arranque de MapMap.app en el runner macOS de GitHub (sin pantalla fisica).
#
# Detecta la arquitectura del runner y solo ejecuta lo que esa maquina puede ejecutar:
#   - Runner Intel (x86_64): arranca la parte x86_64 de forma nativa. La parte arm64
#     NO puede ejecutarse en Intel (Rosetta solo traduce x86_64 -> arm64), asi que queda
#     marcada como PENDIENTE en un Mac Apple Silicon real.
#   - Runner Apple Silicon (arm64): arranca arm64 nativo y, si Rosetta 2 esta instalado,
#     tambien x86_64 traducido (que no sustituye a probar en un Mac Intel real).
# Prueba = la app sigue en ejecucion 20 s despues de lanzarla.
#
# Uso: smoke_test.sh <MapMap.app> <informe.md>
set -uo pipefail
APP="${1%/}"; REPORT="$2"
mkdir -p "$(dirname "$REPORT")"
BIN="$APP/Contents/MacOS/MapMap"
HOST="$(uname -m)"
FAIL=0
ROWS=()

has_slice() { lipo -archs "$BIN" | tr ' ' '\n' | grep -qE "^$1"; }

run() {  # $1 = arquitectura forzada (x86_64|arm64), $2 = etiqueta
  local slice="$1"
  local label="$2"
  local log="smoke_${slice}.log"
  arch "-$slice" "$BIN" > "$log" 2>&1 &
  local pid=$!
  sleep 20
  if kill -0 "$pid" 2>/dev/null; then
    kill "$pid" 2>/dev/null; wait "$pid" 2>/dev/null
    ROWS+=("| Arranque $label | EJECUTADA | OK: sigue en ejecución tras 20 s |")
  else
    wait "$pid"; local code=$?
    ROWS+=("| Arranque $label | EJECUTADA | FALLO: terminó con código $code (ver $log) |")
    FAIL=1
  fi
}

if [ "$HOST" = "x86_64" ]; then
  has_slice x86_64 && run x86_64 "x86_64 nativo (runner Intel)" \
    || { ROWS+=("| Arranque x86_64 | EJECUTADA | FALLO: el ejecutable no tiene parte x86_64 |"); FAIL=1; }
  ROWS+=("| Arranque arm64 | NO EJECUTABLE AQUÍ | Pendiente en un Mac Apple Silicon real (un Mac Intel no puede ejecutar arm64) |")
elif [ "$HOST" = "arm64" ]; then
  has_slice arm64 && run arm64 "arm64 nativo (runner Apple Silicon)" \
    || { ROWS+=("| Arranque arm64 | EJECUTADA | FALLO: el ejecutable no tiene parte arm64 |"); FAIL=1; }
  if arch -x86_64 /usr/bin/true 2>/dev/null; then
    run x86_64 "x86_64 traducido con Rosetta 2"
  else
    ROWS+=("| Arranque x86_64 | NO EJECUTABLE AQUÍ | Rosetta 2 no disponible; pendiente en un Mac Intel real |")
  fi
else
  ROWS+=("| Arranque | NO EJECUTADA | Arquitectura de runner desconocida: $HOST |"); FAIL=1
fi

{
  echo "# Pruebas de macOS"
  echo
  echo "Entorno de CI: GitHub Actions, $(sw_vers -productName) $(sw_vers -productVersion), runner **$HOST**, sin pantalla física ni GPU dedicada."
  echo
  echo "## 1. Pruebas ejecutadas automáticamente en CI"
  echo
  echo "| Prueba | Estado | Resultado |"
  echo "|---|---|---|"
  echo "| Compilación Universal (x86_64 + arm64) | EJECUTADA | Ver paso de compilación |"
  echo "| Verificación estática por arquitectura (dependencias, macOS 12, Qt/FFmpeg/Syphon) | EJECUTADA | Ver \`macos_verificacion_universal.md\` |"
  echo "| Firma ad hoc válida | EJECUTADA | Ver \`macos_verificacion_universal.md\` |"
  for r in "${ROWS[@]}"; do echo "$r"; done
  echo
  echo "## 2. Pendientes en un Mac Apple Silicon real (M1, M2, M3, M4…)"
  echo
  echo "| Prueba | Estado |"
  echo "|---|---|"
  [ "$HOST" = "x86_64" ] && echo "| Arranque nativo arm64 (Monitor de Actividad → Tipo: Apple) | PENDIENTE |"
  echo "| Abrir el DMG, copiar a Aplicaciones y primer arranque con \"Abrir igualmente\" (Gatekeeper) | PENDIENTE |"
  echo "| Interfaz, importar imagen, importar y reproducir vídeo, audio | PENDIENTE |"
  echo "| Crear y deformar superficies; guardar y abrir proyectos | PENDIENTE |"
  echo "| Varias pantallas y salida a proyector | PENDIENTE |"
  echo "| Versión portable (ZIP) | PENDIENTE |"
  echo
  echo "## 3. Pendientes en un Mac Intel real"
  echo
  echo "| Prueba | Estado |"
  echo "|---|---|"
  echo "| Gatekeeper, interfaz, vídeo, audio, superficies, proyectos, pantallas y proyector | PENDIENTE |"
  [ "$HOST" = "arm64" ] && echo "| Arranque x86_64 nativo (Rosetta no equivale a un Mac Intel) | PENDIENTE |"
  echo
  echo "Use \`PRUEBAS_MANUALES.md\` para registrar los resultados."
  echo
  for f in smoke_*.log; do
    [ -e "$f" ] || continue
    echo "## Salida de $f (primeras 60 líneas)"; echo '```'; head -60 "$f"; echo '```'
  done
} > "$REPORT"
cat "$REPORT"
exit $FAIL
