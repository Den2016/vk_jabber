unit AddInObj;

interface

uses  { Какие библиотеки используем }
{$IFDEF DEBUGDC}
  dbugintf, Dialogs,
{$ENDIF}
  ComServ, ComObj, ActiveX, SysUtils, Windows, AddInLib, Classes, Jabber, GmXml, ExtCtrls,
  IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, u_OpenXML, IdCustomTCPServer, IdTCPServer, IdUDPBase, IdUDPClient,
  IdContext, Forms, Winapi.Messages, gForm;

     const c_AddinName = 'vk_jabber'; //Имя внешней компоненты

     //Количество свойств
     const c_PropCount = 22;

     //Идентификаторы свойств
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

     //Имена свойств, видимые из 1С
     //Порядок соблюдайте точно такой же, что и в TProperties
    const c_PropNames: Array[0..c_PropCount-1, 0..1] of WideString =
    (
      ('ErrorMsg','Ошибка'),
      ('JID','Аккаунт'),
      ('Password','Пароль'),
      ('Port','Порт'),
      ('Server','Сервер'),
      ('Online','ВСети'),
      ('Contact','Контакт'),
      ('ContactShow','Видимость'),
      ('KeepAlivePeriod','ПериодичностьПроверкиВСети'),
      ('ContactStatus','Статус'),
      ('LastXML','ПоследнийXML'),
      ('Logging','ВестиЛог'),
      ('LogFileName','ИмяФайлаЛога'),
      ('GUID','ГлобальныйИД'),
      ('SocketHost','СокетХост'),
      ('SocketPort','СокетПорт'),
      ('SocketConnected','СокетПодключен'),
      ('XMLTagName','XMLИмяТега'),
      ('XMLCharacters','XMLСимволы'),
      ('XMLDefaultEncoding', 'XMLКодировкаПоУмолчанию'),
      ('XMLPassword', 'XMLПароль'),
      ('TimeOff', 'ВремяВыключения')

    );

    //Количество методов
     const c_MethCount = 28;
    //Идентификаторы методов.
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

    //Имена методов, видимые из 1С
     //Порядок соблюдайте точно такой же, что и в TMethods
    const c_MethNames: Array[0..c_MethCount-1,0..2] of WideString =
    (
    ('Connect','Подключить','0'),
    ('Disconnect','Отключить','0'),
    ('GetRoster','ПолучитьСписокКонтактов','0'),
    ('SelectContacts','ВыбратьКонтакты','0'),
    ('GetContact','ПолучитьКонтакт','0'),
    ('GetContactShow','ВидимостьКонтакта','1'),
    ('GetContactStatus','СтатусКонтакта','1'),
    ('SendMessage','Отправить','2'),             //два параметра - кому и сообщение
    ('Subscribe','ЗапросПодписки','1'),             //один параметр - кому
    ('SubscribeOK','ОдобритьПодписку','1'),             //один параметр - кому
    ('UnSubscribe','Отписаться','1'),             //один параметр - кому
    ('SocketConnect','СокетПодключить','0'),
    ('SocketDisconnect','СокетОтключить','0'),
    ('SocketSend','СокетОтправить','1'),

    ('OpenFile','ОткрытьФайл','1'),
    ('CloseFile','ЗакрытьФайл', '0'),

    ('ReadTag','ПрочитатьТег', '1'),
    ('ReadValue','ПрочитатьЗначение', '1'),

    ('CreateFile','СоздатьФайл', '1'),
    ('AppendFile','ДополнитьФайл', '1'),
    ('WriteTag','ЗаписатьТег', '1'),
    ('WriteValue','ЗаписатьЗначение', '2'),

    ('AddParam','ДобавитьАтрибут', '2'),
    ('GetParam','ПолучитьАтрибут', '1'),

    ('WriteComment','ЗаписатьКомментарий', '1'),
    ('WriteFreeText','ЗаписатьПроизвольныйТекст', '1'),
    ('FindKKMServer','НайтиСерверККМ','1'),

    ('OpenWindow','СоздатьОкно','0')
    );

const
{Нажмите Ctrl-Shift-G чтобы сгенерировать новый уникальный идентификатор GUID}
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
// Твои действия с Handle... Все handles дочерних окон передаются сюда.

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
  iEvent.SetEventBufferDepth(300); //глубина буфера событий


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
//Здесь 1С читает значения свойств
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
//Здесь 1С устанавливает значения свойств
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
{Здесь 1С узнает, можно ли читать свойства}
begin
//здесь все свойства читабельны
  pboolPropRead := 1;

//     case TProperties(lPropNum) of
//          propErrorMsg: pboolPropRead := 1;{1=можно читать свойство, 0=нет}
//     else
//            IsPropReadable := S_FALSE;
//            Exit;
//     end;
  IsPropReadable := S_OK;

end;
///////////////////////////////////////////////////////////////////////
function AddInObject.IsPropWritable(lPropNum: Integer; var pboolPropWrite: Integer): HResult; stdcall;
//Здесь 1С узнает, можно ли изменять свойство
begin
     case TProperties(lPropNum) of
          propErrorMsg: pboolPropWrite := 0;{1=можно записывать свойство, 0=нет}
          propJID:pboolPropWrite := 1;{1=можно записывать свойство, 0=нет}
          propPassword:pboolPropWrite := 1;{1=можно записывать свойство, 0=нет}
          propPort:pboolPropWrite := 1;{1=можно записывать свойство, 0=нет}
          propServer:pboolPropWrite := 1;{1=можно записывать свойство, 0=нет}
          propOnline:pboolPropWrite := 0;{1=можно записывать свойство, 0=нет}
          propContact:pboolPropWrite := 0;{1=можно записывать свойство, 0=нет}
          propContactShow:pboolPropWrite := 0;{1=можно записывать свойство, 0=нет}
          propKeepAlivePeriod:pboolPropWrite := 1;{1=можно записывать свойство, 0=нет}
          propContactStatus:pboolPropWrite := 0;{1=можно записывать свойство, 0=нет}
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
      // время закрывать 1с
      Close1C;

    end;
  finally

  end;

  {$IFDEF DEBUGDC}
  {
  wnd := GetWindow(Application.Handle, gw_hwndfirst);
  while wnd <> 0 do begin // Не показываем:
    if (wnd <> Application.Handle) // Собственное окно
    and IsWindowVisible(wnd) // Невидимые окна
    //and (GetWindow(wnd, gw_owner) = 0) // Дочерние окна
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
//Здесь 1С узнает количество параметров у методов
begin

     plParams := StrToInt(c_MethNames[lMethodNum, 2]);
(*     plParams := 0;

     case TMethods(lMethodNum) of

          methGetContactShow: plParams := 1;{1 параметр}
          methGetContactStatus: plParams := 1;{1 параметр}
          methSendMessage: plParams := 2;{кому и сообщение}
          methSubscribe: plParams := 1;{кому}
          methSubscribeOK: plParams := 1;{кому}
          methUnSubscribe: plParams := 1;{кому}
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
//Здесь 1С узнает, какие методы работают как функции
begin
  pboolRetValue := 1; //Все методы возвращают значение
  HasRetVal := S_OK;
end;



///////////////////////////////////////////////////////////////////////
function AddInObject.CallAsProc(lMethodNum: Integer; var paParams: PSafeArray{(OleVariant)}): HResult; stdcall;
//Здесь 1С выполняет код процедур
begin
    CallAsProc := S_FALSE;
end;

procedure AddInObject.Close1C;
var V:OleVariant;
    X:Integer;
begin
  {даем команду 1С на закрытие, при этом учитываем наличие
  1. Запросов типа "Сохранить? Да-Нет"
  2. Модальных окон выбора из справочника, документа и прочего
  Закрытие делаем командой 1С "ЗавершитьРаботуСистемы(0)", то есть без подтверждения сохранения, ибо нефиг.
  Перед этим производим проверку наличия модальных окон и окон запросов

  }
  {$IFDEF DEBUGDC}
    SendDebugEx('closetimer call TerminateProcess ',mtInformation);
  {$ENDIF}
  procId:=GetCurrentProcessId; //получаем ID процесса

  SetLength(WndList,0);// обнуляем список окон
  EnumChildWindows(GetDesktopWindow, @EnumProc,0); // строим список открытых окон 1С
  // начинаем анализ
  if Length(WndList)<>0 then begin
    if WndList[0].cls='#32770' then begin // модальное окно. Либо это запрос, либо выбор из справочника, либо какой-то скрытый Dialog
      if WndList[0].title='1С:Предприятие' then begin  //запрос типа "Сохранить данные?" или Вопрос("Удалить?","Да+Нет")
        X:=1; //начинаем поиск в списке окон кнопки с титлом &Нет
        while X<Length(WndList) do begin
          if WndList[x].cls='Button' then begin
            if WndList[x].title='&Нет' then begin
              PostMessage(WndList[x].Wnd,WM_LBUTTONDOWN,0,0); // имитируем клик на кнопке
              PostMessage(WndList[x].Wnd,WM_LBUTTONUP,0,0); // имитируем клик на кнопке
              break;
            end;
          end;
          if WndList[x].cls='#32770' then break;
          Inc(X);
        end;
      end else if WndList[0].title<>'Dialog' then begin // выбор из справочника, если не Dialog
        PostMessage(WndList[0].Wnd,WM_CLOSE,0,0); // просто тупо шлем сигнал WM_CLOSE;
      end;
    end;
  end;

  V:=_App.AppDispatch;
  IDispatch(V)._AddRef;
  V.ExecuteBatch('ЗавершитьРаботуСистемы(0)');

end;

///////////////////////////////////////////////////////////////////////
function AddInObject.CallAsFunc(lMethodNum: Integer; var pvarRetValue: OleVariant; var paParams: PSafeArray): HResult; stdcall;
{Здесь 1С выполняет код функций}
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
        _to:=GetNParam(paParams,0);//получатель
        _msg:=GetNParam(paParams,1);//Сообщение
        g_Jabber.SendMessage(_to,'chat',_msg);
      end;

      methSubscribe: begin
        _to:=GetNParam(paParams,0);//получатель
        g_Jabber.Subscribe(_to);
      end;
      methSubscribeOK: begin
        _to:=GetNParam(paParams,0);//получатель
        g_Jabber.SubscribeOK(_to);
      end;
      methUnSubscribe: begin
        _to:=GetNParam(paParams,0);//получатель
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
        	ss:=TStringStream.Create; //Инициализация потока s
      		ss.WriteString(GetNParam(paParams,0));  //Запись сообщения в поток s
      		ss.Position:=0; //Установка позиция на начало потока s
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
              fname:=trim(GetNParam(paParams,0));//Имя файла
	      xml.OpenDoc(fname);
            end;
       methCloseFile:
            begin
              xml.CloseDoc();
            end;

       methReadTag:
            begin
              TagName:=trim(GetNParam(paParams,0));//Список тегов
              if xml.ReadTag(TagName)=1 then begin
                pvarRetValue:=xml.g_TagName;
              end else begin
                pvarRetValue:='';
              end;

            end;
       methReadValue:
            begin
              TagName:=trim(GetNParam(paParams,0));//Имя тега
              pvarRetValue:=xml.ReadValue(TagName);
            end;

       methCreateFile:
            begin
              fname:=trim(GetNParam(paParams,0));//Имя файла
	      xml.CreateDoc(fname);
            end;

       methAppendFile:
            begin
              fname:=trim(GetNParam(paParams,0));//Имя файла
	      xml.AppendDoc(fname);
            end;

       methWriteTag:
            begin
              TagName:=trim(GetNParam(paParams,0));//Имя тега
              xml.WriteTag(TagName);
            end;
       methWriteValue:
            begin
              TagName:=trim(GetNParam(paParams,0));//Имя тега
              s:=trim(GetNParam(paParams,1));//Значение
              xml.WriteValue(TagName, s);
            end;

       methAddParam:
            begin
              AttrName:=GetNParam(paParams,0);//Имя атрибута
              AttrValue:=GetNParam(paParams,1);//Зн. атрибута
              xml.AddParam(AttrName, AttrValue);
            end;
       methGetParam:
            begin
              AttrName:=GetNParam(paParams,0);//Имя атрибута
              pvarRetValue:=xml.GetParam(AttrName);
            end;
       methWriteComment:
            begin
              s:=GetNParam(paParams,0);//Текст комментария
              xml.WriteComment(s);
            end;

       methWriteFreeText:
            begin
              s:=GetNParam(paParams,0);//Текст
              xml.WriteFreeText(s);
            end;
       methFindKKMServer:
            begin
              // поиск сервера ККМ
              g_IdServer:=TIdTCPServer.Create(nil);
              g_IdUDP:=TIdUDPClient.Create(nil);
              try
                // настраиваем UDP broadcaster
                g_IdUDP.BroadcastEnabled:=True;
                g_IdUDP.Active:=true;

                g_IdServer.Bindings.Add;
                g_IdServer.Bindings.Items[0].Port:=5345;
                g_IdServer.Bindings.Items[0].IP:='0.0.0.0';
                g_IdServer.OnExecute:=g_IdServerExecute;
                g_IdServer.Active:=true;
                s:=GetNParam(paParams,0);//Текст
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
 	s:=TStringStream.Create; //Инициализация потока s
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
  ErrInfo^.sCode:=E_FAIL; //генерация исключения в 1С
  iError.AddError(nil, ErrInfo);
end;

{
///////////////////////////////////////////////////////////////////////
//Процедура потока
procedure TMyThread.Execute;
var str: String;
begin
  try
     repeat
       str:=MyObject.g_cp.ReadString;
       str:=trim(str);
       if str<>'' then begin
         //MessageBox(0, pchar('Считан код: '+str), '*debug',0);
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
       MyObject.ShowErrorLog('Ошибка чтения из COM-порта: '+E.Message);
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
         ShowBalloon(g_Message, 'Осталось '+IntToStr(cnt)+' секунд',750);
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
