Func TeleportKillLootN($x, $y, $z, $N ,$openChest = False, $waitMore = 0)
	TeleportInterface($x, $y, $z)
	Sleep(500)
	If $waitMore > 0 Then Sleep(1000 * $waitMore)
	If $openChest = True Then OpenChest()
	For $i = 1 To $N
		ControlSend ( $g_hwnd, "", "", "{2}")
		Sleep(100)
	Next
	MouseClick($MOUSE_CLICK_RIGHT, 1920/2, 1080/2, 1)
	Sleep(300)
EndFunc

;Func BWL()
;	$g_startBot = True
;	For $i = 1 to 360*48
;		If $g_startBot = False Then return
;		If _MathCheckDiv ($i, 100) == 2 Then
;			; 1，表示不可整除
;			; 2，表示可整除
;			; -1 并设置 @error = 1，表示给定的数字无效
;			_GUICtrlEdit_SetText($log, "") ; 定期清理日志
;		EndIf
;		print("第" & $i & "次挂机")
;		ControlSend ( $g_hwnd, "", "", "{R}")
;		Sleep(100)
;		ControlSend ( $g_hwnd, "", "", "{R}")
;		Sleep(100)
;		;斯坦索姆-入口
;		TeleportInterface(3237.951,-4057.782,108.473)
;		Sleep(1000)
;		;斯坦索姆-镇长-触发点
;		TeleportKillLoot(3662.359,-3617.82,137.681, True)
;		;斯坦索姆-蜘蛛
;		TeleportKillLoot(3853.99,-3526.799,144.21)
;		;斯坦索姆-男爵夫人
;		TeleportKillLoot(3854.206,-3713.866,148.091)
;		;斯坦索姆-dk
;		TeleportKillLoot(4035.866,-3335.007,115.059)
;		;斯坦索姆-出口
;		TeleportInterface(3588.054,-3639.159,138.476)
;		Sleep(1000)
;	Next
;EndFunc
;
;Func BWL_naifalian()
;	$g_startBot = True
;	For $i = 1 to 360*48
;		If $g_startBot = False Then return
;		If _MathCheckDiv ($i, 100) == 2 Then
;			; 1，表示不可整除
;			; 2，表示可整除
;			; -1 并设置 @error = 1，表示给定的数字无效
;			_GUICtrlEdit_SetText($log, "") ; 定期清理日志
;		EndIf
;		print("第" & $i & "次挂机")
;		ControlSend ( $g_hwnd, "", "", "{R}")
;		Sleep(100)
;		ControlSend ( $g_hwnd, "", "", "{R}")
;		Sleep(100)
;		;斯坦索姆-入口
;		TeleportInterface(3237.951,-4057.782,108.473)
;		Sleep(1000)
;		;斯坦索姆-蜘蛛
;		TeleportKillLoot(3853.99,-3526.799,144.21)
;		;斯坦索姆-dk
;		TeleportKillLoot(4035.866,-3335.007,115.059, True)
;		;斯坦索姆-出口
;		TeleportInterface(3588.054,-3639.159,138.476)
;		Sleep(1000)
;	Next
;EndFunc