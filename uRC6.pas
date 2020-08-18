{ *********************************************************************** }
{                                                                         }
{ Delphi Еncryption Library                                               }
{ Еncryption / Decryption stream - RC6                                    }
{                                                                         }
{ Copyright (c) 2004 by Matveev Igor Vladimirovich                        }
{ With offers and wishes write: teap_leap@mail.ru                         }
{                                                                         }
{ Дополнения и представление в виде класса: (c) romix, 2006               }
{ x-romix@mail.ru                                                         }
{ *********************************************************************** }

unit uRC6;

interface

uses
  SysUtils, Classes;



type T_RC6 = class(TObject)
    public
      eof: Boolean;
      Constructor Create;
      Destructor Destroy; Override;
      procedure OpenFile(fname, password: String);
      procedure CreateFile(fname, password: String);
      procedure Write(s: String);
      procedure Writeln(s: String);
      function Read: String;
      procedure CloseFile;
      procedure BlockRead(var Buf; Count: Integer ; var AmtTransferred: Integer);

    private
      mode: char;
      f: File;
      buf:String;
end;

implementation

const
  Rounds    = 20;
  KeyLength = 2 * (Rounds + 2);

  BlockSize = 16;
  KeySize   = 16 * 4;

  P32       = $b7e15163;
  Q32       = $9e3779b9;
  lgw       = 5;

type
  TRC6Block = array[1..4] of LongWord;

var
  S      : array[0..KeyLength-1] of LongWord;
  Key    : String;
  KeyPtr : PChar;


////////////////////////////////////////////////////////////////////////////////

function ROL(a, s: LongWord): LongWord;
asm
  mov    ecx, s
  rol    eax, cl
end;

////////////////////////////////////////////////////////////////////////////////

function ROR(a, s: LongWord): LongWord;
asm
  mov    ecx, s
  ror    eax, cl
end;

////////////////////////////////////////////////////////////////////////////////

procedure InvolveKey;
var
  TempKey : String;
  i, j    : Integer;
  K1, K2  : LongWord;
begin
 // Разворачивание ключа до длинны KeySize = 64
 TempKey := Key;
 i := 1;
 while ((Length(TempKey) mod KeySize) <> 0) do
   begin
     TempKey := TempKey + TempKey[i];
     Inc(i);
   end;

 i := 1;
 j := 0;
 while (i < Length(TempKey)) do
   begin
     Move((KeyPtr+j)^, K1, 4);
     Move(TempKey[i], K2, 4);
     K1 := ROL(K1, K2) xor K2;
     Move(K1, (KeyPtr+j)^, 4);
     j := (j + 4) mod KeySize;
     Inc(i, 4);
   end;
end;

////////////////////////////////////////////////////////////////////////////////

procedure CalculateSubKeys;
var
  i, j, k : Integer;
  L       : array[0..15] of LongWord;
  A, B	  : LongWord;
begin
 // Копирование ключа в L
 Move(KeyPtr^, L, KeySize);

 // Инициализация подключа S
 S[0] := P32;
 for i := 1 to KeyLength-1 do
   S[i] := S[i-1] + Q32;

 // Смешивание S с ключом
 i := 0;
 j := 0;
 A := 0;
 B := 0;
 for k := 1 to 3*KeyLength do
   begin
     A := ROL((S[i] + A + B), 3);
     S[i] := A;
     B := ROL((L[j] + A + B), (A + B));
     L[j] := B;
     i := (i + 1) mod KeyLength;
     j := (j + 1) mod 16;
   end;
end;

////////////////////////////////////////////////////////////////////////////////

procedure Initialize(AKey: string);
begin
 GetMem(KeyPtr, KeySize);
 FillChar(KeyPtr^, KeySize, #0);
 Key := AKey;

 InvolveKey;
end;

////////////////////////////////////////////////////////////////////////////////

procedure EncipherBlock(var Block);
var
  RC6Block : TRC6Block absolute Block;
  i	   : Integer;
  t, u	   : LongWord;
  Temp	   : LongWord;
begin
 try

 // Инициализация блока

 Inc(RC6Block[2], S[0]);
 Inc(RC6Block[4], S[1]);

 for i := 1 to Rounds do
   begin
     t := ROL((RC6Block[2] * (2*RC6Block[2] + 1)),lgw);
     u := ROL((RC6Block[4] * (2*RC6Block[4] + 1)),lgw);
     RC6Block[1] := ROL((RC6Block[1] xor t), u) + S[2*i];
     RC6Block[3] := ROL((RC6Block[3] xor u), t) + S[2*i+1];

     Temp := RC6Block[1];
     RC6Block[1] := RC6Block[2];
     RC6Block[2] := RC6Block[3];
     RC6Block[3] := RC6Block[4];
     RC6Block[4] := Temp;
   end;

 RC6Block[1] := RC6Block[1] + S[2*Rounds+2];
 RC6Block[3] := RC6Block[3] + S[2*Rounds+3];

         except
            on E:Exception do
              Raise Exception.Create('Ошибка EncipherBlock - '+E.Message);
         end;

end;

////////////////////////////////////////////////////////////////////////////////

procedure DecipherBlock(var Block);
var

  RC6Block : TRC6Block absolute Block;
  i	   : Integer;
  t, u	   : LongWord;
  Temp	   : LongWord;
begin
try


 // Инициализация блока
 RC6Block[3] := RC6Block[3] - S[2*Rounds+3];
 RC6Block[1] := RC6Block[1] - S[2*Rounds+2];

 for i := Rounds downto 1 do
   begin
     Temp := RC6Block[4];
     RC6Block[4] := RC6Block[3];
     RC6Block[3] := RC6Block[2];
     RC6Block[2] := RC6Block[1];
     RC6Block[1] := Temp;

     u := ROL((RC6Block[4] * (2*RC6Block[4] + 1)),lgw);
     t := ROL((RC6Block[2] * (2*RC6Block[2] + 1)),lgw);
     RC6Block[3] := ROR((RC6Block[3]-S[2*i+1]), t) xor u;
     RC6Block[1] := ROR((RC6Block[1]-S[2*i]), u) xor t;
   end;

 Dec(RC6Block[4], S[1]);
 Dec(RC6Block[2], S[0]);

         except
            on E:Exception do
              Raise Exception.Create('Ошибка DecipherBlock - '+E.Message);
         end;

end;


////////////////////////////////////////////////////////////////////////////////
      Constructor T_RC6.Create;
      begin
           Mode:=' ';
           inherited Create;
      end;
////////////////////////////////////////////////////////////////////////////////
      Destructor T_RC6.Destroy;
      begin
           inherited Destroy;
      end;
////////////////////////////////////////////////////////////////////////////////
      procedure T_RC6.OpenFile(fname, password: String);
      begin
        try
        Initialize(password);
        CalculateSubKeys;
        Assign(f, fname);
        Reset(f,1);
        mode:='R';
        eof:=False;
        buf:='';
         except
            on E:Exception do begin
              CloseFile;
              Raise Exception.Create('Ошибка OpenFile - '+E.Message);
            end;
         end;

      end;
////////////////////////////////////////////////////////////////////////////////
      procedure T_RC6.CreateFile(fname, password: String);
      begin
        try

        Initialize(password);
        CalculateSubKeys;
        Assign(f, fname);
        Rewrite(f,1);
        Mode:='W';
        eof:=False;

         except
            on E:Exception do begin
              CloseFile;
              Raise Exception.Create('Ошибка CreateFile - '+E.Message);
            end;
         end;

      end;
////////////////////////////////////////////////////////////////////////////////
      procedure T_RC6.Write(s: String);
      begin
        try
          if Mode<>'W' then begin
            Raise Exception.Create('файл должен быть открыт на запись');
          end;
          buf:=buf+s;
          while Length(buf)>=16 do begin;
            EncipherBlock(buf[1]);
            blockwrite(f, buf[1], 16);
            delete(buf,1,16);
          end;
         except
            on E:Exception do begin
              CloseFile;
              Raise Exception.Create('Ошибка Write - '+E.Message);
            end;
         end;

      end;
////////////////////////////////////////////////////////////////////////////////
      procedure T_RC6.WriteLn(s: String);
      begin
        Write(s+#13#10);
      end;
////////////////////////////////////////////////////////////////////////////////
      function T_RC6.Read: String;
      var r: Integer;
      var buf16: Array[1..16] of char;
      //Возвращает из зашифрованного файла строку длиной 16
      begin
          try

          if Mode<>'R' then begin
            Raise Exception.Create('Ошибка Read - файл должен быть открыт на чтение');
          end;
          Result:='';

          System.BlockRead(f, buf16, 16, r);

          //ShowMessage(IntToStr(r));

          if r<16 then begin
            eof:=True;
            Exit;
          end;


          if r<16 then begin
            Raise Exception.Create('длина файла должна быть кратна 16 байт');
          end;
          DecipherBlock(buf16);
          Result:=buf16;

         except
            on E:Exception do begin
              CloseFile;
              Raise Exception.Create('Ошибка Read - '+E.Message);
            end;
         end;
      end;


      procedure  T_RC6.BlockRead(var Buf; Count: Integer ; var AmtTransferred: Integer);
      begin

      end;


////////////////////////////////////////////////////////////////////////////////
      procedure T_RC6.CloseFile;
      begin
       try
        if Mode='R' then begin
          System.CloseFile(f);
        end else if Mode='W' then begin
          Write('               ');
          System.CloseFile(f);
        end;
       finally
        Mode:=' ';
       end;


      end;


end.
