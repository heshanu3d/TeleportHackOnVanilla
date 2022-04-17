;斯坦索姆-入口
Local $stsmPointEntry
;斯坦索姆-镇长-触发点
Local $stsmPointMayor
;斯坦索姆-蜘蛛
Local $stsmPointSpider
;斯坦索姆-男爵夫人
Local $stsmPointBaroness
;斯坦索姆-dk
Local $stsmPointDK
;斯坦索姆-出口
Local $stsmPointExit

Func GetTelepoint($tpInfoArray, $tpInfoArrayCount, ByRef $point, $key)
	$point = FindPostionFromFavFile($key, $tpInfoArray, $tpInfoArrayCount)
	If UBound($point) <> 3 Then
		print("invalid telepoint : " & $key)
	EndIf
	print($point[0]&" "&$point[1]&" "&$point[2])
EndFunc

Func InitTelepoint()
	Local $tpInfoArray = FileReadToArray($teleport_file)
    Local $tpInfoArrayCount = @extended
	If @error Then
        MsgBox($MB_SYSTEMMODAL, "", "There was an error reading tp file. @error: " & @error)
		Return
	EndIf
	GetTelepoint($tpInfoArray, $tpInfoArrayCount, $stsmPointEntry, "斯坦索姆-入口")
	GetTelepoint($tpInfoArray, $tpInfoArrayCount, $stsmPointMayor, "斯坦索姆-镇长-触发点")
	GetTelepoint($tpInfoArray, $tpInfoArrayCount, $stsmPointSpider, "斯坦索姆-蜘蛛")
	GetTelepoint($tpInfoArray, $tpInfoArrayCount, $stsmPointBaroness, "斯坦索姆-男爵夫人")
	GetTelepoint($tpInfoArray, $tpInfoArrayCount, $stsmPointDK, "斯坦索姆-dk")
	GetTelepoint($tpInfoArray, $tpInfoArrayCount, $stsmPointExit, "斯坦索姆-出口")
EndFunc

Func TeleportKillLoot($point, $openChest = False, $waitMore = 0)
	TeleportInterface($point[0], $point[1], $point[2])
	Sleep(500)
	If $waitMore > 0 Then Sleep(1000 * $waitMore)
	If $openChest = True Then OpenChest()
	ControlSend ( $g_hwnd, "", "", "{2}")
	Sleep(100)
	ControlSend ( $g_hwnd, "", "", "{2}")
	Sleep(100)
	ControlSend ( $g_hwnd, "", "", "{2}")
	Sleep(100)
	ControlSend ( $g_hwnd, "", "", "{2}")
	Sleep(100)
	ControlSend ( $g_hwnd, "", "", "{2}")
	Sleep(200)
	MouseClick($MOUSE_CLICK_RIGHT, 1920/2, 1080/2, 1)
	Sleep(300)
EndFunc

Func OpenChest()
	Autoloot()
	Sleep(300)
	ControlSend ( $g_hwnd, "", "", "{6}")
	Sleep(300)
	ControlSend ( $g_hwnd, "", "", "{7}")
	Sleep(300)
	ControlSend ( $g_hwnd, "", "", "{8}")
	Sleep(300)
	ControlSend ( $g_hwnd, "", "", "{9}")
	Sleep(300)
	ControlSend ( $g_hwnd, "", "", "{0}")
	Sleep(300)
	ControlSend ( $g_hwnd, "", "", "{-}")
	Sleep(300)
	Autoloot()
	Sleep(300)
EndFunc

Func STSM()
	InitTelepoint()
	$g_startBot = True
	For $i = 1 to 360*48
		If $g_startBot = False Then return
		If _MathCheckDiv ($i, 100) == 2 Then
			; 1，表示不可整除
			; 2，表示可整除
			; -1 并设置 @error = 1，表示给定的数字无效
			_GUICtrlEdit_SetText($log, "") ; 定期清理日志
		EndIf
		print("第" & $i & "次挂机")
		ControlSend ( $g_hwnd, "", "", "{R}")
		Sleep(100)
		ControlSend ( $g_hwnd, "", "", "{R}")
		Sleep(100)

		;斯坦索姆-入口
		TeleportInterface($stsmPointEntry[0], $stsmPointEntry[1], $stsmPointEntry[2])
		Sleep(1000)
		;斯坦索姆-镇长-触发点
		TeleportKillLoot($stsmPointMayor, True)
		;斯坦索姆-蜘蛛
		TeleportKillLoot($stsmPointSpider)
		;斯坦索姆-男爵夫人
		TeleportKillLoot($stsmPointBaroness)
		;斯坦索姆-dk
		TeleportKillLoot($stsmPointDK)
		;斯坦索姆-出口
		TeleportInterface($stsmPointExit[0], $stsmPointExit[1], $stsmPointExit[2])
		Sleep(1000)
	Next
EndFunc

Func STSM_DK()
	InitTelepoint()
	$g_startBot = True
	For $i = 1 to 360*48
		If $g_startBot = False Then return
		If _MathCheckDiv ($i, 100) == 2 Then
			; 1，表示不可整除
			; 2，表示可整除
			; -1 并设置 @error = 1，表示给定的数字无效
			_GUICtrlEdit_SetText($log, "") ; 定期清理日志
		EndIf
		print("第" & $i & "次挂机")
		ControlSend ( $g_hwnd, "", "", "{R}")
		Sleep(100)
		ControlSend ( $g_hwnd, "", "", "{R}")
		Sleep(100)
		;斯坦索姆-入口
		TeleportInterface($stsmPointEntry[0], $stsmPointEntry[1], $stsmPointEntry[2])
		Sleep(1000)
		;斯坦索姆-蜘蛛
		TeleportKillLoot($stsmPointSpider)
		;斯坦索姆-dk
		TeleportKillLoot($stsmPointDK)
		;斯坦索姆-出口
		TeleportInterface($stsmPointExit[0], $stsmPointExit[1], $stsmPointExit[2])
		Sleep(1000)
	Next
EndFunc