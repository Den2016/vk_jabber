unit kb_hook_Local;

interface

uses windows,sysutils;

function SetupLocalHook: boolean;
function RemoveLocalHook: boolean;
function KeyBoardHook(code: integer; wParam: word; lParam: longword): longword; stdcall;

var CurrentHook: HHook; //contains the handle of the currently installed hook
    HookInstalled: boolean; //true if a hook is installed

var s: String;
var
  Counter: Int64;


implementation

{
SetupLocalHook
---------
This function will setup a local hook to record keyboard input. The hook
function is to be KeyBoardHook. Returns true if succesful
setwindowshookex is called specifying type of hook is WH_KEYBOARD, then the
address of the hook procedure is simply the address of KeyBoardHook. hMod - the
handle for the dll the procedure is in is 0 since this is a local hook. The thread ID
is obtained using the function GetCurrentThreadID}
function SetupLocalHook: boolean;
begin
    CurrentHook:=setwindowshookex(WH_KEYBOARD,@KeyBoardHook,0,GetCurrentThreadID()); //install hook
    if CurrentHook<>0  then SetupLocalHook:=true else SetupLocalHook:=false; //return true if it worked
end;

{
RemoveLocalHook
---------------
This function removes the currently installed hook. Returns false if succesful }
function RemoveLocalHook: boolean;
begin
    RemoveLocalHook:=UnhookWindowsHookEx(CurrentHook);
end;


{
KeyboardHook
------------
This is the function that we will set windows to call whenever a key is pressed
returns 1 - i.e. let windows call the next keybaord hook (if there is one).
Note the STDCALL! This is required because of the way memory is managed when passing arguments
from one function to another. Windows does not normally use the same method as delphi, so the
stdcall option tells the compiler to use the windows method.
With a keyboard hook, code specifies if keyboard message is being processed, (read peekmessage
and getmessage in the sdk. wParam is the key code and lParam contains info on the key.}
function KeyBoardHook(code: integer; wParam: word; lParam: longword): longword; stdcall;
begin
    if code<0 then begin  //if code is <0 your keyboard hook should always run CallNextHookEx instantly and
       KeyBoardHook:=CallNextHookEx(CurrentHook,code,wParam,lparam); //then return the value from it.
       Exit;
    end;

    if (lParam and $F0000000)=0 then begin //нажатие, но не отпускание и не автоповтор
       //MessageBox(0, pchar('dn: '+IntToHex(lParam, 8)), pchar(IntToStr(WParam)), 0);
    //end else begin
       sysutils.beep; //if the key is being pressed, not releases, BEEP!
       //MessageBox(0, pchar('up: '+IntToStr(lParam)), pchar(IntToStr(WParam)), 0);
       if WParam=13 then begin
          MessageBox(0, pchar(s), '', 0);
          s:='';
       end else begin
          s:=s+chr(WParam);
          //MessageBox(0, pchar(s), '', 0);
       end;
       QueryPerformanceCounter(Counter);

    end;
    CallNextHookEx(CurrentHook,code,wParam,lparam);  //call the next hook proc if there is one
    KeyBoardHook:=0; //if KeyBoardHook returns a non-zero value, the window that should get
                     //the keyboard message doesnt get it.
    Exit;
end;

end.
