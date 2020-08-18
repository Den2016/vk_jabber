unit AddInObj;

interface

uses  { ����� ���������� ���������� }
{$IFDEF DEBUGDC}
  dbugintf, Dialogs,
{$ENDIF}
  ComServ, ComObj, ActiveX, SysUtils, Windows, AddInLib, Classes, Jabber, GmXml, ExtCtrls,
  IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, u_OpenXML, IdCustomTCPServer, IdTCPServer, IdUDPBase, IdUDPClient,
  IdContext, Forms, Winapi.Messages, gForm;

     const c_AddinName = 'vk_jabber'; //��� ������� ����������

     //���������� �������
     const c_PropCount = 22;

     //�������������� �������
     type TProperties = (
       propErrorMsg,
       propJID,
       propPassword,
       propPort,
       propServer,
       propOnline,
       propContact,
       propContactShow,
       propKeepAlivePeriod,
       propContactStatus,
       propLastXML,
       propLogging,
       propLogFileName,
       propGUID,
       propSocketHost,
       propSocketPort,
       propSocketConnected,
       propTagName,
       propCharacters,
       propDefaultEncoding,
       propPasswordRC6,
       propTimeOff
     );

     //����� �������, ������� �� 1�
     //������� ���������� ����� ����� ��, ��� � � TProperties
    const c_PropNames: Array[0..c_PropCount-1, 0..1] of WideString =
    (
      ('ErrorMsg','������'),
      ('JID','�������'),
      ('Password','������'),
      ('Port','����'),
      ('Server','������'),
      ('Online','�����'),
      ('Contact','�������'),
      ('ContactShow','���������'),
      ('KeepAlivePeriod','��������������������������'),
      ('ContactStatus','������'),
      ('LastXML','���������XML'),
      ('Logging','��������'),
      ('LogFileName','������������'),
      ('GUID','������������'),
      ('SocketHost','���������'),
      ('SocketPort','���������'),
      ('SocketConnected','��������������'),
      ('XMLTagName','XML�������'),
      ('XMLCharacters','XML�������'),
      ('XMLDefaultEncoding', 'XML��������������������'),
      ('XMLPassword', 'XML������'),
      ('TimeOff', '���������������')

    );

    //���������� �������
     const c_MethCount = 28;
    //�������������� �������.
    type TMethods = (
       methConnect,
       methDisconnect,
       methGetRoster,
       methSelectContacts,
       methGetContact,
       methGetContactShow,
       methGetContactStatus,
       methSendMessage,
       methSubscribe,
       methSubscribeOK,
       methUnSubscribe,
       methSocketConnect,
       methSocketDisConnect,
       methSocketSend,

       methOpenFile,
       methCloseFile,
       methReadTag,
       methReadValue,

       methCreateFile,
       methAppendFile,
       methWriteTag,
       methWriteValue,

       methAddParam,
       methGetParam,

       methWriteComment,
       methWriteFreeText,

       methFindKKMServer,


       methOpenWindow

       );

    //����� �������, ������� �� 1�
     //������� ���������� ����� ����� ��, ��� � � TMethods
    const c_MethNames: Array[0..c_MethCount-1,0..2] of WideString =
    (
    ('Connect','����������','0'),
    ('Disconnect','���������','0'),
    ('GetRoster','�����������������������','0'),
    ('SelectContacts','���������������','0'),
    ('GetContact','���������������','0'),
    ('GetContactShow','�����������������','1'),
    ('GetContactStatus','��������������','1'),
    ('SendMessage','���������','2'),             //��� ��������� - ���� � ���������
    ('Subscribe','��������������','1'),             //���� �������� - ����
    ('SubscribeOK','����������������','1'),             //���� �������� - ����
    ('UnSubscribe','����������','1'),             //���� �������� - ����
    ('SocketConnect','���������������','0'),
    ('SocketDisconnect','��������������','0'),
    ('SocketSend','��������������','1'),

    ('OpenFile','�����������','1'),
    ('CloseFile','�����������', '0'),

    ('ReadTag','������������', '1'),
    ('ReadValue','�����������������', '1'),

    ('CreateFile','�����������', '1'),
    ('AppendFile','�������������', '1'),
    ('WriteTag','�����������', '1'),
    ('WriteValue','����������������', '2'),

    ('AddParam','���������������', '2'),
    ('GetParam','���������������', '1'),

    ('WriteComment','�������������������', '1'),
    ('WriteFreeText','�������������������������', '1'),
    ('FindKKMServer','��������������','1'),

    ('OpenWindow','�����������','0')
    );

const
{������� Ctrl-Shift-G ����� ������������� ����� ���������� ������������� GUID}
     CLSID_AddInObject : TGUID = '{53084AD4-68ED-4391-9549-812C896B74BE}';

type

  AddInObject = class(TComObject, IDispatch, IInitDone, ILanguageExtender)

  public

    CloseTimer:TTimer;
    g_ErrorMsg: String;
    g_Jabber:TJabberClient;
    g_IdClient:TIdTCPClient;
    g_IdServer:TIdTCPServer;
    g_IdUDP:TIdUDPClient;

    xml: T_OpenXML;

    i1cv7: IDispatch;
    iStatus: IStatusLine;
    iExtWindows: IExtWndsSupport;
    iError: IErrorLog;
    iEvent : IAsyncEvent;
    _App: OleVariant;
  protected
    FKKMSrv:String;
    FKKMSrvIp:String;
    Timer:TTimer;
    FGalleryForm:TGalleryForm;
    { These two methods is convenient way to access function
      parameters from SAFEARRAY vector of variants }
    function GetNParam(var pArray : PSafeArray; lIndex: Integer ): OleVariant;
    procedure PutNParam(var pArray: PSafeArray; lIndex: Integer; var varPut: OleVariant);


    { IInitDone implementation }
    function Init(pConnection: IDispatch): HResult; stdcall;
    function Done: HResult; stdcall;
    function GetInfo(var pInfo: PSafeArray): HResult; stdcall;

    { ILanguageExtender implementation }
    function RegisterExtensionAs(var bstrExtensionName: WideString): HResult; stdcall;
    function GetNProps(var plProps: Integer): HResult; stdcall;
    function FindProp(const bstrPropName: WideString; var plPropNum: Integer): HResult; stdcall;
    function GetPropName(lPropNum, lPropAlias: Integer; var pbstrPropName: WideString): HResult; stdcall;
    function GetPropVal(lPropNum: Integer; var pvarPropVal: OleVariant): HResult; stdcall;
    function SetPropVal(lPropNum: Integer; var varPropVal: OleVariant): HResult; stdcall;
    function IsPropReadable(lPropNum: Integer; var pboolPropRead: Integer): HResult; stdcall;
    function IsPropWritable(lPropNum: Integer; var pboolPropWrite: Integer): HResult; stdcall;
    function GetNMethods(var plMethods: Integer): HResult; stdcall;
    function FindMethod(const bstrMethodName: WideString; var plMethodNum: Integer): HResult; stdcall;
    function GetMethodName(lMethodNum, lMethodAlias: Integer; var pbstrMethodName: WideString): HResult; stdcall;
    function GetNParams(lMethodNum: Integer; var plParams: Integer): HResult; stdcall;
    function GetParamDefValue(lMethodNum, lParamNum: Integer; var pvarParamDefValue: OleVariant): HResult; stdcall;
    function HasRetVal(lMethodNum: Integer; var pboolRetValue: Integer): HResult; stdcall;
    function CallAsProc(lMethodNum: Integer; var paParams: PSafeArray): HResult; stdcall;
    function CallAsFunc(lMethodNum: Integer; var pvarRetValue: OleVariant; var paParams: PSafeArray): HResult; stdcall;

    { IDispatch }
    function GetIDsOfNames(const IID: TGUID; Names: Pointer;
      NameCount, LocaleID: Integer; DispIDs: Pointer): HResult; virtual; stdcall;
    function GetTypeInfo(Index, LocaleID: Integer; out TypeInfo): HResult; virtual; stdcall;
    function GetTypeInfoCount(out Count: Integer): HResult; virtual; stdcall;
    function Invoke(DispID: Integer; const IID: TGUID; LocaleID: Integer;
      Flags: Word; var Params; VarResult, ExcepInfo, ArgErr: Pointer): HResult; virtual; stdcall;

    { IStatusLine }
    function SetStatusLine(const bstrSource: WideString): HResult; safecall;
    function ResetStatusLine(): HResult; safecall;

    procedure ShowErrorLog(fMessage:WideString);

    procedure OnTimer(Sender:TObject);
    procedure OnCloseTimer(Sender:TObject);

    procedure Close1C;

    { Jabber events }

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


    procedure g_IdServerExecute(AContext: TIdContext);

    procedure OpenWindow1C;

  end;


  TCloseTimer=class(TTimer)
  private
    FTime:String;
  protected
  public
    procedure SetTime(ATime:String);

  end;

implementation


type
  TWndRec=record
    cls:String;
    Wnd:HWND;
    title:String;
    wLong:LongInt;
  end;
  TWndList=array of TWndRec;

var
  WndList:TWndList;


var
    procId,procId1:DWORD;

function GetWindowClass(hwnd: HWND): string;
var a:array of char;
    x:Integer;
begin
  SetLength(a, 255);
  X:=GetClassName(hwnd, PChar(a), 255);
  a[x]:=#0;
  x:=0;
  Result:='';
  while a[x]<>#0 do begin
    Result:=Result+a[x];
    inc(x);
  end;
  SetLength(a,0);
end;

function EnumProc (WinHandle: HWnd; Param: LongInt): Boolean; stdcall;
var
    buff: array of char;
    cls:String;
    l:Longint;
    wr:TWndRec;
begin
// ���� �������� � Handle... ��� handles �������� ���� ���������� ����.

    SetLength(Buff,128);
    try
      if GetWindowText(WinHandle, PChar(buff), 128) <> 0 then begin
        GetWindowThreadProcessId(WinHandle,procId1);

        if procId=procId1 then begin
          cls:=GetWindowClass(WinHandle);
          if (cls<>'BMASKED') and (cls<>'1CEDIT') and (cls<>'1CEDITSPR') then begin
            wr.cls:=cls;
            wr.title:=StrPas(PChar(buff));
            wr.Wnd:=WinHandle;
            wr.wLong:=GetWindowLong(WinHandle,GWL_STYLE);
            SetLength(WndList,Length(WndList)+1);
            WndList[Length(WndList)-1]:=wr;

 (*
  {$IFDEF DEBUGDC}
            SendDebugEx('window ('+IntToStr(Param)+') '+cls+' '+inttostr(WinHandle)+' '+StrPas(PChar(buff)),mtInformation);
            l:=GetWindowLong(WinHandle,GWL_STYLE);
            cls:='';
            if L and WS_BORDER = WS_BORDER then cls:=cls+'WS_BORDER ';
            if L and WS_CAPTION = WS_CAPTION then cls:=cls+'WS_CAPTION ';
            if L and WS_DLGFRAME = WS_DLGFRAME then cls:=cls+'WS_DLGFRAME ';
            if L and WS_OVERLAPPED = WS_OVERLAPPED then cls:=cls+'WS_OVERLAPPED ';
            if L and WS_POPUP = WS_POPUP then cls:=cls+'WS_POPUP ';
            if L and WS_SIZEBOX = WS_POPUP then cls:=cls+'WS_SIZEBOX ';
            if L and WS_SYSMENU = WS_POPUP then cls:=cls+'WS_SYSMENU ';
            SendDebugEx('window ('+IntToStr(Param)+') '+cls+' '+inttostr(WinHandle)+' '+StrPas(PChar(buff)),mtInformation);
  {$ENDIF}
*)

          end;
        end;

   //   EnumChildWindows(WinHandle,@EnumProc,Param+1);
      end;
    finally
      SetLength(Buff,0);
    end;
  result:=true;
end;


function WindowProc(wnd:HWND; Msg : Integer; Wparam:Wparam; Lparam:Lparam):Lresult; stdcall;
Begin
  {case msg of
    wm_destroy :
      Begin
        postquitmessage(0); exit;
        Result:=0;
      End;
    else }Result:=DefWindowProc(wnd,msg,wparam,lparam);
  //end;
End;


//=======================  General functions  ================================
///////////////////////////////////////////////////////////////////////
function AddInObject.GetNParam(var pArray : PSafeArray; lIndex: Integer ): OleVariant;
var
  varGet : OleVariant;
begin
  SafeArrayGetElement(pArray,lIndex,varGet);
  GetNParam := varGet;
end;

///////////////////////////////////////////////////////////////////////
procedure AddInObject.PutNParam(var pArray: PSafeArray; lIndex: Integer; var varPut: OleVariant);
begin
  SafeArrayPutElement(pArray,lIndex,varPut);
end;



//======================= IInitDone interface ================================
///////////////////////////////////////////////////////////////////////
function AddInObject.Init(pConnection: IDispatch): HResult; stdcall;
var  wnd: HWND;
begin
  i1cv7:=pConnection;
  Timer:=TTimer.Create(nil);
  TIMER.Enabled:=False;
  Timer.OnTimer:=OnTimer;
  CloseTimer:=TCloseTimer.Create(nil);
  CloseTimer.OnTimer:=OnCloseTimer;
  CloseTimer.Interval:=10000;
  CloseTimer.Enabled:=false;

  FGalleryForm:=nil;

  iError:=nil;
  pConnection.QueryInterface(IID_IErrorLog,iError);

  iStatus:=nil;
  pConnection.QueryInterface(IID_IStatusLine,iStatus);

  iEvent := nil;
  pConnection.QueryInterface(IID_IAsyncEvent,iEvent);
  iEvent.SetEventBufferDepth(300); //������� ������ �������


  iExtWindows:=nil;
  pConnection.QueryInterface(IID_IExtWndsSupport,iExtWindows);


  iExtWindows.GetAppMainFrame(wnd);
  Application.Handle := wnd;

  _App:=pConnection;


//  g_cp:= T_ComPort.Create;
  g_Jabber:=TJabberClient.Create(nil);
  g_Jabber.OnConnect:=JabberConnect;
  g_Jabber.OnDisconnect:=JabberDisconnect;
  g_Jabber.OnLoginError:=JabberLoginError;
  g_Jabber.OnConnectError:=JabberConnectError;
//  g_Jabber.OnGetRoster:=JabberGetRoster;
//  g_Jabber.OnPresence:=JabberPresence;
  g_Jabber.OnMessage:=JabberMessage;
//  g_Jabber.OnJabberOnline:=JabberOnline;
//  g_Jabber.OnSendData:=JabberSentData;
//  g_Jabber.OnReceiveData:=JabberRecieveData;

  g_IdClient:=TIdTCPClient.Create(nil);
  try
  xml:=T_OpenXML.Create;
  except
  end;


  Init := S_OK;
end;

///////////////////////////////////////////////////////////////////////
function AddInObject.Done: HResult; stdcall;
begin
  CloseTimer.Enabled:=false;
  FreeAndNil(CloseTimer);
  Timer.Enabled:=False;
  FreeAndNil(Timer);
  if Assigned(g_Jabber) then FreeAndNil(g_Jabber);
  if Assigned(g_IdClient) then FreeAndNil(g_IdClient);

  If ( iStatus <> nil ) then
    iStatus._Release();

  If ( iExtWindows <> nil ) then
    iExtWindows._Release();

  If ( iError <> nil ) then
    iError._Release();

  if (iEvent <> nil) then
    iEvent._Release();

  try
  if (xml <> nil) then
    xml.Destroy;
  except
  end;

  Done := S_OK;
end;
///////////////////////////////////////////////////////////////////////
function AddInObject.GetInfo(var pInfo: PSafeArray{(OleVariant)}): HResult; stdcall;
var  varInfo : OleVariant;
begin
  varInfo := '2000';
  PutNParam(pInfo,0,varInfo);

  GetInfo := S_OK;
end;

//======================= IStatusLine Interface ==============================
///////////////////////////////////////////////////////////////////////
function AddInObject.SetStatusLine(const bstrSource: WideString): HResult; safecall;
begin
  SetStatusLine:=S_OK;
end;
///////////////////////////////////////////////////////////////////////
function AddInObject.ResetStatusLine(): HResult; safecall;
begin
  //ResetStatusLine: = S_OK;
end;

//======================= ILanguageExtender Interface ========================
///////////////////////////////////////////////////////////////////////
function AddInObject.RegisterExtensionAs(var bstrExtensionName: WideString): HResult; stdcall;
begin
  bstrExtensionName := c_AddinName;
  RegisterExtensionAs := S_OK;
end;
///////////////////////////////////////////////////////////////////////
function AddInObject.GetNProps(var plProps: Integer): HResult; stdcall;
begin
     plProps := Integer(c_PropCount);
     GetNProps := S_OK;
end;
///////////////////////////////////////////////////////////////////////
function AddInObject.FindProp(const bstrPropName: WideString; var plPropNum: Integer): HResult; stdcall;
var
  NewPropName: WideString;
  i: Integer;
begin
     plPropNum := -1;

     NewPropName:=bstrPropName;

     for i:=0 to c_PropCount-1 do begin
       if (NewPropName=c_PropNames[i,0]) or (NewPropName=c_PropNames[i,1]) then begin
         plPropNum:=i;
         break;
       end;
     end;

     if (plPropNum = -1) then
       begin
         FindProp := S_FALSE;
         Exit;
       end;

     FindProp := S_OK;
end;
///////////////////////////////////////////////////////////////////////
function AddInObject.GetPropName(lPropNum, lPropAlias: Integer; var pbstrPropName: WideString): HResult; stdcall;
begin
     pbstrPropName := '';
     if (lPropAlias<>0) and (lPropAlias<>1) then begin
            GetPropName := S_FALSE;
            Exit;
     end;
     if (lPropNum<0) or (lPropNum>=c_PropCount) then begin
            GetPropName := S_FALSE;
            Exit;
     end;

     pbstrPropName := c_PropNames[lPropNum, lPropAlias];

     GetPropName := S_OK;
end;
///////////////////////////////////////////////////////////////////////
function AddInObject.GetPropVal(lPropNum: Integer; var pvarPropVal: OleVariant): HResult; stdcall;
//����� 1� ������ �������� �������
var G:TGUID;
begin
     VarClear(pvarPropVal);
     try
       case TProperties(lPropNum) of
            propErrorMsg:
              begin
                   pvarPropVal := g_ErrorMsg;
              end;
            propJID:pvarPropVal := g_Jabber.JID;
            propPassword:pvarPropVal := g_Jabber.Password;
            propPort:pvarPropVal := g_Jabber.JabberPort;
            propServer:pvarPropVal := g_Jabber.JabberServer;
            propOnline:if g_Jabber.JabberOnline then pvarPropVal := 1 else pvarPropVal := 0;
            propContact:pvarPropVal := g_Jabber.CurrentRosterJID;
            propContactShow:pvarPropVal := g_Jabber.CurrentRosterShow;
            propKeepAlivePeriod:pvarPropVal := Trunc(Timer.Interval/1000);
            propContactStatus:pvarPropVal := g_Jabber.CurrentRosterStatus;
            propLastXML:pvarPropVal := g_Jabber.LastXML;
//            propLogging:if g_Jabber.Logging then pvarPropVal := 1 else pvarPropVal := 0;
//            propLogFileName:pvarPropVal := g_Jabber.LogFileName;
            propGUID: begin
              CreateGUID(G);
              pvarPropVal:=GUIDToString(G);
            end;
            propSocketHost:pvarPropVal:=g_IdClient.Host;
            propSocketPort:pvarPropVal:=g_IdClient.Port;
            propSocketConnected:begin
              try
                if g_IdClient.Connected then pvarPropVal:=1 else pvarPropVal:=0;
              except
                pvarPropVal:=0;
              end;
            end;
            propTagName:
                   pvarPropVal := xml.g_TagName;
            propCharacters:
                   pvarPropVal := xml.g_Characters;
            propDefaultEncoding:
                   pvarPropVal := xml.g_DefaultEncoding;
            propPasswordRC6:
                   pvarPropVal := xml.g_PasswordRC6;
            else
              GetPropVal := S_FALSE;
              Exit;
       end;
      except

           on E:Exception do begin
             g_ErrorMsg:=E.Message;
             ShowErrorLog(g_ErrorMsg);
           end;

      end; //try
     GetPropVal := S_OK;
end;
///////////////////////////////////////////////////////////////////////
function AddInObject.SetPropVal(lPropNum: Integer; var varPropVal: OleVariant): HResult; stdcall;
//����� 1� ������������� �������� �������
Var X:Integer;
begin
     try
       case TProperties(lPropNum) of
            propJID: g_Jabber.JID:=varPropVal;
            propPassword: g_Jabber.Password:=varPropVal;
            propPort: g_Jabber.JabberPort:=varPropVal;
            propServer: g_Jabber.JabberServer:=varPropVal;
            propKeepAlivePeriod: begin
              X:=varPropVal;
              if X=0 then begin
                Timer.Enabled:=False;
                Timer.Interval:=0;
              end else begin
                Timer.Interval:=X*1000;
                Timer.Enabled:=True;
              end;
  {$IFDEF DEBUGDC}
    SendDebugEx('Set timer interval '+IntToStr(Timer.Interval),mtInformation);
  {$ENDIF}

            end;
            propSocketHost:g_IdClient.Host:=varPropVal;
            propSocketPort:g_IdClient.Port:=varPropVal;
            propDefaultEncoding:
                   xml.g_DefaultEncoding:=varPropVal;
            propPasswordRC6: begin
                   xml.g_PasswordRC6:=varPropVal;
                   if xml.g_PasswordRC6='' then begin
                     xml.g_RC6:=False;
                   end else begin
                     xml.g_RC6:=True;
                   end;
              end;
            propTimeOff:begin
                TCloseTimer(CloseTimer).SetTime(varPropVal);
                CloseTimer.Enabled:=true;
              end;

            else
              SetPropVal := S_FALSE;
              Exit;
       end;
      except
           on E:Exception do begin
             g_ErrorMsg:=E.Message;
             ShowErrorLog(g_ErrorMsg);
           end;
      end; //try
  SetPropVal := S_OK;
end;
///////////////////////////////////////////////////////////////////////
function AddInObject.IsPropReadable(lPropNum: Integer; var pboolPropRead: Integer): HResult; stdcall;
{����� 1� ������, ����� �� ������ ��������}
begin
//����� ��� �������� ����������
  pboolPropRead := 1;

//     case TProperties(lPropNum) of
//          propErrorMsg: pboolPropRead := 1;{1=����� ������ ��������, 0=���}
//     else
//            IsPropReadable := S_FALSE;
//            Exit;
//     end;
  IsPropReadable := S_OK;

end;
///////////////////////////////////////////////////////////////////////
function AddInObject.IsPropWritable(lPropNum: Integer; var pboolPropWrite: Integer): HResult; stdcall;
//����� 1� ������, ����� �� �������� ��������
begin
     case TProperties(lPropNum) of
          propErrorMsg: pboolPropWrite := 0;{1=����� ���������� ��������, 0=���}
          propJID:pboolPropWrite := 1;{1=����� ���������� ��������, 0=���}
          propPassword:pboolPropWrite := 1;{1=����� ���������� ��������, 0=���}
          propPort:pboolPropWrite := 1;{1=����� ���������� ��������, 0=���}
          propServer:pboolPropWrite := 1;{1=����� ���������� ��������, 0=���}
          propOnline:pboolPropWrite := 0;{1=����� ���������� ��������, 0=���}
          propContact:pboolPropWrite := 0;{1=����� ���������� ��������, 0=���}
          propContactShow:pboolPropWrite := 0;{1=����� ���������� ��������, 0=���}
          propKeepAlivePeriod:pboolPropWrite := 1;{1=����� ���������� ��������, 0=���}
          propContactStatus:pboolPropWrite := 0;{1=����� ���������� ��������, 0=���}
          propSocketHost:pboolPropWrite:=1;
          propSocketPort:pboolPropWrite:=1;
          else
            IsPropWritable := S_FALSE;
            Exit;
     end;

     IsPropWritable := S_OK;
end;

procedure AddInObject.JabberConnect(Sender: TObject);
begin
  iEvent.ExternalEvent(c_AddinName, 'JabberConnect', '');
end;

procedure AddInObject.JabberConnectError(Sender: TObject);
begin
  iEvent.ExternalEvent(c_AddinName, 'JabberConnectError', '');
end;

procedure AddInObject.JabberDisconnect(Sender: TObject);
begin
  iEvent.ExternalEvent(c_AddinName, 'JabberDisconnect', '');
end;

procedure AddInObject.JabberGetRoster(Sender: TObject; XML: TGmXML);
begin
  iEvent.ExternalEvent(c_AddinName, 'JabberGetRoster', '');
end;

procedure AddInObject.JabberLoginError(Sender: TObject; XML: TGmXML);
begin
  iEvent.ExternalEvent(c_AddinName, 'JabberLoginError', XML.DisplayText);
end;

procedure AddInObject.JabberMessage(Sender: TObject; XML: TGmXML);
var _From,_Body:String;
begin
  _From:=XML.Nodes.Root.Params.Values['from'];
  If Pos('/',_From)>0 then _From:=Copy(_From,0,Pos('/',_From)-1);


  if XML.Nodes.Root.Children.NodeByName['body']<>nil then _Body:=XML.Nodes.Root.Children.NodeByName['body'].AsString;
  iEvent.ExternalEvent(c_AddinName, 'JabberMessage', _From+'|'+_Body);

end;

procedure AddInObject.JabberOnline(Sender: TObject);
begin
  iEvent.ExternalEvent(c_AddinName, 'JabberOnline', '');
end;

procedure AddInObject.JabberPresence(Sender: TObject; XML: TGmXML);
begin
  iEvent.ExternalEvent(c_AddinName, 'JabberPresence', '');
end;

procedure AddInObject.JabberRecieveData(Sender: TObject; SendStr: String);
begin
  iEvent.ExternalEvent(c_AddinName, 'JabberRecieve', SendStr);
end;

procedure AddInObject.JabberSentData(Sender: TObject; SendStr: String);
begin
  iEvent.ExternalEvent(c_AddinName, 'JabberSend', SendStr);

end;




procedure AddInObject.OnCloseTimer(Sender: TObject);
var S:String;
var wnd: hwnd;
    buff: array [0..127] of char;
    V:OleVariant;
begin
  inherited;
  S:=TimeToStr(Now);
  if S[2]=':' then S:='0'+S;
  S:=Copy(S,1,5);
  {$IFDEF DEBUGDC}
    SendDebugEx('closetimer proc '+IntToStr(CloseTimer.Interval),mtInformation);
    SendDebugEx('close time '+TCloseTimer(CloseTimer).FTime,mtInformation);
    SendDebugEx('now '+S,mtInformation);

    {
    }
  {$ENDIF}
//  wnd:=GetForegroundWindow;
//  if wnd<>0 then EnumProc(wnd,1);



 // iExtWindows.GetAppMDIFrame(wnd);
  try
    if S=TCloseTimer(CloseTimer).FTime then begin
      // ����� ��������� 1�
      Close1C;

    end;
  finally

  end;

  {$IFDEF DEBUGDC}
  {
  wnd := GetWindow(Application.Handle, gw_hwndfirst);
  while wnd <> 0 do begin // �� ����������:
    if (wnd <> Application.Handle) // ����������� ����
    and IsWindowVisible(wnd) // ��������� ����
    //and (GetWindow(wnd, gw_owner) = 0) // �������� ����
    and (GetWindowText(wnd, buff, SizeOf(buff)) <> 0) then begin
      GetWindowText(wnd, buff, SizeOf(buff));
      SendDebugEx('window '+inttostr(wnd)+' '+StrPas(buff),mtInformation);
    end;
    wnd := GetWindow(wnd, gw_hwndnext);
  end;}
  {$ENDIF}



end;

procedure AddInObject.OnTimer(Sender: TObject);
begin
  {$IFDEF DEBUGDC}
    SendDebugEx('timer proc '+IntToStr(Timer.Interval),mtInformation);
  {$ENDIF}
  g_Jabber.Connect(1);
end;

procedure AddInObject.OpenWindow1C;
var
  wc : TWndClassEx;
  MainWnd, Wnd1C : HWND;
  Mesg : TMsg;
  xPos,yPos,nWidth,nHeight : Integer;
begin

  iExtWindows.GetAppMDIFrame(Wnd1C);
  if FGalleryForm=nil then FGalleryForm:=TGalleryForm.Create(nil);
  FGalleryForm.FormStyle:=fsStayOnTop;
  FGalleryForm.Show;

{  wc.cbSize:=sizeof(wc);
  wc.style:=cs_hredraw or cs_vredraw;
  wc.lpfnWndProc:=@WindowProc;
  wc.cbClsExtra:=0;
  wc.cbWndExtra:=0;
  wc.hInstance:=HInstance;
  wc.hIcon:=LoadIcon(0,idi_application);
  wc.hCursor:=LoadCursor(0,idc_arrow);
  wc.hbrBackground:=COLOR_BTNFACE+1;
  wc.lpszMenuName:=nil;
  wc.lpszClassName:='WinMin:Main';

  RegisterClassEx(wc);
  xPos:=100;
  yPos:=150;
  nWidth:=400;
  nHeight:=250;

  MainWnd:=CreateWindowEx(
  0,
  'WinMin:Main',
  'Win Min',
  ws_overlappedwindow,
  xPos,
  yPos,
  nWidth,
  nHeight,
  Wnd1C,
  0,
  Hinstance,
  nil
  );
 }
//  f:=TTestForm.Create(nil);
//  f.ParentWindow:=MainWnd;
//  f.FormStyle:=fsStayOnTop;
//  f.Show;

//  ShowWindow(MainWnd,CmdShow);

end;

///////////////////////////////////////////////////////////////////////
function AddInObject.GetNMethods(var plMethods: Integer): HResult; stdcall;
begin
     plMethods := c_MethCount;
     GetNMethods := S_OK;
end;
///////////////////////////////////////////////////////////////////////
function AddInObject.FindMethod(const bstrMethodName: WideString; var plMethodNum: Integer): HResult; stdcall;
var NewMethodName: WideString;
var i:Integer;
begin
  NewMethodName := bstrMethodName;

     plMethodNum := -1;

     for i:=0 to c_MethCount-1 do begin
       if (NewMethodName=c_MethNames[i,0]) or (NewMethodName=c_MethNames[i,1]) then begin
         plMethodNum := i;
         break;
       end;
     end;

     if (plMethodNum = -1) then
       begin
         FindMethod := S_FALSE;
         Exit;
       end;

     FindMethod := S_OK;

end;
///////////////////////////////////////////////////////////////////////
function AddInObject.GetMethodName(lMethodNum, lMethodAlias: Integer; var pbstrMethodName: WideString): HResult; stdcall;
begin

     pbstrMethodName := '';
     if (lMethodAlias<>0) and (lMethodAlias<>1) then begin
            Result := S_FALSE;
            Exit;
     end;
     if (lMethodNum<0) or (lMethodNum>=c_MethCount) then begin
            Result := S_FALSE;
            Exit;
     end;

     pbstrMethodName := c_MethNames[lMethodNum, lMethodAlias];

     GetMethodName := S_OK;

end;

///////////////////////////////////////////////////////////////////////
function AddInObject.GetNParams(lMethodNum: Integer; var plParams: Integer): HResult; stdcall;
//����� 1� ������ ���������� ���������� � �������
begin

     plParams := StrToInt(c_MethNames[lMethodNum, 2]);
(*     plParams := 0;

     case TMethods(lMethodNum) of

          methGetContactShow: plParams := 1;{1 ��������}
          methGetContactStatus: plParams := 1;{1 ��������}
          methSendMessage: plParams := 2;{���� � ���������}
          methSubscribe: plParams := 1;{����}
          methSubscribeOK: plParams := 1;{����}
          methUnSubscribe: plParams := 1;{����}
          methSocketSend: plParams := 1;
          else
            begin
               GetNParams := S_FALSE;
               Exit;
            end;
     end;
  *)
     GetNParams := S_OK;

end;
///////////////////////////////////////////////////////////////////////
function AddInObject.GetParamDefValue(lMethodNum, lParamNum: Integer; var pvarParamDefValue: OleVariant): HResult; stdcall;
begin
  { Ther is no default value for any parameter }
  VarClear(pvarParamDefValue);
  GetParamDefValue := S_OK;
end;
///////////////////////////////////////////////////////////////////////
function AddInObject.HasRetVal(lMethodNum: Integer; var pboolRetValue: Integer): HResult; stdcall;
//����� 1� ������, ����� ������ �������� ��� �������
begin
  pboolRetValue := 1; //��� ������ ���������� ��������
  HasRetVal := S_OK;
end;



///////////////////////////////////////////////////////////////////////
function AddInObject.CallAsProc(lMethodNum: Integer; var paParams: PSafeArray{(OleVariant)}): HResult; stdcall;
//����� 1� ��������� ��� ��������
begin
    CallAsProc := S_FALSE;
end;

procedure AddInObject.Close1C;
var V:OleVariant;
    X:Integer;
begin
  {���� ������� 1� �� ��������, ��� ���� ��������� �������
  1. �������� ���� "���������? ��-���"
  2. ��������� ���� ������ �� �����������, ��������� � �������
  �������� ������ �������� 1� "����������������������(0)", �� ���� ��� ������������� ����������, ��� �����.
  ����� ���� ���������� �������� ������� ��������� ���� � ���� ��������

  }
  {$IFDEF DEBUGDC}
    SendDebugEx('closetimer call TerminateProcess ',mtInformation);
  {$ENDIF}
  procId:=GetCurrentProcessId; //�������� ID ��������

  SetLength(WndList,0);// �������� ������ ����
  EnumChildWindows(GetDesktopWindow, @EnumProc,0); // ������ ������ �������� ���� 1�
  // �������� ������
  if Length(WndList)<>0 then begin
    if WndList[0].cls='#32770' then begin // ��������� ����. ���� ��� ������, ���� ����� �� �����������, ���� �����-�� ������� Dialog
      if WndList[0].title='1�:�����������' then begin  //������ ���� "��������� ������?" ��� ������("�������?","��+���")
        X:=1; //�������� ����� � ������ ���� ������ � ������ &���
        while X<Length(WndList) do begin
          if WndList[x].cls='Button' then begin
            if WndList[x].title='&���' then begin
              PostMessage(WndList[x].Wnd,WM_LBUTTONDOWN,0,0); // ��������� ���� �� ������
              PostMessage(WndList[x].Wnd,WM_LBUTTONUP,0,0); // ��������� ���� �� ������
              break;
            end;
          end;
          if WndList[x].cls='#32770' then break;
          Inc(X);
        end;
      end else if WndList[0].title<>'Dialog' then begin // ����� �� �����������, ���� �� Dialog
        PostMessage(WndList[0].Wnd,WM_CLOSE,0,0); // ������ ���� ���� ������ WM_CLOSE;
      end;
    end;
  end;

  V:=_App.AppDispatch;
  IDispatch(V)._AddRef;
  V.ExecuteBatch('����������������������(0)');

end;

///////////////////////////////////////////////////////////////////////
function AddInObject.CallAsFunc(lMethodNum: Integer; var pvarRetValue: OleVariant; var paParams: PSafeArray): HResult; stdcall;
{����� 1� ��������� ��� �������}
var _to,_msg: String;
    ss:TStringStream;
    TagName: ShortString;
    s: String;
    fname: String;
    AttrName, AttrValue: String;
    x:Integer;
begin
  pvarRetValue:=0;
  try
    case TMethods(lMethodNum) of

      methConnect: begin
        g_Jabber.Connect(1);
        pvarRetValue:=1;
      end;

      methDisconnect: begin
        Timer.Enabled:=false;
        Timer.Interval:=0;
        g_Jabber.Disconnect;
        pvarRetValue:=1;
      end;

      methSendMessage: begin
        _to:=GetNParam(paParams,0);//����������
        _msg:=GetNParam(paParams,1);//���������
        g_Jabber.SendMessage(_to,'chat',_msg);
      end;

      methSubscribe: begin
        _to:=GetNParam(paParams,0);//����������
        g_Jabber.Subscribe(_to);
      end;
      methSubscribeOK: begin
        _to:=GetNParam(paParams,0);//����������
        g_Jabber.SubscribeOK(_to);
      end;
      methUnSubscribe: begin
        _to:=GetNParam(paParams,0);//����������
        g_Jabber.UnSubscribe(_to);
      end;

      methGetRoster: begin
        g_Jabber.GetRoster;
        pvarRetValue:=1;
      end;

      methSelectContacts: begin
        pvarRetValue:=g_Jabber.StartRosterSelect;
      end;

      methGetContact: begin
        pvarRetValue:=g_Jabber.GetNextRosterItem;
      end;

      methGetContactShow: begin
        pvarRetValue:=g_Jabber.Roster.JIDs[GetNParam(paParams,0)].Show;
      end;

      methGetContactStatus: begin
        pvarRetValue:=g_Jabber.Roster.JIDs[GetNParam(paParams,0)].Status;
      end;

      methSocketConnect: begin
        pvarRetValue:=0;
        try
          try
            g_IdClient.Connect;
          except

          end;
        finally
          if g_IdClient.Connected then pvarRetValue:=1;
        end;

      end;

      methSocketDisConnect: begin
        g_IdClient.Disconnect;
      end;

      methSocketSend: begin
        try
        	ss:=TStringStream.Create; //������������� ������ s
      		ss.WriteString(GetNParam(paParams,0));  //������ ��������� � ����� s
      		ss.Position:=0; //��������� ������� �� ������ ������ s
          g_IdClient.Socket.Write(ss,ss.Size,true);
          ss.clear;
          g_IdClient.Socket.ReadStream(ss);
          ss.position:=0;
          pvarRetValue:=ss.ReadString(ss.Size);
        finally
          ss.Free;
        end;
      end;
      methOpenFile:
            begin
              fname:=trim(GetNParam(paParams,0));//��� �����
	      xml.OpenDoc(fname);
            end;
       methCloseFile:
            begin
              xml.CloseDoc();
            end;

       methReadTag:
            begin
              TagName:=trim(GetNParam(paParams,0));//������ �����
              if xml.ReadTag(TagName)=1 then begin
                pvarRetValue:=xml.g_TagName;
              end else begin
                pvarRetValue:='';
              end;

            end;
       methReadValue:
            begin
              TagName:=trim(GetNParam(paParams,0));//��� ����
              pvarRetValue:=xml.ReadValue(TagName);
            end;

       methCreateFile:
            begin
              fname:=trim(GetNParam(paParams,0));//��� �����
	      xml.CreateDoc(fname);
            end;

       methAppendFile:
            begin
              fname:=trim(GetNParam(paParams,0));//��� �����
	      xml.AppendDoc(fname);
            end;

       methWriteTag:
            begin
              TagName:=trim(GetNParam(paParams,0));//��� ����
              xml.WriteTag(TagName);
            end;
       methWriteValue:
            begin
              TagName:=trim(GetNParam(paParams,0));//��� ����
              s:=trim(GetNParam(paParams,1));//��������
              xml.WriteValue(TagName, s);
            end;

       methAddParam:
            begin
              AttrName:=GetNParam(paParams,0);//��� ��������
              AttrValue:=GetNParam(paParams,1);//��. ��������
              xml.AddParam(AttrName, AttrValue);
            end;
       methGetParam:
            begin
              AttrName:=GetNParam(paParams,0);//��� ��������
              pvarRetValue:=xml.GetParam(AttrName);
            end;
       methWriteComment:
            begin
              s:=GetNParam(paParams,0);//����� �����������
              xml.WriteComment(s);
            end;

       methWriteFreeText:
            begin
              s:=GetNParam(paParams,0);//�����
              xml.WriteFreeText(s);
            end;
       methFindKKMServer:
            begin
              // ����� ������� ���
              g_IdServer:=TIdTCPServer.Create(nil);
              g_IdUDP:=TIdUDPClient.Create(nil);
              try
                // ����������� UDP broadcaster
                g_IdUDP.BroadcastEnabled:=True;
                g_IdUDP.Active:=true;

                g_IdServer.Bindings.Add;
                g_IdServer.Bindings.Items[0].Port:=5345;
                g_IdServer.Bindings.Items[0].IP:='0.0.0.0';
                g_IdServer.OnExecute:=g_IdServerExecute;
                g_IdServer.Active:=true;
                s:=GetNParam(paParams,0);//�����
                FKKMSrv:='-none-';
                FKKMSrvIp:=S;
                g_IdUDP.Broadcast('ISEEKKKMSRV',5345);
                x:=0;
                while FKKMSrv='-none-' do begin
                  sleep(20);
                  x:=x+1;
                  if X>60 then break;
                end;
                if S=FKKMSrv then
                  pvarRetValue:=FKKMSrvIp else pvarRetValue:='';


              finally
                g_IdServer.Free;
                g_IdUDP.Free;
              end;
            end;
       methOpenWindow:
        begin
          OpenWindow1C;
        end

      else begin
               CallAsFunc := S_FALSE;
               Exit;
               end;
          end; //case

      except

           on E:Exception do begin
             g_ErrorMsg:=E.Message;
             ShowErrorLog(g_ErrorMsg);
           end;

      end; //try
         CallAsFunc := S_OK;
end;
///////////////////////////////////////////////////////////////////////
function AddInObject.GetIDsOfNames(const IID: TGUID; Names: Pointer;
  NameCount, LocaleID: Integer; DispIDs: Pointer): HResult;
begin
  Result := E_NOTIMPL;
end;
///////////////////////////////////////////////////////////////////////
function AddInObject.GetTypeInfo(Index, LocaleID: Integer;
  out TypeInfo): HResult;
begin
  Result := E_NOTIMPL;
end;

///////////////////////////////////////////////////////////////////////
function AddInObject.GetTypeInfoCount(out Count: Integer): HResult;
begin
  Result := E_NOTIMPL;
end;

procedure AddInObject.g_IdServerExecute(AContext: TIdContext);
var Ip:String;
    s1: String;
    s:TStringStream;
begin
  //
  Ip:=AContext.Connection.Socket.Binding.PeerIP;
 	s:=TStringStream.Create; //������������� ������ s
  AContext.Connection.Socket.ReadStream(s);
  s.Position:=0;
  s1:=s.ReadString(s.Size);
  s.Free;
  if S1=FKKMSrvIp then begin
    FKKMSrv:=S1;
    FKKMSrvIp:=Ip;
  end;
end;

///////////////////////////////////////////////////////////////////////
function AddInObject.Invoke(DispID: Integer; const IID: TGUID; LocaleID: Integer;
  Flags: Word; var Params; VarResult, ExcepInfo, ArgErr: Pointer): HResult;
begin
  Result := E_NOTIMPL;
end;

///////////////////////////////////////////////////////////////////////
procedure AddInObject.ShowErrorLog(fMessage:WideString);
var
  ErrInfo: PExcepInfo;
begin
  If Trim(fMessage) = '' then Exit;
  New(ErrInfo);
  ErrInfo^.bstrSource := c_AddinName;
  ErrInfo^.bstrDescription := fMessage;
  ErrInfo^.wCode:=1006;
  ErrInfo^.sCode:=E_FAIL; //��������� ���������� � 1�
  iError.AddError(nil, ErrInfo);
end;

{
///////////////////////////////////////////////////////////////////////
//��������� ������
procedure TMyThread.Execute;
var str: String;
begin
  try
     repeat
       str:=MyObject.g_cp.ReadString;
       str:=trim(str);
       if str<>'' then begin
         //MessageBox(0, pchar('������ ���: '+str), '*debug',0);
         MyObject.iEvent.ExternalEvent(c_AddinName, 'BarCodeValue', str);
       end;

       EnterCriticalSection(g_kb_CriticalSection);

         try
           if g_sz_barcodes.Count>0 then begin
             MyObject.iEvent.ExternalEvent(c_AddinName, 'BarCodeValue', g_sz_barcodes.Strings[0]);
             g_sz_barcodes.Delete(0);
             g_kb_str:='';
           end;
         except
         end;

       LeaveCriticalSection(g_kb_CriticalSection);
       sleep(500);
     until terminated;
  except
     on E:Exception do begin
       MyObject.ShowErrorLog('������ ������ �� COM-�����: '+E.Message);
     end;
  end;

end;

///////////////////////////////////////////////////////////////////////
constructor TMyThread.Create(prm_Obj:AddInObject);
begin
    inherited Create(False);
    MyObject:=prm_Obj;
end;

}

///////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////
procedure Close1C();
//var cnt: Integer;
begin
{     GetIniFile();
     cnt:=g_Delay;
     if cnt=0 then exit;
     repeat
       if g_Message<>'' then begin
         ShowBalloon(g_Message, '�������� '+IntToStr(cnt)+' ������',750);
       end else begin
         Sleep(750);
       end;
       Sleep(250);
     Dec(cnt);
     until cnt=0;
}
     Windows.TerminateProcess(Windows.GetCurrentProcess(),1);
end;

{ TCloseTimer }



procedure TCloseTimer.SetTime(ATime: String);
begin
  if ATime[2]=':' then ATime:='0'+ATime;
  ATime:=Copy(ATime,1,5);
  FTime:=ATime;
end;

initialization
  ComServer.SetServerName('AddIn');
  TComObjectFactory.Create(ComServer,AddInObject,CLSID_AddInObject,
    c_AddinName,'V7 AddIn 2.0',ciSingleInstance);

//  InitializeCriticalSection(g_kb_CriticalSection);

finalization

//  DeleteCriticalSection(g_kb_CriticalSection);


end.
