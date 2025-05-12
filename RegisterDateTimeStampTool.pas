// Revision Date : 05/12/2025
// Revision Time : 12:14 AM
// Revised by : cpstevenc
// Version Count : 13

unit RegisterDateTimeStampTool;

interface

procedure Register;

implementation

uses
 Dialogs,
 DesignIntf,
 ToolsAPI,
 Vcl.Menus,
 Vcl.ActnList,
 Vcl.Controls,
 Vcl.Graphics,
 DateTimeStampTool,
 System.SysUtils,
 System.Classes,
 System.StrUtils,
 Winapi.Windows;

type
 TDateTimeStampTool = class(TNotifierObject, IOTANotifier)
 private

 public
  procedure HandleClick(Sender: TObject);
 end;

 TIDEStartupNotifier = class(TNotifierObject, IOTAIDENotifier)
 private
  procedure AddMenuItem;
 public
  procedure AfterCompile(Succeeded: Boolean); virtual;
  procedure BeforeCompile(const Project: IOTAProject; var Cancel: Boolean); virtual;
  procedure FileNotification(NotifyCode: TOTAFileNotification; const FileName: string; var Cancel: Boolean); virtual;
 end;

 TIDEHotkeyNotifier = class(TNotifierObject, IOTAKeyboardBinding)
 public
  procedure BindKeyboard(const BindingServices: IOTAKeyBindingServices);
  function GetBindingType: TBindingType;
  function GetDisplayName: string;
  function GetName: string;
  procedure ExecuteHotkeyHandler(const Context: IOTAKeyContext; KeyCode: TShortcut; var BindingResult: TKeyBindingResult);
 end;

var
 DateTimeStampTool: TDateTimeStampTool = nil;
 NewMenuItem: TMenuItem = nil;
 MenuItemAdded: Boolean = False;
 IDEStartupNotifierIndex: Integer = -1;

const
 MENU_CAPTION = 'Version Header Stamp';
 HOTKEY_SHORTCUT = 'Ctrl+Shift+V'; // can change this to fit what you need
 PROJECT_EXTENSIONS: array [0 .. 1] of string = ('.pas', '.dpr');

 { TIDEStartupNotifier }

procedure TIDEStartupNotifier.AfterCompile(Succeeded: Boolean);
begin
 // Not used yet
end;

procedure TIDEStartupNotifier.BeforeCompile(const Project: IOTAProject; var Cancel: Boolean);
begin
 // Not used yet
end;

procedure TIDEStartupNotifier.FileNotification(NotifyCode: TOTAFileNotification; const FileName: string; var Cancel: Boolean);
var
 FileExt: string;
begin
 if NotifyCode = ofnFileOpened then
 begin
  FileExt := ExtractFileExt(FileName).ToLower;
  if MatchText(FileExt, PROJECT_EXTENSIONS) then
  begin
   AddMenuItem;
  end;
 end;
end;

procedure TIDEStartupNotifier.AddMenuItem;
var
 NTAServices: INTAServices;
 MainMenu: TMainMenu;
 ToolsMenu: TMenuItem;
 i: Integer;
 FToolButton: TControl;
begin
 if MenuItemAdded then
  Exit;

 NTAServices := (BorlandIDEServices as INTAServices);

 if Assigned(NTAServices) then
 begin
  MainMenu := NTAServices.GetMainMenu;

  if Assigned(MainMenu) then
  begin
   ToolsMenu := nil;

   for i := 0 to MainMenu.Items.Count - 1 do
   begin
    if MainMenu.Items[i].Caption = '&Tools' then
    begin
     ToolsMenu := MainMenu.Items[i];
     Break;
    end;
   end;

   if Assigned(ToolsMenu) then
   begin
    if not Assigned(DateTimeStampTool) then
     DateTimeStampTool := TDateTimeStampTool.Create;

    NewMenuItem := TMenuItem.Create(nil);
    NewMenuItem.Caption := MENU_CAPTION;
    NewMenuItem.ShortCut := TextToShortCut(HOTKEY_SHORTCUT);
    NewMenuItem.OnClick := DateTimeStampTool.HandleClick;
    ToolsMenu.Add(NewMenuItem);

    MenuItemAdded := True;

   end;
  end;
 end;
end;

{ TIDEHotkeyNotifier }

procedure TIDEHotkeyNotifier.BindKeyboard(const BindingServices: IOTAKeyBindingServices);
begin
 BindingServices.AddKeyBinding([TextToShortCut(HOTKEY_SHORTCUT)], Self.ExecuteHotkeyHandler, nil);
end;

function TIDEHotkeyNotifier.GetBindingType: TBindingType;
begin
 Result := btPartial;
end;

function TIDEHotkeyNotifier.GetDisplayName: string;
begin
 Result := 'Version Header Stamp Hotkey';
end;

function TIDEHotkeyNotifier.GetName: string;
begin
 Result := 'VersionHeaderStampHotkey';
end;

procedure TIDEHotkeyNotifier.ExecuteHotkeyHandler(const Context: IOTAKeyContext; KeyCode: TShortcut; var BindingResult: TKeyBindingResult);
begin
 if KeyCode = TextToShortCut(HOTKEY_SHORTCUT) then
 begin
  if Assigned(DateTimeStampTool) then
   DateTimeStampTool.HandleClick(nil);
  BindingResult := krHandled;
 end;
end;

{ TDateTimeStampTool }

procedure TDateTimeStampTool.HandleClick(Sender: TObject);
begin
 AddOrUpdateDateTimeStamp;
end;

procedure RegisterHotkey;
begin
 (BorlandIDEServices as IOTAKeyboardServices).AddKeyboardBinding(TIDEHotkeyNotifier.Create);
end;

procedure RegisterStartupNotifier;
begin
 IDEStartupNotifierIndex := (BorlandIDEServices as IOTAServices).AddNotifier(TIDEStartupNotifier.Create);
end;

procedure Register;
var
 Bitmap: Vcl.Graphics.TBitmap;
 MemStream: TMemoryStream;
 VersionInfo: string;
 PackageName: string;
begin

 if SplashScreenServices <> nil then
 begin

  MemStream := TMemoryStream.Create;
  Bitmap := Vcl.Graphics.TBitmap.Create;
  try
   Bitmap.Width := 32;
   Bitmap.Height := 32;
   Bitmap.PixelFormat := pf24bit;

   // Fill background with black
   Bitmap.Canvas.Brush.Color := clwhite;
   Bitmap.Canvas.FillRect(Rect(0, 0, 32, 32));

   // Draw white V
   Bitmap.Canvas.Pen.Color := clblack;
   Bitmap.Canvas.Pen.Width := 4;
   Bitmap.Canvas.MoveTo(8, 8);
   Bitmap.Canvas.LineTo(16, 24);
   Bitmap.Canvas.MoveTo(16, 24);
   Bitmap.Canvas.LineTo(24, 8);

   // Define Package Info
   PackageName := 'Version Header Stamp';
   VersionInfo := 'v1.0.0.1';

   // Register on splash screen
   SplashScreenServices.AddPluginBitmap(PackageName + ' ' + VersionInfo, Bitmap.Handle, False, ''); // last param adds text under it

  finally
   Bitmap.Free;
   MemStream.Free;
  end;
 end;

 RegisterStartupNotifier;
 RegisterHotkey;
end;

initialization

finalization

if IDEStartupNotifierIndex <> -1 then
 (BorlandIDEServices as IOTAServices).RemoveNotifier(IDEStartupNotifierIndex);

FreeAndNil(DateTimeStampTool);
FreeAndNil(NewMenuItem);
MenuItemAdded := False;

end.
