unit uComPort;

interface
    uses Windows, SysUtils;


    type T_ComPort = class(TObject)
    public
      p_BufferIsEmpty: Boolean;
      p_EOL: String;

      p_BaudRate: Integer;
      p_ByteSize: Integer;
      p_Parity: Integer;
      p_StopBits: Integer;


      Constructor Create;
      Destructor Destroy; Override;

      procedure OpenPort(PortName: String); //��������� ���� (��������� ��� �����, ��������, 'COM2')
      procedure ClosePort; //��������� �������� ����
      procedure WriteString(s:String);
      function  ReadString:String; //���������� ������, ��������� � COM-�����.
      //������ ������ ����������� ��������� #13#10
      //���� ������� �������� ������ (��� ����������� �������� #13#10), �� �� ������������ ������.

      function IntToHex(int: DWORD): String;
      function HexToInt(h: String): DWORD;
    private
      ReadBuffer: String; //����� ��� ��������� ��������
      hCom: DWORD; //���������� Com-�����
      dcb: TDCB;  //uses Windows
      cto: TCommTimeOuts; //uses Windows
      bPortIsOpen: Boolean; //������� �������� �����
    end;



implementation

//////////////////////////////////////////////////////////////
Constructor T_ComPort.Create;
begin
     inherited Create;
     hCom:=0;
     bPortIsOpen:=False;
     ReadBuffer:='';
     p_EOL:=#13#10;

      p_BaudRate:= CBR_9600;
      p_ByteSize:= 8;
      p_Parity:= NOPARITY;
      p_StopBits:= ONESTOPBIT;

end;

//////////////////////////////////////////////////////////////
destructor T_ComPort.Destroy;
begin
     inherited Destroy;
end;

//////////////////////////////////////////////////////////////
procedure T_ComPort.OpenPort(PortName: String);
begin
  if hCom>0 then  Raise Exception.Create('���� ��� ���������������');
  hCom:=CreateFile( //uses Windows
                    pchar(PortName), //��� COM-�����
                    GENERIC_READ or GENERIC_WRITE,
                    0, {exclusive access}
                    nil, {no security attrs}
                    OPEN_EXISTING,
                    0,{not overlapped}
                    0 {hTemplate}
                    );
  if hCom=INVALID_HANDLE_VALUE then
      RaiseLastOSError;

  //���������� ��������� COM-�����

  if not GetCommState(hCom,dcb) //uses Windows
    then RaiseLastOSError;

  dcb.BaudRate:=p_BaudRate;
  dcb.ByteSize:=p_ByteSize;
  dcb.Parity:=p_Parity;
  dcb.StopBits:=p_StopBits;

  if not SetCommState(hCOM,dcb) //uses Windows
    then RaiseLastOSError;

  //���������� ��������� COM-�����
  if not GetCommTimeOuts(hCom,cto) //uses Windows
    then RaiseLastOSError;

    cto.ReadIntervalTimeout:=1;
    cto.ReadTotalTimeoutMultiplier:=1;
    cto.ReadTotalTimeoutConstant:=10;

    cto.WriteTotalTimeoutMultiplier:=0;
    cto.WriteTotalTimeoutConstant:=0;

  if not SetCommTimeOuts(hCom,cto) //uses Windows
    then RaiseLastOSError;

  bPortIsOpen:=True;

end;

//////////////////////////////////////////////////////////////
procedure T_ComPort.ClosePort;
begin
  if hCom<>0 then
    CloseHandle(hCom); //uses Windows
  hCom:=0;
  bPortIsOpen:=False;
end;

//////////////////////////////////////////////////////////////
function T_ComPort.ReadString: String;
  var Buff: Array[1..100] of char;
  var rd_cnt: DWORD;
  var ok: Boolean;
  var i: Integer;
  var p: Integer;
begin

  if bPortIsOpen=False then begin
        Raise Exception.Create('������� �������� COM-����.');
  end;

  if hCom=0 then Raise Exception.Create('���� �� ��� ������.');

  p:=pos(p_EOL, ReadBuffer);

  if p>0 then begin
    p_BufferIsEmpty:=False;
    Result:=ReadBuffer;
    Delete(Result, p, Length(Result));
    Delete(ReadBuffer, 1, p+1);
    exit;
  end;

  ok:=ReadFile(  //uses Windows
    hCom, //����
    Buff, //����� ���� ���������
    100, //����� ������ ��� ����������
    rd_cnt, //����� ��������� ������
    nil
  );

  if not ok then RaiseLastOSError;

  if rd_cnt=0 then begin
    p_BufferIsEmpty:=True;
    Result:='';
    exit;
  end;

  p_BufferIsEmpty:=False;

  for i:=1 to rd_cnt do begin
    ReadBuffer:=ReadBuffer+Buff[i];
  end;

  p:=pos(p_EOL, ReadBuffer);

  if p>0 then begin
    Result:=Copy(ReadBuffer,1,p-1);
    Delete(ReadBuffer, 1, p+1);
  end else begin
    Result:='';
  end;
end;

//////////////////////////////////////////////////////////////
procedure T_ComPort.WriteString(s:String);
  var Buff: String;
  var wr_cnt: DWORD;
  var ok:Boolean;
  var nBytes: DWORD;
begin

  if bPortIsOpen=False then begin
        Raise Exception.Create('������� �������� COM-����.');
  end;

  //MessageBox(0, pchar(s), '-2', 0);


  Buff:=s+p_EOL;

  //MessageBox(0, pchar(buff), '-3', 0);

  nBytes:=Length(Buff);
  ok:=WriteFile(  //uses Windows
    hCom, //����
    Buff[1], //����� ������ �����
    nBytes, //����� ������ ��� ����������
    wr_cnt, //����� ���������� ������
    nil
  );

  //MessageBox(0, pchar(buff), '-4', 0);

  if not ok then RaiseLastOSError;
  if wr_cnt<>nBytes then Raise Exception.Create('����� ���������� ������ � COM-���� ������, ��� ���� �����������.');
end;



//////////////////////////////////////////////////////////////
function T_ComPort.IntToHex(int: DWORD): String;
begin
  Result:=IntToHex(int);
end;

//////////////////////////////////////////////////////////////
function T_ComPort.HexToInt(h: String): DWORD;
  var N:DWORD;
  i:Integer;
  z: char;
begin
  h:=trim(h);
  if length(h)>8 then
    Raise Exception.Create('����� HEX-����� ��������� 8 ��������');

  if length(h)=0 then
    Raise Exception.Create('������ HEX-�����');

   N:=0; 

  for i:=1 to length(h) do begin
    z:=h[i];
    if i>1 then
       N:=N shl 4;

    case z of
      '0': begin end;
      '1': N:=N+1;
      '2': N:=N+2;
      '3': N:=N+3;
      '4': N:=N+4;
      '5': N:=N+5;
      '6': N:=N+6;
      '7': N:=N+7;
      '8': N:=N+8;
      '9': N:=N+9;
      'A', 'a': N:=N+10;
      'B', 'b': N:=N+11;
      'C', 'c': N:=N+12;
      'D', 'd': N:=N+13;
      'E', 'e': N:=N+14;
      'F', 'f': N:=N+15;
      else Exception.Create('������������ HEX-�����: '+h);
    end;//case
  end;
  Result:=N;



end;


end.
