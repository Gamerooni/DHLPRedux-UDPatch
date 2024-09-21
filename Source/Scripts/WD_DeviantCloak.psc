Scriptname WD_DeviantCloak extends ActiveMagicEffect


WD_Util Property util Auto

bool added = false
Actor target

Event OnEffectStart(Actor akTarget, Actor akCaster)
	util.log("OnEffectStart("+akTarget.GetLeveledActorBase().GetName()+", "+ akCaster.GetLeveledActorBase().GetName()+")")
	added = util.AddRapist(akTarget)
	target = akTarget ; Maybe this works around the fact that after unload the script isn't attached to anything?
	
	If !added
		; If actor couldn't be slotted for the rape scene for whatever reason,
		; try again in 2min, instead of full 15 minute duration of the effect
		RegisterForSingleUpdate(120.0)
		RegisterForModEvent("Helpless_Retry", "RemoveSelf") ; Allow retrying sooner than 2min if needed
	Else
		RegisterForModEvent("Helpless_RemoveSpell", "RemoveSelf")
	EndIf
EndEvent

Event OnUpdate()
	util.log("Cloak OnUpdate(), clearing " + target.GetLeveledActorBase().GetName())
	Dispel()		; Kinda redundant calling both, but hopefully ClearSelf() goes through even if unloaded
	ClearSelf()	; Wouldn't bet on it though
EndEvent

Event OnEffectFinish(Actor akTarget, Actor akCaster)
	util.log("OnEffectFinish("+akTarget.GetLeveledActorBase().GetName()+", "+ akCaster.GetLeveledActorBase().GetName()+")")
	ClearSelf()
EndEvent

Event RemoveSelf(string eventName, string argString, float argNum, form sender)
	util.log("Received remove event, dispelling from " + target.GetLeveledActorBase().GetName())
	Dispel()
	ClearSelf()
EndEvent

Function ClearSelf()
	If target
		util.log("ClearSelf() for " + target.GetLeveledActorBase().GetName())
		
		;native check
		if util.config.PyU 
			PyramidUtils.SetActorCalmed(target, false)
		endif
		
		If added
			util.RemoveRapist(target)
			added = false
		EndIf
		
		target.BlockActivation(false)
	endif
EndFunction

Event OnHit(ObjectReference akAggressor, Form akSource, Projectile akProjectile, bool abPowerAttack, bool abSneakAttack, bool abBashAttack, bool abHitBlocked)
	if util.raped && akAggressor == util.pl && util.GetState() == "SceneRunning"
		util.log("Scene done and player attacked a rapist, stopping.")
		util.StopSceneAndClear()
	else
		util.log("Someone attacked one of the bandits, clearing.")
		ClearSelf()
	endif
EndEvent

; Clear the actor from aliases & queue when needed
Event OnDying(Actor akKiller)
	util.log(target.GetLeveledActorBase().GetName() + " dying, clearing.")
	ClearSelf()
EndEvent

Event OnUnload()
	util.log(target.GetLeveledActorBase().GetName() + " unloading, clearing.")
	ClearSelf()
EndEvent
