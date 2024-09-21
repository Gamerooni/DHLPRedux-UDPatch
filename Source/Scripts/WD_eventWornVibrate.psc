scriptName WD_eventWornVibrate extends zadBaseLinkedEvent

Keyword Property LocTypeDraugrCrypt Auto
Keyword Property WD_effVibrateDraugr Auto

Int Function GetChanceModified(actor akActor, int chanceMod)
	float ret = Probability * 1.4
	Location loc = akActor.GetCurrentLocation()
	if loc && loc.HasKeyword(LocTypeDraugrCrypt)
		ret *= 2.3
	EndIf
	return ((ret - Probability) as Int)
EndFunction

Bool Function Filter(actor akActor, int chanceMod=0)
	if akActor == libs.PlayerRef && akActor.GetCombatState() >= 1
		libs.Log("Player is in combat. Not starting new vibration effect.")
		return false	
	EndIf
	if akActor.IsInFaction(libs.Sexlab.ActorLib.AnimatingFaction)
		libs.Log("Player is in a sexlab scene. Not starting new vibration effect.")
		return false
	EndIf
	
	return (akActor.HasMagicEffectWithKeyword(WD_effVibrateDraugr) && akActor.WornHasKeyword(libs.zad_DeviousPlug) && Parent.Filter(akActor, GetChanceModified(akActor, chanceMod)))
EndFunction

Bool Function HasKeywords(actor akActor)
	return akActor.HasMagicEffectWithKeyword(WD_effVibrateDraugr)
EndFunction

Function Execute(actor akActor)
	libs.VibrateEffect(akActor, utility.RandomInt(1,5), duration=0, teaseOnly=libs.shouldEdgeActor(akActor))
EndFunction
