#NoTrayIcon
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <GuiListBox.au3>
#include <WinAPI.au3>
Local $ui=GUICreate("listbox probe",200,250)
Local $id=GUICtrlCreateList("",10,10,150,180,BitOR($LBS_NOTIFY,$LBS_EXTENDEDSEL,$WS_VSCROLL))
For $i=0 To 5
    _GUICtrlListBox_AddString($id,"item" & $i)
Next
GUISetState(@SW_SHOW)
ClickRow(0,0)
ClickRow(2,8)
If Selection() <> "0,2," Then Fail("Ctrl toggle")
ClickRow(4,12)
If Selection() <> "0,2,3,4," Then Fail("Ctrl+Shift range addition")
ClickRow(1,4)
If Selection() <> "1,2," Then Fail("Shift range")
GUIDelete($ui)
ConsoleWrite("category multiselect: passed" & @CRLF)
Exit 0
Func Fail($message)
    ConsoleWriteError($message & @CRLF)
    Exit 1
EndFunc
Func Selection()
    Local $a=_GUICtrlListBox_GetSelItems($id),$out=""
    For $j=1 To $a[0]
        $out &= $a[$j] & ","
    Next
    Return $out
EndFunc
Func ClickRow($row,$flags)
    Local $r=_GUICtrlListBox_GetItemRect($id,$row),$xy=BitOR(10,BitShift(Int(($r[1]+$r[3])/2),-16))
    Local $keyboard = DllStructCreate("byte[256]")
    If BitAND($flags, 8) Then DllStructSetData($keyboard, 1, 0x80, 0x11 + 1)
    If BitAND($flags, 4) Then DllStructSetData($keyboard, 1, 0x80, 0x10 + 1)
    DllCall("user32.dll", "bool", "SetKeyboardState", "ptr", DllStructGetPtr($keyboard))
    _WinAPI_PostMessage(GUICtrlGetHandle($id),$WM_LBUTTONDOWN,BitOR(1,$flags),$xy)
    _WinAPI_PostMessage(GUICtrlGetHandle($id),$WM_LBUTTONUP,$flags,$xy)
    Local $t=TimerInit()
    While TimerDiff($t)<100
        GUIGetMsg()
    WEnd
EndFunc
