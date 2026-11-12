#!/bin/bash
# Ensambla la estructura final de entrega a partir de los artefactos del workflow:
#
# MapMap_Distribucion/
#   Windows/  MapMap_Setup_Windows.exe, MapMap_Portable_Windows.zip
#   macOS/    MapMap_Installer_macOS.dmg, MapMap_Portable_macOS.zip
#   Codigo_Fuente/  Licencias/  Documentacion/  Dependencias/  Informe_Pruebas/
#   Versiones_y_Configuracion.txt  SHA256SUMS.txt
#
# Uso: assemble_distribution.sh <dir_artefactos> <dir_salida> <version> <sha> <qt_version>
set -euo pipefail
A="$1"; D="$2"; VERSION="$3"; SHA="$4"; QT="$5"
HERE="$(cd "$(dirname "$0")/../.." && pwd)"

mkdir -p "$D"/{Windows,macOS,Codigo_Fuente,Licencias,Documentacion,Dependencias,Informe_Pruebas}

cp "$A/windows/MapMap_Setup_Windows.exe" "$A/windows/MapMap_Portable_Windows.zip" "$D/Windows/"
cp "$A/macos/MapMap_Installer_macOS.dmg" "$A/macos/MapMap_Portable_macOS.zip" "$D/macOS/"
cp -r "$A/fuente-y-licencias/Codigo_Fuente/." "$D/Codigo_Fuente/"
cp -r "$A/fuente-y-licencias/Licencias/." "$D/Licencias/"
cp "$HERE"/packaging/docs/*.txt "$HERE"/packaging/docs/*.md "$D/Documentacion/" 2>/dev/null || true
cp "$HERE/packaging/README.md" "$D/Documentacion/COMO_GENERAR_NUEVAS_VERSIONES.md"
cp "$A"/informe-windows/windows_dependencias.txt "$D/Dependencias/" 2>/dev/null || true
cp "$A"/informe-macos/macos_dependencias.txt "$D/Dependencias/" 2>/dev/null || true
cp "$A"/informe-windows/* "$A"/informe-macos/* "$D/Informe_Pruebas/" 2>/dev/null || true
cp "$HERE/packaging/docs/PRUEBAS_MANUALES.md" "$D/Informe_Pruebas/" 2>/dev/null || true

{
  echo "MapMap - Versiones y configuracion de la compilacion"
  echo "===================================================="
  echo "Version de MapMap:   $VERSION (version preliminar 'alpha' del proyecto)"
  echo "Commit:              $SHA"
  echo "Repositorio:         ${GITHUB_SERVER_URL:-https://github.com}/${GITHUB_REPOSITORY:-<fork>}"
  echo "Workflow:            .github/workflows/distribucion.yml (ejecucion ${GITHUB_RUN_ID:-local})"
  echo "Fecha (UTC):         $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "Qt:                  $QT (binarios oficiales, instalados con jurplel/install-qt-action)"
  echo "Backend multimedia:  Qt Multimedia con FFmpeg (incluido en los binarios de Qt)"
  echo
  echo "--- Windows ---"
  cat "$A/informe-windows/windows_versiones.txt" 2>/dev/null || echo "(sin datos)"
  cat "$A/informe-windows/windows_innosetup_version.txt" 2>/dev/null || true
  echo "Destino: Windows 10 (1809+) y Windows 11, x64. Verificado solo en el runner (Windows Server)."
  echo "Firma de codigo: ninguna (Windows SmartScreen puede mostrar un aviso)."
  echo
  echo "--- macOS ---"
  cat "$A/informe-macos/macos_versiones.txt" 2>/dev/null || echo "(sin datos)"
  echo "Arquitecturas: Universal (x86_64/x86_64h + arm64). Sistema minimo declarado: macOS 12."
  echo "Firma de codigo: ad hoc. NO firmada con Developer ID ni notarizada por Apple."
  echo
  echo "--- Cambios respecto al proyecto oficial ---"
  echo "Solo se anadieron .github/workflows/distribucion.yml y packaging/."
  echo "No se modifico el codigo de MapMap. En el bundle de macOS se ajustan, tras compilar,"
  echo "CFBundleShortVersionString y LSMinimumSystemVersion (el Info.plist original declara 0.6.3 / 10.10)."
} > "$D/Versiones_y_Configuracion.txt"

sed -e "s/@VERSION@/$VERSION/g" -e "s/@SHA@/$SHA/g" -e "s/@QT@/$QT/g" \
  "$HERE/packaging/docs/NOTAS_DE_VERSION.md.in" > "$D/Documentacion/NOTAS_DE_VERSION.md"

( cd "$D" && find . -type f ! -name SHA256SUMS.txt -print0 | sort -z | xargs -0 sha256sum > SHA256SUMS.txt )
find "$D" -maxdepth 2 | sort
