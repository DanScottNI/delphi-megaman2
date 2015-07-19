unit cPatternTableSettings;

interface

  uses sysutils, contnrs;

  type TPatternTableSetting = class
  public
    MemoryOffset : Byte;
    RowsToLoad : Byte;
    PRGBank : Byte;
    function GetAddress() : Integer;
    procedure SetAddress(pAddress : Integer);
    function NumberOfBytesToLoad() : Integer;
    procedure SetBytesToLoad(pBytes : Integer);
  end;

  TPatternTableSettingList = class(TObjectList)
  protected
    function GetPatternTableSettingItem(Index: Integer) : TPatternTableSetting;
    procedure SetPatternTableSettingItem(Index: Integer; const Value: TPatternTableSetting);
  public
    function Add(AObject: TPatternTableSetting) : Integer;
    property Items[Index: Integer] : TPatternTableSetting read GetPatternTableSettingItem write SetPatternTableSettingItem;default;
    function Last : TPatternTableSetting;
//    property CurrentLevel : Integer read GetCurrentLevel write SetCurrentLevel;
  end;

implementation

{ TPatternTableSetting }

uses uROM;

function TPatternTableSetting.GetAddress: Integer;
var
  MemOffset : Integer;
  BankOffset : Integer;
begin
  // Take the memory offset.
  MemOffset := StrToInt('$' + IntToHex(MemoryOffset,2) + '10');

  if MemOffset > $C000 then
  begin
    MemOffset := MemOffset - $C000;
  end
  else if MemOffset > $8000 then
  begin
    MemOffset := MemOffset - $8000;
  end;

  BankOffset :=(PRGBank * $4000);
  result := BankOffset + MemOffset;
end;

function TPatternTableSetting.NumberOfBytesToLoad: Integer;
begin
  result := self.RowsToLoad * $100;
end;

procedure TPatternTableSetting.SetAddress(pAddress: Integer);
begin

end;

procedure TPatternTableSetting.SetBytesToLoad(pBytes: Integer);
begin

end;

{ TPatternTableSettingList }

function TPatternTableSettingList.Add(AObject: TPatternTableSetting): Integer;
begin
  Result := inherited Add(AObject);
end;

function TPatternTableSettingList.GetPatternTableSettingItem(
  Index: Integer): TPatternTableSetting;
begin
  Result := TPatternTableSetting(inherited Items[Index]);
end;

function TPatternTableSettingList.Last: TPatternTableSetting;
begin
  result := TPatternTableSetting(inherited Last);
end;

procedure TPatternTableSettingList.SetPatternTableSettingItem(Index: Integer;
  const Value: TPatternTableSetting);
begin
  inherited Items[Index] := Value;
end;

end.
