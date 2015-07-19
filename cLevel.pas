unit cLevel;

interface

uses contnrs, cPatternTableSettings;

type
  TLevel = class
  private
    procedure SetNumberOfPaletteCycles(pNumber : Byte);
    procedure SetPaletteCycleSpeed(pCycleSpeed : Byte);
    function GetPaletteCycleSpeed() : Byte;
    function GetNumberOfPaletteCycles() : Byte;

  public
    Name : String;
    TSAOffset : Integer;
    AttributeOffset : Integer;
    PaletteOffset : Integer;
    LevelOffset : Integer;
    ScrollOffset : Integer;
    PPUSettingsOffset : Integer;
    CHRSettingsOffset : Integer;
    BeamDown0 : Integer;
    BeamDown1 : Integer;
    BeamDown2 : Integer;
    EventStart0 : Integer;
    EventStart1 : Integer;
    EventStart2 : Integer;
    ItemsStart0 : Integer;
    ItemsStart1 : Integer;
    ItemsStart2 : Integer;
    ScreenStart0 : Integer;
    ScreenStart1 : Integer;
    ScreenStart2 : Integer;
    PatternTableSettings : TPatternTableSettingList;
    property PaletteCycleSpeed : Byte read GetNumberOfPaletteCycles write SetPaletteCycleSpeed;
    property PaletteCycles : Byte read GetNumberOfPaletteCycles write SetNumberOfPaletteCycles;
    function GetPaletteOffset(pCycle : Byte) : Integer;
  end;

  TLevelList = class(TObjectList)
  protected
    _CurrentLevel : Integer;
    function GetCurrentLevel: Integer;
    procedure SetCurrentLevel(const Value: Integer);
    function GetLevelItem(Index: Integer) : TLevel;
    procedure SetLevelItem(Index: Integer; const Value: TLevel);
  public
    function Add(AObject: TLevel) : Integer;
    property Items[Index: Integer] : TLevel read GetLevelItem write SetLevelItem;default;
    function Last : TLevel;
//    property CurrentLevel : Integer read GetCurrentLevel write SetCurrentLevel;
  end;

implementation

uses uROM;

{ TLevelList }

{$REGION 'TLevelList'}
  function TLevelList.Add(AObject: TLevel): Integer;
  begin
    Result := inherited Add(AObject);
  end;
  
  function TLevelList.GetCurrentLevel: Integer;
  begin
    result := self._CurrentLevel;
  end;
  
  function TLevelList.GetLevelItem(Index: Integer): TLevel;
  begin
    Result := TLevel(inherited Items[Index]);
  end;
  
  function TLevelList.Last: TLevel;
  begin
    result := TLevel(inherited Last);
  end;
  
  procedure TLevelList.SetCurrentLevel(const Value: Integer);
  begin
    self._CurrentLevel := Value;
  end;
  
  procedure TLevelList.SetLevelItem(Index: Integer; const Value: TLevel);
  begin
    inherited Items[Index] := Value;
  end;
  
{$ENDREGION}

{ TLevel }

function TLevel.GetNumberOfPaletteCycles: Byte;
begin
  result := ROM[self.PaletteOffset];
end;


function TLevel.GetPaletteCycleSpeed: Byte;
begin
  result := ROM[self.PaletteOffset + 1];
end;

function TLevel.GetPaletteOffset(pCycle: Byte): Integer;
var
  BGOffset : Integer;
begin
  if pCycle = 0 then
  begin
    BGOffset := self.PaletteOffset + 2;
  end
  else
  begin
    BGOffset := (self.PaletteOffset + 2 + $10) + ((pCycle - 1) * $10);
  end;
  result := BGOffset;
end;

procedure TLevel.SetNumberOfPaletteCycles(pNumber: Byte);
begin
  ROM[self.PaletteOffset] := pNumber;
end;

procedure TLevel.SetPaletteCycleSpeed(pCycleSpeed: Byte);
begin
  ROM[self.PaletteOffset + 1] := pCycleSpeed;
end;

end.
