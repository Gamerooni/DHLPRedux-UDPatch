Scriptname WD_Compatibility extends Quest

WD_Util	Property util						auto
WD_Config	Property config					auto
FormList	Property WD_AssistingCreatures 	auto

; Defeat
Faction Property DefeatFaction Auto hidden

Function CompatibilityCheck()
	Utility.Wait(2.0) ; Wait a bit to allow setDefaults to run on version update
	
	DDIntegration() ; Do this before "ignore errors" :P

	Defeat()

EndFunction

Function DDIntegration()
	float DDi = util.libs.GetVersion()
	String status = "OK"
	if DDi < 14
		Debug.MessageBox("You are using an old and unsupported version of Devious Devices. Deviously Helpless will not function properly.\nRequired: 14 Detected: " + DDi)
		status = "OLD"
	endif
	util.log("Checking DD version, reported: " + DDi + ", " + status)
EndFunction

Function Defeat()
	
	If Game.GetModByName("SexLabDefeat.esp") != 255
		DefeatFaction = Game.GetFormFromFile(0x00001D92, "SexLabDefeat.esp") as Faction
		util.log("Found SexLab Defeat")
	EndIf
EndFunction

