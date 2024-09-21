Scriptname WD_CreatureCloak extends ActiveMagicEffect

WD_Creatures Property creatures auto
WD_Util Property util auto

bool added = false
Actor target

Event OnEffectStart(Actor akTarget, Actor akCaster)
	util.log("OnEffectStart("+akTarget.GetLeveledActorBase().GetName()+", "+ akCaster.GetLeveledActorBase().GetName()+")")
	added = creatures.AddCreature(akTarget)
	target = akTarget ; Maybe this works around the fact that after unload the script isn't attached to anything?
	
	If !added
		; If actor couldn't be slotted for the rape scene for whatever reason,
		; try again in 2min, instead of full 15 minute duration of the effect
		RegisterForSingleUpdate(120.0)
	Else
		RegisterForModEvent("Helpless_RemoveSpell", "RemoveSelf")
	EndIf
EndEvent

Event OnUpdate()
	Dispel()		; Kinda redundant calling both, but hopefully ClearSelf() goes through even if unloaded
	ClearSelf()	; Wouldn't bet on it though
EndEvent

Event OnEffectFinish(Actor akTarget, Actor akCaster)
	util.log("OnEffectFinish("+akTarget.GetLeveledActorBase().GetName()+", "+ akCaster.GetLeveledActorBase().GetName()+")")
	ClearSelf()
EndEvent

Event RemoveSelf(string eventName, string argString, float argNum, form sender)
	util.log("Received remove event, dispelling...")
	Dispel()
	ClearSelf()
EndEvent

Function ClearSelf()
	util.log("ClearSelf() for " + target.GetLeveledActorBase().GetName())
	If added
		creatures.RemoveCreature(target)
		added = false
	EndIf
	target.BlockActivation(false)
EndFunction

; Clear the actor from aliases & queue when needed
Event OnDying(Actor akKiller)
	ClearSelf()
EndEvent

Event OnUnload()
	ClearSelf()
EndEvent

Event OnHit(ObjectReference akAggressor, Form akSource, Projectile akProjectile, bool abPowerAttack, bool abSneakAttack, bool abBashAttack, bool abHitBlocked)
	if creatures.GetState() == "SceneRunning" && creatures.raped && akAggressor == creatures.pl 
		util.log("Scene done and player attacked a rapist, stopping.")
		creatures.StopCreatureScene()
	endif
EndEvent
