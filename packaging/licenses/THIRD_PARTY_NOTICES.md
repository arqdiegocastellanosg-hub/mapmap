# Avisos de licencia de MapMap y de los componentes incluidos

Esta distribución de MapMap se compiló a partir del código fuente oficial
(https://github.com/mapmapteam/mapmap). El código fuente exacto de esta versión
se incluye en la carpeta `Codigo_Fuente` de la distribución y en la Release de
GitHub del fork desde el que se generó.

## MapMap
- Licencia: **GNU General Public License v3** (`MapMap_GPL-3.0.txt`).
- Copyright: el equipo de MapMap y sus colaboradores (Sofian Audry, Alexandre
  Quessy, Dame Diongue, Mike Latona, Vasilis Liaskovitis y otros; ver el
  archivo `README.md` y el historial del código fuente).
- Este programa se distribuye SIN NINGUNA GARANTÍA. Consulte la licencia.

## Componentes incluidos en el código de MapMap
| Componente | Licencia | Plataforma |
|---|---|---|
| oscpack (Ross Bencina), en `src/control/qosc/contrib/oscpack` | Tipo MIT (aviso incluido en las cabeceras del código fuente) | Todas |
| Qt Solutions Property Browser (Digia), en `src/gui/contrib/qtpropertybrowser` | BSD (aviso en las cabeceras del código fuente) | Todas |
| Syphon.framework | BSD 2-Clause (`Syphon_BSD-2-Clause.txt`) | Solo macOS |

## Bibliotecas que se distribuyen junto al ejecutable
| Componente | Licencia | Notas |
|---|---|---|
| Qt 6 (Core, Gui, Widgets, OpenGL, OpenGLWidgets, Network, Multimedia, MultimediaWidgets y plugins) | **LGPL v3** (`LGPL-3.0.txt`, `GPL-3.0.txt`) | Enlazado dinámicamente. Las bibliotecas se pueden reemplazar por otras versiones compatibles. Código fuente de Qt: https://download.qt.io/official_releases/qt/ (versión indicada en `Versiones_y_Configuracion.txt`) y https://code.qt.io |
| FFmpeg (incluido por Qt Multimedia) | **LGPL v2.1** (`LGPL-2.1.txt`) | Compilación de FFmpeg distribuida por The Qt Company con los binarios de Qt, sin componentes solo GPL. Código fuente: https://ffmpeg.org/download.html. Las versiones exactas aparecen en los nombres de las DLL/dylib (ver `Dependencias/`). |
| Runtime de GCC/MinGW-w64: libstdc++, libgcc_s (solo Windows) | GPL v3 con **GCC Runtime Library Exception 3.1** (`GCC-Runtime-Library-Exception-3.1.txt`) | |
| winpthreads de MinGW-w64 (solo Windows) | MIT / ZPL 2.1 | Código fuente: https://www.mingw-w64.org |
| opengl32sw.dll, Mesa llvmpipe (solo Windows, OpenGL por software) | MIT | Incluido por windeployqt desde los binarios de Qt |

## Cómo obtener el código fuente correspondiente
1. La carpeta `Codigo_Fuente` contiene el archivo `.tar.gz` con el código exacto usado
   para compilar estos binarios, incluidos los scripts de compilación y empaquetado.
2. El mismo archivo se adjunta a la Release de GitHub del fork.
3. Para Qt y FFmpeg, se usaron los binarios oficiales sin modificar. Sus fuentes están
   en los enlaces de arriba. Quien redistribuya este paquete comercialmente debería
   conservar también una copia de esas fuentes, según la sección 6 de la GPL v3 y la
   LGPL.
