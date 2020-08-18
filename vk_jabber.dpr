library vk_jabber;

uses
  ComServ,
  AddInLib in 'AddInLib.pas',
  AddInObj in 'AddInObj.pas',
  uComPort in 'uComPort.pas',
  GmXml in '..\common\GmXml.pas',
  Jabber in 'Jabber.pas',
  JabberSock in 'JabberSock.pas',
  jbconst in 'jbconst.pas',
  u_OpenXML in 'u_OpenXML.pas',
  uRC6 in 'uRC6.pas',
  gForm in 'gForm.pas' {GalleryForm};

{$E dll}

exports
  DllGetClassObject,
  DllCanUnloadNow,
  DllRegisterServer,
  DllUnregisterServer;

{$R *.RES}

begin
end.
