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
**Run workflow**. Elija qué generar en **plataformas**:

| Modo | Jobs que se ejecutan | Artefactos |
|---|---|---|
| **Solo Windows** | `windows` (independiente) y `fuente` (código fuente GPL, en paralelo) | `MapMap_Setup_Windows`, `MapMap_Portable_Windows`, `windows`, `informe-windows`, `fuente-y-licencias` |
| **Completa** (por defecto) | `fuente`, `windows`, `macos`, `distribucion` | Todo lo anterior, más `macos`, `informe-macos` y `MapMap_Distribucion` |

En el modo Solo Windows, el job `windows` no depende de ningún otro: no espera a macOS ni a
Ubuntu, y obtiene su propia versión y licencias. Tampoco se genera el paquete multiplataforma.
En modo Completa, elija también el runner de macOS (por defecto `macos-15-intel`).
Tarda unos 20-40 minutos. Los resultados quedan como artefactos de la ejecución y no se publica nada.

**Opción 2, con etiqueta:** cree una etiqueta que empiece por `v` (por ejemplo `v1.0.0-alpha.1`).
El workflow se ejecuta con el runner de macOS por defecto.

Si un job falla (por ejemplo, porque no hay runner de macOS disponible), abra la ejecución y
pulse **Re-run failed jobs**: solo se repiten el job fallido y los que dependen de él.

## Publicación de Releases (desactivada por defecto)
El job `publicar` tiene un doble seguro. Solo se ejecuta si existe la variable de repositorio
`PUBLICAR_RELEASES` con valor `true` (Settings > Secrets and variables > Actions > Variables)
**y**, además, la ejecución viene de una etiqueta `v*` o se marcó la casilla "publicar".
Mientras esa variable no exista, el workflow nunca crea Releases.

## Runner de macOS y compilación Universal
- Por defecto se usa `macos-15-intel`. Xcode compila las dos arquitecturas (x86_64 y arm64)
  desde un Mac Intel mediante compilación cruzada (`QMAKE_APPLE_DEVICE_ARCHS="x86_64 arm64"`),
  enlazando con el Qt oficial, que es universal. Así se evitan las colas de los runners ARM64.
- Alternativa: `macos-15` (Apple Silicon). Genera el mismo resultado Universal.
- **Limitación:** en un runner Intel la parte arm64 se verifica de forma estática (arquitectura,
  dependencias, sistema mínimo, firma), pero no se puede ejecutar. El arranque en Apple Silicon
  se prueba en un Mac real (ver `docs/PRUEBAS_MANUALES.md`, prueba M12).
- GitHub mantendrá `macos-15-intel` hasta otoño de 2027 (último runner Intel). Después habrá
  que usar `macos-15` u otro runner ARM64: basta elegirlo en el formulario o cambiar el valor
  por defecto en `distribucion.yml`.

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
  macos/check_app.sh          Por cada binario y cada arquitectura: presencia (lipo),
                              dependencias (otool -arch), sistema minimo <= macOS 12
  macos/smoke_test.sh         Arranque de las arquitecturas ejecutables en el runner;
                              informe de pruebas ejecutadas y pendientes
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
