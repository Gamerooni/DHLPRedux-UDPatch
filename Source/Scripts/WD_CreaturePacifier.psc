Scriptname WD_CreaturePacifier extends ActiveMagicEffect

WD_Util property util auto

Event OnEffectStart(Actor akTarget, Actor akCaster)
	util.Pacify(akTarget)
EndEvent