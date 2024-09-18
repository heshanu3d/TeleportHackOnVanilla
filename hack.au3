Func InitMemory()
    print("--------------------------------------------------------")
	print("Memory Initializing")

    SetPrivilege("SeDebugPrivilege", 1)
    $WowProcessList = ProcessList($exe)
    $Wowpid1 = ProcessExists($exe)
    $dll = DllOpen("user32.dll")

	If UBound($WowProcessList) = 1 Then
		MsgBox(0, "error", "please open exe first")
		Return
	EndIf
    For $i = 1 to $WowProcessList[0][0]
        print("WoW pid:" & $WowProcessList[$i][1])
		_ArrayAdd($g_wowPidList, $WowProcessList[$i][1])
    Next
	print("UBound($g_wowPidList)-1:" & UBound($g_wowPidList)-1)
    For $i = 1 to UBound($g_wowPidList)-1
        print("$g_wowPidList[" & $i & "]" & $g_wowPidList[$i])
    Next
    $WowPid = $WowProcessList[1][1]
	$g_selectPid = $Wowpid
	$g_hwnd = _WinGetHandleByPidAndCls($g_selectPid, "GxWindowClassD3d")
    print("$WowPid:" & $WowPid)

    $g_singleWowProcess = _MemoryOpen($WowPid)

    print("Memory Initialize over")
    print("--------------------------------------------------------")
EndFunc

Func ReadPosition()
    If $g_syncTeleport = True Then
        print("syncTeleport checkbox is on, cannot use readPostion function")
        Return
    EndIf
    If $version = "3.3.5" Then
        Local $PB1 = _MemoryRead($StaticPlayer, $g_singleWowProcess, "Ptr")
        Local $PB2 = _MemoryRead($PB1 + $PbPointer1, $g_singleWowProcess, "Ptr")
        Local $PlayerBase = _MemoryRead($PB2 + $PbPointer2, $g_singleWowProcess, "Ptr")
        ;~ $MapId = Round(_MemoryRead($MapID, $g_singleWowProcess, "dword"))
        $CurrX = Round(_MemoryRead($PlayerBase + $PosX, $g_singleWowProcess, "float"), 3)
        $CurrY = Round(_MemoryRead($PlayerBase + $PosY, $g_singleWowProcess, "float"), 3)
        $CurrZ = Round(_MemoryRead($PlayerBase + $PosZ, $g_singleWowProcess, "float"), 3)
        print("CurrPosX : " & $CurrX)
        print("CurrPosY : " & $CurrY)
        print("CurrPosZ : " & $CurrZ)
        ;~ $R=_MemoryRead($Adr+$PosR,$g_singleWowProcess,"float")
        Local $posArr[3] = [Round($CurrX, 3), Round($CurrY, 3), Round($CurrZ, 3)]
        return $posArr
    Else
        $CurrX = _MemoryRead($CurrPosX, $g_singleWowProcess, "float")
        $CurrY = _MemoryRead($CurrPosY, $g_singleWowProcess, "float")
        $CurrZ = _MemoryRead($CurrPosZ, $g_singleWowProcess, "float")
        ;print("PointPosX : " & Hex($CurrPosX))
        ;print("PointPosY : " & Hex($CurrPosY))
        ;print("PointPosZ : " & Hex($CurrPosZ))
        print("CurrPosX : " & $CurrX)
        print("CurrPosY : " & $CurrY)
        print("CurrPosZ : " & $CurrZ)
        ;~ $R=_MemoryRead($Adr+$PosR,$g_singleWowProcess,"float")
        Local $posArr[3] = [Round($CurrX, 3), Round($CurrY, 3), Round($CurrZ, 3)]
        return $posArr
    EndIf
EndFunc

Func WritePositionSingle($x, $y, $z, $wowProcess)
    If $version = "3.3.5" Then
        Local $PB1 = _MemoryRead($StaticPlayer, $WowProcess, "Ptr")
        Local $PB2 = _MemoryRead($PB1 + $PbPointer1, $WowProcess, "Ptr")
        Local $PlayerBase = _MemoryRead($PB2 + $PbPointer2, $WowProcess, "Ptr")
        ;~ $PlayerBase2 = _MemoryRead($PlayerBase + 8, $WowProcess,"Ptr")
        _MemoryWrite($PlayerBase + $PosX, $WowProcess, $y, "float")
        _MemoryWrite($PlayerBase + $PosY, $WowProcess, $x, "float")
        _MemoryWrite($PlayerBase + $PosZ, $WowProcess, $z, "float")
    Else
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

        ; print("teleporting")
        ; print("x : " & $x)
        ; print("y : " & $y)
        ; print("z : " & $z)
    EndIf
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

Func AntiJump()
	If $g_syncTeleport = False Then
		$val = _MemoryRead($AntiJump, $g_singleWowProcess, 'byte')
		;print("AntiJump val:" & $val)
		;; 0x75 = 117
		;; 0xEB = 235
		If $val = 0x75 Then
			print("set Antijump off")
			_MemoryWrite($AntiJump, $g_singleWowProcess, 0xEB, 'byte')
			SetJumpGravity(0.0)
		ElseIf $val = 0xEB Then
			print("set Antijump on")
			_MemoryWrite($AntiJump, $g_singleWowProcess, 0x75, 'byte')
			SetJumpGravity(-7.0)
		EndIf
	Else
		print("not support in sync mode")
	EndIf
EndFunc

Func SetJumpGravity($val)
	print("JumpGravity val:" & _MemoryRead($JumpGravity, $g_singleWowProcess, 'float'))
	_MemoryWrite($JumpGravity, $g_singleWowProcess, $val, 'float')
	print("JumpGravity val:" & _MemoryRead($JumpGravity, $g_singleWowProcess, 'float'))
EndFunc

Func Autoloot()
	print("start Autoloot function")
	If $g_syncTeleport = False Then
		$val_0 = _MemoryRead($autoloot_2, $g_singleWowProcess, 'byte')
		$val_1 = _MemoryRead($autoloot_2+1, $g_singleWowProcess, 'byte')
		print("$autoloot_2 $val_0:" & $val_0)
		print("$autoloot_2 $val_1:" & $val_1)
		;; 0x74 = 116
		;; 0x10 = 16
		If $val_0 = 0x74 and $val_1 = 0x10 Then
			print("set Autoloot on")
			_MemoryWrite($autoloot_2, $g_singleWowProcess, 0x90, 'byte')
			_MemoryWrite($autoloot_2+1, $g_singleWowProcess, 0x90, 'byte')
		ElseIf $val_0 = 0x90 and $val_1 = 0x90 Then
			print("set Autoloot off")
			_MemoryWrite($autoloot_2, $g_singleWowProcess, 0x74, 'byte')
			_MemoryWrite($autoloot_2+1, $g_singleWowProcess, 0x10, 'byte')
		Else
			print("set Autoloot error")
		EndIf
	Else
		print("not support in sync mode")
	EndIf
EndFunc

Func PatchLoot()
	If $g_syncTeleport = False Then
		$val = _MemoryRead($patch_loot, 		$g_singleWowProcess, 'byte')
		$val_2 = _MemoryRead($patch_loot2, 	  	$g_singleWowProcess, 'byte')
		$val_3 = _MemoryRead($patch_lootslot, 	$g_singleWowProcess, 'byte')
		print("$patch_loot $val:" & $val)
		;; 0x72 = 114
		;; 0xEB = 235
		If $val = 0x72 and $val_2 = 0x72 and $val_3 = 1 Then
			print("set PatchLoot on")
			_MemoryWrite($patch_loot,  		$g_singleWowProcess, 0xEB, 'byte')
			_MemoryWrite($patch_loot2, 		$g_singleWowProcess, 0xEB, 'byte')
			_MemoryWrite($patch_lootslot, 	$g_singleWowProcess, 0x00, 'byte')
		ElseIf $val = 0xEB and $val_2 = 0xEB and $val_3 = 0 Then
			print("set PatchLoot off")
			_MemoryWrite($patch_loot,  		$g_singleWowProcess, 0x72, 'byte')
			_MemoryWrite($patch_loot2, 		$g_singleWowProcess, 0x72, 'byte')
			_MemoryWrite($patch_lootslot, 	$g_singleWowProcess, 0x01, 'byte')
		Else
			print("set PatchLoot error")
		EndIf
	Else
		print("not support in sync mode")
	EndIf
EndFunc

Func LuaUnlock()
	If $g_syncTeleport = False Then
		$val_0 = _MemoryRead($luaUnlock+0, $g_singleWowProcess, 'byte')
		$val_1 = _MemoryRead($luaUnlock+1, $g_singleWowProcess, 'byte')
		$val_2 = _MemoryRead($luaUnlock+2, $g_singleWowProcess, 'byte')
		$val_3 = _MemoryRead($luaUnlock+3, $g_singleWowProcess, 'byte')
		$val_4 = _MemoryRead($luaUnlock+4, $g_singleWowProcess, 'byte')
		$val_5 = _MemoryRead($luaUnlock+5, $g_singleWowProcess, 'byte')
		print("$luaUnlock_0 $val:" & $val_0 &", "& $val_1&", "& $val_2&", "& $val_3&", "& $val_4&", "& $val_5)
		If $val_0 = 0x56 and $val_1 = 0x8B and $val_2 = 0xF1 and $val_3 = 0x0F and $val_4 = 0x84 and $val_5 = 0xB1 Then
			print("set LuaUnlock on")
			_MemoryWrite($luaUnlock+0, $g_singleWowProcess, 0xB8, 'byte')
			_MemoryWrite($luaUnlock+1, $g_singleWowProcess, 0x01, 'byte')
			_MemoryWrite($luaUnlock+2, $g_singleWowProcess, 0x00, 'byte')
			_MemoryWrite($luaUnlock+3, $g_singleWowProcess, 0x00, 'byte')
			_MemoryWrite($luaUnlock+4, $g_singleWowProcess, 0x00, 'byte')
			_MemoryWrite($luaUnlock+5, $g_singleWowProcess, 0xC3, 'byte')
		ElseIf $val_0 = 0xB8 and $val_1 = 0x01 and $val_2 = 0x00 and $val_3 = 0x00 and $val_4 = 0x00 and $val_5 = 0xC3 Then
			print("set LuaUnlock off")
			_MemoryWrite($luaUnlock+0, $g_singleWowProcess, 0x56, 'byte')
			_MemoryWrite($luaUnlock+1, $g_singleWowProcess, 0x8B, 'byte')
			_MemoryWrite($luaUnlock+2, $g_singleWowProcess, 0xF1, 'byte')
			_MemoryWrite($luaUnlock+3, $g_singleWowProcess, 0x0F, 'byte')
			_MemoryWrite($luaUnlock+4, $g_singleWowProcess, 0x84, 'byte')
			_MemoryWrite($luaUnlock+5, $g_singleWowProcess, 0xB1, 'byte')
		EndIf
	Else
		print("not support in sync mode")
	EndIf
EndFunc

Func Sync($func)
	Local $ret = []
	If BitAND(GUICtrlRead($g_syncTeleport), $GUI_CHECKED) = $GUI_CHECKED Then
		For $i = 1 to UBound($g_wowPidList) - 1
			_ArrayAdd($ret, $func($g_wowProcess[$i-1]))
		Next
	Else
		_MemoryClose($g_selectPid)
		For $i = 1 to UBound($g_wowPidList) - 1
			$tmp = _MemoryOpen($g_wowPidList[$i])
			_ArrayAdd($ret, $func($tmp))
		Next
		For $i = 1 to UBound($g_wowPidList) - 1
			_MemoryClose($g_wowPidList[$i])
		Next
		$g_singleWowProcess = _MemoryOpen($g_selectPid)
	EndIf
	Return $ret
EndFunc

Func GetPlayerName($wowProcess)
	$c_str = _MemoryRead($PlayerName, $wowProcess, 'byte[12]')
	return _CodepageToString($c_str, 65001)
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

func GlobalSpeedSet($speed)
	If $version = "3.3.5" Then
		Local $PB1 = _MemoryRead($StaticPlayer, $g_singleWowProcess, "Ptr")
		Local $PB2 = _MemoryRead($PB1 + $PbPointer1, $g_singleWowProcess, "Ptr")
		Local $PlayerBase = _MemoryRead($PB2 + $PbPointer2, $g_singleWowProcess, "Ptr")
		;~ $PriveSpeedGlobaleInputed = GUICtrlRead($PriveSpeedGlobaleInput)
		;~ _MemoryWrite($PlayerBase + $SpeedGlobale, $g_singleWowProcess, $PriveSpeedGlobaleInputed, "float")
		_MemoryWrite($PlayerBase + $SpeedGlobal, $g_singleWowProcess, $speed, "float")
	Else
	EndIf
EndFunc
