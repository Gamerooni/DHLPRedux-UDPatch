Scriptname WD_util extends Quest Conditional

import StorageUtil
import ActorUtil

Actor Property pl Auto
Spell Property cloakSpell Auto
Spell Property cloakApplySpell Auto
GlobalVariable Property WD_CreatureSceneRunning Auto
GlobalVariable Property WD_SceneRunning Auto
GlobalVariable Property WD_Chasing Auto
GlobalVariable Property WD_Raped Auto
SexLabFramework Property Sexlab Auto
Faction Property SexlabFaction Auto
Faction Property HelplessFaction Auto 	; Friend to all attacker factions, player is added to this during scenes
											; And actually named wd_tmpPlayerFaction, nothing more permanent than temporary fixes :P
Faction Property CurrentFollowerFaction Auto
Faction Property HirelingFaction Auto
Keyword Property actorTypeNPC auto
GlobalVariable Property PlayerFollowerCount Auto
zadLibs Property libs Auto
slaFrameworkScr Property aroused Auto
zadArmbinderQuestScript Property armbinderQuest auto
WD_Config Property config Auto
WD_Compatibility Property compat Auto
WD_DeviceManager Property devman Auto
WD_Creatures Property creatureQuest Auto
GlobalVariable Property WD_PlayerHasWeaponEquipped Auto
GlobalVariable Property WD_SuspendScenes Auto

string property followerList	= "dhlp-followers"		auto hidden
string property stealList		= "dhlp-itemsToSteal"	auto hidden
string property pacifier		= "dhlp-pacifier"			auto hidden
string property keywordList		= "dhlp-keywords"			auto hidden
string property rapistList		= "dhlp-rapists"			auto hidden
string property rapeQueue		= "dhlp-rapistQueue"		auto hidden
string property followerThreads = "dhlp-followerThreads"	auto hidden

Package Property attackChasePackage auto
Package Property approachPackage	auto
Package Property gatherPackage		auto
Package Property sandboxPackage		auto

GlobalVariable Property WD_Debug Auto

Keyword Property vampireKeyword Auto
MagicEffect Property vampireDisease Auto
MagicEffect Property WDVampireDisease Auto
Spell Property vampirism Auto

Light Property torch Auto
MiscObject Property gold Auto
Keyword Property zad_InventoryDevice Auto
GlobalVariable property stealGear Auto

Armor Property plugWornVag Auto
Armor Property plugWornVagRendered Auto
Armor Property plugWornAn Auto
Armor Property plugWornAnRendered Auto

WD_EscapeAlias Property EscapeAlias Auto

Topic Property dialogue Auto
GlobalVariable Property dialogueID Auto ; Meh, not the best way to do it
; 1 = steal gold, poor, multiple attackers
; 2 = steal gold, poor, single attacker
; 3 = steal gold, rich, multple attackers
; 4 = steal gold, rich, single attacker
; 5 = player gets an armbinder as a parting gift
; 6 = scene start
; 7 = scene end

bool Property raped = false Auto Conditional Hidden
int chaseTimeout = 0

float lastRapistAdded = 0.0
Armor wornBelt = none
Armor[] wornPlugs = none
bool hasAllowedGender = false

bool rapistHasKey = false
bool rapistHasCustomKey = false
bool doInvCheck = false
Key customKey = none
bool keyCheckDone = false
bool checkingKey = false

Form[] wornItems = none

float lastWearCheck = 0.0
bool lastWearResult = false
bool wearCheckMutex = false
bool actorFinderMutex = false
bool clearing = false
bool allowFollowers = false
bool stopping = false
float stopped = 0.0 	; In use during the grace period after the scene, indicates when the grace period started

bool[] noStrip
bool[] doStrip

; -------------------------------------
; Public interface functions
; -------------------------------------

bool Function IsSceneRunning()
	; Can do this also with Game.GetFormFromFile() without needing to have this script around when compiling
	return pl.IsInfaction(HelplessFaction)
EndFunction

; Temporarily prevents scenes from starting, remember to reset with ResumeScenes() after your mod is done
; 5s window to call this after every game load before the setting is automatically reset

; Same can be done with modevents, so this script isn't needed during compiling. SendModEvent("dhlp-Suspend")
Function SuspendScenes()
	log("Suspending scenes")
	WD_SuspendScenes.SetValueInt(1)
	SetIntValue(none, "dhlp-suspending", 1)
EndFunction

; Resumes normal function and removes the scene suspension
; Same can be done with modevents, so this script isn't needed during compiling. SendModEvent("dhlp-Resume")
Function ResumeScenes()
	log("Resuming scenes")
	WD_SuspendScenes.SetValueInt(0)
	SetIntValue(none, "dhlp-suspending", 0)
EndFunction

bool Function IsSuspended()
	return WD_SuspendScenes.GetValueInt() == 1
EndFunction

float Function GetVersion()
	return 1.1503
EndFunction

String Function GetVersionString()
	return "1.0 rc"
EndFunction

Event SuspendScenesEvent(String eventName, String argString, float argNum, Form Sender)
	log("Suspending scenes, called from: " + Sender + ", (" + Sender.GetName() + ")")
	WD_SuspendScenes.SetValueInt(1)
	SetIntValue(none, "dhlp-suspending", 1)
EndEvent 

Event ResumeScenesEvent(String eventName, String argString, float argNum, Form Sender)
	log("Resuming scenes, called from: " + Sender + ", (" + Sender.GetName() + ")")
	WD_SuspendScenes.SetValueInt(0)
	SetIntValue(none, "dhlp-suspending", 0)
EndEvent

;/
To force player drop her weapons or spells, use a custom mod event named "dhlp-weapondrop", with these parameters:
bool both, float chanceMult, String weaponMsg, String magicMsg

both - drop weapons in both hands? If false, only left is dropped
chanceMult - multiplier for spell drop chance, the base chance is calculated from arousal and current magicka
weaponMsg - message shown if weapons are dropped
magicMsg - message shown if spells are unequipped

For help how to construct a custom modevent, see the documentation in ModEvent.psc

/;

; -------------------------------------
; End public functions
; -------------------------------------

function Maintenance()
	RegisterForModEvent("dhlp-Suspend", "SuspendScenesEvent")
	RegisterForModEvent("dhlp-Resume", "ResumeScenesEvent")
	RegisterWeaponDrop()
	lastWearCheck = Utility.GetCurrentRealTime() - 90 ; Make sure the last check doesn't carry over from a previous game session
	Utility.Wait(5)
	If GetIntValue(none, "dhlp-suspending") >= 1
		SetIntvalue(none, "dhlp-suspending", 0)
	Else
		WD_SuspendScenes.SetValueInt(0)
	EndIf
	If WD_SuspendScenes.GetValueInt() == 1
		log("Scenes are currently suspended")
	EndIf
endFunction

Function RegisterWeaponDrop()
	if config.dropWeapons
		RegisterForModEvent("DeviceVibrateEffectStart", "OnVibrate")
		RegisterForModEvent("DeviousEventBlindfold Trip", "OnBlindfoldTrip")
		RegisterForModEvent("dhlp-weapondrop", "CustomWeaponDrop")
	else
		UnregisterForModEvent("DeviceVibrateEffectStart")
		UnregisterForModEvent("DeviousEventBlindfold Trip")
		UnregisterForModEvent("dhlp-weapondrop")
	endIf
EndFunction

function UpdateMaintenance()
	Maintenance()
	noStrip = new bool[33]
	doStrip = new bool[33]
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
endFunction

bool function allowAdding()
	lockWearMutex() ; Wait if a check has already started
	float currentTime = Utility.GetCurrentRealTime()
	If currentTime - lastWearCheck > 15.0 ; Check only every 15s if player is wearing needed items
		lastWearCheck = currentTime		  ; Hopefully comparing the time is faster than looping through the keyword list
		lastWearResult = true
		
		;If compat.SubmitSurrender ; If submit is installed, make sure we're not breaking any scenes from it
		;	lastWearResult = compat.SubmitSurrender.GetValue() == 0 && compat.SubmitBound.GetValue() == 0 && compat.SubmitBleedOut.GetValue() == 0
		;	; This might happen with unarmed only enabled when surrendering through submit and while wearing DD items
		;	; If unarmed only is disabled, helpless most likely triggers long before any surrendering
		;	If !lastWearResult
		;		log("Submit running: " + compat.SubmitSurrender.GetValue() + ", " + compat.SubmitBound.GetValue() +", " + compat.SubmitBleedOut.GetValue())
		;	EndIf
		;endIf
		
		if compat.DefeatFaction && lastWearResult
			; Possibly need to check followers in the faction as well?
			lastWearResult = lastWearResult && !pl.IsInFaction(compat.DefeatFaction)	
			If !lastWearResult
				log("Defeat running : " + pl.IsInFaction(compat.DefeatFaction))
			EndIf
		endIf
		
	;	lastWearResult = ( IsPlayerWearingDevice() || WD_SceneRunning.GetValueInt() == 1 || WD_CreatureSceneRunning.GetValueInt() == 1 ) && !pl.IsBleedingOut()
		lastWearResult = lastWearResult && ( IsPlayerWearingDevice() || WD_SceneRunning.GetValueInt() == 1 || WD_CreatureSceneRunning.GetValueInt() == 1 ) && !pl.IsBleedingOut()
		
		if !lastWearResult
			log("allowAdding() returning false, not starting a scene.")
		endIf
;	Else
;		log("Skipping starting checks: " + currentTime + " - " + lastWearCheck)
	EndIf
	wearCheckMutex = false
	return lastWearResult
endFunction

bool Function AddRapist(Actor akActor)
	log("AddRapist()")
	; returns true if adding succeeded
	
	If WD_CreatureSceneRunning.GetValueInt() == 1 || !allowAdding()
		return false
	endIf

	if akActor.HasKeyword( Keyword.GetKeyword( "AcheronDefeated" ) )
		log("Acheron Defeated actor, aborting")
		return false
	endIf

	int stoppingTimeout = 40 ; wait max 20s
	while stopping && stoppingTimeout > 0; let the previous scene finish cleanly until adding more rapists
		if stoppingTimeout == 40
			log("Waiting for previous scene to finish...")
		endIf
		stoppingTimeout -= 1
		Utility.Wait(0.5)
	endwhile
	
	raped = false
	WD_Raped.SetValueInt(0)
	
	If config.allowedGender > 0 && !hasAllowedGender
		; GetSex(): -1 = none, 0 = male, 1 = female
		; Config: 0 = both, 1 = male, 2 = female
		if akActor.GetLeveledActorBase().GetSex() != config.allowedGender - 1
			log("Attacker is the wrong sex, skipping")
			return false
		elseif akActor.GetLeveledActorBase().GetSex() == config.allowedGender - 1
			hasAllowedGender = true
			SendModEvent("Helpless_Retry") ; Removes the magic effect from the skipped actors, allowing them to be added again
			log("Attacker is of the allowed sex, adding")
		endIf
	endIf
	
	if FormListFind(none, rapistList, akActor) != -1
		log(akActor.GetLeveledActorBase().GetName() + " already listed!", 1)
		return false
	endif

	lastRapistAdded = Utility.GetCurrentRealTime()
	FormListAdd(none, rapistList, akActor, false)
	FormListAdd(pl, rapeQueue, akActor, false)
	if config.followers
		int npcIdx = FormListCount(none, followerList)
		while npcIdx > 0
			npcIdx -= 1
			FormListAdd(FormListGet(none, followerList, npcIdx), rapeQueue, akActor, false)
		endwhile
	endIf
	
	akActor.AddToFaction(HelplessFaction)
	
	log(akActor.GetLeveledActorBase().GetName() + " slotted.")
	
	AddPackageOverride(akActor, attackChasePackage, 0) ;Slorm - line kept for backward compatibily
	AddPackageOverride(akActor, approachPackage, 99)
	AddPackageOverride(akActor, gatherPackage, 98)
	AddPackageOverride(akActor, sandboxPackage, 97)
	
	akActor.EvaluatePackage()
	
	;native check
	if config.PyU
		PyramidUtils.SetActorCalmed(akActor, true)
	else
		akActor.StopCombat() 
		akActor.StopCombatAlarm()
	endif

	akActor.ModAv("SpeedMult", GetRapistSpeedModifier()) ; Make sure they catch the player
	akActor.BlockActivation(true)
	If !keyCheckDone && config.requireKeys
		customKey = GetCustomWornBeltKey() ; returns none if the key is the generic one
		keyCheckDone = true
		checkingKey = false
	EndIf
	if akActor.GetItemCount(libs.chastityKey) > 0
		log(akActor.GetLeveledActorBase().GetName() + " has a key!")
		rapistHasKey = true
	endIf
	if customKey && akActor.GetItemCount(customKey) > 0
		log(akActor.GetLeveledActorBase().GetName() + " has a custom key!")
		rapistHasCustomKey = true
	endIf
	if GetState() != "SceneRunning" || stopped != 0.0
		RegisterForSingleUpdate(2.0) ; Wait 2s and see how many rapists have been added
		EscapeAlias.ForceStop()
		EscapeAlias.Clear()
		stopped = 0.0
	endif
	return true
EndFunction

bool Function RemoveRapist(Actor akActor)
	if FormListFind(none, rapistList, akActor) != -1
		FormListRemove(none, rapistList, akActor, allInstances = true)
		FormListRemove(pl, rapeQueue, akActor, allInstances = true)
		int i = FormListCount(none, followerList)
		while i > 0
			i -= 1
			FormListRemove(FormListGet(none, followerList, i), rapeQueue, akActor, allInstances = true)
		endWhile
		akActor.ModAv("SpeedMult", GetRapistSpeedModifier(true))
		akActor.BlockActivation(false)
		akActor.RemoveFromFaction(HelplessFaction)
		ClearPackageOverride(akActor)
		log(akActor.GetLeveledActorBase().GetName() + " removed from rapist list.")
		return true
	endIf
	return false
EndFunction

Event OnUpdate()
	log("OnUpdate()")
	If lastRapistAdded == 0 || !IsRunning() || pl.IsInFaction(SexlabFaction)
		log("Can't start scene")
		return
	EndIf
	
	If Utility.GetCurrentRealTime() - lastRapistAdded >= 1.5 && WD_SceneRunning.GetValueInt() == 0
		lastRapistAdded = 0.0
		log("Starting scene")
		pl.AddToFaction(HelplessFaction)
		pl.SetFactionRank(HelplessFaction, 100)
		CeaseFire()
		dialogueID.SetValueInt(6)
		getClosestRapist(pl).say(dialogue)
		dialogueID.SetValueInt(0)
		GoToState("SceneRunning")
		CleanFollowerList()
	EndIf	
EndEvent

State SceneRunning	
	Event OnBeginState()
		log("Begin state SceneRunning")
		UnregisterForUpdate()
		WD_SceneRunning.SetValueInt(1)
		chaseTimeout = 0
		RegisterForSingleUpdate(2.0)
	EndEvent
	
	Event OnUpdate()
		int num = FormListCount(pl, rapeQueue)
		
		if num == 0
			log("No attackers left on queue, stopping.")
			StopSceneAndClear()
			return
		endIf
		
		bool closeEnough = false
		while num > 0
			num -= 1
			Actor rapist = FormListGet(pl, rapeQueue, num) as Actor
			If (rapist).GetDistance(pl) < 300 && ( config.allowedGender == 0 || rapist.GetLeveledActorBase().GetSex() == config.allowedGender - 1 )
				log("Attackers close enough, starting scene")
				Game.SetPlayerAIDriven(true)			
				;native check
				Debug.SendAnimationEvent(pl, "IdleCowering")
				WD_Chasing.SetValueInt(0)
				closeEnough = true
				num = 0 ; break
				allowFollowers = true
				chaseTimeout = 0
				StartPlayerRape(new actor[1])
				if config.followers && FormListCount(none, followerList) > 0
					RegisterForModEvent("Helpless_FollowerStart", "StartFollowerRape")
					SendModevent("Helpless_FollowerStart", "Humans")
					RegisterForModEvent("HookAnimationEnd_HelplessFollower", "FollowerRapeEnd")
				endIf
			endIf
		endWhile
		
		if !closeEnough
			chaseTimeout += 1
			if chaseTimeout % 5 == 0
				log("Not close enough")
			endIf
			RegisterForSingleUpdate(2.0)
		endIf
		
		if chaseTimeout >= 30
			UnregisterForUpdate()
			chaseTimeout = 0
			notify("Attackers gave up after a minute chase!")
			log("Attackers gave up after a minute chase!")
			StopSceneAndClear()
			GoToState("")
		endIf
	EndEvent
	
	Event OnEndState()
		WD_SceneRunning.SetValueInt(0)
		WD_Chasing.SetValueInt(1)
		log("End state SceneRunning")
	EndEvent
EndState

Event InventoryCheck(string eventName, string argString, float argNum, form sender)
	UnregisterForModEvent("Helpless_inventorycheck")
	log("InventoryCheck()")
	devman.SplitItems(pl)
	devman.StoreInventory(pl)
EndEvent

Function CeaseFire()
	;native check
	if config.PyU ;we got native 
		PyramidUtils.SetActorCalmed(pl, true)
		
		int i = FormListCount(none, rapistList)
		Actor a
		while i > 0
			i -= 1
			a = FormListGet(none, rapistList, i) as Actor
		if a
			PyramidUtils.SetActorCalmed(a, true)
		endIf
		endWhile	
		
	else ;no native plugin, let's do it the legacy way
	
	pl.StopCombatAlarm()
	pl.StopCombat()
	
	int i = FormListCount(none, rapistList)
	Actor a
	while i > 0
		i -= 1
		a = FormListGet(none, rapistList, i) as Actor
		if a
			a.StopCombatAlarm() 
			a.StopCombat()
		endIf
	endWhile
	endif
EndFunction

Actor[] Function GetActors(Actor target)
	; Returns an actor array to use with sexlab
	; includes player and one or two enemies within 350 units of player.
	; Returns an empty array if not enough enemies are found
	log("GetActors(" + target.GetLeveledActorBase().GetName() + ")")
	int numRapists = FormListCount(target, rapeQueue)

	log("Found " + numRapists + " actors")
	
	If numRapists == 0
		return new Actor[1]
	EndIf
	
	Actor[] res
	
	If numRapists >= 3 && !target.WornHasKeyword(libs.zad_DeviousBelt) && !target.WornHasKeyword(libs.zad_DeviousHeavyBondage) && Utility.RandomInt(0, 99) < 40
		res = new Actor[4] ; 4-way scenes!
	ElseIf numRapists >= 2 && !target.WornHasKeyword(libs.zad_DeviousBelt) && !target.WornHasKeyword(libs.zad_DeviousHeavyBondage) && Utility.RandomInt(0, 99) < 40
		res = new Actor[3]
	Else
		res = new Actor[2]
	EndIf
	int i = 0
	int iResult = 1
	res[0] = target
	int repeat = 2
	int maxDistance = 530
	if target == pl
		maxDistance = 380
	endIf
	lockActorFinderMutex()
	log("-- Building actor list (" + target.GetLeveledActorBase().GetName() + ") -------------------------------------------------")
	While repeat > 0
		While i < FormListCount(target, rapeQueue) && iResult < res.Length
			Actor currentActor = FormListGet(target, rapeQueue, i) as Actor
			If currentActor && SexLab.ValidateActor(currentActor) == 1 && FormListFind(self, "dhlp-actorsInUse", currentActor) == -1 && !currentActor.IsInFaction(SexlabFaction)
				float distance = currentActor.GetDistance(target)
				log(i + ": " + currentActor.GetLeveledActorBase().GetName() + " at a distance of " + distance )
				If distance < maxDistance && ( config.allowedGender == 0 || currentActor.GetLeveledActorBase().GetSex() == config.allowedGender - 1 )
					; Check that actors are close enough to player to prevent them just from teleporting
					; And if male attackers only is enabled, check their gender
					FormListAdd(self, "dhlp-actorsInUse", currentActor, false)
					res[iResult] = currentActor
					iResult += 1
					log("    added.")
				EndIf
			ElseIf currentActor == none
				log("Found a none actor in the queue at " + i + "!", 1)
				FormListRemoveAt(target, rapeQueue, i)
			EndIf
			i += 1
		EndWhile
		
		if target == pl && res[1] == none && FormListCount(target, rapeQueue) > 0 && FormListCount(none, followerList) > 0
			if repeat == 2
				log("Couldn't find actors for player, stopping follower threads and trying again.", 1)
				; Couldn't find any actors for player, but there are more in the queue with followers around
				; stop any follower animations and try again
				StopAllFollowerThreads()
				i = 0
				iResult = 1
				Utility.Wait(2.5)
			elseif repeat == 1
				log("Still no valid actors, stopping.")
			endIf
			repeat -= 1
		else
			repeat = 0
		endIf		
	endWhile
	actorFinderMutex = false
	log("-- Actor list done. ------------------------------------------------------------")
	If res[1] == None
		log("No more valid actors, ending scene")
		return new Actor[1]
	EndIf
	
	If res.length == 4 && res[3] == None
		; Tried to start 4 way, but 4rd actor is out of range
		Actor[] tmp2 = new Actor[3]
		tmp2[0] = target
		tmp2[1] = res[1]
		tmp2[2] = res[2]
		res = tmp2
	EndIf
	
	If res.length == 3 && res[2] == None
		; Tried to start 3 way, but 3rd actor is out of range
		Actor[] tmp = new Actor[2]
		tmp[0] = target
		tmp[1] = res[1]
		res = tmp
	EndIf
	
	i = 0
	While i < res.Length
		; Remove the used actors from the queue
		FormListRemove(target, rapeQueue, res[i], true)
		i += 1
	EndWhile
	
	return res
EndFunction

Function StartPlayerRape(Actor[] actors)
	log("StartPlayerRape()")
	Game.SetPlayerAIDriven(true)
		
	If actors[0] == None
		actors = GetActors(pl)	; GetActors should only be called here on the scene start, after that
								; the actor checks are done in RapeEnd() to decide whether to continue or not
		If actors[0] == None
			Debug.Notification("Deviously Helpless failed to start the scene.")
			Debug.Notification("See the log for more details.")
			log("Tried to start scene, but initial GetActors() returned nothing.", 2)
			Game.SetPlayerAIDriven(false)
			StopSceneAndClear()
			return
		EndIf
		; Disable periodic device events
		libs.DisableEventProcessing()
		; Dismount if needed
		WaitForDismount()
		; Steal player keys if she has any, only check this on the inital attack
		RemoveKeys()
		; Steal gear if needed
		StealGoldAndGear()
		; Steal delivery from Captured Dreams
		;StealDelivery()
		
		If config.overrideStrip
			wornItems = SexLab.StripSlots(pl, doStrip) ; Strip the player only on the initial attack, and leave her that way until the end
		Else
			wornItems = SexLab.StripActor(pl, VictimRef=pl, DoAnimate=false, LeadIn=false)
		EndIf 
		doInvCheck = true 
	EndIf
	

	bool agg = true
	If actors.Length > 2 || !config.onlyAggressive
		; No 3 way aggressive animations by default, workaround for that
		agg = false
	EndIf

	If  config.stripArmbinder 
		ForceStripArmbinder(pl)
	EndIf
	
	; Remove worn belt if needed
	If pl.WornHasKeyword( libs.zad_DeviousBelt )
		StripBelt()
	EndIf
	
	if config.randomEquip && doInvCheck
		RegisterForModEvent("Helpless_inventorycheck", "InventoryCheck")
		SendModEvent("Helpless_inventorycheck")
		doInvCheck = false
	endIf
	
	If  pl.WornHasKeyword(libs.zad_DeviousHeavyBondage)
	
		sslBaseAnimation[] SAnims = libs.SelectValidDDAnimations( actors, 2, agg )
		
			If Sanims.Length <= 0
				log("DD failed to find the animation, stripping the arm bindings", 2)
				ForceStripArmbinder(pl)
			EndIf
		
		RegisterForModEvent("HookAnimationEnd_Helpless", "RapeEnd")			
		libs.StartValidDDAnimation( SexActors = actors, includetag = "", suppresstag = "foreplay", victim = pl, hook = "Helpless" ) 	
		
	else	
	
		sslBaseAnimation[] anims = GetAnimations(pl, actors.Length, agg)
		RegisterForModEvent("HookAnimationEnd_Helpless", "RapeEnd")	
		SexLab.StartSex(actors, anims, pl, none, none, "Helpless") 
		
	endif
		
	int tid = SexLab.FindActorController(pl)
	sslThreadController controller = SexLab.GetController(tid)
	
	if controller == none
		; Animation failed to start
		log("SexLab failed to start the animation!", 2)
		controller.EndAnimation()
		ContinueScene() ; Try to continue normally with other actors, or end normally if no more actors	
	Else
		; Check that attacker is a vampire, player isn't, and that the player doesn't have the disease already from vanilla, this or submit
		if actors[1].HasKeyword(vampireKeyword) && !pl.HasKeyword(vampireKeyword) && !pl.HasMagicEffect(vampireDisease) && !pl.HasMagicEffect(WDVampireDisease) ;&& ( !compat.SLVampireDisease || !pl.HasMagicEffect(compat.SLVampireDisease) )
		RegisterForModEvent("HookOrgasmStart_Helpless", "Orgasm")
		endIf
	EndIf
	
	int i = actors.length
	while i > 1
		i -= 1
		FormListRemove(self, "dhlp-actorsInUse", actors[i], true)
	endWhile
	
EndFunction

bool Function ForceStripArmbinder(Actor akActor)
	log("Trying to force-strip armbinder")
	; returns true if succeeded
	If akActor.WornHasKeyword(libs.zad_DeviousHeavyBondage)
		Armor binder = libs.GetWornDeviceFuzzyMatch(akActor, libs.zad_DeviousHeavyBondage)
		;If binder
	;		int disableStruggle = 0
	;		If armbinderQuest.DisableStruggle && akActor == pl
	;			disableStruggle = 1
	;		EndIf
			If libs.UnlockDeviceByKeyword(akActor, libs.zad_DeviousHeavyBondage, false ); libs.ManipulateGenericDevice(akActor, binder, false, false, true) 
				SetFormValue(akActor, "dhlp-wornArmbinder", binder)
		;		If akActor == pl
		;			SetIntValue(akActor, "dhlp-wornArmbinderStruggle", disableStruggle)
		;		EndIf
				return true
			EndIf
		;EndIf
	EndIf
	return false
EndFunction

sslBaseAnimation[] function GetAnimations(Actor akActor, int count, bool aggressive, bool skipRetry = false)
	; Try to minimize the shuffling needed to be done by DDi
	; and suppress the couple of non-fitting Zaz animations
	
	; Basically try to include everything possible in the non-aggressive version, apart from the couple supressed ones
	String tags = "Footjob,Handjob,"
	String suppress = "SubSub,Pillory,Cuddling,"
	If !skipRetry && aggressive
		suppress += "Handjob,Footjob,"
	EndIf
	bool requireAll = false
	If count > 2
		log("Getting "+count+"-way animations for " + akActor.GetLeveledActorBase().GetName() + ".")
		return SexLab.GetAnimationsByType(count)
	endIf
	
	if (akActor.WornHasKeyword(libs.zad_DeviousBelt))
		if (akActor.WornHasKeyword(libs.zad_permitAnal))
			tags += "Anal,"
		else
			suppress += "Anal,"
		endIf
		suppress += "Vaginal,Fisting,"
	else
		tags += "Vaginal,Anal,"	
	endIf
	
	if (!akActor.WornHasKeyword(libs.zad_DeviousGag) || akActor.WornHasKeyword(libs.zad_permitOral))
		tags += "Oral,"
	else
		suppress += "Oral,"
	endIf
	
	if (akActor.WornHasKeyword(libs.zad_DeviousBra))
		suppress += "Boobjob,"
	else
		tags += "Boobjob,"
	endIf
	
;	if akActor.WornHasKeyword(libs.zad_DeviousHeavyBondage) && !skipRetry
;		; If player is bound, get only the bound anims
;		; Skip this when retrying, to prevent getting no animations with custom armbinders, if no bound animations are installed
;		tags = "Armbinder"
;		requireAll = true
;	elseIf aggressive
;		; If aggressive, only look for it
;		tags = "Aggressive"
;		suppress += "DomSub"
;		requireAll = true
;	else 
;		suppress += "DomSub"
;	endIf
	
		
	log("Getting animations for " + akActor.GetLeveledActorBase().GetName() + " with tags: " + tags + " suppressing: " + suppress)
	sslBaseAnimation[] ret = SexLab.GetAnimationsByTags(count, tags, suppress, requireAll) 
	
;	if (ret == none || ret[0] == none) && akActor.WornHasKeyword(libs.zad_DeviousHeavyBondage) && !skipRetry
	;	if akActor.GetItemCount(libs.armbinderRendered) > 0
;		If ForceStripArmbinder(akActor)
;		;	libs.ManipulateDevice(akActor, libs.armbinder, false)
;			log("No bound animations found, forcing strip and trying again!", 1)
;		;	SetIntValue(akActor, "dhlp-wornArmbinder", 1)
;		else
;			log("No bound animations found, while wearing a generic blocked armbinder. Retrying animation fetch, ignoring the armbinder.", 1)
;		endIf
;	;	config.stripArmbinder = true
;		ret = GetAnimations(akActor, count, aggressive, true)
;	endIf

	return ret
	
EndFunction

Function WaitForDismount()
	If Game.GetCameraState() == 10 || pl.IsOnMount() ; Riding a horse
		pl.Dismount()
		int w = 0
		While pl.IsOnMount() &&  w <= 40
			; Wait for dismount
			Utility.Wait(0.1)
			w += 1
		EndWhile
		If w >= 40
			log("Dismount wait timed out!", 1)
		EndIf
	EndIf
EndFunction

Function RemoveKeys()
	If config.stealKeys && ( pl.GetItemCount(libs.chastityKey) > 0 || pl.GetItemCount(libs.restraintsKey) > 0 || ( customKey && pl.GetItemCount(customKey) > 0 ) )
		If pl.GetItemCount(libs.chastityKey) > 0
			rapistHasKey = true ; If the attackers didn't have a key yet, they do now
			log("Player has generic key")
		EndIf
		If customKey && pl.GetItemCount(customKey) > 0
			log("Player has custom key")
			rapistHasCustomKey = true
		EndIf
		Actor thief = getClosestRapist(pl)
		
		notify("You've lost your precious keys!")
		
		; 33% chance per key to not transfer it to the thief
		int keycount = pl.GetItemCount(libs.chastityKey)
		if keycount > 0
			int n = keycount
			while n > 0
				n -= 1
				if Utility.RandomInt(0, 99) < 33
					keycount -= 1
				endif
			endWhile
			pl.RemoveItem(libs.chastityKey, keycount, true, thief)
		endif

		keycount = pl.GetItemCount(libs.restraintsKey)
		if keycount > 0
			int n = keycount
			while n > 0
				n -= 1
				if Utility.RandomInt(0, 99) < 33
					keycount -= 1
				endif
			endWhile
			pl.RemoveItem(libs.restraintsKey, keycount, true, thief)
		endif
		
		log(thief.GetLeveledActorBase().GetName() + " stole the keys!")
		; Destroy the remaining keys
		pl.RemoveItem(libs.chastityKey, pl.GetItemCount(libs.chastityKey), true)
		pl.RemoveItem(libs.restraintsKey, pl.GetItemCount(libs.restraintsKey), true)
		If customKey
			pl.RemoveItem(customKey, pl.GetItemCount(customKey), true, thief)
		EndIf
	EndIf
EndFunction

Key Function GetCustomWornBeltKey()
	; Redo this at some point if GetDeviceKey() gets performance improvements
	; returns none if the key is the generic from DDi
	If !pl.WornHasKeyword(libs.zad_DeviousBelt)
		return none
	EndIf
	int i = 15 
	While checkingKey && i > 0
	;	log("GetKey waiting...")
		Utility.Wait(1.0)
		i -= 1
	EndWhile
	checkingKey = true ; This is reset to false in AddActor() after setting keyCheckDone to true
	If keyCheckDone
		log("GetKey skipped, done already")
		return customKey
	EndIf
	If pl.GetItemCount(libs.beltIronRendered) > 0 || pl.GetItemCount(libs.beltPaddedRendered) > 0 || pl.GetItemCount(libs.beltPaddedOpenRendered) > 0 || pl.GetItemCount(libs.harnessBodyRendered) > 0 ;|| compat.expansion && pl.GetItemCount(compat.xlibs.eboniteHarnessBodyRendered) > 0
		return none
;	ElseIf pl.GetItemCount(beltRustedRendered) > 0
;		return none
	Else
		Key k = libs.GetDeviceKey(libs.GetWornDeviceFuzzyMatch(pl, libs.zad_DeviousBelt)) ; bit slow...
		If k != libs.chastityKey ;&& k != rustykey
			log("Custom belt with a custom key found.")
			return k
		Else
			log("Custom belt with a generic key found.")
			return none
		EndIf
	EndIf
	return none
EndFunction 

Function StripBelt()
	
	bool hasBelt = pl.WornHasKeyword(libs.zad_DeviousBelt)
	If config.stripBelt && !wornBelt && hasBelt
		If !config.requireKeys || rapistHasKey
		;	if pl.GetItemCount(libs.beltIronRendered) > 0
		;		wornBelt = libs.beltIron
		;		libs.ManipulateDevice(pl, libs.beltIron, false, false)
		;	elseif pl.GetItemCount(libs.beltPaddedRendered) > 0
		;		wornBelt = libs.beltPadded
		;		libs.ManipulateDevice(pl, libs.beltPadded, false, false)
		;	elseif pl.GetItemCount(libs.beltPaddedOpenRendered) > 0
		;		wornBelt = libs.beltPaddedOpen
		;		libs.ManipulateDevice(pl, libs.beltPaddedOpen, false, false)
		;	elseif pl.GetItemCount(libs.harnessBodyRendered) > 0
		;		wornBelt = libs.harnessBody
		;		libs.ManipulateDevice(pl, libs.harnessBody, false, false)
		;	elseif customKey == none
		;		; unrecognized belt, try generic manipulation
		;		log("Custom belt, generic key")
		;		wornBelt = libs.GetWornDeviceFuzzyMatch(pl, libs.zad_DeviousBelt)
		;		log("wornBelt: " + wornBelt.GetName())
		;		If !libs.ManipulateGenericDevice(pl, wornBelt, false, false, true)
		;			wornBelt = none					
		;		EndIf
		;	endif
			If pl.WornHasKeyword( libs.zad_DeviousBelt )
				wornBelt = libs.GetWornDeviceFuzzyMatch( pl, libs.zad_DeviousBelt )
				If !wornBelt.HasKeyword( libs.zad_BlockGeneric ) && !libs.UnlockDevice( pl, wornBelt, libs.GetRenderedDevice( wornBelt ), libs.zad_DeviousBelt, True, True )
					wornBelt = None
				EndIf
			EndIf
		EndIf
		
		; Custom belts here
;		If !config.requireKeys || rapistHasRustykey
;			if pl.GetItemCount(beltRustedRendered) > 0
;				ManipulateDevice(pl, beltRusted, false, false)
;				wornBelt = beltRusted
;			endIf
;		EndIf
		
		If !config.requireKeys || rapistHasCustomKey
			if pl.WornHasKeyword(libs.zad_DeviousBelt)
				log("Custom belt, custom key.")
				wornBelt = libs.GetWornDeviceFuzzyMatch(pl, libs.zad_DeviousBelt)
				log("wornBelt: " + wornBelt.GetName())
			;	If !libs.ManipulateGenericDevice(pl, wornBelt, false, false, true)
				If !libs.UnlockDevice( pl, wornBelt, libs.GetRenderedDevice( wornBelt ), libs.zad_DeviousBelt, True )
					wornBelt = None					
				EndIf
			EndIf
		EndIf
		
		if wornBelt
			wornPlugs = StripWornPlugs(pl)
		endIf
		
	EndIf
	; Show some flavor messages if player was wearing a belt and it is configured to be stripped
	If hasBelt && config.stripBelt
		If wornBelt
			; The belt was stripped
			notify("Your attackers roughly remove the chastity belt protecting you.")
			doInvCheck = true
		Else
			; The belt should've been stripped but wasn't due to missing keys or a custom belt
			notify("Your attackers futilely tug at the unyielding belt around you.")
		EndIf
	EndIf
EndFunction

;Event Orgasm(String eventName, String argString, float argNum, Form Sender)
Event Orgasm(int thread, bool hasPlayer)
	UnregisterForModEvent("HookOrgasmStart_Helpless")
	Utility.Wait(0.8)
	log("Applying vampirism...")
	Actor[] actors = SexLab.HookActors(thread)
	int i = actors.length
	while i > 0
		i -= 1
		if actors[i] != pl
			actors[i].DoCombatSpellApply(vampirism, pl)
			return
		endIf
	EndWhile
EndEvent

Event RapeEnd(int thread, bool hasPlayer)
	log("RapeEnd()")
	
	If !hasPlayer
		; This can happen if one of the attackers has a belt and gets put into her own thread by DDi
		log("Received AnimationEnd on a thread with no player!")
		return
	EndIf
	
	Game.SetPlayerAIDriven(true)
	
	Debug.SendAnimationEvent(pl, "IdleCowering")
	UnregisterForModEvent("HookAnimationEnd_Helpless")
	
	ContinueScene()
EndEvent

Function ContinueScene()
	log("ContinueScene()")
	Actor[] newRapists = GetActors(pl)
	If newRapists[0] != None
		log("More actors found, continuing scene")
		Utility.Wait(1.0)
		StartPlayerRape(newRapists)
	Else
		stopping = true
		log("No more actors, ending scene")
		If config.randomEquip
			log("Equipping random items")
			devman.EquipRandomDevices(pl, config.restrictiveChance)
			devman.ClearStoredInventory(pl)
		EndIf
		
		If wornPlugs && !pl.WornHasKeyword(libs.zad_DeviousPlug)
			int i = wornPlugs.length
			while i > 0
				i -= 1 ; So much hassle for one missing line...
			;	libs.ManipulateGenericDevice(pl, wornplugs[i], true, false, true)
				libs.LockDevice( pl, wornplugs[i] )
			;	ManipulateDevice(pl, wornPlugs[i], true)
			endWhile
		EndIf
		
		If wornBelt && !pl.WornHasKeyword(libs.zad_DeviousBelt)
		;	ManipulateDevice(pl, wornBelt, true, false)
			libs.LockDevice( pl, wornbelt )
		EndIf
		
	;	bool wearingArmbinder = GetIntValue(pl, "dhlp-wornArmbinder", 0) == 1
		Armor binder = GetFormValue(pl, "dhlp-wornArmbinder") as Armor
		int bchance = config.enemyItemChance
		
		bool wearingBinder = false
		
		if pl.WornHasKeyword(libs.zad_DeviousHeavyBondage)	
			wearingBinder = true
		EndIf
		
		If bchance < 15
			bchance = 15
		EndIf
		If ( binder ||  Utility.RandomInt(0, 99) < bchance  ) && !pl.WornHasKeyWord(libs.zad_DeviousHeavyBondage)
			If !binder  
				log("Gifted an armbinder.")
				dialogueID.SetValueInt(5)
				getClosestRapist(pl).say(dialogue)
				binder = devman.GetPreferredDevice(libs.zad_DeviousArmbinder)
				Utility.Wait(3) ; wait a bit to allow the dialogue to play before the scene end one
			EndIf
		;	libs.ManipulateGenericDevice(pl, binder, true, false, true)
			libs.LockDevice( pl, binder )
			wearingBinder = true
			dialogueID.SetValueInt(0)
		EndIf
		
		wornPlugs = new Armor[1]
		wornbelt = none
		UnsetFormValue(pl, "dhlp-wornArmbinder")
		raped = true
		WD_Raped.SetValueInt(1)
		WD_Chasing.SetValueInt(1) ; Make the enemies actually chase the player if triggered during escape
		
		if config.followers
			StopAllFollowerThreads()
			; Prevent laggy equip events on followers from slowing down the freeing process
			RegisterForModEvent("Helpless_FollowerRedress", "RedressFollowers")
			SendModEvent("Helpless_FollowerRedress")
			;RedressFollowers()
		endIf
		
		dialogueID.SetValueInt(7)
		getClosestRapist(pl).say(dialogue)
		
		CeaseFire()
		rapistHasKey = false
;		rapistHasRustykey = false
		rapistHasCustomKey = false
		keyCheckDone = false
		customKey = none
		;hasMale = false
		hasAllowedGender = false
		Utility.Wait(1.5) ; Looks like it takes a while for the armbinder to be equipped, so lets wait a while
		if(!pl.WornHasKeyword(libs.zad_DeviousHeavyBondage))
			SexLab.UnstripActor(pl, wornItems)
		endIf
		EquipFollowers()
		dialogueID.SetValueInt(0)
		wornItems = new Form[1]
		SetFollowerAnimation()
		
	;if GetIntValue(pl, "dhlp-wornArmbinderStruggle") == 1
	;		armbinderQuest.DisableStruggling()
	;	EndIf
	;	UnsetIntValue(pl, "dhlp-wornArmbinderStruggle")
		
		Debug.SendAnimationEvent(pl, "IdleForceDefaultState")
		
		
		Game.SetPlayerAIDriven(false)
		EscapeAlias.ForceRefTo(pl)
		EscapeAlias.StartEscape(armbinder = wearingBinder)
		libs.EnableEventProcessing()
		stopped = Utility.GetCurrentRealTime()
		stopping = false
	;	Utility.Wait(Utility.RandomFloat(15.0, 45.0))
	;	if lastRapistAdded < stopped ;&& chaseTimeout == 0
	;		; Don't stop the scene if more rapists have been added to start another one
	;		stopped = 0.0
	;		StopSceneAndClear()
	;	endIf
	EndIf
EndFunction

Function StopIfAble()
	If lastRapistAdded < stopped
		stopped = 0.0
		StopSceneAndClear()
	EndIf
EndFunction

Function StopSceneAndClear()
	if clearing
		return
	endIf
	clearing = true
	log("StopSceneAndClear()")

	
	EscapeAlias.ForceStop()
	EscapeAlias.Clear()
	
	int i = FormListCount(none, rapistList)
	Actor a
	while i > 0
		i -= 1
		a = FormListGet(none, rapistList, i) as Actor
		if a
			a.ModAv("SpeedMult", GetRapistSpeedModifier(true))
			a.BlockActivation(false)
			a.RemoveFromFaction(HelplessFaction)
			
			;native check
			if config.PyU
				PyramidUtils.SetActorCalmed(a, false)
			endif
			
			FormListRemove(none, rapistList, a, true)
			ClearPackageOverride(a)
			log("Cleared " + a.GetLeveledActorBase().GetName())
		endIf
	endWhile
	
	pl.RemoveFromFaction(HelplessFaction)
	
	;native check
	if config.PyU
		PyramidUtils.SetActorCalmed(pl, false)
	endif
	
	i = FormListCount(none, followerList)
	log(i + " followers to clear.")
	while i > 0
		i -= 1
		a = FormListGet(none, followerList, i) as Actor
		if a
			log("Clearing follower " + a.GetLeveledActorBase().GetName())
			a.RemoveFromFaction(HelplessFaction)
			
			;native check
			if config.PyU
				PyramidUtils.SetActorCalmed(a, false)
			endif
			
			FormListClear(a, rapeQueue)
		endIf
	endWhile
	libs.EnableEventProcessing() ; Re-enable device events
	wornBelt = none
;	wearingArmbinder = false
	UnsetIntValue(pl, "dhlp-wornArmbinder")
	FormListClear(pl, rapeQueue)
	WD_SceneRunning.SetValueInt(0)
	InciteActors()
	GoToState("")
	clearing = false
EndFunction


bool Function IsPlayerWearingDevice()
	int i = FormListCount(none, keywordList)
	while i > 0
		i -= 1
		if pl.WornHasKeyword(FormListGet(none, keywordList, i) as Keyword)
			log("Player wearing a device with keyword " + FormListGet(none, keywordList, i))
			return true
		endIf
	endWhile
	log("Player is not wearing a device.")
	return false
EndFunction

function clean()
	SendModEvent("Helpless_RemoveSpell")
	; The magic effect stays on the actors for 15 minutes to prevent them from continously starting the scene
	; So need to use SendModEvent here to reach them all in this case
	StopSceneAndClear()
EndFunction

function checkForWeapons()
	if pl.getEquippedWeapon(false) == None && pl.getEquippedWeapon(true) == none && pl.getEquippedSpell(0) == none && pl.getEquippedSpell(1) == none && pl.getEquippedShield() == none
		WD_PlayerHasWeaponEquipped.setValueInt(0)
	else
		WD_PlayerHasWeaponEquipped.setValueInt(1)
	endIf
endFunction

event OnVibrate(string eventName, string argString, float argNum, form sender)
	log("OnVibrate("+eventName+", "+argString+", "+argNum+")")
	if argString == pl.GetLeveledActorBase().GetName()
	
		Utility.Wait(Utility.RandomFloat(0.1, 1.5)); Wait a random amount to vary the drop time from vibration start
		
		If argNum >= 3
			if pl.IsSneaking()
				pl.StartSneaking() ; Should stop sneaking if was already sneaking
			endIf
			pl.CreateDetectionEvent(pl, (25 * (argNum - 1) as float + 0.5) as int)
		EndIf

		int[] drops = new int[2] ; no drops = none array = log spam >.>
		; wtb switch
		if argNum >= 3.5 ; argNum should be 3.5 with only vaginal plug and vibstrength of 5. 0.7 * 5 = 3.5
			log("Vibrate >= 3.5")
			drops = dropWeapons(true, 1.2) ; Both hands, higher spell drop chance
		elseIf argNum >= 2.5
			log("Vibrate >= 2.5")
			drops = dropWeapons(true) ; Both hands
		elseIf argNum >= 1.5 ; argNum should be 1.5 with only anal plug and a vib strength of 5. 0.3 * 5 = 1.5
			log("Vibrate >= 1.5")
			drops = dropWeapons(false, 0.8) ; Left hand, lower spell drop chance
		endIf	
		
		; Show flavor messages
		string msg
		if drops[0] == 1
			msg = "Surprised by the sudden vibrations, you lose your grip of your weapon."
		elseif drops[0] >= 2
			msg = "Unable to resist the strong vibrations, your strength wanes and your weapons drop."
		else
			msg = ""
		endif
		
		string spellmsg
		if drops[1] >= 1 && argNum >= 3.0
			spellmsg = "The strong vibrations cloud your mind and prevent you from focusing."
		elseif drops[1] >= 1
			spellmsg = "A wave of pleasure jumbles your thoughts and breaks your concentration."
		else
			spellmsg = ""
		endif
		
		notify(msg)
		notify(spellmsg)
	endIf
endEvent

Event OnBlindfoldTrip(string eventName, string argString, float argNum, form sender)
	if argString == pl.GetLeveledActorBase().GetName() && !libs.IsAnimating(pl)
		log("OnBlindfoldTrip()")
		dropWeapons(true, 2.0)
	endIf
EndEvent

Event CustomWeaponDrop(bool both, float chanceMult, String weaponMsg, String magicMsg)
	log("CustomWeaponDrop - " + weaponMsg)
	int[] result = dropWeapons(both, chanceMult)
	If result[0] > 0
		notify(weaponMsg)
	ElseIf result[1] > 0
		notify(magicMsg)
	EndIf
EndEvent

int[] function dropWeapons(bool both = false, float chanceMult = 1.0)
	; By default, drops only stuff on left hand, if both == true, also right hand
	; returns an array of dropped item counts, weapon & shield at 0, spells at 1
	log("dropWeapons(both = "+both+", chanceMult = "+chanceMult+")")
	
	; Calculate the spell drop chance
	float spellDropChance = ( 100.0 - ( pl.GetAvPercentage("Magicka") * 100.0 ) ) ; inverse of magicka percentage
	float arousal = aroused.GetActorArousal(pl)
	if arousal >= 30 ; If arousal is over 30, increase the drop chance
		arousal = ( arousal - 30 ) / 2 ; 0 - 35% extra
		spellDropChance = spellDropChance + arousal
	endIf
	
	spellDropChance *= chanceMult
	
	if spellDropChance > 90
		spellDropChance = 90
	elseif spellDropChance < 10
		spellDropChance = 10
	endif

	log("spellDropChance: " + spellDropChance)
	
	int[] drops = new int[2]
	drops[0] = 0
	drops[1] = 0
		
	float chance = Utility.RandomInt(0, 99)
	Spell spl
	Weapon weap
	Armor sh
	
	int i = 2
	bool drop = true
	While i > 0
		i -= 1
		if i == 0
			Utility.Wait(1.0) ; Equipping the secondary set takes a while...
		EndIf
		if both
			spl = pl.getEquippedSpell(1)
			if spl && chance < spellDropChance
				pl.unequipSpell(spl, 1)
				drops[1] = drops[1] + 1
			endIf
			
			weap = pl.GetEquippedWeapon(true)
			if weap && pl.IsWeaponDrawn()
				DropOrUnequip(pl, weap, drop)
				drops[0] = drops[0] + 1
			endIf
			
			sh = pl.GetEquippedShield()
			if sh && pl.IsWeaponDrawn()
				DropOrUnequip(pl, sh, drop)
				drops[0] = drops[0] + 1
			endIf
		endIf
		
		spl = pl.getEquippedSpell(0)
		if spl && chance < spellDropChance
			pl.unequipSpell(spl, 0)
			drops[1] = drops[1] + 1
		endIf
		
		weap = pl.GetEquippedWeapon(false)
		if weap && pl.IsWeaponDrawn()
			both = both || weap.GetWeaponType() >= 5 ; if this is a two handed weapon, unequip both hands on the 2nd loop
			DropOrUnequip(pl, weap, drop)
			drops[0] = drops[0] + 1
		endIf
		
		If pl.GetEquippedItemType(0) == 11 ; Torch
			DropOrUnequip(pl, torch, drop)
		EndIf
		
		drop = false
		If drops[0] > 0
		; Some weapons are dropped already, make sure to unequip any spells on the second iteration as well
			spellDropChance = 100
		EndIf
	EndWhile

	return drops
endFunction

Function DropOrUnequip(Actor akActor, Form akObject, bool drop = true)
	If drop 
		akActor.DropObject(akObject)
	else
		akActor.UnequipItem(akObject, false, true)
	EndIf
EndFunction

function StealGoldAndGear()
	if !config.stealGear
		return
	endIf
	log("StealGoldAndGear()")
	; each attacker gets an equal gold share and one hopefully expensive item
	int num = FormListCount(none, rapistList)
	
	; Set the gold amount to steal
	int goldAmount = pl.GetItemCount(gold)
	if goldAmount <= 50
		goldAmount = 0
	else
		if num > 1
			if goldAmount >= 10000
				dialogueID.SetValueInt(3)
			else
				dialogueID.SetValueInt(1)
			endIf
		else
			if goldAmount >= 10000
				dialogueID.SetValueInt(4)
			else
				dialogueID.SetValueInt(2)
			endif
		endif
		goldAmount -= 50
		getClosestRapist(pl).say(dialogue)
	endIf
	log("Stealing " + goldAmount + " gold.")
	; Destroy random amount of the players gold
	pl.RemoveItem(gold, ( goldAmount as float * Utility.RandomFloat(0.1, 0.5) ) as int, true)
	bool spent = goldAmount > 0
	
	; Steal the rest
	goldAmount = pl.GetItemCount(gold)
	if goldAmount <= 50
		goldAmount = 0
	else
		goldAmount -= 50
	endif
	
	
	; change item steal probability based on its value and player level
	; below level 10, items worth 500g have 100% chance to be stolen
	; after that add 100g per level to the value at 100%
	int maxItemValue = 500
	if pl.GetLevel() > 10
		int levelOffSet = pl.GetLevel() - 10
		maxItemValue += levelOffSet * 100
	endIf
	log("Max item value " + maxItemValue + " with player level " + pl.GetLevel() + ".")
		
	; Pick a few items to steal
	int stealNum = 0
	int i = pl.GetNumItems()
	float goldVal = 0
	Form cForm
	while i > 0 &&  stealNum < num && stealGear.GetValue() == 1
		; Gear Stealing is disabled by default for now to avoid stealing quest items
		; Can be enabled ingame through console:
		; set WD_StealGear to 1
		i -= 1
		cForm = pl.GetNthForm(i)
		goldVal = cForm.GetGoldValue()
		
		int chance = (( goldVal / maxItemValue as float ) * 100.0 ) as int
		
		if Utility.RandomInt(0, 99) < chance && cForm.GetName() != "" && !cForm.HasKeyword(zad_InventoryDevice)
			FormListAdd(none, stealList, cForm, false)
		;	itemsToSteal.AddForm(cForm)
			log("Stealing " + cForm.GetName() + ", chance was " + chance + ".")
			stealNum += 1
		endif
	endWhile
	
	;keywords for PyUtils
	Keyword[] StealKeywords = new Keyword[6]
	StealKeywords[0] = Keyword.GetKeyword( "VendorItemArmor" )
	StealKeywords[1] = Keyword.GetKeyword( "VendorItemClothing" )
	StealKeywords[2] = Keyword.GetKeyword( "VendorItemWeapon" )
	StealKeywords[3] = Keyword.GetKeyword( "VendorItemArrow" )
	StealKeywords[4] = Keyword.GetKeyword( "VendorItemScroll" )
	StealKeywords[5] = Keyword.GetKeyword( "VendorItemSpellTome" )
	
	i = 0
	int ii = 0
	Actor rapist
	
	while i < FormListCount(none, rapistList)
		rapist = FormListGet(none, rapistList, i) as Actor
		if rapist
			pl.RemoveItem(gold, goldAmount / num, true, rapist)
			;native check
			if config.PyU && ii == 0
				Form[] stealstuff = PyramidUtils.GetItemsByKeyword(pl, StealKeywords, false)
				PyramidUtils.RemoveForms(pl, stealstuff, rapist)
				notify("They've stolen your items from you.")
				ii += 1
			elseif stealGear.GetValue() == 1
				pl.RemoveItem(FormListGet(none , stealList, ii), pl.GetItemCount(FormListGet(none , stealList, ii)), true, rapist)
				ii += 1
			endIf
		endIf
		i += 1
	endWhile
	
	if FormListCount(none, stealList) > 0 || goldAmount > 0 || spent
		notify("Your pockets feel significantly lighter.")
	endif
	dialogueID.SetValueInt(0)
	FormListClear(none, stealList)
endFunction

;function StealDelivery()
;	if !config.capturedDreams
;		return
;	endIf
;	log("StealDelivery()")
;	
;	Actor closest = getClosestRapist(pl)
;	Actor thief = none
;	
;	FormList items = Game.GetFormFromFile(0x00137EDC , "Captured Dreams.esp") as FormList
;	int i = items.GetSize()
;	while i > 0
;		i -= 1
;	;	log("Stealing " + items.GetAt(i).GetName())
;		if Utility.RandomInt(0, 99) < 60
;		;	If Utility.RandomInt(0, 99) < 50
;		;		thief = none
;		;	Else
;		;		thief = closest
;		;	EndIf		
;			pl.RemoveItem(items.GetAt(i), 10, true, closest)
;		endif
;	endWhile
;endFunction

function notify(string msg)
	if config.messages && msg != ""
		Debug.Notification(msg)
	endIf
endFunction

Actor function getClosestRapist(Actor akActor)
	int i = FormListCount(none, rapistList)
	float dist
	Actor closest = none
	Actor current
	while i > 0
		i -= 1
		current = FormListGet(none, rapistList, i) as Actor
		if closest == none || current.GetDistance(akActor) < closest.GetDistance(akActor)
			closest = current
		endIf
	endWhile
	return closest
endFunction

function lockWearMutex()
	if wearCheckMutex
		int n = 0
		While wearCheckMutex
			Utility.Wait(0.1)
			if n >= 50 ; Wait max of 5s
				log("wear check mutex timed out!", 1)
				wearCheckMutex = false
			endIf
			n += 1
		EndWhile
	endIf
	wearCheckMutex = true
EndFunction

function lockActorFinderMutex()
	if actorFinderMutex
		int n = 0
		While actorFinderMutex
			Utility.Wait(0.5)
			if n >= 12 ; Wait max of 6s
				log("Actor finder mutex timed out!", 1)
				actorFinderMutex = false
			endIf
			n += 1
		EndWhile
	endIf
	actorFinderMutex = true
EndFunction

function unlockActorFinderMutex()
	actorFinderMutex = false
EndFunction

Function ManipulateDevice(actor akActor, armor device, bool equipOrUnequip)
	if akActor == none || device == none
		return
	endIf
;	log("ManipulateDevice(" + akActor.GetLeveledActorBase().GetName() + ", " + device.GetName() + ", " + equipOrUnequip + ")")
;	Armor deviceRendered
;	Keyword deviceKeyword
;	if device == beltRusted
;		deviceRendered = beltRustedRendered
;		deviceKeyword = libs.zad_DeviousBelt
;	elseIf device == plugWornVag
;		deviceRendered = plugWornVagRendered
;		deviceKeyword = libs.zad_DeviousPlugVaginal
;	elseIf device == plugWornAn
;		deviceRendered = plugWornAnRendered
;		deviceKeyword = libs.zad_DeviousPlugAnal
;	elseif config.capturedDreams && device == compat.plugsMage
;		deviceRendered = compat.plugsMageRendered
;		deviceKeyword = libs.zad_DeviousPlugVaginal
;	elseif config.capturedDreams && device == compat.plugsAssassin
;		deviceRendered = compat.plugsAssassinRendered
;		deviceKeyword = libs.zad_DeviousPlugVaginal
;	elseif config.capturedDreams && device == compat.plugsThief
;		deviceRendered = compat.plugsThiefRendered
;		deviceKeyword = libs.zad_DeviousPlugVaginal
;	elseif config.capturedDreams && device == compat.plugsFighter
;		deviceRendered = compat.plugsFighterRendered
;		deviceKeyword = libs.zad_DeviousPlugVaginal
;	elseif config.capturedDreams && device == compat.plugsTormentor
;		deviceRendered = compat.plugsTormentorRendered
;		deviceKeyword = libs.zad_DeviousPlug
;	Else
;		If !device.HasKeyword(libs.zad_BlockGeneric)
;			If libs.ManipulateGenericDevice(akActor, device, equipOrUnequip, skipEvents, skipMutex)
;				return
;			EndIf
;		EndIf
;	;	If compat.expansion
;	;		compat.xlibs.ManipulateDevice(akActor, device, equipOrUnequip, skipEvents)
;	;	Else
;			libs.ManipulateDevice(akActor, device, equipOrUnequip, skipEvents)
;	;	EndIf
;		return
;	EndIf
	if equipOrUnequip
		libs.LockDevice( akActor, device, False )
	else
		libs.UnlockDevice( akActor, device, libs.GetRenderedDevice( device ), libs.GetDeviceKeyword( device ), True, False )
	EndIf
EndFunction

Armor[] Function StripWornPlugs(actor akActor)
	Armor[] ret = new Armor[2] ; 0 = vag, 1 = anal, 2 = set
	
	If akActor.WornHasKeyWord(libs.zad_DeviousPlugVaginal)
		Armor vagPlugInv = libs.GetWornDeviceFuzzyMatch(akActor, libs.zad_DeviousPlugVaginal)
	;	If libs.ManipulateGenericDevice(akActor, vagPlugInv, false, false, true)
		If libs.UnlockDevice( akActor, vagPlugInv, libs.GetRenderedDevice( vagPlugInv ), libs.zad_DeviousPlugVaginal, True, True )
			ret[0] = vagPlugInv
		EndIf
	EndIf
	
	If akActor.WornHasKeyWord(libs.zad_DeviousPlugVaginal)
		Armor anPlugInv = libs.GetWornDeviceFuzzyMatch(akActor, libs.zad_DeviousPlugAnal)
	;	If libs.ManipulateGenericDevice(akActor, anPlugInv, false, false, true)
		If libs.UnlockDevice( akActor, anPlugInv, libs.GetRenderedDevice( anPlugInv ), libs.zad_DeviousPlugAnal, True, True )
			ret[1] = anPlugInv
		EndIf
	EndIf
	
;	If akActor.WornHasKeyWord(libs.zad_DeviousPlug)
;		Armor plugsInv = libs.GetWornDeviceFuzzyMatch(akActor, libs.zad_DeviousPlug)
;		If libs.ManipulateGenericDevice(akActor, plugsInv, false, false, true)
;			ret[2] = plugsInv
;		EndIf
;	EndIf
		
	return ret
EndFunction

float Function GetRapistSpeedModifier(bool reset = false)
	If reset
		return -30.0
	Else
		return 30
	EndIf
EndFunction

; --------------------------------------------------
; Follower Functions
; --------------------------------------------------
; No way in hell I'd do this without PapyrusUtil
; Ideally these would be in a separate script though...

Event StartFollowerRape(String eventName, String argString, float argNum, Form Sender)
	log("StartFollowerRape()")
	bool creatures = argString == "creatures"
	UnregisterForModEvent("Helpless_FollowerStart")
	Utility.Wait(3)
	int numFollowers = FormListCount(none, followerList)

	SetFollowerAnimation("IdleCowering")
	int i = 0 
	Actor follower
	int leftovers = 0
	if !creatures 
		leftovers = FormListCount(pl, rapeQueue)
	Else
		leftovers = FormListCount(pl, creatureQuest.creatureQueue)
	EndIf
	while i < numFollowers && leftovers > i
		follower = FormListGet(none, followerList, i) as Actor
		log("Starting scene for follower: " + follower.GetLeveledActorBase().GetName() + ", creatures: " + creatures)
		if follower
			follower.AddToFaction(HelplessFaction)
			Actor thief = getClosestRapist(follower)
			if config.stealKeys && !creatures
				; same for keys
				if follower.getItemCount(libs.chastityKey) > 0
					rapistHasKey = true
					follower.RemoveItem(libs.chastityKey, 99, true, thief)
				endIf
				if follower.getItemCount(libs.restraintsKey) > 0
					follower.RemoveItem(libs.restraintsKey, 99, true, thief)
				endIf
			endIf
			if !creatures && follower.GetLeveledActorBase().GetSex() == 1
				devman.StoreInventory(follower)
			endIf
			StripFollowerBelt(follower)
			if config.stealGear
				; prevent player from stashing gold on followers
				follower.RemoveItem(gold, (follower.GetItemCount(gold) as float * Utility.RandomFloat(0.1, 0.5)) as int, true )
				follower.RemoveItem(gold, follower.GetItemCount(gold), true, thief)
			endIf
			if config.stripArmbinder; && follower.GetItemCount(libs.armbinderRendered) > 0 
				ForceStripArmbinder(follower)
			endIf
		;	StoreActorItems(follower, SexLab.StripSlots(follower, doStrip))
			if GetState() == "SceneRunning" && allowFollowers && !creatures
				StartFollowerAnimation(follower)
			ElseIf creatureQuest.GetState() == "SceneRunning" && creatures
				StartFollowerAnimation(follower, true)
			endIf
		endIf
		i += 1
	endWhile
EndEvent

Function StartFollowerAnimation(Actor follower, bool creatures = false)
	Actor[] actors
	If !creatures 
		actors = GetActors(follower)
	Else
		actors = creatureQuest.GetCreatures(follower)
	EndIf
	if actors[0] == none
		log("Stopping scene for follower " + follower.GetLeveledActorBase().GetName() + ", no more rapists.")
		return
	endIf
;	sslBaseAnimation[] anims 

;	If !creatures
;		anims = GetAnimations(follower, actors.length, config.onlyAggressive)
;	EndIf
	
;	sslThreadModel thread = SexLab.NewThread()
;	thread.AddActor(follower, true)
;	thread.SetStrip(follower, doStrip)
;	If !creatures
;		thread.AddActor(actors[1])
;		thread.SetStrip(actors[1], doStrip)
;		if actors.length == 3
;			thread.AddActor(actors[2])
;			thread.SetStrip(actors[2], doStrip)
;		endIf
;		thread.SetAnimations(anims)
;	Else
;		int i = 1
;		while i < actors.length
;			thread.AddActor(actors[i])
;			i += 1
;		endWhile
;	EndIf
;	thread.SetHook("HelplessFollower")
;	thread.DisableLeadIn()
;	thread.DisableBedUse(true)
	
;	sslThreadController controller = thread.StartThread()
	

	if	libs.StartValidDDAnimation( SexActors = actors, includetag = "", suppresstag = "foreplay", victim = follower, hook = "HelplessFollower" )
;		IntListAdd(none, followerThreads, controller.tid)
		SetFormValue(self, "dhlp-followerThread-", follower)
		log("Follower " + follower.GetLeveledActorBase().GetName() + " slotted to thread.")
	else 
		log("Failed to start animation for follower " + follower.GetLeveledActorBase().GetName() + ", retrying.", 1)
		StartFollowerAnimation(follower, creatures)
	endIf
	
	int i = actors.length
	while i > 1
		i -= 1
		FormListRemove(self, "dhlp-actorsInUse", actors[i], true)
	endWhile
	
EndFunction

Event FollowerRapeEnd(int threadID, bool hasPlayer)
	log("FollowerRapeEnd(" + threadId + ")")
	IntListRemove(none, followerThreads, threadID)
	; use formvalues to link the thread and follower, where key = threadID, value = follower
	Actor follower = GetFormValue(self, "dhlp-followerThread-" + threadID) as Actor
	UnsetFormValue(self, "dhlp-followerThread-" + threadID)
	Debug.SendAnimationEvent(follower, "IdleCowering")
	if follower && GetState() == "SceneRunning" && allowFollowers
		StartFollowerAnimation(follower)
	elseIf follower && creatureQuest.GetState() == "SceneRunning" && allowFollowers
		StartFollowerAnimation(follower, true)
	endIf
EndEvent

Function StopAllFollowerThreads()
	allowFollowers = false
	int i = IntListCount(none, followerThreads)
	while i > 0
		i -= 1
		int threadID = IntListGet(none, followerThreads, i)
		UnsetFormValue(self, "dhlp-followerThread-" + threadID)
		SexLab.HookController(threadID).EndAnimation(quickly = true)
	endWhile
	IntListClear(none, followerThreads)
	UnregisterForModEvent("HookAnimationEnd_HelplessFollower")
	SetFollowerAnimation("IdleCowering")
EndFunction

Event RedressFollowers(String eventName, String argString, float argNum, Form Sender)
	UnregisterForModEvent("Helpless_FollowerRedress")
	DoRedressFollowers()
EndEvent

Function DoRedressFollowers()
	int i = FormListCount(none, followerList)
	while i > 0
		i -= 1
		Actor follower = FormListGet(none, followerList, i) as Actor
;		SexLab.UnstripActor(follower, GetStoredActorItems(follower))
		Armor belt = GetFormValue(follower, "dhlp-wornBelt") as Armor
		;Armor beltRendered = GetFormValue(follower, "dhlp-wornBeltRendered") as Armor
		if belt
			log("Re-equipped " + follower.GetLeveledActorBase().GetName() + " with a chastity belt.")
			UnsetFormValue(follower, "dhlp-wornBelt")
			UnsetFormValue(follower, "dhlp-wornBeltRendered")
		;	libs.EquipDevice(follower, belt, beltRendered, libs.zad_DeviousBelt, skipEvents=true, skipMutex=true)
			libs.LockDevice( follower, belt )
		;	ManipulateDevice(follower, belt, true)
		endIf
		Armor binder = GetFormValue(follower, "dhlp-wornArmbinder") as Armor
		If binder
	;	if GetIntValue(follower, "dhlp-wornArmbinder", 0) == 1
			log("Re-equipped " + follower.GetLeveledActorBase().GetName() + " with an armbinder.")
		;	libs.ManipulateGenericDevice(follower, binder, true, false, true)
			libs.LockDevice( follower, binder )
		;	libs.EquipDevice(follower, libs.armbinder, libs.armbinderRendered, libs.zad_DeviousArmbinder, skipEvents=true, skipMutex=true)
		;	libs.ManipulateDevice(follower, libs.armbinder, true)
		;	UnsetIntValue(follower,"dhlp-wornArmbinder")
			UnsetFormValue(follower, "dhlp-wornArmbinder")
		endIf
		devman.EquipRandomDevices(follower)
		devman.ClearStoredInventory(follower)
	endwhile
EndFunction

Function FindFollowers()
;	log("FindFollowers()")
	Cell c = pl.GetParentCell()
	int n = c.GetNumRefs(43)
	Actor a
	while n > 0
		n -= 1
		a = c.GetNthRef(n, 43) as Actor
		if a && a.HasKeyword(actorTypeNPC) && ( a.IsInFaction(CurrentFollowerFaction) || a.IsInFaction(HirelingFaction) || a.IsPlayerTeammate() ) && FormListFind(none, followerList, a) == -1 && !a.isDead() && !a.IsDisabled()
			log("Found " + a.GetLeveledActorBase().GetName())
			FormListAdd(none, followerList, a, false)
		endIf
	endWhile
;	log("Found " + FormListCount(none, followerList) + " followers.")
EndFunction

Function CleanFollowerList()
;	log("CleanFollowerList()")
	int i = FormListCount(none, followerList)
;	int num = 0
	while i > 0
		i -= 1
		Actor a = FormListGet(none, followerList, i) as Actor
		if a == none || !a.Is3DLoaded() || a.IsDead() || a.IsDisabled() || a.GetWorldSpace() != pl.GetWorldSpace() || a.GetDistance(pl) > 3500
			FormListRemoveAt(none, followerList, i)
;			num += 1
		endIf
	endWhile
;	log("Removed " + num + " follower(s).")
EndFunction

Function EquipFollowers(bool forceArmbinder = false)
	int i = FormListCount(none, followerList)
;	log("EquipFollowers(), count: " + i)
	if i > 0
		while i > 0 
			i -= 1
			Actor ref = FormListGet(none, followerList, i) as Actor
			if pl.WornHasKeyWord(libs.zad_DeviousHeavyBondage) || forceArmbinder
				if ref && !ref.WornHasKeyword(libs.zad_DeviousHeavyBondage)
				;	libs.ManipulateDevice(ref, libs.armbinder, true, false)
				;	libs.ManipulateGenericDevice(ref, libs.GetGenericDeviceByKeyword(libs.zad_DeviousArmbinder), true, false, true)
					libs.LockDevice( ref, libs.GetGenericDeviceByKeyword( libs.zad_DeviousArmbinder ) )
					log("Equipped " + ref.GetLeveledActorBase().GetName() + " with armbinder.")
				endIf
			endIf	
		endWhile
	endIf
EndFunction

Function SetFollowerAnimation(String anim = "IdleForceDefaultState")
;	log("SetFollowerAnimation("+anim+")")
	int i = FormListCount(none, followerList)
	while i > 0
		i -= 1
		Debug.SendAnimationEvent(FormListGet(none, followerList, i) as Actor, anim)
	endwhile
EndFunction

Function Pacify(Actor akActor)
	if akActor && FormListFind(none, pacifier, akActor) == -1
		log("Pacifying " + akActor.GetLeveledActorBase().GetName())
		FormListAdd(none, pacifier, akActor, false)	
		akActor.AddToFaction(HelplessFaction)
		akActor.SetFactionRank(HelplessFaction, 100)
		
		;native check
		if config.PyU
			PyramidUtils.SetActorCalmed(akActor, true)
		else
			akActor.StopCombat()
		endif
		
	endIf
EndFunction

Function InciteActors()
	int i = FormListCount(none, pacifier)
	Actor akActor
	while i > 0
		i -= 1
		akActor = FormListGet(none, pacifier, i) as Actor
		if akActor
			akActor.RemoveFromFaction(HelplessFaction)
			
			;native check
			if config.PyU
				PyramidUtils.SetActorCalmed(akActor, false)
			endif
				
		endIf
	endwhile
	FormListClear(none, pacifier)
EndFunction

Function AllowFollowerScenes(bool a = true)
	allowFollowers = a
EndFunction

Function StripFollowerBelt(Actor follower, bool force = false)
	Armor worn = none 
	;Armor rendered = none
	If follower.WornHasKeyword(libs.zad_DeviousBelt) && config.stripBelt && ( !config.requireKeys || rapistHasKey || force )
	;	if follower.GetItemCount(libs.beltIronRendered) > 0
	;		worn = libs.beltIron
	;		rendered = libs.beltIronRendered
	;	;	libs.ManipulateDevice(follower, libs.beltIron, false, true)
	;	elseif follower.GetItemCount(libs.beltPaddedRendered) > 0
	;		worn = libs.beltPadded
	;		rendered = libs.beltPaddedRendered
	;	;	libs.ManipulateDevice(follower, libs.beltPadded, false, true)
	;	elseif follower.GetItemCount(libs.beltPaddedOpenRendered) > 0
	;		worn = libs.beltPaddedOpen
	;		rendered = libs.beltPaddedOpenRendered
	;	;	libs.ManipulateDevice(follower, libs.beltPaddedOpen, false, true)
	;	elseif follower.GetItemCount(libs.harnessBodyRendered) > 0
	;		worn = libs.harnessBody
	;		rendered = libs.harnessBodyRendered
	;	else
	;		worn = libs.GetWornDeviceFuzzyMatch(follower, libs.zad_DeviousBelt)
	;		If worn && !worn.HasKeyword(libs.zad_BlockGeneric)
	;			rendered = libs.GetRenderedDevice(worn)
	;		Else
	;			worn = none
	;		EndIf

		;	libs.ManipulateDevice(follower, libs.harnessBody, false, true)
	;	elseif compat.expansion && follower.GetItemCount(compat.xlibs.eboniteHarnessBodyRendered) > 0
	;		worn = compat.xlibs.eboniteHarnessBody
	;		rendered = compat.xlibs.eboniteHarnessBodyRendered
	;	endif
		worn = libs.GetWornDeviceFuzzyMatch( follower, libs.zad_deviousBelt )
	EndIf
	If worn && !worn.HasKeyword( libs.zad_BlockGeneric )
	;	libs.RemoveDevice(follower, worn, rendered, libs.zad_deviousBelt, skipEvents = true, skipMutex = true)
		libs.UnlockDevice( follower, worn, libs.GetRenderedDevice( worn ), libs.zad_deviousBelt, True, True )
		SetFormValue( follower, "dhlp-wornBelt", worn )
		SetFormValue( follower, "dhlp-wornBeltRendered", libs.GetRenderedDevice( worn ) )
	EndIf
EndFunction
; -----------------------------------------
; Maintenance functions
; -----------------------------------------

function uninstall()
	clean()
	pl.DispelSpell(vampirism)
	FormListClear(none, stealList)
	FormListClear(none, pacifier)
	FormListClear(none, keywordList)
	FormListClear(none, rapistList)
	FormListClear(pl, rapeQueue)
	int npcIdx = FormListCount(none, followerList)
	while npcIdx > 0
		npcIdx -= 1
		FormListClear(FormListGet(none, followerList, npcIdx), rapeQueue)
	endWhile
	FormListClear(none, followerList)
	RemoveAllPackageOverride(attackChasePackage)
	RemoveAllPackageOverride(gatherPackage)
	RemoveAllPackageOverride(sandboxPackage)
	RemoveAllPackageOverride(approachPackage)
	stop()
	Debug.Notification("Deviously Helpless successfully uninstalled")
endFunction

Function log(String msg, int level = 0)
	String prefix = "[Helpless]"
	If level == 0
		Debug.TraceConditional(prefix + ": " + msg, config.logging)
	ElseIf level == 1
		Debug.TraceConditional(prefix + "|WARNING|: " + msg, config.logging)
	ElseIf level >= 2
		Debug.TraceConditional("=================================================================================", config.logging)
		Debug.TraceConditional(prefix + "|ERROR|: " + msg, config.logging)
		Debug.TraceConditional("=================================================================================", config.logging)
	EndIf
	if WD_Debug.GetValueInt() == 1
		If level == 0
			MiscUtil.PrintConsole(prefix + ": " + msg)
		ElseIf level == 1
			MiscUtil.PrintConsole(prefix + "|WARNING|: " + msg)
		ElseIf level >= 2
			MiscUtil.PrintConsole("=================================================================================")
			MiscUtil.PrintConsole(prefix + "|ERROR|: " + msg)
			MiscUtil.PrintConsole("=================================================================================")
		EndIf
	EndIf
EndFunction
