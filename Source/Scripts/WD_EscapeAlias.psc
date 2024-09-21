Scriptname WD_EscapeAlias extends ReferenceAlias

WD_Util Property util Auto
WD_Creatures Property creatureQuest Auto
String Property listName Auto

int tick = 0 
bool creature = false

Function StartEscape(bool creatures = false, bool armbinder = false)
	util.log("Starting daring escape.")
	creature = creatures
;	If !armbinder 
;		util.libs.LockDevice(util.libs.PlayerRef, util.libs.armbinder, force = true)
;	EndIf
	tick = 0
	RegisterForSingleUpdate(10)
EndFunction

Event OnUpdate()
	int numRapists = StorageUtil.FormListCount(none, listName)
	
	If numRapists == 0
		util.log("Rapist list is empty, stopping.")
		BreakFree(true)
		return
	EndIf
	
	If tick >= 6 ; Wait max of 1 min and break free anyway
		util.log("Ending escape after 1 minute.")
		BreakFree(true)
		return
	EndIf	
	
	int num = 0
	int i = 0
	Actor rapist
	While i < numRapists
		rapist = StorageUtil.FormListGet(none, listName, i) as Actor
		If rapist && ( rapist.GetWorldSpace() != GetActorReference().GetWorldSpace() || GetActorReference().GetDistance(rapist) > 6000 )
			num += 1
		EndIf
		i += 1	
	EndWhile
	
	If num == numRapists
		util.log("All rapists are out of range, stopping.")
		BreakFree()
	Else
		tick += 1
		RegisterForSingleUpdate(10)
	EndIf	
EndEvent

Function BreakFree(bool force = false)
	Utility.Wait(Utility.RandomFloat(2.0, 15.0))
	If !creature
		If force
			util.StopSceneAndClear()
		Else
			util.StopIfAble()
		EndIf
	Else
		If force
			creatureQuest.StopCreatureScene()
		Else
			creatureQuest.StopIfAble()
		EndIf
	EndIf
EndFunction

Function ForceStop()
	UnregisterForUpdate()
	clear()
EndFunction
