# Lista de pruebas manuales

Las pruebas automáticas de GitHub Actions comprueban la compilación, las dependencias,
la instalación y desinstalación (Windows), la arquitectura Universal (macOS) y que la
aplicación arranque. Todo lo demás requiere un equipo real. Anote el resultado de cada
prueba: **OK**, **FALLO** (con descripción) o **NO PROBADO**.

Equipo: ____________________  Sistema: ____________________  Fecha: __________

## Windows (Windows 10 y Windows 11, por separado)
| # | Prueba | Resultado | Notas |
|---|---|---|---|
| W1 | Instalar desde cero con MapMap_Setup_Windows.exe (equipo o VM sin Qt) | | |
| W2 | Accesos directos del escritorio y del menú Inicio | | |
| W3 | MapMap abre y muestra la interfaz | | |
| W4 | Importar una imagen (PNG/JPG) | | |
| W5 | Importar y reproducir un vídeo (MP4 H.264) | | |
| W6 | Audio del vídeo audible | | |
| W7 | Crear una superficie (triángulo, cuadrilátero, malla) | | |
| W8 | Deformar la superficie moviendo los vértices | | |
| W9 | Guardar el proyecto, cerrar y volver a abrirlo | | |
| W10 | Detectar una segunda pantalla | | |
| W11 | Salida a pantalla completa en el proyector | | |
| W12 | Versión portable: descomprimir y ejecutar | | |
| W13 | Desinstalar y comprobar que la carpeta se elimina | | |

## macOS (Apple Silicon e Intel, por separado)
| # | Prueba | Resultado | Notas |
|---|---|---|---|
| M1 | Abrir el DMG y copiar MapMap.app a Aplicaciones | | |
| M2 | Primer arranque con "Abrir igualmente" (ver LEEME) | | |
| M3 | MapMap abre y muestra la interfaz | | |
| M4 | Importar una imagen | | |
| M5 | Importar y reproducir un vídeo (MP4 H.264 / MOV) | | |
| M6 | Audio del vídeo audible | | |
| M7 | Crear y deformar superficies | | |
| M8 | Guardar y abrir un proyecto | | |
| M9 | Detectar una segunda pantalla | | |
| M10 | Salida a pantalla completa en el proyector | | |
| M11 | Mac Intel: funciona de forma nativa | | |
| M12 | Apple Silicon: funciona de forma nativa (Monitor de Actividad: tipo "Apple") | | |
| M13 | Versión portable: descomprimir y ejecutar | | |
