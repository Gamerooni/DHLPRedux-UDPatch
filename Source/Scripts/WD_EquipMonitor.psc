Scriptname WD_EquipMonitor Extends ReferenceAlias

WD_Util property util auto
WD_Config property config auto
GlobalVariable Property WD_HoursRestrained Auto
Spell Property weightPerk00 Auto ; Could do these as straight up perks,
Spell Property weightPerk01 Auto ; but they wouldn't show up in active effects

Message Property lvlUpMsg00 Auto
Message Property lvlUpMsg01 Auto

bool unequipping = false
bool restrained = false
bool fastTravelOn = true
int lvlupshown = 0 

event OnPlayerLoadGame()
	util.Maintenance()
	If WD_HoursRestrained.GetValueInt() < 150
		RegisterForSingleUpdateGameTime(1.0)
		If GetActorReference().WornHasKeyword(util.libs.zad_Lockable)
			restrained = true
		EndIf	
	EndIf
	DisableFastTravel()
	RegisterForModEvent("dhlp-maintenance", "maintenance")
endEvent

event OnObjectUnequipped(Form akBaseObject, ObjectReference akReference)
	unequipping = true
	if config.onlyUnarmed && ( akBaseObject as Weapon || akBaseObject as Spell || akBaseObject as Armor )
		util.checkForWeapons()
	endIf
	DisableFastTravel()
	unequipping = false	
endEvent

event OnObjectEquipped(Form akBaseObject, ObjectReference akReference)
	if config.onlyUnarmed && ( akBaseObject as Weapon || akBaseObject as Spell || akBaseObject as Armor )
		int timeout = 0
		while unequipping
			Utility.Wait(0.1)
			if timeout >= 30
				unequipping = false
				util.log("Unequipping timed out!", 1)
			endIf
			timeout += 1
		endWhile
		util.checkForWeapons()
		DisableFastTravel()
	endIf	
endEvent

Event OnCellLoad()
	DisableFastTravel()

	Utility.Wait(2.5) ; Wait a bit to allow everyone to load in 
	util.FindFollowers()
EndEvent

Event OnUpdateGameTime()
	
	If GetActorReference().WornHasKeyword(util.libs.zad_Lockable)
		If restrained
			WD_HoursRestrained.Mod(1)
		EndIf
		restrained = true
	Else
		restrained = false
	EndIf
	
	RegisterForSingleUpdateGameTime(1.0)
	
	If WD_HoursRestrained.GetValueInt() >= 150
		GetActorReference().RemoveSpell(weightPerk00)
		GetActorReference().AddSpell(weightPerk01, abVerbose = false)
		UnregisterForUpdateGameTime()
	ElseIf WD_HoursRestrained.GetValueInt() >= 75 && !GetActorReference().HasSpell(weightPerk00) && !GetActorReference().HasSpell(weightPerk01)
		GetActorReference().AddSpell(weightPerk00, abVerbose = false)
	EndIf
	
	If WD_HoursRestrained.GetValueInt() >= 150 && lvlupshown < 2
		WaitForCombatStop()
		lvlUpMsg01.show()
		lvlupshown += 1
	ElseIf WD_HoursRestrained.GetValueInt() >= 75 && lvlupshown < 1
		WaitForCombatStop()
		lvlUpMsg00.show()
		lvlupshown += 1
	EndIf
	
EndEvent

Event OnLocationChange(Location loc1, Location loc2)
	DisableFastTravel()
EndEvent

Function WaitForCombatStop()
	int timeout = 0
	While GetActorReference().GetCombatState() > 0 && timeout < 100
		Utility.Wait(4)
		timeout += 1
	EndWhile
EndFunction

Function DisableFastTravel()
	If ( config.noFast == 1 && util.pl.WornHasKeyword(util.libs.zad_lockable) ) || ( config.noFast == 2 && ( util.pl.WornHasKeyword(util.libs.zad_DeviousArmbinder) || util.pl.WornHasKeyword(util.libs.zad_DeviousBlindfold) ) )
		Game.EnableFastTravel(false)
		fastTravelOn = false
	ElseIf !util.pl.IsInInterior() && !fastTravelOn
		Game.EnableFastTravel(true)
		fastTravelOn = true
	EndIf
EndFunction

Event Maintenance(string eventName, string argString, float argNum, form sender)
	DisableFastTravel()
EndEvent
