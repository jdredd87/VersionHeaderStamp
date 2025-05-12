// Revision Date : 05/12/2025
// Revision Time : 12:13 AM
// Revised by : cpstevenc
// Version Count : 8

unit DateTimeStampTool;

interface

uses
 ToolsAPI, System.SysUtils, System.Classes, Winapi.Windows;

procedure AddOrUpdateDateTimeStamp;

implementation

const
 REVISION_DATE = '// Revision Date : ';
 REVISION_TIME = '// Revision Time : ';
 REVISED_BY = '// Revised by : ';
 VERSION_COUNT = '// Version Count : ';

function GetWindowsUserName: string;
var
 Buffer: array [0 .. 255] of Char;
 Size: DWORD;
begin
 Size := Length(Buffer);
 if GetUserName(Buffer, Size) then
  Result := Buffer
 else
  Result := 'Unknown User';
end;

procedure AddOrUpdateDateTimeStamp;
var
 EditorServices: IOTAEditorServices;
 EditBuffer: IOTAEditBuffer;
 EditWriter: IOTAEditWriter;
 EditReader: IOTAEditReader;
 Content: AnsiString;
 ReadBytes, Offset: Integer;
 LineIndex, BuildValue: Integer;
 LineText: string;
 FoundDate, FoundTime, FoundUser, FoundBuild, BlankLineInserted: Boolean;
 DateStamp, TimeStamp, UserStamp, BuildStamp: string;
 Lines: TStringList;
 Buffer: array [0 .. 1023] of AnsiChar;
begin
 EditorServices := (BorlandIDEServices as IOTAEditorServices);

 if not Assigned(EditorServices) or not Assigned(EditorServices.TopBuffer) then
  Exit;

 EditBuffer := EditorServices.TopBuffer;
 if not Assigned(EditBuffer) then
  Exit;

 EditReader := EditBuffer.CreateReader;
 EditWriter := EditBuffer.CreateWriter;

 try
  Offset := 0;
  Content := '';

  // Read the entire buffer content
  repeat
   ReadBytes := EditReader.GetText(Offset, @Buffer[0], Length(Buffer));
   if ReadBytes > 0 then
   begin
    SetString(LineText, Buffer, ReadBytes);
    Content := Content + LineText;
    Inc(Offset, ReadBytes);
   end;
  until ReadBytes < Length(Buffer);

  Lines := TStringList.Create;
  try
   Lines.Text := string(Content); // Convert AnsiString to string for TStringList processing

   FoundDate := False;
   FoundTime := False;
   FoundUser := False;
   FoundBuild := False;
   BlankLineInserted := False;
   BuildValue := 1;

   DateStamp := REVISION_DATE + FormatDateTime('mm/dd/yyyy', Now);
   TimeStamp := REVISION_TIME + FormatDateTime('hh:nn AM/PM', Now);
   UserStamp := REVISED_BY + GetWindowsUserName;

   // Check for existing headers
   for LineIndex := 0 to Lines.Count - 1 do
   begin
    LineText := Trim(Lines[LineIndex]);

    if LineText.StartsWith(REVISION_DATE) then
    begin
     Lines[LineIndex] := DateStamp;
     FoundDate := True;
    end else if LineText.StartsWith(REVISION_TIME) then
    begin
     Lines[LineIndex] := TimeStamp;
     FoundTime := True;
    end else if LineText.StartsWith(REVISED_BY) then
    begin
     Lines[LineIndex] := UserStamp;
     FoundUser := True;
    end else if LineText.StartsWith(VERSION_COUNT) then
    begin
     try
      BuildValue := StrToInt(Copy(LineText, Length(VERSION_COUNT) + 1, MaxInt));
     except
      BuildValue := 1;
     end;
     Inc(BuildValue);
     Lines[LineIndex] := VERSION_COUNT + IntToStr(BuildValue);
     FoundBuild := True;
    end;

    if FoundDate and FoundTime and FoundUser and FoundBuild then
     Break;
   end;

   // Insert missing headers at the top
   Lines.Insert(0, '');

   if not FoundBuild then
    Lines.Insert(0, VERSION_COUNT + '1');

   if not FoundUser then
    Lines.Insert(0, UserStamp);

   if not FoundTime then
    Lines.Insert(0, TimeStamp);

   if not FoundDate then
    Lines.Insert(0, DateStamp);

   // Write the modified content back
   EditWriter.CopyTo(0);
   EditWriter.DeleteTo(EditWriter.Position + Length(Content));

   // Not 100% sure this is best fix
   // But prevents a blank line being added every time you run this

   Lines.Text := Trim(Lines.Text);

   EditWriter.Insert(PAnsiChar(AnsiString(Lines.Text)));

  finally
   Lines.Free;
  end;

 finally
  EditWriter := nil;
  EditReader := nil;
 end;
end;

end.
