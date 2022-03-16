#NoTrayIcon
#RequireAdmin
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Res_Language=2052
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
;#include <THHH_TPList_func.au3>
#include <ButtonConstants.au3>
#include <GUIConstantsEx.au3>
#include <GuiComboBox.au3>
#include <SliderConstants.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#include <SliderConstants.au3>
#include <EditConstants.au3>
#include <Misc.au3>
#include <NomadMemory.au3>
#include <GuiListView.au3>
#include <file.au3>
#include <WinAPI.au3>
#include <GuiRichEdit.au3>
#include <GuiEdit.au3>

Global $exe = "大荒60.exe"
Global $WowProcess
Global $CurrPosX = 0x00C7FC64 ; 0x00C7B548
Global $CurrPosY = 0x00C7FC68 ; 0x00C7B544
Global $CurrPosZ = 0x00C7FC6c ; 0x00C7B54C

Global $StaticPlayer = 0x00C803F4 ; 0x00C7BCD4

Global $DstYOffsetArray[5] = [0x88, 0x28, 0x6B4, 0x3C, 0x2C8]
Global $DstXOffsetArray[5] = [0x88, 0x28, 0x708, 0xC, 0x2A8]
Global $DstZOffsetArray[5] = [0x88, 0x28, 0x7C8, 0x1A4, 0x54]

Global $teleport_file = "favlist.fav"
Global $DelLine = -1
Global $log

Func print($content)
    ;~ _GUICtrlRichEdit_AppendText($log, $content & @CR)
    _GUICtrlEdit_AppendText($log, $content & @CRLF)
    ConsoleWrite($content & @CR)
EndFunc

Func InitListview($listview = 0)
    If $listview = 0 Then
        print("launch ui")
    Else
        GUICtrlDelete($listview)
        print("reload")
    Endif

    $listview = GUICtrlCreateListView("        描述        |      x      |      y      |      z      ", 10, 10, 380, 500)
    $g_listview = $listview
    $columnCount = _GUICtrlListView_GetColumnCount($listview)


    Local $tpInfoArray = FileReadToArray($teleport_file)
    Local $lineCount = @extended
    print("$lineCount : " & $lineCount)
    If @error Then
        MsgBox($MB_SYSTEMMODAL, "", "There was an error reading the file. @error: " & @error)
    Else
        Local $i = 0
        While $i + $columnCount-1 < $lineCount
            $text = $tpInfoArray[$i]
            For $c = 1 to $columnCount - 1
                $text = $text & "|" & $tpInfoArray[$i+$c]
            Next
            $i = $i + $columnCount
            GUICtrlCreateListViewItem($text, $listview)
        WEnd
    EndIf

    return $listview
EndFunc

Func GetListFd($op = $FO_READ)
    $fd = FileOpen($teleport_file, $op)
    If $fd = -1 Then
        print("An error occurred when reading the file.")
    EndIf
    Return $fd
EndFunc

Func InitMemory()
    print("--------------------------------------------------------")
    print("Memory Initializing")

    SetPrivilege("SeDebugPrivilege", 1)
    $WowProcessList = ProcessList($exe)
    $Wowpid1 = ProcessExists($exe)
    $dll = DllOpen("user32.dll")
    For $i = 1 to $WowProcessList[0][0]
        print("WoW pid:" & $WowProcessList[$i][1])
    Next

    $WowPid = $WowProcessList[1][1]
    print("$WowPid:" & $WowPid)

    $WowProcess = _MEMORYOPEN($WowPid)

    print("Memory Initialize over")
    print("--------------------------------------------------------")
EndFunc

Func Teleport($listview)
    $itemId = GUICtrlRead($listview)
    If $itemId == 0 Then
        Return
    EndIf
    $text = GUICtrlRead($itemId)
    If $text == 0 Then
        Return
    EndIf
    $array = StringSplit($text, '|')
    WritePosition($array[3], $array[2], $array[4])
EndFunc

Func TeleportDBClick($listview)
    $columnCount = _GUICtrlListView_GetColumnCount($listview)
    $selectedLine = _GUICtrlListView_GetSelectedIndices($listview)
    $text = _GUICtrlListView_GetItem($listview, $selectedLine)[3]
    For $i = 1 to $columnCount - 1
        $text = $text & "|" & _GUICtrlListView_GetItem($listview, $selectedLine, $i)[3]
    Next

    print("$text : " & $text)

    If $text == 0 Then
        Return
    EndIf
    $array = StringSplit($text, '|')
    WritePosition($array[3], $array[2], $array[4])
EndFunc

Func AddPos($input, $listview)
    $currPosArr = ReadPosition()
    $text = GUICtrlRead($input)
    $text = $text &"|"& $currPosArr[0] &"|"& $currPosArr[1] &"|"& $currPosArr[2]
    ;~ print($text)
    GUICtrlCreateListViewItem($text, $listview)
EndFunc

Func EditPos($input, $listview)
    $currPosArr = ReadPosition()
    $text = GUICtrlRead($input)
    $selectedLine = _GUICtrlListView_GetSelectedIndices($listview)
    _GUICtrlListView_SetItem($listview, $text, $selectedLine)
    _GUICtrlListView_SetItem($listview, $currPosArr[0], $selectedLine, 1)
    _GUICtrlListView_SetItem($listview, $currPosArr[1], $selectedLine, 2)
    _GUICtrlListView_SetItem($listview, $currPosArr[2], $selectedLine, 3)
EndFunc

Func DelPos($listview)
    ;~ print("$DelLine : " & $DelLine)
    Local $selectedLine
    If $DelLine <> -1 Then
        $selectedLine = $DelLine
        $DelLine = -1
    Else
        $selectedLine = _GUICtrlListView_GetSelectedIndices($listview)
    EndIf
    _GUICtrlListView_DeleteItem($listview, $selectedLine)
    $lineCount = _GUICtrlListView_GetItemCount($listview)
    if $selectedLine > $lineCount - 1 Then
        _GUICtrlListView_SetItemSelected($listview, $selectedLine - 1)
    ElseIf $lineCount = 0 Then
        Return
    Else
        $DelLine = $selectedLine
    EndIf
EndFunc

Func Save($listview)
    $lineCount = _GUICtrlListView_GetItemCount($listview)
    $columnCount = _GUICtrlListView_GetColumnCount($listview)
    $fd = GetListFd($FO_OVERWRITE + $FO_CREATEPATH)
    If $fd = -1 Then
        print("An error occurred when opening the file.")
    EndIf
    For $i = 0 to $lineCount - 1
        FileWriteLine($fd, _GUICtrlListView_GetItem($listview, $i, 0)[3])
        For $c = 0 to $columnCount - 2
            FileWriteLine($fd, _GUICtrlListView_GetItem($listview, $i, $c + 1)[3])
        Next
    Next
    print("saved " & $lineCount & " teleports")
EndFunc

Func ReloadUI($listview)
    InitListview($listview)
EndFunc

Func GoHome()
    ;~ 闪金镇
    Local $x = -9458.8232
    Local $y = 43.626
    Local $z = 56.9500
    WritePosition($y, $x, $z)
EndFunc

Func LaunchUI()
    Global $g_listview
    Local $button, $msg

    $ui = GUICreate("Hack大荒60", 400, 850, 100, 200, -1, $WS_EX_ACCEPTFILES)
    GUISetBkColor(0x00E0FFFF) ; will change background color
    GUISetState(@SW_SHOW)

    $listview = InitListview()
    $g_listview = $listview
    $addPos = GUICtrlCreateButton("addPos",     10, 550, 70, 20)
    $editPos = GUICtrlCreateButton("editPos",   100, 550, 70, 20)
    $delPos = GUICtrlCreateButton("delPos",     190, 550, 70, 20)

    $teleport = GUICtrlCreateButton("Teleport", 280, 550, 100, 50)

    $goHome = GUICtrlCreateButton("goHome",     10, 580, 70, 20)
    $save = GUICtrlCreateButton("save",         100, 580, 70, 20)
    $reload = GUICtrlCreateButton("reload",     190, 580, 70, 20)

    Global $input = GUICtrlCreateInput("",      10, 520, 210, 20)
    $log = GUICtrlCreateEdit("",                10, 610, 380, 220, BitOR($ES_AUTOVSCROLL, $WS_VSCROLL))
    
    ;~ richEdit loaded too slow
    ;~ $log = _GUICtrlRichEdit_Create($ui, "", 10, 610, 380, 320, BitOR($ES_MULTILINE, $WS_VSCROLL, $ES_AUTOVSCROLL))

    GUIRegisterMsg($WM_NOTIFY, "OnClickListViewItem")
    Do
        $msg = GUIGetMsg()
        Select
            Case $msg = $goHome
                GoHome()
            Case $msg = $addPos
                AddPos($input, $listview)
            Case $msg = $editPos
                EditPos($input, $listview)
            Case $msg = $delPos
                DelPos($listview)
            Case $msg = $save
                Save($listview)
            Case $msg = $reload
                ReloadUI($listview)
            Case $msg = $teleport
                Teleport($listview)
        EndSelect
    Until $msg = $GUI_EVENT_CLOSE
EndFunc   ;==>Example


Func OnClickListViewItem($hWnd, $Msg, $wParam, $lParam)
    Local $hWndFrom, $iIDFrom, $iCode, $tNMHDR, $listview
    $listview = $g_listview
    If Not IsHWnd($listview) Then $listview = GUICtrlGetHandle($g_listview)

    $tNMHDR = DllStructCreate($tagNMHDR, $lParam)
    $hWndFrom = HWnd(DllStructGetData($tNMHDR, "hWndFrom"))
    $iCode = DllStructGetData($tNMHDR, "Code")

    Switch $hWndFrom
        Case $listview
            Switch $iCode
                Case $NM_CLICK
                    Local $tInfo = DllStructCreate($tagNMLISTVIEW, $lParam)
                    Local $iItem = DllStructGetData($tInfo, "Item")
                    If $iItem <> -1 Then
                        $selectedLine = _GUICtrlListView_GetSelectedIndices($listview)
                        $retArr = _GUICtrlListView_GetItem($listview, $selectedLine, 0)
                        GUICtrlSetData($input, $retArr[3])
                        $DelLine = -1
                        print("!> Click on item " & $iItem)
                    EndIf
                Case $NM_DBLCLK
                    Local $tInfo = DllStructCreate($tagNMLISTVIEW, $lParam)
                    Local $iItem = DllStructGetData($tInfo, "Item")
                    If $iItem <> -1 Then
                        TeleportDBClick($listview)
                        print("!> DBClick on item " & $iItem)
                    Endif
            EndSwitch
    EndSwitch

    Return $GUI_RUNDEFMSG
EndFunc

Func ReadPosition()
    $CurrX=_MemoryRead($CurrPosX,$WowProcess,"float")
    $CurrY=_MemoryRead($CurrPosY,$WowProcess,"float")
    $CurrZ=_MemoryRead($CurrPosZ,$WowProcess,"float")
    ;print("PointPosX : " & Hex($CurrPosX))
    ;print("PointPosY : " & Hex($CurrPosY))
    ;print("PointPosZ : " & Hex($CurrPosZ))
    print("CurrPosX : " & $CurrX)
    print("CurrPosY : " & $CurrY)
    print("CurrPosZ : " & $CurrZ)
    ;~ $R=_MemoryRead($Adr+$PosR,$WowProcess,"float")
    Local $posArr[3] = [Round($CurrX, 3), Round($CurrY, 3), Round($CurrZ, 3)]
    return $posArr
EndFunc

Func WritePosition($x, $y, $z)
    Local $addrX = $StaticPlayer
    Local $addrY = $StaticPlayer
    Local $addrZ = $StaticPlayer

    ;~ print("$addrX : " & $addrX)
    ;~ print("$addrY : " & $addrY)
    ;~ print("$addrZ : " & $addrZ)

    for $i = 0 to UBound($DstYOffsetArray) - 1
        ;~ print("loop : " & $i)
        ;~ print("$offset : " & $DstYOffsetArray[$i])
        $addrX = _MemoryRead($addrX, $WowProcess) + $DstXOffsetArray[$i]
        $addrY = _MemoryRead($addrY, $WowProcess) + $DstYOffsetArray[$i]
        $addrZ = _MemoryRead($addrZ, $WowProcess) + $DstZOffsetArray[$i]
        ;~ print("$addrX : " & $addrX)
        ;~ print("$addrY : " & $addrY)
        ;~ print("$addrZ : " & $addrZ)
    Next

    _MemoryWrite($addrX,$WowProcess,$x,'float')
    _MemoryWrite($addrY,$WowProcess,$y,'float')
    _MemoryWrite($addrZ,$WowProcess,$z,'float')

    print("teleporting")
    print("x : " & $x)
    print("y : " & $y)
    print("z : " & $z)
EndFunc

InitMemory()
LaunchUI()
_MemoryClose($WowProcess)