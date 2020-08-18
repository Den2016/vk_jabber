Unit u_OpenXML;

Interface
Uses SysUtils, Windows, uRC6;

Const c_BufSize=65536; //������ ������ ��� ������ ����� (� ������)
Const c_MaxAttrCount=100; //������������ ����� ��������� ����
Const c_MaxStackSize=100; //������������ ����������� �����


    Type T_OpenXML = Class(TObject)

    //����� ��� ������ � ������ XML.


    Public
      g_TagName: String; //��� ���������� ����
      g_Characters: String; //������� �� �����

      //���� ��� ������ � ����������� (����������) ����
      g_AttrNames: Array[1..c_MaxAttrCount] of String;
      g_AttrValues: Array[1..c_MaxAttrCount] of String;
      g_AttrCount: Integer; //����� ����������
      g_DefaultEncoding: String; //��������� �� ��������� (���� �� ������� � ���������)
      g_PasswordRC6: String; //������ ��� ���������� RC6
      g_RC6: Boolean; //������� ���������� RC6


      Constructor Create;
      Destructor Destroy; Override;

      Procedure OpenDoc(fname: String); //��������� �������� �� ����� �����
      Procedure CloseDoc; //��������� ��������
      Procedure CreateDoc(fname: String); //������� ����� �������� � ��������� ������ �����
      Procedure AppendDoc(fname: String); //��������� �������� � ��������� ������ ����� �� ����������

      Function ReadTag(p_names: String): Integer;
       //������ ��������� ��� (������ �������� ����� ����������� ������ ����).
       //��������� ������ ��������� ����� ����� �������.
       //���������� 1 ���� ��� ��������.

      Function ReadValue(p_name: String):String;
       //������ ��� � ������� ���� <���> ��� ������ </���>
       //���������� �������� ������ ����. ���������� ����������,
       //���� ����������� ����������� ��� ����.

      procedure WriteTag(p_name: String);
       //����� ��������� ��� (������ �������� ����� ����������� ������ ����).

      Procedure WriteValue(p_name: String; p_value: String);
       //����� ��� � ������� ���� <���> ��� ������ </���>

      Procedure AddParam(p_name, p_value: String);
       //��������� �������� � ������ ���������� ����. ���� ����� �����
       //������� WriteTag, �� ��������� ����� �������� ������ � �����.

      Function GetParam(p_name: String): String;
       //������ �������� ����, ����� ������������ ��� ������ ReadTag ���
       //ReadValue. ���� �������� �� ����������, �� ���������� ������ ������.

      Procedure WriteComment(s: String);
      //����� �����������

      Procedure WriteFreeText(s: String);
      //����� ������������ �����

    private

      g_BufTagName: String; //����������� ��� ���� ��� ����������� <tag/>
      g_f1: TextFile; //���� ��� ������
      g_f: File of ansichar; //���� ��� ������
      g_BufChar: ansichar; //������ ��� ungetch

      //���� ��� �������� ����������� �����
      g_TagStack: Array[1..100] of String;
      g_TagPoint: Integer; //��������� � �����


      g_Spaces: String; //������ (����) �� ������ ������ ��� ������
      g_DocMode: ansichar; //R=������ ��� W=������
      g_LineNumber: Integer; //����� ������ (��� ������ ������)

      //����� ��� ������ �����
      g_buf: Array[1..c_BufSize] of ansichar;
      g_buf_p: Integer;//��������� � ������
      g_buf_max: Integer;//����������� �� ����� ����, ������� ����� �������

      g_utf8: Integer; //������� ��������� UTF-8

      g_append: Integer; //������� ���������� �����

      g_frc6: T_RC6; //������ ��� ���������� RC6


      procedure DecodeUTF8(); //������������� �� UTF-8

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
//����������� ������
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
//���������� ������
begin
     CloseDoc();
     inherited Destroy;
end;

////////////////////////////////////////////
procedure T_OpenXML.Error(s:String);
//���������� ���������� ��� ������.
begin
  if g_LineNumber>0 then
   s:='������ '+IntToStr(g_LineNumber)+': '+s;
  raise Exception.Create(s);
end;



////////////////////////////////////////////
procedure T_OpenXML.AddParam(p_name, p_value: String);
//��������� �������� (�������) � �������� ���� ����� ��� �������.
begin
   inc(g_AttrCount);
   if g_AttrCount > c_MaxAttrCount then Error('��������� ������������ ����� ��������� ����.');
   g_AttrNames[g_AttrCount]:=p_name;
   g_AttrValues[g_AttrCount]:=p_value;
end;



////////////////////////////////////////////
Function T_OpenXML.GetParam(p_name: String): String;
//�������� �������� ��������� �� ��� �����
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
//���������� ������ � �������� ����.
//��������� ������ �� ������ ������
//(� ����������� �� ����������� ����) � ����� ������.
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
    Error('������ ������ � ����: '+E.Message);
  end;
end;


////////////////////////////////////////////
procedure  T_OpenXML.Push1;
//���������� ��� ���� � ���� ��� ��� �������� �� �����������
var s: String;
begin
  if g_append=1 then exit;
  s:=Copy(g_TagName,2,Length(g_TagName)-2);
  inc(g_TagPoint);
  if g_TagPoint>100 then begin
    Error('��������� ������������ ����������� ����� - 100 �������');
  end;
  g_TagStack[g_TagPoint]:=s;
  g_Spaces:=g_Spaces+'  ';
end;

////////////////////////////////////////////
procedure  T_OpenXML.Pop1;
//��������� ��� ���� �� ����� � ������ ������, ���� ������ ����������� �����
var s, s1: String;
begin
  if g_append=1 then exit;
  if g_TagPoint<1 then Error('������ ����������� �����: ������� ������� ���������� ���.');
  s:=Copy(g_TagName,3,Length(g_TagName)-3);
  s1:=g_TagStack[g_TagPoint];
  dec(g_TagPoint);
  if s1<>s then begin
    Error('��������� ����������� ��� </'+s1+'>, � ������� ���: '+g_TagName);
  end;
  Delete(g_Spaces,1,2);
end;

////////////////////////////////////////////
procedure T_OpenXML.CreateDoc(fname: String);
//������� ���� XML
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
     Error('������ �������� �����: '+fname);
   end;
   g_TagPoint:=0;
   g_DocMode:='W';
   g_Spaces:='';
end;

////////////////////////////////////////////
procedure T_OpenXML.AppendDoc(fname: String);
//������� ���� XML
begin
   CloseDoc();
   g_LineNumber:=1;
   try
     if g_RC6 then Raise Exception.Create('����� ���������� �� �������������� ��� ���������� ����������');

     AssignFile(g_f1, fname);
     Append(g_f1);
     g_append:=1;
   except
     Error('������ �������� ����� �� ����������: '+fname);
   end;
   g_DocMode:='W';
end;


////////////////////////////////////////////
function T_OpenXML.Encode1(s: String):String;
//�������� ������, ������� � ��� ������� < > &
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
//�������� ������, ������� � ��� ������� < > & " '
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
//����� ��� � �������� ����
var i: Integer;
var s: String;
var flag_close: Boolean;

begin
  if g_DocMode<>'W' then begin
    Error('��������� ������ ���� ����� ������ ��� �������� �� ������ �����. ');
  end;

  if p_name='' then Error('������� ��� ����.');
  s:=trim(p_name);

  if s[1]<>'<' then begin
    Error('��� ���� ������ ���������� �������� "<".');
  end;

  if s[Length(s)]<>'>' then begin
    Error('��� ���� ������ ������������� �������� ">".');
  end;

  if Pos(' ',s)>0 then begin
    Error('��� ���� �� ������ ��������� �������.');
  end;

  if length(s)=2 then Error('������� �������� ��� ���� <> ');

  g_TagName:=s;

  if s[2]='/' then begin //���� ����������� ���
    if length(s)=3 then Error('������� �������� ��� ���� </> ');

    WriteString(s);      //���������� ���
    Pop1;                //��������� ��� �� �����������

  end else begin
      if s[Length(s)-1]='/' then begin //��� ���� <tag/>
        Delete(s, Length(s)-1, 1);
        flag_close:=True;
        g_Spaces:='  '+g_Spaces;
      end else begin
        g_TagName:=s;
        Push1;
        flag_close:=False;
      end;

    if g_AttrCount>0 then begin
      Delete(s, Length(s), 1); //������� ���������� ������ >

      for i:=1 to g_AttrCount do begin //��������� ���������
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
//����� ��� ���� <�������>��������</�������>

var s, s1: String;
var i: Integer;
begin
  s:=p_name;

  if g_DocMode<>'W' then begin
    Error('��������� ������ ���� ����� ������ ��� �������� �� ������ �����. ');
  end;

  if s[1]<>'<' then begin
    Error('��� ���� ������ ���������� �������� "<".');
  end;

  if s[Length(s)]<>'>' then begin
    Error('��� ���� ������ ������������� �������� ">".');
  end;

  if Pos(' ',s)>0 then begin
    Error('��� ���� �� ������ ��������� �������.');
  end;

  if Pos('/',s)>0 then begin
    Error('��� ���� �� ������ ��������� ������� /.');
  end;

  if length(s)=2 then Error('������� �������� ��� ���� <> ');

  s1:=s;

  if g_AttrCount>0 then begin
    Delete(s, Length(s), 1); //������� ���������� ������ >

    for i:=1 to g_AttrCount do begin //��������� ���������
      s:=s+' '+g_AttrNames[i]+'="'+Encode2(g_AttrValues[i])+'"';
    end; //for
    g_AttrCount:=0;
    s:=s+'>';
  end;//if


  g_Spaces:=g_Spaces+'  ';

  if p_value='' then begin //� ������ ������ ������ ����� ��� <tag/>
     Insert('/', s1, Length(s1));
     WriteString(s1);
  end else begin
     Insert('/',s1,2); //��������� ��� ������������ ����
     WriteString(s+Encode1(p_value)+s1);
  end;

  Delete(g_Spaces, 1, 2);

end;

////////////////////////////////////////////
procedure T_OpenXML.WriteComment(s:String);
//����� �����������
begin
        WriteString( '<!--'+
        Encode1(s)+ '-->');
end;

////////////////////////////////////////////
procedure T_OpenXML.WriteFreeText(s:String);
//����� �����������
begin
        WriteString(s);
end;

////////////////////////////////////////////
Function T_OpenXML.getch:ansichar;
//������ ������ �� �����
var c:ansiChar;
begin
     if g_BufChar<>#0 then begin
       Result:= g_BufChar; //��������� ������ �� ungetch
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
           Error('����������� ����� �����');
       end;
       c:=g_buf[g_buf_p];
     end;
     inc(g_buf_p);
     if c=#13 then inc(g_LineNumber);
     Result:=c;
end;

////////////////////////////////////////////
Procedure T_OpenXML.ungetch(c:ansichar);
//���������� ������ � �����
begin
     g_BufChar:=c;
     //��� ����� ������� ������ ������ ������� � �����
end;


////////////////////////////////////////////
function T_OpenXML.ReadAmp: ansichar;
//��������� ������������������ &quot; &apos; &lt; &gt; &amp; ��� ������
//���������� ���� ������.
var amp: String;
var c: ansichar;
begin
  amp:='&';
  Repeat
    c:=getch;
    if c<=' ' then Error('������ &-������������������ (������): '+amp);
    amp:=amp+c;
  Until c=';';

  Result:=' ';

  if amp='&amp;' then Result:='&'
  else if amp='&quot;' then Result:='"'
  else if amp='&apos;' then Result:=''''
  else if amp='&lt;' then Result:='<'
  else if amp='&gt;' then Result:='>'
  else Error('������ &-������������������: '+amp);
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
//������ ���.
//����������� ��������� ��� ��������� ��� � ������ <!-->

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
     Error('���� �� ������ ��� ������');
   end;

   if g_BufTagName<>'' then begin
   //��������� ��� ����, ���������� �� ������� <tag/>
     g_TagName:=g_BufTagName;
     g_BufTagName:='';
     Exit;
   end;

   repeat
     c:=getch;
     case c of
       '<': break;
       #0..#32: continue;
       else Error('����������� ������ ����� ������� ����');
     end;
   until false;


   s:='<';

   c:=getch;

   if c='!' then begin

     //������������ �����������
     repeat
         s:=s+c;
         //������� ����������� ������������������ -->
         c:=getch;
         if c<>'-' then continue;
         c:=getch;
         if c<>'-' then continue;
         c:=getch;
         if c<>'>' then continue;
     until true; //���� �� �����������

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


   //������ ������ ��� ����

   c:=getch;
   if c=' ' then Error('��� ���� �� ������ ���������� ��������');
   if c='/' then Error('��� ���� �� ������ ���������� �������� /');
   if c='?' then Error('��� ���� �� ������ ���������� �������� ?');
   if c='>' then Error('��� ���� �� ������ ���������� �������� >');

   TagNameChars:=c;

   repeat
     c:=getch;
     case c of
       '/', '?', '>': begin
         ungetch(c);
         break;
       end;
       #0..#32: begin //���������� �������
         break;
       end;
       else
         TagNameChars:=TagNameChars+c;
     end;//case
   until false;

   //��������� ��� ����


   repeat //���� �� ��������� ����

     //��������� ��������� ���������� �������
     repeat
       c:=getch;
       case c of
         #0..#32: begin //���������� �������
           Continue;
         end;
         else
           ungetch(c);
           break;
       end;//case
     until false;

     case c of
       '>','?','/': break; //��������� ���� �� ��������� ����
     end;// case


     //��������� ��� ���������

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

     //������� ��� ���������, ������ ������� ��������� ������� � ������ =

     repeat
       c:=getch;
       case c of
         #0..#32: continue;
         '=': break;
         else
           Error('��������� ������ =');
       end;//case
     until false;

     //������ ������� ��������� ������� ����� ������� =

     repeat
       c:=getch;
       case c of
         #0..#32: continue;
         else
           ungetch(c);
           break;
       end;//case
     until false;

     //������ ������ ���� �������� � ��������� ��� ������� ��������

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
           Error('��������� �������� � ��������� ��� ������� ��������');
         end;
       end;//case


     //������ ��������� ������� �� ����������� �������
     AttrValueChars:='';
     repeat
       c:=getch;
       if c=AttrQuote then break; //����� ����������� �������
       if c='&' then c:=ReadAmp(); //������������������ ���� &quot; � �.�.
       AttrValueChars:=AttrValueChars+c;
     until false;

      //���������� ������� � �������

      inc(g_AttrCount);
      if g_AttrCount>c_MaxAttrCount then Error('��������� ������������ ���������� ��������� ����.');
      g_AttrNames[g_AttrCount]:=AttrNameChars;
      g_AttrValues[g_AttrCount]:=AttrValueChars;


   until false; //���� �� ���������

   //������ ��������� ����������� ������� ����

   CloseChars:='';

   repeat
       c:=getch;
       case c of
         '/','?','>': begin
           CloseChars:=CloseChars+c;
         end;
         #0..#32: Continue; //���������� ������� ����������
         else Error('����������� ����������� ������ ����')
       end;//case
   until c='>';

   g_Characters:='';

   if OpenChars='<?' then begin
     if CloseChars<>'?>' then Error('��������� ����������� ������� /?>');
     g_TagName:=OpenChars+TagNameChars+CloseChars;

   end else if OpenChars='</' then begin
     if CloseChars<>'>' then Error('��� ������������ ���� ����������� �������� ������ >');
     if g_AttrCount>0 then Error('��� ������������ ���� �� ����������� ���������');
     g_TagName:=OpenChars+TagNameChars+CloseChars;

   end else if OpenChars='<' then begin
     if CloseChars='>' then begin
      //������� �������� ���� - ������ ������� �� �����

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
       //��� ���� <tag/> - ���� ������������ ��� �� ��� ������� ����
       //������� �� ����� ������ �� �����.

       g_TagName:=OpenChars+TagNameChars+'>';
       g_BufTagName:='</'+TagNameChars+'>';
     end else begin
       Error('��� ����������� �������� ���� < ��������� ����������� ������� > ��� />');
     end;
   end else begin
     Error('����������� ������ ����: '+OpenChars);
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
     Error('��������� ��������� XML � ������� <?xml ... ?>');
   end;

   if g_utf8=0 then begin
     if enc='' then enc:=LowerCase(trim(g_DefaultEncoding));

     if enc='windows-1251' then begin
       g_utf8:=0;
     end else if enc='utf-8' then begin
       g_utf8:=1;
     end else begin
       Error('��������� ��������� ��������� windows-1251 ��� utf-8');
     end;
   end;

   if ver<>'1.0' then begin
     Error('��������� ������ 1.0 � ��������� XML.');
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
     if pos(g_TagName, p_names)=0 then Error('��� '+g_TagName+' �� ������������� ������ ��������� ����� '+p_names);
   end;

   Result:=1;

end;

////////////////////////////////////////////
function T_OpenXML.ReadValue(p_name: String):String;
//��������� �������� ��������� <���>��������</���>
var s: String;
begin
   if p_name='' then begin
     Error('������� ��������� ��� ����');
   end;
  if p_name[1]<>'<' then begin
    Error('��� ���� ������ ���������� �������� <');
  end;

  if p_name[Length(p_name)]<>'>' then begin
    Error('��� ���� ������ ������������� �������� >');
  end;


   ReadTag1;
   if g_utf8=1 then DecodeUTF8;

   if g_TagName<>p_name then begin
     Error('��������� ��� ���� '+p_name+' � ��������� '+g_TagName);
   end;

   Result:=g_Characters;

   s:=p_name;
   Insert('/',s,2);

   ReadTag1;
   if g_utf8=1 then DecodeUTF8;
   

   if g_TagName<>s then Error('��������� ����������� ��� '+s+
   ', � �������� - '+g_TagName);
end;



////////////////////////////////////////////
procedure T_OpenXML.OpenDoc(fname: String);
var c1, c2, c3: ansichar;
begin
   CloseDoc();
   g_LineNumber:=1;
   if FileExists(fname)=False then begin
     Error('���� �� ����������: '+fname);
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
     Error('�� ������� ������� ����: '+fname+'  '+E.Message);
   end;

   g_utf8:=0;

   //��������� ������� ��������� UTF8
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
