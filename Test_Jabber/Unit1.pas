unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, GmXml, Jabber, JabberSock, jbconst,
  Vcl.ExtCtrls, IPPeerClient, REST.Client, Data.Bind.Components,
  Data.Bind.ObjectScope;

type
  TForm1 = class(TForm)
    Edit1: TEdit;
    Label1: TLabel;
    Edit2: TEdit;
    Label2: TLabel;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Edit3: TEdit;
    Button5: TButton;
    Button6: TButton;
    Button7: TButton;
    Label3: TLabel;
    Message: TLabel;
    Edit4: TEdit;
    Send: TButton;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    Memo1: TMemo;
    Memo2: TMemo;
    Memo3: TMemo;
    Button8: TButton;
    Label4: TLabel;
    Edit5: TEdit;
    RESTRequest1: TRESTRequest;
    RESTClient1: TRESTClient;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure Button7Click(Sender: TObject);
    procedure SendClick(Sender: TObject);
    procedure Button8Click(Sender: TObject);
  private
    { Private declarations }
    procedure JabberConnect(Sender: TObject);
    procedure JabberDisconnect(Sender: TObject);
    procedure JabberLoginError(Sender: TObject; XML: TGmXML);
    procedure JabberConnectError(Sender: TObject);
    procedure JabberGetRoster(Sender: TObject; XML: TGmXML);
    procedure JabberPresence(Sender: TObject; XML: TGmXML);
    procedure JabberMessage(Sender: TObject; XML: TGmXML);
    procedure JabberOnline(Sender: TObject);
    procedure JabberSentData(Sender: TObject; SendStr: String);
    procedure JabberRecieveData(Sender: TObject; SendStr: String);
  public
    { Public declarations }
    J:TJabberClient;
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}



procedure TForm1.Button1Click(Sender: TObject);
begin
  J.JID:=Edit1.Text;
  J.Password:=Edit2.Text;
  J.Connect(1);
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  Memo1.Lines.Clear;
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  J.Disconnect;
end;

procedure TForm1.Button4Click(Sender: TObject);
begin
  J.GetRoster;
end;

procedure TForm1.Button5Click(Sender: TObject);
begin
  J.SubscribeOK(Edit3.Text);
end;

procedure TForm1.Button6Click(Sender: TObject);
begin
  J.Subscribe(Edit3.Text);
end;

procedure TForm1.Button7Click(Sender: TObject);
begin
  J.unsubscribe(edit3.Text);
end;

procedure TForm1.Button8Click(Sender: TObject);
var S1,s2:String;
begin
  S1:=Edit1.Text;
  S2:=Edit2.Text;
  Edit1.Text:=Edit3.Text;
  Edit2.Text:=Edit5.Text;
  Edit3.Text:=S1;
  Edit5.Text:=S2;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  J:=TJabberClient.Create(self);
  J.OnConnect:=JabberConnect;
  J.OnDisconnect:=JabberDisconnect;
  J.OnLoginError:=JabberLoginError;
  J.OnConnectError:=JabberConnectError;
  J.OnGetRoster:=JabberGetRoster;
  J.OnPresence:=JabberPresence;
  J.OnMessage:=JabberMessage;
  J.OnJabberOnline:=JabberOnline;
  J.OnSendData:=JabberSentData;
  J.OnReceiveData:=JabberRecieveData;

end;

procedure TForm1.JabberConnect(Sender: TObject);
begin

end;

procedure TForm1.JabberConnectError(Sender: TObject);
begin

end;

procedure TForm1.JabberDisconnect(Sender: TObject);
begin

end;

procedure TForm1.JabberGetRoster(Sender: TObject; XML: TGmXML);
var x:integer;
begin
  memo1.Lines.Add('OnGetRoster');
  memo1.Lines.Add(XML.DisplayText);
  for x:=0 to J.Roster.Count-1 do begin
    Memo2.Lines.Add(J.Roster.JID[x]+', '+J.Roster.Status[x]+', '+J.Roster.Show[x]);
  end;
end;

procedure TForm1.JabberLoginError(Sender: TObject; XML: TGmXML);
begin

end;

procedure TForm1.JabberMessage(Sender: TObject; XML: TGmXML);
var _From,_Body:String;
begin
  _From:=XML.Nodes.Root.Params.Values['from'];
  If Pos('/',_From)>0 then _From:=Copy(_From,0,Pos('/',_From)-1);


  if XML.Nodes.Root.Children.NodeByName['body']<>nil then _Body:=XML.Nodes.Root.Children.NodeByName['body'].AsString;
  Memo3.Lines.Add(_From+'('+IntToStr(Length(_Body))+'):'+_Body);
end;

procedure TForm1.JabberOnline(Sender: TObject);
begin

end;

procedure TForm1.JabberPresence(Sender: TObject; XML: TGmXML);
begin
  Memo1.Lines.Add('PRESENCE');
    Memo1.Lines.Add(XML.DisplayText);
end;

procedure TForm1.JabberRecieveData(Sender: TObject; SendStr: String);
begin
    Memo1.Lines.Add('Прием');

    Memo1.Lines.Add(SendStr);
end;

procedure TForm1.JabberSentData(Sender: TObject; SendStr: String);
begin
    Memo1.Lines.Add('Отправка');

    Memo1.Lines.Add(SendStr);

end;

procedure TForm1.SendClick(Sender: TObject);
var G:TGUID;
begin
  CreateGUID(G);
  Memo3.Lines.Add('Sended message size='+IntToStr(Length(Edit4.Text)));

  J.SendMessage(Edit3.Text,'chat',Edit4.Text);
end;

end.
