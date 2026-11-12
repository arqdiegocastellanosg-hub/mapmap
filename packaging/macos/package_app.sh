#!/bin/bash
# Prepara MapMap.app para distribucion:
#   - macdeployqt (Qt, plugins, FFmpeg dentro del bundle)
#   - version y sistema minimo correctos en el Info.plist del bundle generado
#     (resources/macOS/Info.plist del proyecto declara 0.6.3 y macOS 10.10; no se
#      modifica el original, solo la copia dentro del .app)
#   - licencias dentro de Contents/Resources/licencias
#   - firma ad hoc (sin certificado de Apple Developer)
#
# Uso: package_app.sh <MapMap.app> <version> <carpeta_licencias>
set -euo pipefail
APP="$1"; VERSION="$2"; LICS="$3"
PLIST="$APP/Contents/Info.plist"

macdeployqt "$APP" -always-overwrite -verbose=1

# Version visible en Finder y sistema minimo exigido por Qt 6.8 (macOS 12).
SHORT="${VERSION%%-*}"   # CFBundleShortVersionString solo admite numeros: 1.0.0
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $SHORT" "$PLIST"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $SHORT" "$PLIST"
/usr/libexec/PlistBuddy -c "Set :LSMinimumSystemVersion 12.0" "$PLIST"
/usr/libexec/PlistBuddy -c "Set :CFBundleName MapMap" "$PLIST"
/usr/libexec/PlistBuddy -c "Delete :NOTE" "$PLIST" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :MapMapBuildVersion string $VERSION" "$PLIST" 2>/dev/null \
  || /usr/libexec/PlistBuddy -c "Set :MapMapBuildVersion $VERSION" "$PLIST"

mkdir -p "$APP/Contents/Resources/licencias"
cp "$LICS"/* "$APP/Contents/Resources/licencias/"

# Firma ad hoc ("-"): obligatoria para ejecutar codigo arm64 en Apple Silicon.
# No es una firma Developer ID ni esta notarizada; Gatekeeper mostrara un aviso.
codesign --force --deep --sign - --timestamp=none "$APP"
codesign --verify --deep --strict --verbose=2 "$APP"
codesign -dv "$APP" 2>&1 | grep -E 'Signature|Identifier|Format' || true
