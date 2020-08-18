Unit u_OpenXML;

Interface
Uses SysUtils, Windows, uRC6;

Const c_BufSize=65536; //размер буфера при чтении файла (в байтах)
Const c_MaxAttrCount=100; //максимальное число атрибутов тега
Const c_MaxStackSize=100; //максимальная вложенность тегов


    Type T_OpenXML = Class(TObject)

    //Класс для чтения и записи XML.


    Public
      g_TagName: String; //Имя считанного тега
      g_Characters: String; //Символы за тегом

      //Поля для работы с параметрами (атрибутами) тега
      g_AttrNames: Array[1..c_MaxAttrCount] of String;
      g_AttrValues: Array[1..c_MaxAttrCount] of String;
      g_AttrCount: Integer; //число параметров
      g_DefaultEncoding: String; //Кодировка по умолчанию (если не указана в документе)
      g_PasswordRC6: String; //Пароль для шифрования RC6
      g_RC6: Boolean; //Признак шифрования RC6


      Constructor Create;
      Destructor Destroy; Override;

      Procedure OpenDoc(fname: String); //Открывает документ по имени файла
      Procedure CloseDoc; //Закрывает документ
      Procedure CreateDoc(fname: String); //Создает новый документ с указанным именем файла
      Procedure AppendDoc(fname: String); //Открывает документ с указанным именем файла на дополнение

      Function ReadTag(p_names: String): Integer;
       //Читает групповой тег (внутри которого могут содержаться другие теги).
       //Принимает список ожидаемых тегов через запятую.
       //Возвращает 1 если тег прочитан.

      Function ReadValue(p_name: String):String;
       //Читает тег с данными вида <Тег> Это данные </Тег>
       //Возвращает значение внутри тега. Генерирует исключение,
       //если встретилось неожиданное имя тега.

      procedure WriteTag(p_name: String);
       //Пишет групповой тег (внутри которого могут содержаться другие теги).

      Procedure WriteValue(p_name: String; p_value: String);
       //Пишет тег с данными вида <Тег> Это данные </Тег>

      Procedure AddParam(p_name, p_value: String);
       //Добавляет параметр к списку параметров тега. Если после этого
       //вызвать WriteTag, то параметры будут записаны вместе с тегом.

      Function GetParam(p_name: String): String;
       //Читает параметр тега, ранее прочитанного при помощи ReadTag или
       //ReadValue. Если параметр не существует, то возвращает пустую строку.

      Procedure WriteComment(s: String);
      //Пишет комментарий

      Procedure WriteFreeText(s: String);
      //Пишет произвольный текст

    private

      g_BufTagName: String; //закрывающее имя тега для расшифровки <tag/>
      g_f1: TextFile; //Файл для записи
      g_f: File of ansichar; //Файл для чтения
      g_BufChar: ansichar; //символ для ungetch

      //Стек для проверки вложенности тегов
      g_TagStack: Array[1..100] of String;
      g_TagPoint: Integer; //указатель в стеке


      g_Spaces: String; //Отступ (поле) от начала строки при записи
      g_DocMode: ansichar; //R=Чтение или W=Запись
      g_LineNumber: Integer; //Номер строки (для выдачи ошибки)

      //Буфер для чтения файла
      g_buf: Array[1..c_BufSize] of ansichar;
      g_buf_p: Integer;//Указатель в буфере
      g_buf_max: Integer;//Ограничение на число байт, которые можно считать

      g_utf8: Integer; //Признак кодировки UTF-8

      g_append: Integer; //Признак дополнения файла

      g_frc6: T_RC6; //Объект для шифрования RC6


      procedure DecodeUTF8(); //Перекодировка из UTF-8

      procedure Error(s:String);
      procedure WriteString(s:String);
      procedure Push1();
      procedure Pop1();
      function Encode1(s: String):String;
      function Encode2(s: String):String;
      function getch():ansichar;
      Procedure ungetch(c:ansichar);
      procedure ReadTag1();
      procedure ReadHeader();
      function ReadAmp(): ansichar;


    end;

implementation


//////////////////////////////////////////////////////////////
//Конструктор класса
Constructor T_OpenXML.Create;
begin
     inherited Create;
     g_DocMode:=' ';
     g_TagPoint:=0;
     g_Spaces:='';
     g_LineNumber:=0;
     g_AttrCount:=0;
     g_BufTagName:='';
     g_BufChar:=#0;
     g_DefaultEncoding:='';
     g_RC6:=False;
     g_PasswordRC6:='';

end;

//////////////////////////////////////////////////////////////
destructor T_OpenXML.Destroy;
//Деструктор класса
begin
     CloseDoc();
     inherited Destroy;
end;

////////////////////////////////////////////
procedure T_OpenXML.Error(s:String);
//Генерирует исключение при ошибке.
begin
  if g_LineNumber>0 then
   s:='Строка '+IntToStr(g_LineNumber)+': '+s;
  raise Exception.Create(s);
end;



////////////////////////////////////////////
procedure T_OpenXML.AddParam(p_name, p_value: String);
//Добавляет параметр (атрибут) к описанию тега перед его записью.
begin
   inc(g_AttrCount);
   if g_AttrCount > c_MaxAttrCount then Error('Превышено максимальное число атрибутов тега.');
   g_AttrNames[g_AttrCount]:=p_name;
   g_AttrValues[g_AttrCount]:=p_value;
end;



////////////////////////////////////////////
Function T_OpenXML.GetParam(p_name: String): String;
//Получает значение параметра по его имени
var i: Integer;
begin
   for i:=1 to g_AttrCount do begin
     if g_AttrNames[i]=p_name then begin
       Result:=g_AttrValues[i];
       Exit;
     end;
   end;
   Result:='';
end;


////////////////////////////////////////////
procedure T_OpenXML.WriteString(s: String);
//Записывает строку в выходной файл.
//Добавляет отступ от начала строки
//(в зависимости от вложенности тега) и конец строки.
begin
  try
    if g_rc6 then begin
      g_frc6.Writeln(g_Spaces+s);
    end else begin
      Writeln(g_f1, g_Spaces+s);
    end;  
    inc(g_LineNumber);
  except
    on E:Exception do
    Error('Ошибка записи в файл: '+E.Message);
  end;
end;


////////////////////////////////////////////
procedure  T_OpenXML.Push1;
//Записывает имя тега в стек для его проверки на вложенность
var s: String;
begin
  if g_append=1 then exit;
  s:=Copy(g_TagName,2,Length(g_TagName)-2);
  inc(g_TagPoint);
  if g_TagPoint>100 then begin
    Error('Превышена максимальная вложенность тегов - 100 уровней');
  end;
  g_TagStack[g_TagPoint]:=s;
  g_Spaces:=g_Spaces+'  ';
end;

////////////////////////////////////////////
procedure  T_OpenXML.Pop1;
//Извлекает имя тега из стека и выдает ошибку, если ошибка вложенности тегов
var s, s1: String;
begin
  if g_append=1 then exit;
  if g_TagPoint<1 then Error('Ошибка вложенности тегов: попытка закрыть неоткрытый тег.');
  s:=Copy(g_TagName,3,Length(g_TagName)-3);
  s1:=g_TagStack[g_TagPoint];
  dec(g_TagPoint);
  if s1<>s then begin
    Error('Ожидается закрывающий тег </'+s1+'>, а получен тег: '+g_TagName);
  end;
  Delete(g_Spaces,1,2);
end;

////////////////////////////////////////////
procedure T_OpenXML.CreateDoc(fname: String);
//Создает файл XML
begin
   CloseDoc();
   g_LineNumber:=1;
   try
     if g_RC6=False then begin
       AssignFile(g_f1, fname);
       Rewrite(g_f1);
       Writeln(g_f1,'<?xml version="1.0" encoding="windows-1251"?>');
     end else begin
       g_frc6:=T_RC6.Create;
       g_frc6.CreateFile(fname, g_PasswordRC6);
       g_frc6.Writeln('<?xml version="1.0" encoding="windows-1251"?>');
     end;
     g_append:=0;
   except
     Error('Ошибка создания файла: '+fname);
   end;
   g_TagPoint:=0;
   g_DocMode:='W';
   g_Spaces:='';
end;

////////////////////////////////////////////
procedure T_OpenXML.AppendDoc(fname: String);
//Создает файл XML
begin
   CloseDoc();
   g_LineNumber:=1;
   try
     if g_RC6 then Raise Exception.Create('Режим дополнения не поддерживается при включенном шифровании');

     AssignFile(g_f1, fname);
     Append(g_f1);
     g_append:=1;
   except
     Error('Ошибка открытия файла на дополнение: '+fname);
   end;
   g_DocMode:='W';
end;


////////////////////////////////////////////
function T_OpenXML.Encode1(s: String):String;
//Кодирует строку, заменяя в ней символы < > &
var i: Integer;
var c: Char;
begin
  Result:='';
  for i:=1 to length(s) do begin
    c:=s[i];
    case c of
      '<': Result:=Result+'&lt;';
      '>': Result:=Result+'&gt;';
      '&': Result:=Result+'&amp;';
    else
           Result:=Result+c;
    end;
  end;
end;
////////////////////////////////////////////
function T_OpenXML.Encode2(s: String):String;
//Кодирует строку, заменяя в ней символы < > & " '
var i: Integer;
var c: Char;
begin
  Result:='';
  for i:=1 to length(s) do begin
    c:=s[i];
    case c of
      '<': Result:=Result+'&lt;';
      '>': Result:=Result+'&gt;';
      '&': Result:=Result+'&amp;';
      '"': Result:=Result+'&quot;';
      '''': Result:=Result+'&apos;';
    else
           Result:=Result+c;
    end;
  end;
end;

////////////////////////////////////////////
procedure T_OpenXML.WriteTag(p_name: String);
//Пишет тег в выходной файл
var i: Integer;
var s: String;
var flag_close: Boolean;

begin
  if g_DocMode<>'W' then begin
    Error('Выполнять запись тега можно только при открытом на запись файле. ');
  end;

  if p_name='' then Error('Укажите имя тега.');
  s:=trim(p_name);

  if s[1]<>'<' then begin
    Error('Имя тега должно начинаться символом "<".');
  end;

  if s[Length(s)]<>'>' then begin
    Error('Имя тега должно заканчиваться символом ">".');
  end;

  if Pos(' ',s)>0 then begin
    Error('Имя тега не должно содержать пробелы.');
  end;

  if length(s)=2 then Error('Попытка записать тег вида <> ');

  g_TagName:=s;

  if s[2]='/' then begin //если закрывающий тег
    if length(s)=3 then Error('Попытка записать тег вида </> ');

    WriteString(s);      //записываем тег
    Pop1;                //проверяем тег на вложенность

  end else begin
      if s[Length(s)-1]='/' then begin //тег вида <tag/>
        Delete(s, Length(s)-1, 1);
        flag_close:=True;
        g_Spaces:='  '+g_Spaces;
      end else begin
        g_TagName:=s;
        Push1;
        flag_close:=False;
      end;

    if g_AttrCount>0 then begin
      Delete(s, Length(s), 1); //удаляем замыкающий символ >

      for i:=1 to g_AttrCount do begin //добавляем параметры
        s:=s+' '+g_AttrNames[i]+'="'+Encode2(g_AttrValues[i])+'"';
      end; //for

      s:=s+'>';
    end;//if

    if flag_close then begin
      Insert('/', s, Length(s));
    end;

    WriteString(s);

    if flag_close then begin
        Delete(g_Spaces,1,2);
    end;

    g_AttrCount:=0;
  end;
end;


////////////////////////////////////////////
Procedure T_OpenXML.WriteValue(p_name: String; p_value: String);
//Пишет тег вида <ИмяТега>Значение</ИмяТега>

var s, s1: String;
var i: Integer;
begin
  s:=p_name;

  if g_DocMode<>'W' then begin
    Error('Выполнять запись тега можно только при открытом на запись файле. ');
  end;

  if s[1]<>'<' then begin
    Error('Имя тега должно начинаться символом "<".');
  end;

  if s[Length(s)]<>'>' then begin
    Error('Имя тега должно заканчиваться символом ">".');
  end;

  if Pos(' ',s)>0 then begin
    Error('Имя тега не должно содержать пробелы.');
  end;

  if Pos('/',s)>0 then begin
    Error('Имя тега не должно содержать символы /.');
  end;

  if length(s)=2 then Error('Попытка записать тег вида <> ');

  s1:=s;

  if g_AttrCount>0 then begin
    Delete(s, Length(s), 1); //удаляем замыкающий символ >

    for i:=1 to g_AttrCount do begin //добавляем параметры
      s:=s+' '+g_AttrNames[i]+'="'+Encode2(g_AttrValues[i])+'"';
    end; //for
    g_AttrCount:=0;
    s:=s+'>';
  end;//if


  g_Spaces:=g_Spaces+'  ';

  if p_value='' then begin //В случае пустых данных пишем как <tag/>
     Insert('/', s1, Length(s1));
     WriteString(s1);
  end else begin
     Insert('/',s1,2); //формируем имя закрывающего тега
     WriteString(s+Encode1(p_value)+s1);
  end;

  Delete(g_Spaces, 1, 2);

end;

////////////////////////////////////////////
procedure T_OpenXML.WriteComment(s:String);
//Пишет комментарий
begin
        WriteString( '<!--'+
        Encode1(s)+ '-->');
end;

////////////////////////////////////////////
procedure T_OpenXML.WriteFreeText(s:String);
//Пишет комментарий
begin
        WriteString(s);
end;

////////////////////////////////////////////
Function T_OpenXML.getch:ansichar;
//Читает символ из файла
var c:ansiChar;
begin
     if g_BufChar<>#0 then begin
       Result:= g_BufChar; //извлекаем символ от ungetch
       g_BufChar:=#0;
       Exit;
     end;

     c:=g_buf[g_buf_p];
     if g_buf_p>g_buf_max then begin
       g_buf_p:=1;
       if g_rc6 then begin
         //sdsdf
       end else begin
         BlockRead(g_f, g_buf, c_BufSize, g_buf_max);
       end;
       if g_buf_max=0 then begin
           Error('Неожиданный конец файла');
       end;
       c:=g_buf[g_buf_p];
     end;
     inc(g_buf_p);
     if c=#13 then inc(g_LineNumber);
     Result:=c;
end;

////////////////////////////////////////////
Procedure T_OpenXML.ungetch(c:ansichar);
//Возвращает символ в буфер
begin
     g_BufChar:=c;
     //Нам нужен возврат только одного символа в буфер
end;


////////////////////////////////////////////
function T_OpenXML.ReadAmp: ansichar;
//Считывает последовательность &quot; &apos; &lt; &gt; &amp; как символ
//Возвращает этот символ.
var amp: String;
var c: ansichar;
begin
  amp:='&';
  Repeat
    c:=getch;
    if c<=' ' then Error('Ошибка &-последовательности (пробел): '+amp);
    amp:=amp+c;
  Until c=';';

  Result:=' ';

  if amp='&amp;' then Result:='&'
  else if amp='&quot;' then Result:='"'
  else if amp='&apos;' then Result:=''''
  else if amp='&lt;' then Result:='<'
  else if amp='&gt;' then Result:='>'
  else Error('Ошибка &-последовательности: '+amp);
end;


////////////////////////////////////////////
procedure T_OpenXML.DecodeUTF8();
var i: Integer;
begin

      g_TagName:=Utf8ToAnsi(g_TagName);
      g_Characters:=Utf8ToAnsi(g_Characters);
      for i:=1 to g_AttrCount do begin
        g_AttrNames[i]:=Utf8ToAnsi(g_AttrNames[i]);
        g_AttrValues[i]:=Utf8ToAnsi(g_AttrValues[i]);
      end;
end;



////////////////////////////////////////////
procedure T_OpenXML.ReadTag1;
//Читаем тег.
//Комментарий считываем как отдельный тег с именем <!-->

var c: ansichar;
var s: String;

var OpenChars: String;
var CloseChars: String;
var TagNameChars: String;
var AttrNameChars: String;
var AttrValueChars: String;

var AttrQuote: ansichar;




begin
   g_AttrCount:=0;

   if g_DocMode<>'R' then begin
     Error('Файл не открыт для чтения');
   end;

   if g_BufTagName<>'' then begin
   //Извлекаем имя тега, оставшееся от разбора <tag/>
     g_TagName:=g_BufTagName;
     g_BufTagName:='';
     Exit;
   end;

   repeat
     c:=getch;
     case c of
       '<': break;
       #0..#32: continue;
       else Error('Неожиданный символ перед началом тега');
     end;
   until false;


   s:='<';

   c:=getch;

   if c='!' then begin

     //обрабатываем комментарий
     repeat
         s:=s+c;
         //Ожидаем завершающую последовательность -->
         c:=getch;
         if c<>'-' then continue;
         c:=getch;
         if c<>'-' then continue;
         c:=getch;
         if c<>'>' then continue;
     until true; //цикл не выполняется

     g_Characters:=s;
     g_TagName:='<!-->';
     exit;

   end;

   repeat
     case c of
       '/': s:=s+c;
       '?': s:=s+c;
       else
         ungetch(c);
         break;
     end; //case
     c:=getch;
   until false;

   OpenChars:=s;
   s:='';


   //Теперь читаем имя тега

   c:=getch;
   if c=' ' then Error('Имя тега не должно начинаться пробелом');
   if c='/' then Error('Имя тега не должно начинаться символом /');
   if c='?' then Error('Имя тега не должно начинаться символом ?');
   if c='>' then Error('Имя тега не должно начинаться символом >');

   TagNameChars:=c;

   repeat
     c:=getch;
     case c of
       '/', '?', '>': begin
         ungetch(c);
         break;
       end;
       #0..#32: begin //пробельные символы
         break;
       end;
       else
         TagNameChars:=TagNameChars+c;
     end;//case
   until false;

   //Прочитали имя тега


   repeat //цикл по атрибутам тега

     //считываем возможные пробельные символы
     repeat
       c:=getch;
       case c of
         #0..#32: begin //пробельные символы
           Continue;
         end;
         else
           ungetch(c);
           break;
       end;//case
     until false;

     case c of
       '>','?','/': break; //прерываем цикл по атрибутам тега
     end;// case


     //считываем имя параметра

     AttrNameChars:='';
     repeat
       c:=getch;
       case c of
         #0..#32: break;
         '=': begin
           ungetch(c);
           break;
         end;
         else
           AttrNameChars:=AttrNameChars+c;
       end;//case
     until false;

     //считали имя параметра, теперь считаем возможные пробелы и символ =

     repeat
       c:=getch;
       case c of
         #0..#32: continue;
         '=': break;
         else
           Error('Ожидается символ =');
       end;//case
     until false;

     //теперь считаем возможные пробелы после символа =

     repeat
       c:=getch;
       case c of
         #0..#32: continue;
         else
           ungetch(c);
           break;
       end;//case
     until false;

     //Теперь должен быть параметр в одиночных или двойных кавычках

       c:=getch;
       case c of
         '"': begin
           AttrQuote:=c;
         end;
         '''': begin
           AttrQuote:=c;
         end;
         else begin
           AttrQuote:=' ';
           Error('Ожидается параметр в одиночных или двойных кавычках');
         end;
       end;//case


     //Теперь считываем символы до закрывающей кавычки
     AttrValueChars:='';
     repeat
       c:=getch;
       if c=AttrQuote then break; //нашли закрывающую кавычку
       if c='&' then c:=ReadAmp(); //последовательность вида &quot; и т.п.
       AttrValueChars:=AttrValueChars+c;
     until false;

      //Запоминаем атрибут в массиве

      inc(g_AttrCount);
      if g_AttrCount>c_MaxAttrCount then Error('Превышено максимальное количество атрибутов тега.');
      g_AttrNames[g_AttrCount]:=AttrNameChars;
      g_AttrValues[g_AttrCount]:=AttrValueChars;


   until false; //цикл по атрибутам

   //теперь считываем завершающие символы тега

   CloseChars:='';

   repeat
       c:=getch;
       case c of
         '/','?','>': begin
           CloseChars:=CloseChars+c;
         end;
         #0..#32: Continue; //пробельные символы пропускаем
         else Error('Неожиданный завершающий символ тега')
       end;//case
   until c='>';

   g_Characters:='';

   if OpenChars='<?' then begin
     if CloseChars<>'?>' then Error('Ожидаются завершающие символы /?>');
     g_TagName:=OpenChars+TagNameChars+CloseChars;

   end else if OpenChars='</' then begin
     if CloseChars<>'>' then Error('Для закрывающего тега допускается конечный символ >');
     if g_AttrCount>0 then Error('Для закрывающего тега не допускаются параметры');
     g_TagName:=OpenChars+TagNameChars+CloseChars;

   end else if OpenChars='<' then begin
     if CloseChars='>' then begin
      //Простое закрытие тега - читаем символы за тегом

       repeat
         c:=getch();
         if c='<' then begin
           ungetch(c);
           break;
         end;
         if c='&' then c:=ReadAmp();
         g_Characters:=g_Characters+c;
       until false;

       g_TagName:=OpenChars+TagNameChars+CloseChars;
     end else if CloseChars='/>' then begin
       //Тег вида <tag/> - надо расколбасить его на два простых тега
       //Символы за тегом читать не будем.

       g_TagName:=OpenChars+TagNameChars+'>';
       g_BufTagName:='</'+TagNameChars+'>';
     end else begin
       Error('Для открывающих символов тега < ожидаются закрывающие символы > или />');
     end;
   end else begin
     Error('Неожиданное начало тега: '+OpenChars);
   end;
end;



////////////////////////////////////////////
procedure T_OpenXML.ReadHeader;
var enc, ver: String;
begin
   ReadTag1;

   enc:=LowerCase(GetParam('encoding'));
   ver:=GetParam('version');

   if g_TagName<>'<?xml?>' then begin
     Error('Ожидается заголовок XML в формате <?xml ... ?>');
   end;

   if g_utf8=0 then begin
     if enc='' then enc:=LowerCase(trim(g_DefaultEncoding));

     if enc='windows-1251' then begin
       g_utf8:=0;
     end else if enc='utf-8' then begin
       g_utf8:=1;
     end else begin
       Error('Ожидается кодировка документа windows-1251 или utf-8');
     end;
   end;

   if ver<>'1.0' then begin
     Error('Ожидается версия 1.0 в заголовке XML.');
   end;

end;

////////////////////////////////////////////
Function T_OpenXML.ReadTag(p_names: String): Integer;
begin

   ReadTag1;
   if g_utf8=1 then DecodeUTF8;

   //MessageBox(0, pchar(g_TagName), 'TagName',0);

   if g_TagName[2]='/' then begin
     Pop1;
   end else begin
     Push1;
   end;



   if p_names<>'' then begin
     if pos(g_TagName, p_names)=0 then Error('Тег '+g_TagName+' не соответствует списку ожидаемых тегов '+p_names);
   end;

   Result:=1;

end;

////////////////////////////////////////////
function T_OpenXML.ReadValue(p_name: String):String;
//Считывает значение наподобие <Тег>Значение</Тег>
var s: String;
begin
   if p_name='' then begin
     Error('Укажите ожидаемое имя тега');
   end;
  if p_name[1]<>'<' then begin
    Error('Имя тега должно начинаться символом <');
  end;

  if p_name[Length(p_name)]<>'>' then begin
    Error('Имя тега должно заканчиваться символом >');
  end;


   ReadTag1;
   if g_utf8=1 then DecodeUTF8;

   if g_TagName<>p_name then begin
     Error('Ожидается имя тега '+p_name+' а прочитано '+g_TagName);
   end;

   Result:=g_Characters;

   s:=p_name;
   Insert('/',s,2);

   ReadTag1;
   if g_utf8=1 then DecodeUTF8;
   

   if g_TagName<>s then Error('Ожидается закрывающий тег '+s+
   ', а прочитан - '+g_TagName);
end;



////////////////////////////////////////////
procedure T_OpenXML.OpenDoc(fname: String);
var c1, c2, c3: ansichar;
begin
   CloseDoc();
   g_LineNumber:=1;
   if FileExists(fname)=False then begin
     Error('Файл не существует: '+fname);
   end;
   try
     if g_rc6 then begin
        g_frc6.OpenFile(fname, g_PasswordRC6);
     end else begin
       AssignFile(g_f, fname);
       Reset(g_f);
     end;
   except
     on E:Exception do
     Error('Не удается открыть файл: '+fname+'  '+E.Message);
   end;

   g_utf8:=0;

   //Проверяем признак кодировки UTF8
   Read(g_f, c1, c2, c3);


   if (c1=ansichar($EF)) and (c2=ansichar($BB)) and (c3=ansichar($BF)) then begin
     g_utf8:=1;
   end else begin
     if g_rc6 then begin
        g_frc6.CloseFile;
        g_frc6.OpenFile(fname, g_PasswordRC6);
     end else begin
       Reset(g_f);
     end;
   end;

   g_TagPoint:=0;
   g_DocMode:='R';

   g_buf_p:=1;
   g_buf_max:=0;

   ReadHeader;
end;

////////////////////////////////////////////
procedure T_OpenXML.CloseDoc;
begin
   g_DocMode:=' ';
    {$I-}
      CloseFile(g_f);
      IOResult;
      CloseFile(g_f1);
      IOResult;
    {$I+}

    if g_RC6=True then begin
      g_fRC6.CloseFile;
    end;
end;

end.
