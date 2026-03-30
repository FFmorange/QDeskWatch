#define MyAppName "QDeskWatch"
#define MyAppPublisher "QDeskWatch"
#define MyAppExeName "QDeskWatch.exe"
#define MyAppURL "https://github.com/"

#ifndef MyAppVersion
  #define MyAppVersion "0.0.0"
#endif

#ifndef MyAppSourceDir
  #define MyAppSourceDir "install"
#endif

#ifndef MyInstallerOutputDir
  #define MyInstallerOutputDir "dist"
#endif

#ifndef MyInstallerBaseName
  #define MyInstallerBaseName MyAppName + "-Setup-" + MyAppVersion
#endif

[Setup]
AppId={{5E30E48A-5151-4B4B-B7A7-53B248D2A6CC}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
SourceDir={#MyAppSourceDir}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
LicenseFile={#AddBackslash(SourcePath) + "..\..\LICENSE"}
PrivilegesRequired=admin
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
OutputDir={#MyInstallerOutputDir}
OutputBaseFilename={#MyInstallerBaseName}
UninstallDisplayIcon={app}\bin\{#MyAppExeName}

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "bin\vc_redist.x64.exe"; Flags: dontcopy noencryption
Source: "*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs; Excludes: "bin\vc_redist.x64.exe"

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\bin\{#MyAppExeName}"; WorkingDir: "{app}\bin"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\bin\{#MyAppExeName}"; WorkingDir: "{app}\bin"; Tasks: desktopicon

[Run]
Filename: "{app}\bin\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#MyAppName}}"; WorkingDir: "{app}\bin"; Flags: nowait postinstall skipifsilent

[Code]
function PrepareToInstall(var NeedsRestart: Boolean): String;
var
  ResultCode: Integer;
  RedistPath: String;
begin
  Result := '';
  ExtractTemporaryFile('vc_redist.x64.exe');
  RedistPath := ExpandConstant('{tmp}\vc_redist.x64.exe');

  Log(Format('Running Visual C++ Redistributable installer: %s', [RedistPath]));

  if not Exec(RedistPath, '/install /quiet /norestart', '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
  begin
    Result :=
      'Unable to start the Microsoft Visual C++ Redistributable installer.' + #13#10 +
      'Please run Setup again, or install vc_redist.x64.exe manually before launching QDeskWatch.';
    Exit;
  end;

  Log(Format('vc_redist.x64.exe exit code: %d', [ResultCode]));

  case ResultCode of
    0, 1638:
      Result := '';
    3010, 1641:
      begin
        NeedsRestart := True;
        Result :=
          'Microsoft Visual C++ Redistributable was installed and requires a system restart.' + #13#10 +
          'Please restart Windows and run this installer again to finish installing QDeskWatch.';
      end;
  else
    Result :=
      'Microsoft Visual C++ Redistributable installation failed with exit code ' +
      IntToStr(ResultCode) + '.' + #13#10 +
      'Please install vc_redist.x64.exe manually, then run this installer again.';
  end;
end;


