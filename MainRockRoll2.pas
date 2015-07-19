unit MainRockRoll2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ToolWin, ComCtrls, Menus, StdCtrls, GR32_Image, ActnList, ImgList,
  cMegaROM2, cConfiguration, GR32, GR32_Layers;

type
  TfrmRockRoll2Main = class(TForm)
    imgTiles: TImage32;
    scrTiles: TScrollBar;
    MainMenu1: TMainMenu;
    File1: TMenuItem;
    ToolBar1: TToolBar;
    StatusBar1: TStatusBar;
    OpenROM1: TMenuItem;
    SaveROM1: TMenuItem;
    CloseROM1: TMenuItem;
    N1: TMenuItem;
    Recent1: TMenuItem;
    mnuRecentItem1: TMenuItem;
    mnuRecentItem2: TMenuItem;
    mnuRecentItem3: TMenuItem;
    mnuRecentItem4: TMenuItem;
    mnuRecentItem5: TMenuItem;
    DistributeHack1: TMenuItem;
    BackupManager1: TMenuItem;
    Preferences1: TMenuItem;
    FileProperties1: TMenuItem;
    LaunchAssociatedEmulatro1: TMenuItem;
    N2: TMenuItem;
    Exit1: TMenuItem;
    ImageList: TImageList;
    ActionList1: TActionList;
    actOpenROM: TAction;
    actSaveROM: TAction;
    Edit1: TMenuItem;
    View1: TMenuItem;
    ools1: TMenuItem;
    Help1: TMenuItem;
    About1: TMenuItem;
    MapEditingMode1: TMenuItem;
    ObjectEditingMode1: TMenuItem;
    Gridlines1: TMenuItem;
    PaletteEditor1: TMenuItem;
    SAEditor1: TMenuItem;
    scrboxLevel: TScrollBox;
    imgScreen: TImage32;
    imgScreenInfo: TImage32;
    procedure FormShow(Sender: TObject);
    procedure actSaveROMExecute(Sender: TObject);
    procedure actOpenROMExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure scrLevelChange(Sender: TObject);
    procedure imgScreenMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);
    procedure imgScreenMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);
    procedure imgScreenMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer; Layer: TCustomLayer);
  private
    _CurTileLeft, _CurTileMid : Byte;
    _EditingMode : Byte;
    _ROMData : TMegaman2ROM;
    _EditorConfig : TRRConfig;
    procedure EnableControls(Enable: Boolean);
    procedure CreateRecentMenu();
    procedure UpdateTitleCaption();
    procedure LoadROM(pFilename, pDataFile: String; pAutoCheck: Boolean);
    function AutoCheckROMType(pFilename: String): String;
    procedure SetupLevel;
    procedure DrawLevelData;
    procedure DisplayScreenInfo;
    procedure DrawTileSelector;
    procedure SetTileScrMax;
    procedure SetIconTransparency;
    procedure SetEmuMenuText;
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmRockRoll2Main: TfrmRockRoll2Main;

implementation

{$R *.dfm}

uses uConst,uResources, uToday, fOpenDialog, MemINIHexFile, iNESImage;

procedure TfrmRockRoll2Main.FormCreate(Sender: TObject);
begin
  _EditorConfig := TRRConfig.Create(ExtractFileDir(Application.ExeName) + '\options.ini');
end;

procedure TfrmRockRoll2Main.FormShow(Sender: TObject);
begin
  // Disable all the controls on the form.
  EnableControls(false);
  // Create a recent menu.
  CreateRecentMenu();
  // Update the title caption of the form with the application name.
  UpdateTitleCaption();
end;

procedure TfrmRockRoll2Main.imgScreenMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);
var
  CurTilePos : Integer;
begin
  if _EditingMode = MAPEDITINGMODE then
  begin
    if button = mbLeft then
    begin
      if ssShift in Shift then
        _ROMData.RoomData[_ROMData.CurrentRoom,(x div 2) div 32,(y div 2) div 32] := _CurTileMid
      else
        _ROMData.RoomData[_ROMData.CurrentRoom,(x div 2) div 32,(y div 2) div 32] := _CurTileLeft;

      DrawLevelData();
    end
    else if button = mbRight then
    begin
      CurTilePos := _ROMData.RoomData[_ROMData.CurrentRoom,(x div 2) div 32,(y div 2) div 32];
      if ssShift in Shift then
        _CurTileMid := CurTilePos
      else
        _CurTileLeft := CurTilePos;
      if CurTilePos > scrTiles.Max then CurTilePos := scrTiles.Max;
      if (CurTilePos <= scrTiles.Position) or (CurTilePos >= scrTiles.Position + 7) then
        scrTiles.Position := CurTilePos;
      DrawTileSelector();

    end
    else if Button = mbMiddle then
    begin
      if ssShift in Shift then
        _CurTileMid := _ROMData.RoomData[_ROMData.CurrentRoom,(x  div 2) div 32,(y div 2) div 32]
      else
        _ROMData.RoomData[_ROMData.CurrentRoom,(x  div 2) div 32,(y div 2) div 32] := _CurTileMid;

      DrawLevelData();
    end;

  end;
end;

procedure TfrmRockRoll2Main.imgScreenMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);
begin
  if _EditingMode = MAPEDITINGMODE then
  begin
    if ssLeft in Shift  then
    begin
      if ssShift in Shift then
        _ROMData.RoomData[_ROMData.CurrentRoom,(x  div 2) div 32,(y div 2) div 32] := _CurTileMid
      else
        _ROMData.RoomData[_ROMData.CurrentRoom,(x div 2) div 32,(y div 2) div 32] := _CurTileLeft;

      DrawLevelData();
    end
    else if ssRight in Shift then
    begin
      if ssShift in Shift then
        _CurTileMid := _ROMData.RoomData[_ROMData.CurrentRoom,(x div 2) div 32,(y div 2) div 32]
      else
        _CurTileLeft := _ROMData.RoomData[_ROMData.CurrentRoom,(x div 2) div 32,(y div 2) div 32];
    end
    else if ssMiddle in Shift then
    begin
      if ssShift in Shift then
        _CurTileMid := _ROMData.RoomData[_ROMData.CurrentRoom,(x div 2) div 32,(y div 2) div 32]
      else
        _ROMData.RoomData[_ROMData.CurrentRoom,(x div 2) div 32,(y div 2) div 32] := _CurTileMid;

      DrawLevelData();
    end;
  end;
end;

procedure TfrmRockRoll2Main.imgScreenMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);
begin
//  _ROMData.EditLevelData( _ROMData.CurrentRoom,0,0,0 );
//  DrawLevelData();
end;

procedure TfrmRockRoll2Main.UpdateTitleCaption;
var
  AppTitleBarText : String;
begin
  if Assigned(_ROMData) = True then
  begin
    AppTitleBarText := APPLICATIONTITLE + ' [Build: ' + COMPILETIME + ']' + ' - [' + ExtractFilename(_ROMData.Filename) + ']';

    if _ROMData.Changed = True then
      Caption := AppTitleBarText + ' *'
    else
      Caption := AppTitleBarText;
  end
  else
  begin
    Caption := uResources.APPLICATIONTITLE + ' [Build: ' + COMPILETIME + ']';
  end;

end;

procedure TfrmRockRoll2Main.actOpenROMExecute(Sender: TObject);
var
  OpDlg : TfrmOpenDialog;
begin
  OpDlg := TfrmOpenDialog.Create(self);
  try
    OpDlg.OpenDir := ExtractFileDir(_EditorConfig.RecentFile[0]);
    OpDlg.EditorConfig := _EditorConfig;
    OpDlg.ShowModal;

//    RRConfig.AddRecentFile(OpDlg.Filename);
    if FileExists(OpDlg.Filename) = True then
      LoadROM(OpDlg.FileName,OpDlg.DataFile,OpDlg.AutoCheck);
  finally
    FreeAndNil(OpDlg);
  end;
end;

procedure TfrmRockRoll2Main.LoadROM(pFilename : String; pDataFile : String; pAutoCheck : Boolean);
var
  TempFilename : String;
begin
  // If the ROM file does not exist then exit the subroutine.
  if FileExists(pFilename) = False then
    exit;
  // Transfer the datafile's filename over to another variable.
  TempFilename := pDataFile;
  // If the user wants to automatically check the ROM type then
  // check it. If there is no matches, reset the TempFileName variable
  // back to pDataFile (Usually the default datafile).
  if pAutoCheck = True then
  begin
    TempFilename := AutoCheckROMType(pFilename);
    if TempFilename = '' then
      TempFilename := pDataFile
    else
      TempFilename := ExtractFileDir(Application.ExeName) + '\Resources\' + TempFilename;
  end;

  // If the datafile does not exist, then exit the subroutine.
  if FileExists(TempFileName) = False then
    exit;

  // First check if the ROM is already loaded.
  if assigned(_ROMData) = True then
  begin
    FreeAndNil(_ROMData);
  end;
  _EditorConfig.AddRecentFile(pFilename);
  CreateRecentMenu();
  _ROMData := TMegaman2ROM.Create(pFilename, TempFilename);

  if _ROMData.IsMegaman2ROM = false then
  begin
    // If the user elects to not load the ROM, then
    // display a prompt informing the user that the ROM will
    // not be loaded, free the ROM, and exit the subroutine.
    if _EditorConfig.MapperWarnings = 0 then
    begin
        Messagebox(handle,'This is not a Mega Man ROM.',PChar(Application.Title),0);
        FreeAndNil(_ROMData);
        exit;
    end
    // If the user has elected to be prompted about the
    // ROM not conforming to the standard Mega Man settings
    // tell the user, and give them the choice of whether or not to load it.
    else if _EditorConfig.MapperWarnings = 1 then
    begin
      if MessageBox(Handle,'The memory mapper of this ROM does not match the specifications of'
        + chr (13) + chr(10) + 'the Mega Man 2 ROMs. Do you wish to continue?',
            PChar(Application.Title),MB_YESNO) = IDNO	then
      begin
        FreeAndNil(_ROMData);
        exit;
      end;
    end;

  end;


  // If the palette specified exists, then load it.
  if FileExists(_EditorConfig.FullPaletteName) = True then
    _ROMData.LoadPaletteFile(_EditorConfig.FullPaletteName)
  else
    _ROMData.LoadDefaultPalette;
  _ROMData.CurrentLevel := 0;

  //StatusBar.Panels[2].Text := ExtractFileName(_ROMData.DataFile);
  SetEnabled(True);

  // If the ROM is write protected (has it's read-only flag set)
  // disable the save command.
{  if _ROMData.ROM.WriteProtected = True then
  begin
    showmessage('This ROM is currently set to read-only. Please remove the read-only flag.');
    actSaveROM.Enabled := False;
  end;}

  //actSetMapEditingMode.Execute;
  SetIconTransparency;
  SetEmuMenuText();
  SetupLevel;
  UpdateTitleCaption();

  //_CurTSABlock := -1;

end;

procedure TfrmRockRoll2Main.scrLevelChange(Sender: TObject);
begin
//  _ROMData.CurrentRoom := scrLevel.Position; 
  DrawLevelData();
end;

procedure TfrmRockRoll2Main.SetIconTransparency;
begin

end;

procedure TfrmRockRoll2Main.SetEmuMenuText();
begin

end;

procedure TfrmRockRoll2Main.actSaveROMExecute(Sender: TObject);
begin
  // Do open ROM stuff.
end;

procedure TfrmRockRoll2Main.CreateRecentMenu;
begin

end;

procedure TfrmRockRoll2Main.EnableControls(Enable : Boolean);
begin
  // Do save ROM stuff.
end;

procedure TfrmRockRoll2Main.SetupLevel();
begin
  SetTileScrMax;
  //scrTiles.Position := _ROMData.CurrLevel.StartTSAAt;

  //scrboxLevel.HorzScrollBar.Position := _ROMdata.CurrLevel.Properties['ScreenStartCheck1'].Value * 512;
  DrawLevelData();
  DrawTileSelector();
  DisplayScreenInfo;
  UpdateTitleCaption();
end;

procedure TfrmRockRoll2Main.SetTileScrMax();
begin

end;

procedure TfrmRockRoll2Main.DrawLevelData();
var
  ScrBitmap : TBitmap32;
begin
  ScrBitmap := TBitmap32.Create;
  try
    ScrBitmap.Height := 256;
    ScrBitmap.Width := 256;
    _ROMData.DrawScreen(0,0,_ROMData.CurrentRoom ,ScrBitmap);
    imgScreen.Bitmap := ScrBitmap;
  finally
    FreeAndNil(ScrBitmap);
  end;
end;

procedure TfrmRockRoll2Main.DisplayScreenInfo;
begin

end;

procedure TfrmRockRoll2Main.DrawTileSelector();
begin

end;

function TfrmRockRoll2Main.AutoCheckROMType(pFilename : String) : String;
var
  DataFiles : TStringList;
  INI : TMemINIHexFile;
  i : Integer;
  Loc : Integer;
  Auto1,Auto2,Auto3,Auto4 : Byte;
  TempROM : TiNESImage;
begin
  result := '';
  DataFiles := TStringList.Create;
  try
    DataFiles.LoadFromFile(ExtractFileDir(Application.ExeName) + '\Resources\data.dat');

    for i := 0 to DataFiles.Count -1 do
    begin
      INI := TMemINIHexFile.Create(ExtractFileDir(Application.ExeName) + '\Resources\' + DataFiles[i]);
      try
        Loc := INI.ReadHexValue('AutoCheck','Location');
        Auto1 := INI.ReadHexValue('AutoCheck','Auto1');
        Auto2 := INI.ReadHexValue('AutoCheck','Auto2');
        Auto3 := INI.ReadHexValue('AutoCheck','Auto3');
        Auto4 := INI.ReadHexValue('AutoCheck','Auto4');
        TempROM := TiNESImage.Create(pFilename);
        if TempROM.ROM[Loc] = Auto1 then
          if TempROM.ROM[Loc+1] = Auto2 then
            if TempROM.ROM[Loc+2] = Auto3 then
              if TempROM.ROM[Loc+3] = Auto4 then
              begin
                result := DataFiles[i];
                break;
              end;
      finally
        FreeAndNil(TempROM);
        FreeAndNil(INI);
      end;
    end;
  finally
    FreeAndNil(DataFiles);
  end;

end;

end.
