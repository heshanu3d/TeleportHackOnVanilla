#NoTrayIcon
#RequireAdmin
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_UseX64=n
#AutoIt3Wrapper_Res_Language=2052
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

Global $exe = "WoW.exe"
Global $winTitle = "HackWow_1.12"
Global $CurrPosX = 0x00C7B548
Global $CurrPosY = 0x00C7B544
Global $CurrPosZ = 0x00C7B54C
Global $StaticPlayer = 0x00C7BCD4

#include <include.au3>

LaunchUI(InitMemory())
_MemoryClose($g_singleWowProcess)
