# Distribución automatizada de MapMap (Windows y macOS)

Esta carpeta y el workflow `.github/workflows/distribucion.yml` se añadieron en el fork.
**No modifican el código de MapMap**, así que el fork se puede seguir actualizando
desde el proyecto oficial sin conflictos.

## Qué genera cada ejecución
| Artefacto | Contenido |
|---|---|
| `MapMap_Distribucion` | Estructura completa de entrega (instaladores, portables, código fuente, licencias, documentación, informes, `SHA256SUMS.txt`) |
| `windows` | `MapMap_Setup_Windows.exe`, `MapMap_Portable_Windows.zip` |
| `macos` | `MapMap_Installer_macOS.dmg`, `MapMap_Portable_macOS.zip` |
| `informe-windows`, `informe-macos` | Dependencias verificadas, pruebas automáticas, versiones de las herramientas |
| `fuente-y-licencias` | Código fuente correspondiente (`.tar.gz`) y textos de licencia |

Los artefactos se guardan 90 días en GitHub. Para conservarlos más tiempo, publique una
Release (ver abajo) o descargue `MapMap_Distribucion` y guárdelo como copia maestra.

## Generar una nueva versión
**Opción 1, manual:** en GitHub, abra el fork > pestaña **Actions** > **Distribucion** >
**Run workflow**. Marque "Publicar" si quiere crear una Release (pre-release) con los
instaladores adjuntos. Tarda unos 20-40 minutos.

**Opción 2, con etiqueta:** cree una etiqueta que empiece por `v` en el commit deseado
(por ejemplo `v1.0.0-alpha.1`). El workflow se ejecuta y publica la Release automáticamente.

## Actualizar el fork con los cambios del proyecto oficial
En la página del fork: **Sync fork** > **Update branch**. Después ejecute el workflow.
Si el proyecto oficial cambia el sistema de compilación (por ejemplo, de qmake a CMake),
habrá que adaptar `distribucion.yml`.

## Cambiar la versión de Qt
Edite `QT_VERSION` al principio de `distribucion.yml`. Notas:
- Windows usa `win64_mingw` con `tools_mingw1310`. Otras versiones de Qt pueden requerir
  otra versión de MinGW. Consulte la documentación de Qt de esa versión.
- Qt 6.12 será la última versión de Qt compatible con Windows 10.
- macOS usa `clang_64`, que son binarios universales de Qt.

## Estructura de esta carpeta
```
packaging/
  windows/MapMap.iss          Script de Inno Setup (instalador)
  windows/check_deps.ps1      Verifica DLL, plugins y FFmpeg (objdump)
  windows/test_installer.ps1  Instala, arranca sin Qt en el PATH y desinstala
  macos/package_app.sh        macdeployqt, Info.plist, licencias, firma ad hoc
  macos/check_app.sh          Verifica Universal (lipo) y rutas externas (otool)
  macos/smoke_test.sh         Arranque arm64 y x86_64 (Rosetta)
  macos/make_dmg.sh           DMG y ZIP portable
  common/assemble_distribution.sh  Estructura MapMap_Distribucion
  licenses/THIRD_PARTY_NOTICES.md  Avisos de licencia
  docs/                       Instrucciones para usuarios finales y pruebas manuales
```

## Limitaciones conocidas
- **macOS:** firma ad hoc, sin notarización. Los usuarios deben permitir la app la primera
  vez (ver `docs/INSTALAR_macOS.txt`). Para eliminar ese paso hace falta el Apple Developer
  Program, añadir el certificado Developer ID como secreto del repositorio y un paso de
  `notarytool`.
- **Windows:** sin firma Authenticode, así que SmartScreen muestra un aviso.
- Las pruebas automáticas se ejecutan en servidores sin GPU ni pantalla. Las funciones
  interactivas, de vídeo, de audio y de proyector se validan con `docs/PRUEBAS_MANUALES.md`.
