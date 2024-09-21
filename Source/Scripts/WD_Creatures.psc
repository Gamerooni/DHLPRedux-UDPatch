Scriptname WD_Creatures extends Quest

import StorageUtil
import ActorUtil

WD_Util Property util auto
WD_Config Property config auto
SexLabFramework Property SexLab auto
zadLibs Property libs auto

Quest Property chestFinder Auto
Actor Property pl Auto
GlobalVariable Property WD_CreatureSceneRunning Auto
Faction Property HelplessFaction Auto
Faction Property SexlabFaction Auto

Package Property gatherPackage Auto
Package Property sandboxPackage Auto
Race Property DraugrRace Auto

ReferenceAlias Property bossChest Auto

string property creatureList = "dhlp-creatureList" auto hidden
string property creatureQueue = "dhlp-creatureQueue" auto hidden

WD_EscapeAlias Property EscapeAlias Auto
bool wearingArmbinder
bool wearingRustedBelt
bool wearingBelt
bool property raped auto hidden

int chaseTimeout = 0
float lastCreatureAdded = 0.0
bool stopping = false
float stopped = 0.0

bool function addCreature(Actor creature)

	if util.WD_SceneRunning.GetValueInt() == 1
		return false
	endIf

	if !SexLab.AllowedCreature(DraugrRace) || !util.AllowAdding()
		return false
	endIf
	
	While stopping
		Utility.Wait(1.0)
	EndWhile
	raped = false
	
	FormListAdd(none, creatureList, creature, false)
	FormListAdd(pl, creatureQueue, creature, false)
	int i = FormListCount(none, util.followerList)
;	Actor f
	while i > 0 
;		f = FormListGet(none, util.followerList, i) as Actor
		i -= 1
		FormListAdd(FormListGet(none, util.followerList, i), creatureQueue, creature, false)
;		util.log(creature.GetLeveledActorBase().GetName() + " queued for " + f.GetLeveledActorBase().GetName() + ".")
	EndWhile
	
	creature.ModAv("SpeedMult", util.GetRapistSpeedModifier())
	creature.BlockActivation(true)
	creature.AddToFaction(HelplessFaction)
	
	creature.StopCombatAlarm()
	creature.StopCombat()
	
	AddPackageOverride(creature, gatherPackage, 99)
	creature.EvaluatePackage()
	lastCreatureAdded = Utility.GetCurrentRealTime()
	util.log(creature.GetLeveledActorBase().GetName() + " added.")
	
	if GetState() != "SceneRunning" || stopped != 0.0
		stopped == 0.0
		EscapeAlias.ForceStop()
		EscapeAlias.clear()
		registerForSingleUpdate(2.0)
	endIf
	
	return true
endFunction

bool function removeCreature(Actor creature)
	if FormListRemove(none, creatureList, creature)
		FormListRemove(pl, creatureQueue, creature)
		int i = FormListCount(none, util.followerList)
		while i > 0
			FormListRemove(FormListGet(none, util.followerList, i), creatureQueue, creature)
			i -= 1
		endwhile
		creature.RemoveFromFaction(HelplessFaction)
		creature.ModAv("SpeedMult", util.GetRapistSpeedModifier(true))
		creature.BlockActivation(false)
		ClearPackageOverride(creature)
		util.log(creature.GetLeveledActorBase().GetName() + " removed.")
		return true
	endIf
	return false
endFunction

Event OnUpdate()
	if !IsRunning() || pl.IsInFaction(SexlabFaction)
		util.log("Can't start the scene.")
		return
	endIf
	
	if WD_CreatureSceneRunning.GetValueInt() == 0 && GetState() != "SceneRunning"
		pl.AddToFaction(HelplessFaction)
		pl.SetFactionRank(HelplessFaction, 100)
		CeaseFire()
		util.log("Starting creature scene")
		GoToState("SceneRunning")
	endIf
EndEvent

State SceneRunning
	Event OnBeginState()
		WD_CreatureSceneRunning.SetValueInt(1)
		chaseTimeout = 0
		RegisterForSingleUpdate(2.0)
	EndEvent
	
	Event OnUpdate()

		int num = FormListCount(pl, creatureQueue)
		
		if num == 0
			util.log("All creatures removed, stopping.")
			StopCreatureScene()
			return
		endIf
		
		bool closeEnough = false
		while num > 0
			num -= 1
			if pl.GetDistance(FormListGet(pl, creatureQueue, num) as Actor) < 280
				num = 0
				closeEnough = true
				util.log("Close enough!")
				StartCreaturePlayerRape(new actor[1])
				util.CleanFollowerList()
				util.AllowFollowerScenes()
				if config.followers && FormListCount(none, util.followerList) > 0
					util.RegisterForModEvent("Helpless_FollowerStart", "StartFollowerRape")
					SendModevent("Helpless_FollowerStart", "Creatures")
					util.RegisterForModEvent("HookAnimationEnd_HelplessFollower", "FollowerRapeEnd")
				endIf
			endIf
		endWhile
		if !closeEnough
			chaseTimeout += 1
			if chaseTimeout % 5 == 0
				util.log("Not close enough")
			endIf
			RegisterForSingleUpdate(2.0)
		endIf
		if chaseTimeout >= 30 ; 1min
			UnregisterForUpdate()
			util.log("Creatures chased player for a minute, stopping.")
			StopCreatureScene()
			GoToState("")
		endIf
	EndEvent
	
	Event OnEndState()
		libs.EnableEventProcessing()
		WD_CreatureSceneRunning.SetValueInt(0)
	EndEvent
EndState

function StartCreaturePlayerRape(Actor[] actors)
	util.log("StartCreaturePlayerRape()")
	
	Game.DisablePlayerControls()
	bool[] noStrip = new bool[33]
	bool[] doStrip = new bool[33]
	doStrip[0] = true ; head
	doStrip[2] = true ; body
	doStrip[5] = true ; amulet
	doStrip[9] = true ; shield
	doStrip[14] = true ; face/mouth
	doStrip[15] = true ; neck
	doStrip[16] = true ; chest
	doStrip[17] = true ; back
	doStrip[19] = true ; pelvis primary
	doStrip[22] = true ; pelvis secondary
	doStrip[25] = true ; face/jewelry
	doStrip[26] = true ; chest secondary
	doStrip[27] = true ; shoulder
	doStrip[32] = true ; weapons
	
	if actors[0] == none
		actors = getCreatures(pl)
		
		if actors[0] == none
			Debug.Notification("Deviously Helpless failed to start the scene.")
			Debug.Notification("See the log for more details.")
			util.log("Tried to start the creature scene, but initial getCreatures() returned nothing.", 2)
			Game.EnablePlayerControls()
			Debug.SendAnimationEvent(pl, "IdleCowering")
			StopCreatureScene()
			return
		endIf
		libs.DisableEventProcessing()
		util.WaitForDismount()
		SexLab.StripSlots(pl, doStrip)
		WireTransfer()
	
		If  config.stripArmbinder 
			util.ForceStripArmbinder(pl)
		EndIf
		
	;	If config.stripArmbinder && pl.GetItemCount(libs.armbinderRendered) > 0
	;		wearingArmbinder = true
	;		libs.ManipulateDevice(pl, libs.armbinder, false, false)
	;	EndIf
		
		DraugrBeltStrip()

	;	util.StealDelivery()
	endIf
	
	RegisterForModEvent("HookAnimationEnd_HelplessCreature", "CreatureRapeEnd")	
	
	sslThreadModel thread = SexLab.NewThread()
	int i = 0
	while i < actors.length
		thread.AddActor(actors[i])
		i += 1
	endWhile
	thread.SetStrip(pl, noStrip)
	thread.SetHook("HelplessCreature")
	thread.DisableLeadIn()
	thread.DisableBedUse(true)
	
	if thread.StartThread() == none
		util.log("SexLab failed to start the animation!", 2)
		ContinueCreatureScene()
	endIf
	i = actors.length
	while i > 1
		i -= 1
		FormListRemove(util, "dhlp-actorsInUse", actors[i], true)
	endWhile
endFunction

Actor[] function getCreatures(Actor target)
	util.log("getCreatures()")
	int num = FormListCount(target, creatureQueue)
	util.log("Found " + num + " creatures.")
	if num < 1
		util.log("No creatures, stopping.")
		return new Actor[1]
	endIf
	
	int maxNum
	if num > 4
		maxNum = 4
	else
		maxNum = num
	endIf
	
	util.log("Max number of creatures: " + maxNum)
	
	int aAmount = Utility.RandomInt(2, maxNum + 1)
	util.log("Starting scene for " + aAmount + " actors.")
	
	; Actor[] creatures = new Actor[size] ; WTF? Seriously, this doesn't work?!
	Actor[] creatures = new Actor[5]
	
	int iRes = 1
	int iCrea = 0
	creatures[0] = target
	int repeat = 2
	int maxDistance = 530
	if target == pl
		maxDistance = 380
	endIf
	util.lockActorFinderMutex()
	util.log("-- Building creature list ("+target.GetLeveledActorBase().GetName()+") ----------------------")
	while repeat > 0
		while iRes < aAmount && iCrea < num
			Actor c = FormListGet(target, creatureQueue, iCrea) as Actor
			float distance = target.GetDistance(c)
			If c && SexLab.ValidateActor(c) == 1 && FormListFind(util, "dhlp-actorsInUse", c) == -1 && !c.IsInFaction(SexlabFaction)
				util.log(iCrea + ": " + c.GetLeveledActorBase().GetName() + " at a distance of " + distance + ".")
				if distance < maxDistance && !c.IsDead()
					creatures[iRes] = c
					FormListAdd(util, "dhlp-actorsInUse", c, false)
					util.log("    added.")
					iRes += 1
				endIf
			EndIf
			iCrea += 1
		endWhile
		
		if target == pl && creatures[1] == none && FormListCount(target, creatureQueue) > 0 && FormListCount(none, util.followerList) > 0
			if repeat == 2
				util.log("Couldn't find creatures for player, stopping follower threads and trying again.", 1)
				; Couldn't find any actors for player, but there are more in the queue with followers around
				; stop any follower animations and try again
				util.StopAllFollowerThreads()
				iCrea = 0
				iRes = 1
				Utility.Wait(1.0)
			elseif repeat == 1
				util.log("Still no valid actors, stopping.")
			endIf
			repeat -= 1
		else
			repeat = 0
		endIf	
	endWhile
	util.log("-- Creature list done. ---------------------------------")
	util.unlockActorFinderMutex()
	
	if creatures[1] == none
		util.log("All creatures out of range.")
		return new Actor[1]
	endIf
	
	If iRes == 2 ; Avoid none references
		creatures = SexLab.MakeActorArray(creatures[0], creatures[1]) 
	ElseIf iRes == 3
		creatures = SexLab.MakeActorArray(creatures[0], creatures[1], creatures[2])
	ElseIf iRes == 4
		creatures = SexLab.MakeActorArray(creatures[0], creatures[1], creatures[2], creatures[3]) 
	ElseIf iRes == 5
		creatures = SexLab.MakeActorArray(creatures[0], creatures[1], creatures[2], creatures[3], creatures[4]) 
	EndIf
	
	int i = 1
	while i < creatures.length
		; Remove used creatures from queue
		FormListRemove(target, creatureQueue, creatures[i])
		i += 1
	endWhile
	return creatures
EndFunction

;Event CreatureRapeEnd(String eventName, String argString, float argNum, Form Sender)
Event CreatureRapeEnd(int thread, bool hasPlayer)
	util.log("CreatureRapeEnd()")

	If !hasPlayer
		return
	EndIf
	Debug.SendAnimationEvent(pl, "IdleCowering")
	Game.DisablePlayerControls() 

	UnregisterForModEvent("AnimationEnd_HelplessCreature")
	
	ContinueCreatureScene()
EndEvent

function ContinueCreatureScene()
	util.log("ContinueCreatureScene()")
	Actor[] creatures = GetCreatures(pl)
	If creatures[0] != None
		util.log("More creatures found, continuing scene")
		Utility.Wait(1.0)
		StartCreaturePlayerRape(creatures)
	Else
		stopping = true
		util.log("No more creatures, ending scene")
		
		raped = true
		
		If !pl.WornHasKeyWord(libs.zad_DeviousBelt) && ( wearingRustedBelt || wearingBelt || Utility.RandomInt() < 67 )
			pl.RemoveItem(util.beltRusted, 99, true) ; Remove old belts if any, to force the belt script to use the latest version
			pl.RemoveItem(util.rustyKey, 99, true)
			; If a belt was already worn, equip the rusted belt. Otherwise, 67% chance to equip it.
			if !pl.WornHasKeyWord(libs.zad_DeviousPlugAnal)
				util.ManipulateDevice(pl, util.plugWornAn, true)
			endIf
			if !pl.WornHasKeyWord(libs.zad_DeviousPlugVaginal)
				util.ManipulateDevice(pl, util.plugWornVag, true)
			endIf
			util.ManipulateDevice(pl, util.beltRusted, true)
			if !wearingRustedBelt
				; Don't show the "surprise, belt!" message if it's already familiar
				rustedBeltMsg.show()
			endIf
			libs.Moan(pl)
			util.log("Equipped a rusted belt.")
		endIf
		
		Armor binder = GetFormValue(pl, "dhlp-wornArmbinder") as Armor
		bool forceBinder = false
		If ( binder || Utility.RandomInt() <= 15 ) && !pl.WornHasKeyWord(libs.zad_DeviousArmbinder)
			If !binder  
				util.log("Gifted an armbinder.")
				binder = util.devman.GetPreferredDevice(libs.zad_DeviousArmbinder)
			EndIf
			libs.ManipulateGenericDevice(pl, binder, true, false)
			forceBinder = true
		EndIf

		if config.followers
			util.StopAllFollowerThreads()
			util.RegisterForModEvent("Helpless_FollowerRedress", "RedressFollowers")
			SendModEvent("Helpless_FollowerRedress")
		endIf
		
		wearingRustedBelt = false
		wearingBelt = false
		UnsetFormValue(pl, "dhlp-wornArmbinder")
		
		SandBoxCreatures()
		util.EquipFollowers(forceBinder)
		Debug.SendAnimationEvent(pl, "IdleForceDefaultState")
		util.SetFollowerAnimation()
		Game.EnablePlayerControls()
		EscapeAlias.ForceRefTo(pl)
		EscapeAlias.StartEscape(true, forceBinder)
		libs.EnableEventProcessing()
		stopped = Utility.GetCurrentRealTime()
		stopping = false
	;	Utility.Wait(Utility.RandomFloat(10.0, 45.0))
	;	If lastCreatureAdded < stopped
	;		StopCreatureScene()
	;	EndIf
	EndIf
endFunction

function SandBoxCreatures()
	int num = FormListCount(none, creatureList)
;	RemoveAllPackageOverride(gatherPackage) ; PapyrusUtil 2.3 crashes here for some reason, but not on the identical call in StopCreatureScene() later
	while num > 0
		num -= 1
		Actor creature = FormListGet(none, creatureList, num) as Actor
		AddPackageOverride(creature, sandboxPackage, 100)
		creature.EvaluatePackage()
	endWhile
endFunction

Function StopIfAble()
	If lastCreatureAdded < stopped
		stopped = 0.0
		lastCreatureAdded = 0.0
		StopCreatureScene()
	EndIf
EndFunction

function StopCreatureScene()
	util.log("StopCreatureScene()")
	EscapeAlias.ForceStop()
	EscapeAlias.Clear()
	int num = FormListCount(none, creatureList)
	while num > 0
		num -= 1
		Actor creature = FormListGet(none, creatureList, num) as Actor
		if creature
			creature.RemoveFromFaction(HelplessFaction)
			creature.ModAv("SpeedMult", util.GetRapistSpeedModifier(true))
			creature.BlockActivation(false)
			RemovePackageOverride(creature, gatherPackage)
			RemovePackageOverride(creature, sandboxPackage)
		;	ClearPackageOverride(creature)
		endIf
	endWhile
	num = FormListCount(none, util.followerList)
	while num > 0
		num -= 1
		Actor a = FormListGet(none, util.followerList, num) as Actor
		FormListClear(a, creatureQueue)
		a.RemoveFromFaction(HelplessFaction)
	endwhile
;	RemoveAllPackageOverride(gatherPackage)
;	RemoveAllPackageOverride(sandboxPackage)
	FormListClear(none, creatureList)
	FormListClear(pl, creatureQueue)
	pl.RemoveFromFaction(HelplessFaction)
	
	GoToState("")
endFunction

function DraugrBeltStrip()
	; No chastity friendly animations with creatures really, so strip regardless of user setting 
	bool skipMsg = false
	
	if pl.GetItemCount(util.beltRustedRendered) > 0
	;	util.ManipulateDevice(pl, util.beltRusted, false, false)
		libs.LockDevice( pl, util.beltRusted )
		wearingRustedBelt = true
		skipMsg = true ; Draugr manage to open their own belt without any issues
	endIf
	
	if pl.WornHasKeyWord(libs.zad_DeviousBelt) ; && Utility.RandomInt() < 60
		if pl.GetItemCount(libs.beltIronRendered) > 0
			libs.ManipulateDevice(pl, libs.beltIron, false, false)
			pl.RemoveItem(libs.beltIron, 1, true)
		ElseIf pl.GetItemCount(libs.beltPaddedRendered) > 0
			libs.ManipulateDevice(pl, libs.beltPadded, false, false)
			pl.RemoveItem(libs.beltPadded, 1, true)
		ElseIf pl.GetItemCount(libs.beltPaddedOpenRendered) > 0
			libs.ManipulateDevice(pl, libs.beltPaddedOpen, false, false)
			pl.RemoveItem(libs.beltPaddedOpen, 1, true)
		ElseIf pl.GetItemCount(libs.harnessBodyRendered) > 0
			libs.ManipulateDevice(pl, libs.harnessBody, false, false)
			pl.RemoveItem(libs.harnessBody, 1, true)
		ElseIf pl.WornHasKeyWord(libs.zad_DeviousBelt)
			Armor genericBelt = libs.GetWornDeviceFuzzyMatch(pl, libs.zad_DeviousBelt)
			If libs.ManipulateGenericDevice(pl, genericBelt, false, false)
				pl.RemoveItem(genericBelt, 1, true)
			EndIf
		EndIf
		
		if !pl.WornHasKeyWord(libs.zad_DeviousBelt)
			wearingBelt = true
		endIf		
	elseif !pl.WornHasKeyWord(libs.zad_DeviousBelt)
		skipMsg = true ; No belt in the first place, don't show messages regarding it
	endIf
	
	
	if !pl.WornHasKeyWord(libs.zad_DeviousBelt)
		util.StripWornPlugs(pl) ; apparently it should be possible to wear plugs without any belts
	endIf
	
	if !skipMsg
		if wearingBelt
			util.notify("With inhuman strength, the Draugr rip the belt from you, breaking it in the process.")
		else
			util.notify("Despite their strength, the draugr fail to rip your chastity belt off.")
		endIf
	endIf
endFunction

function WireTransfer()
	; Moves the players gold to the dungeon boss chest
	; If not available, the gold is gone
	if !config.stealGear
		return
	endIf
	
	chestFinder.start()
	
	int amount = pl.GetItemCount(util.gold) - 50
	if amount < 0
		amount = 0
	endIf
	
	pl.RemoveItem(util.gold, ( amount as float * Utility.RandomFloat(0.1, 0.5) ) as int, true)
	amount = pl.GetItemCount(util.gold) - 50
	if amount < 0
		amount = 0
	endIf
	
	pl.RemoveItem(util.gold, amount, true, bossChest.GetReference())

	if amount > 0
		util.notify("Your pockets feel significantly lighter.")
	endIf
	
	chestFinder.stop()
endFunction

Function CeaseFire()
	pl.StopCombatAlarm()
	pl.StopCombat()
	int i = FormListCount(none, creatureList)
	While i > 0
		i -= 1
		Actor creature = FormListGet(none, creatureList, i) as Actor
		creature.StopCombatAlarm()	
		creature.StopCombat()
	EndWhile
EndFunction
