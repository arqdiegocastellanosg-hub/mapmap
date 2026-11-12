; Instalador de MapMap para Windows (Inno Setup 6.3 o superior).
; Lo compila .github/workflows/distribucion.yml:
;   ISCC.exe /DMyAppVersion=1.0.0 /DSourceDir=<carpeta desplegada> /DOutputDir=<salida> MapMap.iss
; SourceDir es la carpeta generada por windeployqt (MapMap.exe + DLL + plugins + licencias).

#ifndef MyAppVersion
  #define MyAppVersion "0.0.0"
#endif
#ifndef SourceDir
  #error "Falta /DSourceDir=<carpeta con MapMap.exe desplegado>"
#endif
#ifndef OutputDir
  #define OutputDir "."
#endif

#define MyAppName "MapMap"
#define MyAppExeName "MapMap.exe"

[Setup]
; AppId fijo: permite actualizar/desinstalar versiones anteriores de este instalador.
AppId={{8F3C2B71-5D4E-4A8B-9C1F-2E6D7A9B0C13}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher=MapMap Team (compilacion de la comunidad)
AppPublisherURL=https://github.com/mapmapteam/mapmap
AppSupportURL=https://github.com/mapmapteam/mapmap/issues
AppCopyright=MapMap Team - GNU GPL v3
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableDirPage=no
DisableProgramGroupPage=yes
LicenseFile={#SourceDir}\licencias\MapMap_GPL-3.0.txt
OutputDir={#OutputDir}
OutputBaseFilename=MapMap_Setup_Windows
SetupIconFile=..\..\resources\app_icons\mapmap.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
UninstallDisplayName={#MyAppName} {#MyAppVersion}
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
; Solo Windows de 64 bits; Windows 10 version 1809 (compilacion 17763) o superior, minimo de Qt 6.8.
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0.17763
; Instala en "Archivos de programa" (requiere confirmacion de administrador).
; El usuario puede elegir "solo para mi" en el dialogo inicial.
PrivilegesRequired=admin
PrivilegesRequiredOverridesAllowed=dialog
CloseApplications=yes

[Languages]
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "french";  MessagesFile: "compiler:Languages\French.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\Licencias de {#MyAppName}"; Filename: "{app}\licencias"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#MyAppName}}"; Flags: nowait postinstall skipifsilent
