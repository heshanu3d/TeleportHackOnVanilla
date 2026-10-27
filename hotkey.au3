Func HotKeyInit()
	HotKeyRegFromConfigFile()
	HotKeyReg()
EndFunc

Func HotKeyReg()
	HotKeySet("!a", "HotKeyProcs")
	HotKeySet("!c", "HotKeyProcs")
	HotKeySet("!j", "HotKeyProcs")
	HotKeySet("!l", "HotKeyProcs")
	HotKeySet("!p", "HotKeyProcs")
	HotKeySet("!x", "HotKeyProcs")
	;HotKeySet("!1", "HotKeyProcs")
	;HotKeySet("!2", "HotKeyProcs")
	;HotKeySet("!3", "HotKeyProcs")
	For $i = 0 To $hotkeyRegFromFileConfigArrayLen - 1
		HotKeySet($hotkeyRegFromFileConfigArray[$i][0], "HotKeyProcs")
	Next
EndFunc

Func HotKeyProcs()
	$keyPressed = @HotKeyPressed
	Switch $keyPressed
		Case "!a"
			Autoloot()
		Case "!c"
			$g_startBot = False
		Case "!j"
			AntiJump()
		Case "!l"
			LuaUnlock()
		Case "!p"
			PatchLoot()
		Case "!x"
			Teleport($g_listview)
	EndSwitch
	For $i = 0 To $hotkeyRegFromFileConfigArrayLen - 1
		If $keyPressed = $hotkeyRegFromFileConfigArray[$i][0] Then
			TeleportInterface($hotkeyRegFromFileConfigArray[$i][2], $hotkeyRegFromFileConfigArray[$i][3], $hotkeyRegFromFileConfigArray[$i][4], $hotkeyRegFromFileConfigArray[$i][5], $hotkeyRegFromFileConfigArray[$i][1], $hotkeyRegFromFileConfigArray[$i][6])
			Return
		EndIf
	Next
EndFunc

Func FindPostionFromFavFile($postionText, $tpInfoArray, $tpInfoCount, $includeMetadata = False)
	$columnCount = 4 ; $columnCount = _GUICtrlListView_GetColumnCount($listview), this should be 4,  modified later
        Local $i = 0
        While $i < $tpInfoCount
			Local $split = StringSplit($tpInfoArray[$i], $g_telelist_split_str)
			If $split[0] >= 4 And $split[0] <= 6 Then
				If $split[1] = $postionText Then
					If $includeMetadata Then
						Local $metadata[5] = [$split[2], $split[3], $split[4], "", ""]
						If $split[0] >= 5 Then $metadata[3] = $split[5]
						If $split[0] >= 6 Then $metadata[4] = $split[6]
						Return $metadata
					EndIf
					Local $point[3] = [$split[2], $split[3], $split[4]]
					Return $point
				EndIf
				$i += 1
				ContinueLoop
			EndIf
			If $i + 3 >= $tpInfoCount Then ExitLoop
			If $tpInfoArray[$i] = $postionText Then
				If $includeMetadata Then
					Local $metadata[5] = [$tpInfoArray[$i+1], $tpInfoArray[$i+2], $tpInfoArray[$i+3], "", ""]
					If $i + 4 < $tpInfoCount And StringRegExp(StringStripWS($tpInfoArray[$i+4], 3), "^[+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?$") Then $metadata[3] = $tpInfoArray[$i+4]
					Return $metadata
				EndIf
				Local $posArr[3] = [$tpInfoArray[$i+1], $tpInfoArray[$i+2], $tpInfoArray[$i+3]]
				return $posArr
			EndIf
            $i = $i + $columnCount
			If $i < $tpInfoCount And StringRegExp(StringStripWS($tpInfoArray[$i], 3), "^[+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?$") Then $i += 1
        WEnd
    Local $missing[0]
    Return $missing
EndFunc

Func HotKeyRegFromConfigFile()
	Local $tpInfoArray = FileReadToArray($teleport_file)
    Local $tpInfoArrayCount = @extended
	If @error Then
        MsgBox($MB_SYSTEMMODAL, "", "There was an error reading tp file. @error: " & @error)
		$fileHandle = FileOpen($teleport_file, $FO_OVERWRITE)
		Return
	EndIf

	Local $hotkeyInfoArray = FileReadToArray($hotkey_file)
    Local $lineCount = @extended
	print("hotkeyfile len:" & $lineCount)
    If @error Then
        MsgBox($MB_SYSTEMMODAL, "", "There was an error reading hotkey file. @error: " & @error)
    Else
        Local $i = 1 								; start from 1 because the first line is comment
		Local $columnCount = 2 						; first line is hotkey, second line is position key
        While $i + $columnCount-1 < $lineCount
            $hotkey = $hotkeyInfoArray[$i]
            $posKey = $hotkeyInfoArray[$i+1]
			$posInfo = FindPostionFromFavFile($posKey, $tpInfoArray, $tpInfoArrayCount, True)
            If UBound($posInfo) = 5 Then
				If $hotkeyRegFromFileConfigArrayLen < $hotkeyRegFromFileConfigArrayMaxLen Then
					$hotkeyRegFromFileConfigArray[$hotkeyRegFromFileConfigArrayLen][0] = $hotkey
					$hotkeyRegFromFileConfigArray[$hotkeyRegFromFileConfigArrayLen][1] = $posKey
					$hotkeyRegFromFileConfigArray[$hotkeyRegFromFileConfigArrayLen][2] = $posInfo[0]
					$hotkeyRegFromFileConfigArray[$hotkeyRegFromFileConfigArrayLen][3] = $posInfo[1]
					$hotkeyRegFromFileConfigArray[$hotkeyRegFromFileConfigArrayLen][4] = $posInfo[2]
					$hotkeyRegFromFileConfigArray[$hotkeyRegFromFileConfigArrayLen][5] = $posInfo[3]
					$hotkeyRegFromFileConfigArray[$hotkeyRegFromFileConfigArrayLen][6] = $posInfo[4]
					$hotkeyRegFromFileConfigArrayLen = $hotkeyRegFromFileConfigArrayLen + 1
					print("reg " & $posKey & "hot key success")
				EndIf
			EndIf
			$i = $i + $columnCount
        WEnd
    EndIf
EndFunc
