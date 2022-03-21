
Global $DstYOffsetArray[5] = [0x88, 0x28, 0x6B4, 0x3C, 0x2C8]
Global $DstXOffsetArray[5] = [0x88, 0x28, 0x708, 0xC, 0x2A8]
Global $DstZOffsetArray[5] = [0x88, 0x28, 0x7C8, 0x1A4, 0x54]


Global $g_listview
Global $g_input

Global $g_singleWowProcess
Global $g_wowProcess[5][2]
Global $g_selectPid
Global $g_syncTeleport = False
Global $g_farmEYun = False

Global $teleport_file = "favlist.fav"
Global $DelLine = -1
Global $log