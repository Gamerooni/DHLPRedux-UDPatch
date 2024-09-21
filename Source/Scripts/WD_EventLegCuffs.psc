scriptName WD_EventLegCuffs extends zadBaseEvent

WD_Util Property util auto

Int Function GetChance(actor akActor)
	int arousal = libs.Aroused.GetActorArousal(akActor)
	float ret = Probability
	if arousal >= 75
		ret *= 1.60
	elseif arousal >= 50
		ret *= 1.30
	endif
	
	if akActor.IsSprinting()
		ret *= 1.75
	elseif akActor.IsRunning()
		ret *= 1.33
	; elseif akActor.IsWalking()
	;	ret *= 1.0
	elseif akActor.IsSneaking()
		ret *= 0.33
	endif
	
	if akActor.WornHasKeyword(libs.zad_DeviousBlindfold)
		ret *= 3.00
	endif	
;	util.log("Trip chance: " + ret)
	return (ret + 0.5) as int
EndFunction

Bool Function Filter(actor akActor, int chanceMod=0)
	return (akActor.WornHasKeyword(libs.zad_DeviousLegCuffs) || akActor.WornHasKeyword(libs.zad_DeviousBoots) ) && akActor == util.pl && Probability > 0 
EndFunction

Function Execute(actor akActor)
	if libs.IsAnimating(akActor) || akActor == libs.PlayerRef && akActor.GetCombatState() >= 1
		return
	EndIf

	bool IsMoving = akActor.IsSprinting() || akActor.IsRunning() || Input.IsKeyPressed(Input.GetMappedKey("Forward")) || Input.IsKeyPressed(Input.GetMappedKey("Back")) || Input.IsKeyPressed(Input.GetMappedKey("Strafe Left")) || Input.IsKeyPressed(Input.GetMappedKey("Strafe Right"))
	bool IsMenuOpen = Utility.IsInMenuMode() || UI.IsMenuOpen("Dialogue Menu")
	if IsMoving && !IsMenuOpen && !akActor.IsOnMount() && !akActor.IsSwimming() && Utility.RandomInt() <= GetChance(akActor)
		if akActor.IsSneaking()
			If akActor.WornHasKeyword(libs.zad_DeviousBoots)
				util.Notify("Distracted, you trip on your clumsy slave boots.")
			Else
				util.Notify("Distracted, you trip over your bulky leg cuffs.")
			EndIf
		else
			If akActor.WornHasKeyword(libs.zad_DeviousBoots)
				util.Notify("In your haste, you trip on your clumsy slave boots.")
			Else
				util.Notify("In your haste, you trip over your bulky leg cuffs.")
			EndIf
		endif
		Game.ForceThirdPerson()
		If akActor.IsSneaking()
			akActor.StartSneaking()
		EndIf
		akActor.CreateDetectionEvent(akActor, 100)
		Debug.SendAnimationEvent(akActor, "BleedOutStart")
		if util.config.dropWeapons
			util.dropWeapons(both = true, chanceMult = 2.0)
		endif
		Utility.Wait(2.0)
		Debug.SendAnimationEvent(akActor, "BleedOutStop")
	endif
EndFunction