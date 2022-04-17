#NoTrayIcon
#RequireAdmin
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_UseX64=n
#AutoIt3Wrapper_Res_Language=2052
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

Global $exe = "WoW.exe"
;Global $exe = "WoW-HY.exe"
;Global $exe = "天启魔兽.exe"
;Global $exe = "WOW - 启航.exe"
Global $winTitle = "1.12.3"
Global $CurrPosX = 0x00C7FC64 ; 0x00C7B548
Global $CurrPosY = 0x00C7FC68 ; 0x00C7B544
Global $CurrPosZ = 0x00C7FC6C ; 0x00C7B54C
Global $StaticPlayer = 0x00C803F4 ; 0x00C7BCD4
Global $AntiJump = 0x7C973F
Global $JumpGravity = 0x7C9752
Global $PlayerName = 0xC2C430

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