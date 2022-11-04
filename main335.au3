#NoTrayIcon
#RequireAdmin
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_UseX64=n
#AutoIt3Wrapper_Res_Language=2052
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

Global $version = "3.3.5"
Global $exe = "WoW.exe"
Global $winTitle = "HackWow_1.12"
Global $CurrPosX = 0x00C7B548
Global $CurrPosY = 0x00C7B544
Global $CurrPosZ = 0x00C7B54C
Global $AntiJump = 0x7C625F
Global $JumpGravity = 0x7C6272

Global $StaticPlayer = 0x00CD87A8
Global $PlayerName = 0xC79D10+8
Global $PbPointer1 = 0x34
Global $PbPointer2 = 0x24
Global $PosX = 0x798
Global $PosY = 0x79C
Global $PosZ = 0x7A0
Global $PosR = 0x7A8

Global $autoloot_call = 0x4C1FA0
Global $Script_LootSlot = 0x4C2E70
Global $autoloot_2 = 0x4C1ECF ; write 2 nop to use autoloot
Global $patch_loot = 0x4C21C0
Global $patch_loot2 = 0x4C28FF
Global $patch_lootslot = 0x4C2E94
Global $luaUnlock = 0x494A57


#include <include.au3>

InitMemory()
HotKeyInit()
LaunchUI()
_MemoryClose($g_singleWowProcess)
