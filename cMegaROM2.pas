unit cMegaROM2;

interface
  uses iNESImage, gr32, inifiles, sysutils, cLevel, classes;
type
  TObjDetect = record
    ObjType : integer;
    ObjIndex : Integer;
  end;

  T16x16Graphic = record
    Pixels : Array [0..63, 0..63] of Byte;
  end;

  TMegaman2ROM = class
  private
    _Tiles : TBitmap32;
    _PatternTable : Array [0.. 8191] of Byte;
    _CurrentLevel : Integer;
    _DrawTiles : Array [0..255] Of Boolean;
    _NumberOfLevels : Integer;
    _CurrentRoom : Byte;
    function GetChanged(): boolean;
    procedure SetChanged(pChanged : boolean);
    procedure LoadDataFile;
    procedure LoadEnemyData;
    procedure LoadEnemyDescriptions;
    procedure LoadEnemyStatistics;
    procedure LoadPatternTableSettings;
    procedure LoadSoundEffectList;
    procedure LoadTSASettingsList;
    procedure SetLevel(pLevel: Integer);
    procedure SaveScrollData;
    procedure LoadPatternTable;
    procedure LoadScrollData;
    procedure LoadBGPalette(pCycle : Byte);
    procedure LoadSpecObjData;
    procedure LoadRoomTiles;
    procedure SavePatternTable;
    procedure DumpPatternTable(pFilename: String);
    procedure DrawLevelTile(pIndex: Integer);
    procedure DrawPatternTable(var pBitmap: TBitmap32; pTable: Integer;
      pPal: Byte);
    procedure DrawTSAPatternTable(pBitmap: TBitmap32; pPal: Byte);
    function GetROMFilename: String;
    procedure SetRoom(pRoom: Byte);
    procedure EditLevelData(pScreenNum : Byte; pX, pY : Integer;pTileID: Byte);
    function GetLevelData(pScreenNum : Byte; pX, pY : Integer) : Byte;
  public
    CurrLevel : TLevel;
    DataFile : String;
    Levels : TLevelList;
    Palette : Array [0..7,0..3] of Byte;
    constructor Create(pFilename, pDataFile: String);
    function IsMegaman2ROM() : Boolean;
    procedure LoadDefaultPalette;
    procedure LoadPaletteFile(pPaletteFile: String);
    procedure DrawScreen(pX, pY, pScreenNum: Integer; var pBitmap: TBitmap32);
    procedure DrawScreenIndex(var pBitmap: TBitmap32; pIndex: Integer);
    procedure DrawScreenOffset(var pBitmap: TBitmap32; pOffset: Integer);
    property RoomData[pScreenNum : Byte;pX,pY : Integer] : Byte read GetLevelData write EditLevelData;
    property Changed : Boolean read GetChanged write SetChanged;
    property CurrentLevel : Integer read _CurrentLevel write SetLevel;
    property Filename : String read GetROMFilename;
    property CurrentRoom : Byte read _CurrentRoom write SetRoom;
  end;


implementation

uses MemINIHexFile, uROM, cPatternTableSettings;

constructor TMegaman2ROM.Create(pFilename : String;pDataFile : String);
begin
  ROM := TiNESImage.Create(pFilename);
  DataFile := pDataFile;
  LoadDataFile();
  self._CurrentLevel := -1;
  LoadPatternTableSettings;
  LoadEnemyDescriptions;
  LoadTSASettingsList;
  LoadSoundEffectList;
//  SaveScrollData();
  LoadEnemyData();
  LoadEnemyStatistics;
end;

procedure TMegaman2ROM.LoadDataFile();
var
  ini : TMemINIHexFile;
  i: Integer;
  lvl : TLevel;
begin
  ini := TMemINIHexFile.Create(DataFile);
  try
    self._NumberOfLevels := ini.ReadInteger('General','NumLevels');

    Levels := TLevelList.Create(True);

    for i := 0 to _NumberOfLevels-1 do
    begin
      Levels.Add(TLevel.Create());
      lvl := Levels.Last;

      lvl.Name := ini.ReadString('Level' + IntToStr(i),'Name');
      lvl.TSAOffset := ini.ReadHexValue('Level' + IntToStr(i),'TSA');
      lvl.AttributeOffset := ini.ReadHexValue('Level' + IntToStr(i),'Attribute');
      lvl.LevelOffset := ini.ReadHexValue('Level' + IntToStr(i),'LevelData');
      lvl.CHRSettingsOffset := ini.ReadHexValue('Level' + IntToStr(i),'CHRSettings');
      lvl.PPUSettingsOffset := ini.ReadHexValue('Level' + IntToStr(i),'PPUSettings');
      lvl.PaletteOffset := ini.ReadHexValue('Level' + IntToStr(i), 'pal');

      // Beam down co-ordinates.
      lvl.BeamDown0 := ini.ReadHexValue('Level' + IntToStr(i),'BeamDown0');
      lvl.BeamDown1 := ini.ReadHexValue('Level' + IntToStr(i),'BeamDown1');
      lvl.BeamDown2 := ini.ReadHexValue('Level' + IntToStr(i),'BeamDown2');

      // Level items.
      lvl.ItemsStart0 := ini.ReadHexValue('Level' + IntToStr(i),'ItemsStart0');
      lvl.ItemsStart1 := ini.ReadHexValue('Level' + IntToStr(i),'ItemsStart1');
      lvl.ItemsStart2 := ini.ReadHexValue('Level' + IntToStr(i),'ItemsStart2');

      // Events.
      lvl.EventStart0 := ini.ReadHexValue('Level' + IntToStr(i),'EvStart0');
      lvl.EventStart1 := ini.ReadHexValue('Level' + IntToStr(i),'EvStart1');
      lvl.EventStart2 := ini.ReadHexValue('Level' + IntToStr(i),'EvStart2');

      // The various scroll settings.
      lvl.ScrollOffset := ini.ReadHexValue('Level' + IntToStr(i),'ScrData');

      // Screen starting settings.
      lvl.ScreenStart0 := ini.ReadHexValue('Level' + IntToStr(i),'ScreenStart0');
      lvl.ScreenStart1 := ini.ReadHexValue('Level' + IntToStr(i),'ScreenStart1');
      lvl.ScreenStart2 := ini.ReadHexValue('Level' + IntToStr(i),'ScreenStart2');
    end;

  finally
    FreeAndNil(INI);
  end;
end;


procedure TMegaman2ROM.LoadPatternTableSettings();
var
  i, x, off, numentries : integer;
  LastPat : TPatternTableSetting;
begin
  {
  This code loads in the pattern table settings.
  Format is as follows:

  Byte #00 - Number of Entries

  Entries are three bytes in size.

  Entry Byte #00 - Memory Address (Multiply by 1000)
  Entry Byte #01 - Number of PPU Rows
  Entry Byte #02 - Bank ?
  }

  // These are the number of entries in this PPU settings entry.
  for i := 0 to Levels.Count -1 do
  begin
    if Assigned(Levels[i].PatternTableSettings) then
      FreeAndNil(Levels[i].PatternTableSettings);
    Levels[i].PatternTableSettings := TPatternTableSettingList.Create(true);

    numentries := ROM[Levels[i].PPUSettingsOffset];
    for x := 0 to numentries -1 do
    begin
      Levels[i].PatternTableSettings.Add(TPatternTableSetting.Create);
      off := Levels[i].PPUSettingsOffset;
      LastPat := Levels[i].PatternTableSettings.Last;
      LastPat.MemoryOffset := ROM[off + 1 + (x*3)];
      LastPat.RowsToLoad := ROM[off + 1 + (x*3) + 1];
      LastPat.PRGBank := ROM[off + 1 + (x*3) + 2];
    end;
  end;

end;

procedure TMegaman2ROM.LoadEnemyDescriptions();
begin

end;

procedure TMegaman2ROM.LoadTSASettingsList();
begin

end;

procedure TMegaman2ROM.LoadSoundEffectList();
begin

end;

procedure TMegaman2ROM.LoadEnemyData();
begin

end;

procedure TMegaman2ROM.LoadEnemyStatistics();
begin

end;

function TMegaman2ROM.IsMegaman2ROM: Boolean;
var
  Mapper,PRG,CHR : Integer;
  INI : TMemINIHexFile;
begin
  INI := TMemINIHexFile.Create(self.Datafile);
  try
    Mapper := INI.ReadInteger('Mapper','MapperNum',1);
    PRG := INI.ReadInteger('Mapper','PRGSize',16);
    CHR := INI.ReadInteger('Mapper','CHRSize',0);
    result := true;
    if ROM.ValidImage = False then
      result := false
    else if Mapper <> ROM.MapperNumber then
      result := false
    else if PRG <> ROM.PRGCount then
      result := false
    else if CHR <> ROM.CHRCount then
      result := false;
  finally
    freeandNil(INI);
  end;

end;

procedure TMegaman2ROM.SetLevel(pLevel : Integer);
var
  i : Integer;
begin
  if self._CurrentLevel > -1 then SaveScrollData();

  self._CurrentLevel := pLevel;

  CurrLevel := Levels[_CurrentLevel];
  LoadScrollData;
  // Reinitialise DrawTiles
  for i := 0 to 255 do
    _DrawTiles[i] := False;

  if Assigned(_Tiles) = False then
    _Tiles := TBitmap32.Create;

  _Tiles.Width := 256 * 32;
  _Tiles.Height := 32;
  setroom(ROM[currlevel.ScreenStart0]);
  LoadPatternTable();
  LoadBGPalette(0);
  LoadSpecObjData();
  LoadRoomTiles();
  //DumpPatternTable('c:\test.nes');
end;

procedure TMegaman2ROM.SetRoom(pRoom : Byte);
begin
  _CurrentRoom := pRoom;
end;

procedure TMegaman2ROM.SaveScrollData();
begin

end;

procedure TMegaman2ROM.LoadScrollData();
begin

end;

procedure TMegaman2ROM.LoadPatternTable;
var
  i,x,patpos : Integer;
begin
  for i := 0 to high(_PatternTable) do
    _PatternTable[i] := $00;
  patpos := 0;
  for i := 0 to CurrLevel.PatternTableSettings.Count - 1 do
  begin
    for x := 0 to CurrLevel.PatternTableSettings[i].NumberOfBytesToLoad - 1 do
    begin
      _PatternTable[patpos + x] := ROM[CurrLevel.PatternTableSettings[i].GetAddress() +x];
    end;
    patpos := patpos + CurrLevel.PatternTableSettings[i].NumberOfBytesToLoad;
  end;
end;

procedure TMegaman2ROM.DumpPatternTable(pFilename : String);
var
  Mem : TMemoryStream;
begin
  Mem := TMemoryStream.Create;
  try
    Mem.Write( _PatternTable[0], 4096);
    Mem.SaveToFile(pFilename);
  finally
    FreeAndNil(Mem);
  end;
end;

procedure TMegaman2ROM.EditLevelData(pScreenNum: Byte; pX, pY: Integer;
  pTileID : Byte);
var
  RoomOffset : Integer;
begin
  if (pX >= 0) and (pX <= 8) then
    if (pY >= 0) and (pY <= 8) then
    begin
      RoomOffset := CurrLevel.LevelOffset + (pScreenNum * 64);
      ROM[RoomOffset + (pX * 8) + pY] := pTileID;
    end;
//  _RoomData[pIndex,pIndex1] := pData;

end;

procedure TMegaman2ROM.SavePatternTable;
var
  i,x,patpos : Integer;
begin
  patpos := 0;
  for i := 0 to CurrLevel.PatternTableSettings.Count -1 do
  begin
    for x := 0 to CurrLevel.PatternTableSettings[i].NumberOfBytesToLoad - 1 do
    begin
      ROM[CurrLevel.PatternTableSettings[i].GetAddress() +x] := _PatternTable[patpos + x];
    end;
    patpos := patpos + CurrLevel.PatternTableSettings[i].NumberOfBytesToLoad;
  end;

end;

procedure TMegaman2ROM.LoadBGPalette(pCycle : Byte);
var
  i,x : Integer;
begin
  for i := 0 to 3 do
    for x := 0 to 3 do
      Palette[i,x] := ROM[CurrLevel.GetPaletteOffset(pCycle) + (i * 4) + x];

  for i := 0 to 3 do
    for x := 0 to 3 do
      Palette[i+4,x] := ROM[(CurrLevel.PaletteOffset + $12) + (i * 4) + x];
end;

procedure TMegaman2ROM.DrawScreen(pX,pY : Integer;pScreenNum : Integer;var pBitmap : TBitmap32);
var
  i,x,RoomOffset : Integer;
begin
  RoomOffset := CurrLevel.LevelOffset + (pScreenNum * 64);
  for i := 0 to 7 do
    for x := 0 to 7 do
    begin
      pBitmap.Draw( bounds(pX + (i*32),pY + (x*32),32,32),bounds((ROM[RoomOffset + (i * 8) + x]) * 32,0,32,32),_Tiles);
    end;
end;

procedure TMegaman2ROM.DrawScreenOffset(var pBitmap : TBitmap32;pOffset : Integer);
var
  i,x : Integer;
begin
  for i := 0 to 7 do
    for x := 0 to 7 do
    begin
      pBitmap.Draw(bounds(i*32,x*32,32,32),bounds(ROM[pOffset + (i*8) + x] * 32,0,32,32),_Tiles);
    end;

end;

procedure TMegaman2ROM.DrawScreenIndex(var pBitmap : TBitmap32;pIndex : Integer);
var
  i,x, RoomOffset : Integer;
begin
  RoomOffset := CurrLevel.LevelOffset + (pIndex * 64);
  for i := 0 to 7 do
    for x := 0 to 7 do
    begin
      if _DrawTiles[ROM[RoomOffset + (i*8) + x]] = False then
      begin

        DrawLevelTile(ROM[RoomOffset + (i*8) + x]);
        _DrawTiles[ROM[RoomOffset + (i*8) + x]] := True;

      end;
      pBitmap.Draw(bounds(i*32,x*32,32,32),bounds(ROM[RoomOffset + (i*8) + x] * 32,0,32,32),_Tiles);

    end;

end;


procedure TMegaman2ROM.LoadSpecObjData();
begin

end;

procedure Tmegaman2ROM.DrawTSAPatternTable(pBitmap : TBitmap32; pPal : Byte);
var
  i,x : Integer;
  pal : Pointer;
begin
  pal := @Palette[pPal,0];

  for x := 0 to 7 do
    for i := 0 to 31 do
      ROM.DrawNESTile(@_PatternTable[$1000 + (x*32 + i) * 16],pBitmap,(i div 2) *8,(x*16)+(i mod 2) *8,Pal);
end;

procedure TMegaman2ROM.DrawPatternTable(var pBitmap : TBitmap32;pTable : Integer;pPal : Byte);
var
  i,x : Integer;
begin
  for i := 0 to 15 do
    for x := 0 to 15 do
      ROM.DrawNESTile(@_PatternTable[pTable + (i*16 + x) * 16],pBitmap,x*8,i*8,@Palette[pPal,0]);
end;

procedure TMegaman2ROM.LoadRoomTiles();
var
  i : integer;
begin

  for i := 0 to 255 -1 do
  begin
    DrawLevelTile(i);
  end;
  //_Tiles.SaveToFile('c:\test.bmp');

end;

procedure TMegaman2ROM.DrawLevelTile(pIndex : Integer);
var
  i,x, TileID : Integer;
  TilePal : Array [0..1,0..1] Of Byte;
  Pal : Pointer;
begin
  if Assigned(_Tiles) = False then
    exit;

  TilePal[0,0] := (ROM[CurrLevel.AttributeOffset  +pIndex]) and 3;
  tilepal[0,1] := (ROM[CurrLevel.AttributeOffset + pIndex] shr 2) and 3;
  tilepal[1,0] := (ROM[CurrLevel.AttributeOffset + pIndex] shr 4) and 3;
  tilepal[1,1] := (ROM[CurrLevel.AttributeOffset + pIndex] shr 6) and 3;

  for i := 0 to 1 do
    for x := 0 to 1 do
    begin
{      if (Room > CurrLevel.Properties['DoorsWorkFrom'].Value) and (CurrLevel.Properties.ValueExists('AfterDoorsPalette') = true) then
        pal := @AfterDoorsPalette[TilePal[x,i],0]
      else}
        pal := @palette[TilePal[x,i],0];
      TileID := ROM[CurrLevel.TSAOffset + (pIndex*4) + ((i*2)+x)];
      ROM.DrawNESTile(@_PatternTable[((TileID and $3F) * $40)+$1000],_Tiles ,(i*16) + pIndex*32,(x*16) + 0,Pal);
      ROM.DrawNESTile(@_PatternTable[((TileID and $3F) * $40)+$10 + $1000],_Tiles ,(i*16) + pIndex*32,(x*16) + 8,Pal);
      ROM.DrawNESTile(@_PatternTable[((TileID and $3F) * $40)+$20 + $1000],_Tiles ,(i*16) + (pIndex*32) + 8,(x*16) + 0,Pal);
      ROM.DrawNESTile(@_PatternTable[((TileID and $3F) * $40)+$30 + $1000],_Tiles ,(i*16) + (pIndex*32) + 8,(x*16) + 8,Pal);
    end;

end;

{$REGION 'Properties'}
function TMegaman2ROM.GetChanged: boolean;
begin
  result := ROM.Changed;
end;

function TMegaman2ROM.GetLevelData(pScreenNum: Byte; pX, pY: Integer): Byte;
begin

end;

procedure TMegaman2ROM.SetChanged(pChanged: boolean);
begin
  ROM.Changed := pChanged;
end;

procedure TMegaman2ROM.LoadPaletteFile(pPaletteFile : String);
begin
  ROM.LoadPaletteFile(pPaletteFile);
end;

procedure TMegaman2ROM.LoadDefaultPalette;
begin
  ROM.LoadDefaultPalette;
end;

function TMegaman2ROM.GetROMFilename(): String;
begin
  result := ROM.Filename;
end;

{$ENDREGION}

end.
