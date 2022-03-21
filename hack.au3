Func InitMemory()
    print("--------------------------------------------------------")
	print("Memory Initializing")

    SetPrivilege("SeDebugPrivilege", 1)
    $WowProcessList = ProcessList($exe)
    $Wowpid1 = ProcessExists($exe)
    $dll = DllOpen("user32.dll")
	Local $wowPidList = []
	If UBound($WowProcessList) = 1 Then
		MsgBox(0, "error", "please open exe first")
		Return $wowPidList
	EndIf
    For $i = 1 to $WowProcessList[0][0]
        print("WoW pid:" & $WowProcessList[$i][1])
		_ArrayAdd($wowPidList, $WowProcessList[$i][1])
    Next
	print("UBound($wowPidList)-1:" & UBound($wowPidList)-1)
    For $i = 1 to UBound($wowPidList)-1
        print("$wowPidList[" & $i & "]" & $wowPidList[$i])
    Next
    $WowPid = $WowProcessList[1][1]
	$g_selectPid = $Wowpid
    print("$WowPid:" & $WowPid)

    $g_singleWowProcess = _MemoryOpen($WowPid)

    print("Memory Initialize over")
    print("--------------------------------------------------------")
	return $wowPidList
EndFunc

Func ReadPosition()
	If $g_syncTeleport = True Then
		print("syncTeleport checkbox is on, cannot use readPostion function")
		Return
	EndIf
    $CurrX=_MemoryRead($CurrPosX,$g_singleWowProcess,"float")
    $CurrY=_MemoryRead($CurrPosY,$g_singleWowProcess,"float")
    $CurrZ=_MemoryRead($CurrPosZ,$g_singleWowProcess,"float")
    ;print("PointPosX : " & Hex($CurrPosX))
    ;print("PointPosY : " & Hex($CurrPosY))
    ;print("PointPosZ : " & Hex($CurrPosZ))
    print("CurrPosX : " & $CurrX)
    print("CurrPosY : " & $CurrY)
    print("CurrPosZ : " & $CurrZ)
    ;~ $R=_MemoryRead($Adr+$PosR,$g_singleWowProcess,"float")
    Local $posArr[3] = [Round($CurrX, 3), Round($CurrY, 3), Round($CurrZ, 3)]
    return $posArr
EndFunc

Func WritePositionSingle($x, $y, $z, $wowProcess)
    Local $addrX = $StaticPlayer
    Local $addrY = $StaticPlayer
    Local $addrZ = $StaticPlayer

    ;~ print("$addrX : " & $addrX)
    ;~ print("$addrY : " & $addrY)
    ;~ print("$addrZ : " & $addrZ)

    for $i = 0 to UBound($DstYOffsetArray) - 1
        ;~ print("loop : " & $i)
        ;~ print("$offset : " & $DstYOffsetArray[$i])
        $addrX = _MemoryRead($addrX, $wowProcess) + $DstXOffsetArray[$i]
        $addrY = _MemoryRead($addrY, $wowProcess) + $DstYOffsetArray[$i]
        $addrZ = _MemoryRead($addrZ, $wowProcess) + $DstZOffsetArray[$i]
        ;~ print("$addrX : " & $addrX)
        ;~ print("$addrY : " & $addrY)
        ;~ print("$addrZ : " & $addrZ)
    Next

    _MemoryWrite($addrX, $wowProcess, $x, 'float')
    _MemoryWrite($addrY, $wowProcess, $y, 'float')
    _MemoryWrite($addrZ, $wowProcess, $z, 'float')

    print("teleporting")
    print("x : " & $x)
    print("y : " & $y)
    print("z : " & $z)
EndFunc

Func WritePosition($x, $y, $z)
	If $g_syncTeleport = False Then
		WritePositionSingle($x, $y, $z, $g_singleWowProcess)
	Else
		print("multi-teleport, num:" & (UBound($g_wowProcess)-1)/2)
		For $i = 0 to (UBound($g_wowProcess)-1)/2 - 1
			Local $tmp[2] = [$g_wowProcess[$i][0]]
			$tmp[1] = $g_wowProcess[$i][1]
			WritePositionSingle($x, $y, $z, $tmp)
		Next
	EndIf
EndFunc

;DWORD
;ClntObjMgrObjectPtr(
;    QWORD Guid
;    )
;{
;    UINT UnitGuid;
;    UINT UnitBaseAddress;
;
;    UnitBaseAddress = ReadDword(ReadDword(s_curMgr) + 0xAC);
;    while (UnitBaseAddress != 0) {
;        if ((UnitGuid = (ReadQword(UnitBaseAddress + 0x30) == Guid)) != 0) {
;            return UnitBaseAddress;
;        }
;        UnitBaseAddress = ReadDword(UnitBaseAddress + 0x3C);
;    }
;    return 0;
;}
;
;QWORD
;ClntObjMgrGetActivePlayer(
;    VOID
;    )
;{
;    return ReadDword(ReadDword(s_curMgr) + 0xC0);
;}
;
;Playerbase = ClntObjMgrObjectPtr(ClntObjMgrGetActivePlayer());