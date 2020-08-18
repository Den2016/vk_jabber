library vk_rs232;

uses
  ComServ,
  AddInLib in 'AddInLib.pas',
  AddInObj in 'AddInObj.pas',
  uComPort in 'uComPort.pas';

{$E dll}

exports
  DllGetClassObject,
  DllCanUnloadNow,
  DllRegisterServer,
  DllUnregisterServer;

{$R *.RES}

begin
end.
