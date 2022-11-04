#NoTrayIcon
#RequireAdmin
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_UseX64=n
#AutoIt3Wrapper_Res_Language=2052
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

Global $version = "3.3.5"
Global $exe = "WoW.exe"
Global $winTitle = "HackWow_3.3.5"
Global $CurrPosX = 0
Global $CurrPosY = 0
Global $CurrPosZ = 0
Global $AntiJump = 0
Global $JumpGravity = 0

Global $StaticPlayer = 0x00CD87A8
Global $PlayerName = 0xC79D10+8
Global $PbPointer1 = 0x34
Global $PbPointer2 = 0x24
Global $PosX = 0x798
Global $PosY = 0x79C
Global $PosZ = 0x7A0
Global $PosR = 0x7A8

Global $autoloot_call = 0
Global $Script_LootSlot = 0
Global $autoloot_2 = 0 ; write 2 nop to use autoloot
Global $patch_loot = 0
Global $patch_loot2 = 0
Global $patch_lootslot = 0
Global $luaUnlock = 0


#include <include.au3>

InitMemory()
HotKeyInit()
LaunchUI()
_MemoryClose($g_singleWowProcess)
