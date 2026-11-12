#!/bin/bash
# Prueba de arranque en el runner macOS de GitHub (Apple Silicon, sin pantalla fisica).
# Lanza MapMap y comprueba que siga en ejecucion tras 20 s.
# Si Rosetta 2 esta disponible, repite la prueba forzando la parte x86_64 (Intel).
# Uso: smoke_test.sh <MapMap.app> <informe.md>
set -uo pipefail
APP="$1"; REPORT="$2"
mkdir -p "$(dirname "$REPORT")"
BIN="$APP/Contents/MacOS/MapMap"
FAIL=0

run() {  # $1 = etiqueta, resto = comando
  local label="$1"; shift
  "$@" > "smoke_$label.log" 2>&1 &
  local pid=$!
  sleep 20
  if kill -0 "$pid" 2>/dev/null; then
    kill "$pid"; wait "$pid" 2>/dev/null
    echo "| Arranque $label (20 s sin cerrarse) | OK |"
  else
    wait "$pid"; local code=$?
    echo "| Arranque $label (20 s sin cerrarse) | FALLO (codigo $code) |"
    return 1
  fi
}

{
  echo "# Pruebas automaticas de macOS"
  echo
  echo "Entorno: GitHub Actions $(sw_vers -productName) $(sw_vers -productVersion), $(uname -m), sin pantalla fisica."
  echo
  echo "| Prueba | Resultado |"
  echo "|---|---|"
  run arm64 arch -arm64 "$BIN" || FAIL=1
  if arch -x86_64 /usr/bin/true 2>/dev/null; then
    run x86_64-Rosetta arch -x86_64 "$BIN" || FAIL=1
  else
    echo "| Arranque x86_64 | NO VERIFICADO (Rosetta 2 no disponible en el runner) |"
  fi
  echo
  echo "## No verificable en este entorno (requiere un Mac real)"
  echo "- Apertura del DMG y primer arranque con Gatekeeper (firma ad hoc, no notarizada)."
  echo "- Funcionamiento nativo en un Mac Intel (Rosetta solo emula x86_64)."
  echo "- Interfaz interactiva, importacion de imagenes y videos, audio, superficies,"
  echo "  guardar y abrir proyectos, varias pantallas y salida a proyector."
  echo
  for f in smoke_*.log; do echo "## $f"; echo '```'; head -60 "$f"; echo '```'; done
} > "$REPORT"
cat "$REPORT"
exit $FAIL
