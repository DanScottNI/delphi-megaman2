program RockRoll2;

uses
  Forms,
  MainRockRoll2 in 'MainRockRoll2.pas' {frmRockRoll2Main},
  cMegaROM2 in 'cMegaROM2.pas',
  uROM in 'uROM.pas',
  uLunarCompress in 'uLunarCompress.pas',
  uGlobal in 'uGlobal.pas',
  cLevel in 'cLevel.pas',
  uResources in 'uResources.pas',
  uToday in 'uToday.pas',
  fOpenDialog in 'fOpenDialog.pas' {frmOpenDialog},
  cconfiguration in 'cconfiguration.pas',
  cPatternTableSettings in 'cPatternTableSettings.pas',
  uConst in 'uConst.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmRockRoll2Main, frmRockRoll2Main);
  Application.CreateForm(TfrmOpenDialog, frmOpenDialog);
  Application.Run;
end.
