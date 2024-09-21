scriptName WD_EventArmCuffs extends zadBaseEvent

WD_Util Property util auto

Bool Function Filter(actor akActor, int chanceMod=0)
	if akActor != util.pl || Probability <= 0 || !akActor.WornHasKeyword(libs.zad_DeviousArmCuffs)
		return false
	endIf

	float arousal = libs.Aroused.GetActorArousal(akActor)
	
	float chance = Probability as float + (arousal / 5.0)
	
	if(util.pl.WornHasKeyword(libs.zad_DeviousBlindfold))
		chance *= 2.8
	endif
	
	return Utility.RandomInt(0, 99) < ((chance + 0.5) as int)
EndFunction

Function Execute(actor akActor)
	RegisterForActorAction(0) ; Weapon Swing
	RegisterForActorAction(5) ; Bow Draw
	RegisterForSingleUpdate(180.0) ; Wait maximum of 3 minutes
EndFunction

Event OnActorAction(int actionType, Actor akActor, Form source, int slot)
	
	if akActor != util.pl
		; Turns out it's not only the player, despite wiki claiming otherwise :P
		return
	endif
	
	UnregisterForActorAction(0)
	UnregisterForActorAction(5)
	UnregisterForUpdate()
;	util.log("Fumble: OnActorAction("+actionType+", "+akActor+", "+source+", "+slot+")")
	
	if !akActor.WornHasKeyword(libs.zad_DeviousArmCuffs)
		; Make sure the cuffs are still equipped
		return
	endif
	
	float dropchance = 30 + ((libs.Aroused.GetActorArousal(akActor) as float) / 3.0 )
	if actionType == 5
		; bow fumble
		Input.TapKey(Input.GetMappedKey("Ready Weapon"))
		util.Notify("With the cuffs in the way, you fumble drawing your bow.  ")
	else
		; weapon swing
		; show the message only if something happens, that is, weapons are dropped
		dropchance *= 1.2
	endif
	
	if util.config.dropWeapons &&  Utility.RandomInt() <= (dropchance + 0.5) as int
		if actionType == 0
			util.Notify("With the cuffs in the way, you fumble and drop your weapon.  ")
		endif
		if slot == 1
			; right hand
			util.dropWeapons(both = true)
		else
			util.dropWeapons(both = false)
		endif
		akActor.CreateDetectionEvent(akActor, 20)
	endif
EndEvent

Event OnUpdate()
	UnregisterForActorAction(0)
	UnregisterForActorAction(5)
EndEvent
