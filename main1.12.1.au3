#NoTrayIcon
#RequireAdmin
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_UseX64=n
#AutoIt3Wrapper_Res_Language=2052
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

Global $version = "1.12.1"
Global $exe = "WoW.exe"
Global $winTitle = "HackWow_1.12.1"
Global $CurrPosX = 0x00C7B548
Global $CurrPosY = 0x00C7B544
Global $CurrPosZ = 0x00C7B54C
Global $StaticPlayer = 0x00C7BCD4
Global $AntiJump = 0x7C625F
Global $JumpGravity = 0x7C6272
Global $PlayerName = 0xC27D88

Global $PbPointer1 = 0
Global $PbPointer2 = 0
Global $PosX = 0
Global $PosY = 0
Global $PosZ = 0
Global $PosR = 0
Global $SpeedGlobal = 0

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
