Func HotKeyReg()
	HotKeySet("!`", "HotKeyProcs")
	HotKeySet("!1", "HotKeyProcs")
	HotKeySet("!2", "HotKeyProcs")
	HotKeySet("!3", "HotKeyProcs")
EndFunc

Func HotKeyProcs()
	Switch @HotKeyPressed
		Case "!1" ; 通灵学院-出口
			If $g_farmEYun = True Then
				Local $array[5] = [0,0,6.808,-837.15,-33.043]  		  ; 厄运东-出口
				WritePosition($array[3], $array[2], $array[4])
			Else
				Local $array[5] = [0,0,188.088,126.329,138.777]       ; 通灵学院-出口
				WritePosition($array[3], $array[2], $array[4])
			EndIf
		Case "!2"
			If $g_farmEYun = True Then
				Local $array[5] = [0,0,9922.528,2316.097,1330.786]    ; 达纳苏斯-goHome
				WritePosition($array[3], $array[2], $array[4])
			Else
				Local $array[5] = [0,0,-9458.8232, 43.626, 56.9500]   ; 闪金镇goHome
				WritePosition($array[3], $array[2], $array[4])
			EndIf
		Case "!3"
			If $g_farmEYun = True Then
				Local $array[5] = [0,0,-3734.736,934.378,161.012]    ; 厄运东-入口
				WritePosition($array[3], $array[2], $array[4])
			Else
				Local $array[5] = [0,0,1277.969,-2551.743,88.23]     ; 通灵学院-入口
				WritePosition($array[3], $array[2], $array[4])
			EndIf
		Case "!`"
			Teleport($g_listview)
	EndSwitch
EndFunc