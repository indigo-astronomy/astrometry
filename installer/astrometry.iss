; Inno Setup script for the Windows build of the Astrometry.net command-line
; tools (image2xy, new-wcs, solve-field, astrometry-engine, wcsinfo).
;
; The binaries produced by ..\Makefile are fully statically linked (verified
; with `objdump -p bin\*.exe | findstr "DLL Name"` -> only KERNEL32.dll,
; msvcrt.dll and USER32.dll, all standard Windows system DLLs), so there are
; no extra runtime libraries (no libwinpthread-1.dll, no libgcc DLL, etc.) to
; ship. The "*.dll" line below is only a safety net in case a future build
; isn't fully static.
;
; Build with: iscc installer\astrometry.iss   (from an Inno Setup 6 install)
;
; This script expects the 5 binaries to already be built in ..\bin (run
; `make` first from the repo root).

#define MyAppName "Astrometry.net for Windows"
#define MyAppVersion "0.95"
#define MyAppPublisher "Astrometry.net"
#define MyAppURL "https://astrometry.net"

[Setup]
AppId={{6F1B0F1E-6C0B-4B7C-9C7B-6E7C7B0C7A11}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\Astrometry.net
DefaultGroupName=Astrometry.net
DisableProgramGroupPage=yes
; Let the user choose a per-machine (admin) or per-user install; this also
; determines whether we edit the system-wide or the per-user PATH below.
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir=..\dist
OutputBaseFilename=astrometry-windows-{#MyAppVersion}-setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
UninstallDisplayIcon={app}\bin\solve-field.exe

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "modifypath"; Description: "Add the Astrometry.net ""bin"" folder to my PATH environment variable"; Flags: checkedonce

[Files]
; The 5 command-line tools built by the top-level Makefile.
Source: "..\bin\image2xy.exe"; DestDir: "{app}\bin"; Flags: ignoreversion
Source: "..\bin\new-wcs.exe"; DestDir: "{app}\bin"; Flags: ignoreversion
Source: "..\bin\solve-field.exe"; DestDir: "{app}\bin"; Flags: ignoreversion
Source: "..\bin\astrometry-engine.exe"; DestDir: "{app}\bin"; Flags: ignoreversion
Source: "..\bin\wcsinfo.exe"; DestDir: "{app}\bin"; Flags: ignoreversion
; Safety net only: pick up any DLLs that end up next to the binaries (there
; shouldn't be any, since the build is fully static).
Source: "..\bin\*.dll"; DestDir: "{app}\bin"; Flags: ignoreversion skipifsourcedoesntexist

[Dirs]
; Where the user should drop index files; referenced by the generated
; astrometry.cfg (see WriteDefaultConfig below).
Name: "{app}\data"
Name: "{app}\etc"

[Code]
const
  AST_WM_SETTINGCHANGE = $001A;
  AST_HWND_BROADCAST = $FFFF;
  AST_SMTO_ABORTIFHUNG = $0002;
  EnvKeyHKLM = 'SYSTEM\CurrentControlSet\Control\Session Manager\Environment';
  EnvKeyHKCU = 'Environment';

function SendMessageTimeoutA(hWnd: LongInt; Msg: LongInt; wParam: LongInt;
  lParam: AnsiString; fuFlags: LongInt; uTimeout: LongInt; var lpdwResult: LongInt): LongInt;
  external 'SendMessageTimeoutA@user32.dll stdcall';

function EnvRootKey(): Integer;
begin
  if IsAdminInstallMode then
    Result := HKEY_LOCAL_MACHINE
  else
    Result := HKEY_CURRENT_USER;
end;

function EnvSubKey(): String;
begin
  if IsAdminInstallMode then
    Result := EnvKeyHKLM
  else
    Result := EnvKeyHKCU;
end;

procedure BroadcastEnvironmentChange();
var
  Res: LongInt;
begin
  SendMessageTimeoutA(AST_HWND_BROADCAST, AST_WM_SETTINGCHANGE, 0, 'Environment',
    AST_SMTO_ABORTIFHUNG, 5000, Res);
end;

function PathContainsDir(Path, Dir: string): Boolean;
var
  P: Integer;
  Entry, Remaining: string;
begin
  Result := False;
  Remaining := Path;
  while Length(Remaining) > 0 do
  begin
    P := Pos(';', Remaining);
    if P = 0 then
    begin
      Entry := Remaining;
      Remaining := '';
    end
    else
    begin
      Entry := Copy(Remaining, 1, P - 1);
      Remaining := Copy(Remaining, P + 1, Length(Remaining));
    end;
    if CompareText(Trim(Entry), Dir) = 0 then
    begin
      Result := True;
      exit;
    end;
  end;
end;

procedure AddDirToPath(Dir: string);
var
  Path: string;
begin
  if not RegQueryStringValue(EnvRootKey(), EnvSubKey(), 'Path', Path) then
    Path := '';

  if PathContainsDir(Path, Dir) then
    exit;

  if (Path <> '') and (Path[Length(Path)] <> ';') then
    Path := Path + ';' + Dir
  else
    Path := Path + Dir;

  if RegWriteStringValue(EnvRootKey(), EnvSubKey(), 'Path', Path) then
    BroadcastEnvironmentChange();
end;

procedure RemoveDirFromPath(Dir: string);
var
  Path, NewPath, Entry, Remaining: string;
  P: Integer;
begin
  if not RegQueryStringValue(EnvRootKey(), EnvSubKey(), 'Path', Path) then
    exit;

  NewPath := '';
  Remaining := Path;
  while Length(Remaining) > 0 do
  begin
    P := Pos(';', Remaining);
    if P = 0 then
    begin
      Entry := Remaining;
      Remaining := '';
    end
    else
    begin
      Entry := Copy(Remaining, 1, P - 1);
      Remaining := Copy(Remaining, P + 1, Length(Remaining));
    end;

    if (Trim(Entry) <> '') and (CompareText(Trim(Entry), Dir) <> 0) then
    begin
      if NewPath = '' then
        NewPath := Entry
      else
        NewPath := NewPath + ';' + Entry;
    end;
  end;

  if RegWriteStringValue(EnvRootKey(), EnvSubKey(), 'Path', NewPath) then
    BroadcastEnvironmentChange();
end;

// astrometry-engine looks for "astrometry.cfg" in "..\etc" relative to its
// own folder (i.e. {app}\etc, next to {app}\bin), or in "..\etc" from the
// current directory. We can't ship a static config file with the right
// "add_path" (the real install directory isn't known until now), so write
// a minimal one pointing at {app}\data, unless the user already has one.
procedure WriteDefaultConfig();
var
  CfgPath, DataPath, EtcDir: string;
  Cfg: TStringList;
begin
  EtcDir := ExpandConstant('{app}\etc');
  if not ForceDirectories(EtcDir) then
  begin
    Log('Failed to create ' + EtcDir);
    exit;
  end;

  CfgPath := EtcDir + '\astrometry.cfg';
  if FileExists(CfgPath) then
    exit;

  DataPath := ExpandConstant('{app}\data');
  Cfg := TStringList.Create;
  try
    Cfg.Add('# Config file for astrometry-engine, generated by the installer.');
    Cfg.Add('# See https://astrometry.net for details on each option.');
    Cfg.Add('');
    Cfg.Add('# Check the indices in parallel (needs enough RAM to hold them all).');
    Cfg.Add('#inparallel');
    Cfg.Add('');
    Cfg.Add('# Maximum CPU time to spend solving a field, in seconds.');
    Cfg.Add('cpulimit 300');
    Cfg.Add('');
    Cfg.Add('# Directory to search for index files (drop your index-*.fits files here).');
    Cfg.Add('add_path ' + DataPath);
    Cfg.Add('');
    Cfg.Add('# Automatically load any indices found in the directories above.');
    Cfg.Add('autoindex');
    Cfg.SaveToFile(CfgPath);
  finally
    Cfg.Free;
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    if WizardIsTaskSelected('modifypath') then
      AddDirToPath(ExpandConstant('{app}\bin'));
    WriteDefaultConfig();
  end;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usPostUninstall then
    RemoveDirFromPath(ExpandConstant('{app}\bin'));
end;
