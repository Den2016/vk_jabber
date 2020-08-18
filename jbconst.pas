unit jbconst;

interface

uses
  Controls, Messages, SysUtils, Classes;
const

  WM_JBDISCONNECT = WM_USER + 100;            // Произошло отключение от сервера
  WM_JBCLOSEMESSAGEWINDOW = WM_USER + 101;    // Вызов закрытия окна
  WM_JBMESSAGE = WM_USER + 102;               // Имется сообщение (вызывается с переодичностью мерцания)
  WM_JBUSERCHANGESTATUS = WM_USER + 103;      // Пользователь сменил статус



  XMLNS_AUTH       = 'jabber:iq:auth';
  XMLNS_ROSTER     = 'jabber:iq:roster';
  XMLNS_REGISTER   = 'jabber:iq:register';
  XMLNS_LAST       = 'jabber:iq:last';
  XMLNS_TIME       = 'jabber:iq:time';
  XMLNS_VERSION    = 'jabber:iq:version';
  XMLNS_IQOOB      = 'jabber:iq:oob';
  XMLNS_BROWSE     = 'jabber:iq:browse';
  XMLNS_AGENTS     = 'jabber:iq:agents';
  XMLNS_SEARCH     = 'jabber:iq:search';
  XMLNS_PRIVATE    = 'jabber:iq:private';
  XMLNS_CONFERENCE = 'jabber:iq:conference';

  XMLNS_BM         = 'storage:bookmarks';
  XMLNS_PREFS      = 'storage:imprefs';

  XMLNS_XEVENT     = 'jabber:x:event';
  XMLNS_DELAY      = 'jabber:x:delay';
  XMLNS_XROSTER    = 'jabber:x:roster';
  XMLNS_XCONFERENCE= 'jabber:x:conference';
  XMLNS_XDATA      = 'jabber:x:data';
  XMLNS_XOOB       = 'jabber:x:oob';

  XMLNS_MUC        = 'http://jabber.org/protocol/muc';
  XMLNS_MUCOWNER   = 'http://jabber.org/protocol/muc#owner';
  XMLNS_MUCADMIN   = 'http://jabber.org/protocol/muc#admin';
  XMLNS_MUCUSER    = 'http://jabber.org/protocol/muc#user';

  XMLNS_DISCO      = 'http://jabber.org/protocol/disco';
  XMLNS_DISCOITEMS = 'http://jabber.org/protocol/disco#items';
  XMLNS_DISCOINFO  = 'http://jabber.org/protocol/disco#info';

  XMLNS_SI         = 'http://jabber.org/protocol/si';
  XMLNS_FTPROFILE  = 'http://jabber.org/protocol/si/profile/file-transfer';
  XMLNS_BYTESTREAMS= 'http://jabber.org/protocol/bytestreams';
  XMLNS_FEATNEG    = 'http://jabber.org/protocol/feature-neg';

  XMLNS_CLIENTCAPS = 'http://jabber.org/protocol/caps';

  XMLNS_STREAMERR  = 'urn:ietf:params:xml:ns:xmpp-stanzas';
  XMLNS_XMPP_SASL  = 'urn:ietf:params:xml:ns:xmpp-sasl';
  XMLNS_XMPP_BIND  = 'urn:ietf:params:xml:ns:xmpp-bind';
  XMLNS_XMPP_SESSION  = 'urn:ietf:params:xml:ns:xmpp-session';
  XMLNS_COMMANDS   = 'http://jabber.org/protocol/commands';
  XMLNS_CAPS       = 'http://jabber.org/protocol/caps';
  XMLNS_ADDRESS    = 'http://jabber.org/protocol/address';

  XMLNS_XHTMLIM    = 'http://jabber.org/protocol/xhtml-im';
  XMLNS_XHTML      = 'http://www.w3.org/1999/xhtml';
  XMLNS_SHIM       = 'http://jabber.org/protocol/shim';






  // константы видов IM
  JC_STANDART = $00000000;
  JC_JABBER   = $00000000;
  JC_ICQ      = $00000001;
  JC_AIM      = $00000002;

  // Константы стандартных жаберных групп
  JG_ONLINE  = 001;
  JG_OFFLINE = 002;
  JG_NOTLIST = 003;

  // Константы состояния пользователей
  S_OFFLINE     = $00;    //The user is offline. / Set status to offline
  S_ONLINE      = $01;    //Online
  S_AWAY        = $02;    //Away
  S_NA          = $03;    //N/A
  S_OCCUPIED    = $04;    //Occupied
  S_DND         = $05;    //Do Not Disturb
  S_FFC         = $06;    //Free For Chat
  S_EVIL        = $07;    //Злой
  S_DEPRESSION  = $08;    //депрессия
  S_ATHOME      = $09;    //Дома
  S_ATWORK      = $0A;    //На работе
  S_LAUNCH      = $0B;    //кушаем
  S_INVISIBLE   = $0C;    //Invisible
  S_NOTINLIST   = $0D;    //Not in List

  S_MESAGEICON  = $08;    // Иконка конверта
  S_NOICON      = $FF;    //нет иконки
  // уведомление что есть сообщение
  S_MESSAGE     = $00000020;    //Message

  //Запрос на подписку
  S_SUBSCRIBE   = $00000021;    //Запрос на подписку

  // Типы подписок
  // отвечают за получение текущего статуса
  // если пользователь не имеет подписки то он не сможет знать текущее состояние контакта
  S_SUBSCRIBE_NONE = $00000030; // не подписаный клиент
  S_SUBSCRIBE_TO   = $00000031; // пользователь имеет подписку контакт нет
  S_SUBSCRIBE_FROM = $00000032; // контакт имеет подписку пользователь нет
  S_SUBSCRIBE_BOTH = $00000033; // пользователь и контакт имеют подписку

  // строковые ошибки
  MSG_BigDataForSend        = 'Big String for send';
  MSG_StreamError           = 'Error Connect';
  MSG_Failure               = 'Protokol Error';

type

{// "+" Сохраняемые; "-" не сохранямые; "*" должны восстановиться
  PRosterInfo = ^TRosterInfo;
  TRosterInfo = record
    RosterName: String;        // + Имя в ростере
    FullName: String;          // + Полное имя
    NickName: String;          // + ник
    BirthDay: TDate;           // + ДР
    Phone: String;             // +
    HomePage: String;          // +
    EMail: String;             // +
    FullJID: String;           // + Полный JID c ресурсом
    JID: String;               // + JID
    Resource: String;          // + Ресурс клиента
    GroupName: String;         // + имя группы
    Status: Byte;              // - Статус пользователя (онлайн, офлайн, NA, Away etc)
    Position: Byte;            // - В списке не в списке
    StatusText: String;        // - текст статуса пользователя (Отошел, Недоступен etc)
    ContactClient: String;     // - клиент используемый контаком
    IMType: byte;              // - тип IM (ICQ, Jabber, AIM etc)
    AddImage: Byte;            // - Значек дополнительного статуса
    Subscribe: TSubscribeType; // - Тип подписки
    Node: Boolean;             // - False - это юзер; True - это группа
    MsgBody: String;           // * Последние пришедшие сообщения
    Priority: byte;            // - приоритет
    FlashIcon: byte;           // - необходимо для прорисовки мерцания
  end;
}
  // Тип подписки
  TSubscribeType = (sbNone, sbTo, sbFrom, sbBoth);

  // тип сообщения
  TMessageType = (mtChat, mtError, mtGroupchat, mtHeadline, mtNormal);

  // Тип присутствия
  TShowType = (ptNormal, ptAway, ptChat, ptDnd, ptXa);
  // описание типа контакта
  TContactType = (ctUser,           // 1. пользователь
                  ctChatRoom,       // 2. комната
                  ctTransport,      // 3. транспорт
                  ctNode);          // 4. узел/группа


  // структура с информацией о клиенте в ростере.
  TPresenceInfo = record
    Resource: WideString;
    Show: TShowType;
    Status: WideString;
    Priority: Shortint;
  end;
  PPresenceInfo = ^TPresenceInfo;

  TPresenceList = class(TList)
    function  Add(AItem: TPresenceInfo): Integer;
    procedure Delete(Index: Integer);
    procedure Modify(Index: Integer; AItem: TPresenceInfo);
    procedure Free;
  end;
  PPresenceList = ^TPresenceList;

  // структура записи в ростере
  PContactInfo = ^TContactInfo;
  TContactInfo = record
    ContactType:      TContactType;       // Тип контакта
    FullJID:          WideString;         // JID контакта
    Subscribe:        TSubscribeType;     // Тип подписки, влияет на иконку
    DisplayName:      WideString;         // Отображаемое имя
    Group:            Boolean;            // является ли узел группой
    IsMessage:        Boolean;            // Новое сообщение
    Flash:            Boolean;            // моргаем
    MessageCount:     Integer;            // для групчата
    PresenceList:     TPresenceList;      // список статусов для контакта если запущено несколько клиентов 
  end;


// ------------------------------------------------------------------------------- //
// Полученно событие Presence. При получении этого события мы
// создаем объект в котором весь XML поток будет разобран
// ------------------------------------------------------------------------------- //
// TJ - стандартный заголовок
// El - элемент
// At - атрибут
// например TJPresenceElShow, TJPresenceAtType;

  TJPresenceElShow = record
    Value: String;
  end;
  TJPresenceElStatus = record
    Value: String;
  end;

  



implementation


{ TJPresenceEvent }




{ TPresenceList }
function TPresenceList.Add(AItem: TPresenceInfo): Integer;
var
  Item: PPresenceInfo;
begin
  New(Item);
  Item^ := AItem;
  Result := inherited Add(Item);
end;

procedure TPresenceList.Delete(Index: Integer);
var
  Item: PPresenceInfo;
begin
  Item := Items[Index];
  inherited Delete(Index);
  Dispose(Item);
end;

procedure TPresenceList.Free;
var
  i: Integer;
  Item: PPresenceInfo;
begin
  for i := 0 to Count - 1 do begin
    Item := Items[i];
    Dispose(Item);
  end;
  inherited Free;
end;

procedure TPresenceList.Modify(Index: Integer; AItem: TPresenceInfo);
var
  Item: PPresenceInfo;
begin
  try
    Item := Items[Index];
    Item^ := AItem;
  except
    on E: Exception do begin
      E.Message := 'Не удалось изменить параметры: ' + E.Message;
    end;
  end;
end;

end.
