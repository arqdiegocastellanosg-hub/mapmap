#!/bin/bash
# Crea MapMap_Installer_macOS.dmg (MapMap.app + acceso a Aplicaciones + LEEME + licencias)
# y MapMap_Portable_macOS.zip.
# Uso: make_dmg.sh <MapMap.app> <carpeta_salida> <carpeta_licencias>
set -euo pipefail
APP="$1"; LICS="$3"
mkdir -p "$2"; OUT="$(cd "$2" && pwd)"
HERE="$(cd "$(dirname "$0")/../.." && pwd)"

STAGE="$(mktemp -d)/MapMap"
mkdir -p "$STAGE/Licencias"
ditto "$APP" "$STAGE/MapMap.app"
ln -s /Applications "$STAGE/Aplicaciones"
cp "$HERE/packaging/docs/INSTALAR_macOS.txt" "$STAGE/LEEME - Como abrir MapMap.txt"
cp "$LICS"/* "$STAGE/Licencias/"

hdiutil create -volname "MapMap" -srcfolder "$STAGE" -fs HFS+ -format UDZO -ov \
  "$OUT/MapMap_Installer_macOS.dmg"
hdiutil verify "$OUT/MapMap_Installer_macOS.dmg"

# Portable: misma carpeta sin el enlace a Aplicaciones.
rm "$STAGE/Aplicaciones"
( cd "$(dirname "$STAGE")" && ditto -c -k --sequesterRsrc --keepParent MapMap "$OUT/MapMap_Portable_macOS.zip" )
ls -lh "$OUT"
