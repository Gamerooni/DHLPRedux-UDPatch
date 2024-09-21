Scriptname WD_Compatibility extends Quest

WD_Util	Property util						auto
WD_Config	Property config					auto
FormList	Property WD_AssistingCreatures 	auto

; SexLab Submit 
;GlobalVariable Property SubmitBound 		= none Auto hidden
;GlobalVariable Property SubmitSurrender 	= none Auto hidden
;GlobalVariable Property SubmitBleedOut	 	= none Auto hidden
;MagicEffect	 Property SLVampireDisease 	= none Auto hidden

; Captured Dreams
;bool  Property capturedDreamsLoaded = false Auto hidden

;Armor Property plugsMage 				Auto hidden
;Armor Property plugsMageRendered 		Auto hidden
;Armor Property plugsFighter 				Auto hidden
;Armor Property plugsFighterRendered	Auto hidden
;Armor Property plugsThief 				Auto hidden
;Armor Property plugsThiefRendered 		Auto hidden
;Armor Property plugsAssassin 			Auto hidden
;Armor Property plugsAssassinRendered 	Auto hidden
;Armor Property plugsTormentor 			Auto hidden
;Armor Property plugsTormentorRendered 	Auto hidden

; Defeat
Faction Property DefeatFaction Auto hidden

Function CompatibilityCheck()
	Utility.Wait(2.0) ; Wait a bit to allow setDefaults to run on version update
	
	DDIntegration() ; Do this before "ignore errors" :P
	;ZazAnimationPack()
	
	;Dawnguard()
	;CapturedDreams()
	;sslSubmit()
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

;Function ZazAnimationPack()
;	String status = "OK"
;EndFunction

;Function Dawnguard()
;		ActorBase hound = Game.GetFormFromFile(0x0000C5EF, "Dawnguard.esm") as ActorBase
;		WD_AssistingCreatures.AddForm(hound)
;		hound = Game.GetFormFromFile(0x00008D76, "Dawnguard.esm") as ActorBase
;		WD_AssistingCreatures.AddForm(hound)
;		hound = Game.GetFormFromFile(0x00017EC2, "Dawnguard.esm") as ActorBase
;		WD_AssistingCreatures.AddForm(hound)
;		hound = Game.GetFormFromFile(0x00008D79, "Dawnguard.esm") as ActorBase
;		WD_AssistingCreatures.AddForm(hound)
;		hound = Game.GetFormFromFile(0x00004D88, "Dawnguard.esm") as ActorBase
;		WD_AssistingCreatures.AddForm(hound)
;EndFunction

;Function CapturedDreams()
;		config.capturedDreams = false
;		capturedDreamsLoaded = false
;EndFunction

;Function sslSubmit()
;	
;	If Game.GetModByName("SexLab Submit.esp") != 255
;		util.log("Found SexLab Submit")
;		SubmitSurrender = Game.GetFormFromFile(0x0002840F, "SexLab Submit.esp") as GlobalVariable
;		SubmitBound = Game.GetFormFromFile(0x0004DAE0, "SexLab Submit.esp") as GlobalVariable
;		SubmitBleedOut = Game.GetFormFromFile(0x0005DDB1 , "SexLab Submit.esp") as GlobalVariable
;		SLVampireDisease = Game.GetFormFromFile(0x0004EB12, "SexLab Submit.esp") as MagicEffect
;		
;	endIf
;EndFunction

Function Defeat()
	
	If Game.GetModByName("SexLabDefeat.esp") != 255
		DefeatFaction = Game.GetFormFromFile(0x00001D92, "SexLabDefeat.esp") as Faction
		util.log("Found SexLab Defeat")
	EndIf
EndFunction

