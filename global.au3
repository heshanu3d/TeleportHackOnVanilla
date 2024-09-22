
Global $DstYOffsetArray[5] = [0x88, 0x28, 0x6B4, 0x3C, 0x2C8]
Global $DstXOffsetArray[5] = [0x88, 0x28, 0x708, 0xC, 0x2A8]
Global $DstZOffsetArray[5] = [0x88, 0x28, 0x7C8, 0x1A4, 0x54]


Global $g_listview
Global $g_input
Global $g_speed
Global $g_telelist_split_str = "#"

Global $g_singleWowProcess
Global $g_wowProcess[10][2]
Global $g_teleList_whole[0]
;~ Global $g_teleportListGroup = []
Global $g_lineCount
Global $g_wowPidList = []
Global $g_selectPid
Global $g_hwnd
Global $g_syncTeleport = False
Global $g_step = False
Global $g_farmEYun = False
Global $g_startBot = False

Global $teleport_file = "favlist.fav"
Global $hotkey_file = "hotkey.txt"
Global $DelLine = -1
Global $g_log


Global $hotkeyRegFromFileConfigArrayMaxLen = 50
Global $hotkeyRegFromFileConfigArray[$hotkeyRegFromFileConfigArrayMaxLen][5]
Global $hotkeyRegFromFileConfigArrayLen = 0