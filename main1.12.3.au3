#NoTrayIcon
#RequireAdmin
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_UseX64=n
#AutoIt3Wrapper_Res_Language=2052
#AutoIt3Wrapper_Icon="icon.ico"
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

Global $version = "1.12.3"
Global $exe = "WoW.exe"
Global $winTitle = "HackWow_1.12.3"
Global $CurrPosX = 0x00C7FC64 ; 0x00C7B548
Global $CurrPosY = 0x00C7FC68 ; 0x00C7B544
Global $CurrPosZ = 0x00C7FC6C ; 0x00C7B54C
Global $StaticPlayer = 0x00C803F4 ; 0x00C7BCD4
Global $AntiJump = 0x7C973F
Global $JumpGravity = 0x7C9752
Global $PlayerName = 0xC2C430

Global $PbPointer1 = 0
Global $PbPointer2 = 0
Global $PosX = 0
Global $PosY = 0
Global $PosZ = 0
Global $PosR = 0
Global $SpeedGlobal = 0

Global $autoloot_call = 0x4C2D90
Global $Script_LootSlot = 0x4C3C60
Global $autoloot_2 = 0x4C2CBF ; write 2 nop to use autoloot
Global $patch_loot = 0x4C2FB0
Global $patch_loot2 = 0x4C36EF
Global $patch_lootslot = 0x4C3C96
Global $luaUnlock = 0x495847

#include <include.au3>

InitMemory()
HotKeyInit()
LaunchUI()
_MemoryClose($g_singleWowProcess)