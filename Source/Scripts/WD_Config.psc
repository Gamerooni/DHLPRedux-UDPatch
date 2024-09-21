Scriptname WD_Config extends SKI_ConfigBase

import StorageUtil

WD_Util Property util Auto
WD_Compatibility Property compat Auto
WD_DeviceManager Property devman Auto
WD_Creatures Property creatureQuest Auto
Race Property DraugrRace Auto
zadLibs Property libs Auto
SexLabFramework Property SexLab auto
Spell Property cloakSpell Auto
Perk Property pricePerk Auto
Actor Property pl Auto
ReferenceAlias Property PlayerEventAlias Auto
GlobalVariable Property WD_PlayerHasWeaponEquipped Auto
GlobalVariable Property WD_CreatureEnabler Auto
GlobalVariable Property WD_SheathedTrigger Auto

int uninstOID
bool uninst = false

Bool Property PyU = False  Auto Hidden

bool Property stripBelt Auto hidden
bool property stripDefault = true autoreadonly hidden
int stripOID

bool Property stripArmbinder Auto hidden
bool Property stripArmbinderDefault = false autoreadonly hidden
int stripArmbinderOID

bool Property CloakEnabled = true Auto hidden
bool property CloakDefault = true autoreadonly hidden
int cloakOID

;bool Property creaturesEnabled auto hidden
;bool property creaturesDefault = false autoreadonly hidden
;int creatureOID

bool Property logging = true Auto hidden
bool property loggingDefault = true autoreadonly hidden
int loggingOID

int panicOID
bool panic = false

bool property onlyUnarmed = true Auto hidden
bool property onlyUnarmedDefault = true autoreadonly hidden
int onlyUnarmedOID

bool property whileSheathed Auto hidden
bool property whileSheathedDefault = true autoreadonly hidden
int whileSheathedOID

bool property dropWeapons = true Auto hidden
bool property dropWeaponsDefault = true autoreadonly hidden
int dropWeaponsOID

bool property messages = true auto hidden
bool property messagesDefault = true autoreadonly hidden
int messagesOID

bool property stealKeys = true auto hidden
bool property stealKeysDefault = true autoreadonly hidden
int stealKeysOID

bool property requireKeys = true auto hidden
bool property requireKeysDefault = true autoreadonly hidden
int requireKeysOID

bool property stealGear = true auto hidden
bool property stealGearDefault = true autoreadonly hidden
int stealGearOID


;bool property capturedDreams auto hidden
;bool property capturedDreamsDefault = false autoreadonly hidden
;int capturedDreamsOID

bool property onlyAggressive auto hidden
bool property onlyAggressiveDefault = true autoreadonly hidden
int onlyAggressiveOID

bool property randomEquip auto hidden
bool property randomEquipDefault = true autoreadonly hidden
int randomEquipOID

int property restrictiveChance auto hidden
int property restrictiveChanceDefault = 40 autoreadonly hidden
int restrictiveChanceOID

int property enemyItemChance auto hidden
int property enemyItemChanceDefault = 15 autoreadonly hidden
int enemyItemChanceOID

bool property followers auto hidden
bool property followersDefault = true autoreadonly hidden
int followersOID

bool property overrideStrip auto hidden
bool property overrideStripDefault = false autoreadonly hidden
int overrideStripOID

;bool property priceBias auto hidden
;bool property priceBiasDefault = true autoreadonly hidden
;int priceBiasOID

bool armbinder
bool property armbinderDefault = true autoreadonly hidden
int armbinderOID

bool cBelt
bool property cBeltDefault = false autoreadonly hidden
int cBeltOID

bool bra
bool property braDefault = false autoreadonly hidden
int braOID

bool collar
bool property collarDefault = true autoreadonly hidden
int collarOID

bool gag
bool property gagDefault = false autoreadonly hidden
int gagOID

bool legCuffs
bool property legCuffsDefault = true autoreadonly hidden
int legCuffsOID

bool armCuffs
bool property armCuffsDefault = true autoreadonly hidden
int armCuffsOID

bool blindfold
bool property blindfoldDefault = true autoreadonly hidden
int blindfoldOID

bool harness
bool property harnessDefault = false auto hidden
int harnessOID

bool boots
bool property bootsDefault = true auto hidden
int bootsOID

bool heavybond
bool property heavybondDefault = true auto hidden
int heavybondOID


string[] genders
int property allowedGender = 0 auto hidden
int property allowedGenderDefault = 0 autoreadonly hidden
int allowedGenderOID

String[] noFastOpt
int Property noFast auto hidden
int property noFastDefault = 0 autoreadonly hidden
int noFastOID

String[] property materials auto hidden
String[] displayMaterials
String[] property colors auto hidden
String[] displayColors
int property primMat = 0 auto hidden
int property primCol = 0 auto hidden
int property secMat = 0 auto hidden
int property secCol = 0 auto hidden
int primMatOID
int primColOID
int secMatOID
int secColOID

bool property allowBlind auto hidden
bool property allowBlindDefault = true autoreadonly hidden
int allowBlindOID

bool property allowBoots auto hidden
bool property allowBootsDefault = true autoreadonly hidden
int allowBootsOID

int suspendOID

int debugOID
int debug02OID
int debug03OID

Function PyUtils()

    if SKSE.GetPluginVersion("PyramidUtils") != -1
        if PyramidUtils.GetVersion() >= 0.002002
            PyU = true
            util.log("PyUtils v" + PyramidUtils.GetVersion() + " found.")
			;util.notify("PyU here! version:" + SKSE.GetPluginVersion("pyramid-utils") )
			return
        else
            PyU = false
            util.log("PyUtils found, but version isn't correct - please update.")
			;util.notify("PyU incorrect! version:" + SKSE.GetPluginVersion("pyramid-utils") )
			return
        EndIf
    else 
        PyU = false
        util.log("PyUtils not found, using legacy functions")
		;util.notify("PyU not here! SKSE says" + SKSE.GetPluginVersion("pyramid-utils") )
    EndIf

EndFunction

Function PopulateKeywordList()
	util.log("PopulateKeywordList()")
		
	If armbinder
		FormListAdd(none, util.keywordList, libs.zad_DeviousArmbinder, false)
	Else
		FormListRemove(none, util.keywordList, libs.zad_DeviousArmbinder, true)
	EndIf
	
	If cBelt
		FormListAdd(none, util.keywordList, libs.zad_DeviousBelt, false)
	Else
		FormListRemove(none, util.keywordList, libs.zad_DeviousBelt, true)
	EndIf
	
	If bra
		FormListAdd(none, util.keywordList, libs.zad_DeviousBra, false)
	Else
		FormListRemove(none, util.keywordList, libs.zad_DeviousBra, true)
	EndIf
	
	If collar
		FormListAdd(none, util.keywordList, libs.zad_DeviousCollar, false)
	Else
		FormListRemove(none, util.keywordList, libs.zad_DeviousCollar, true)
	EndIf
	
	If gag
		FormListAdd(none, util.keywordList, libs.zad_DeviousGag, false)
	Else
		FormListRemove(none, util.keywordList, libs.zad_DeviousGag, true)
	EndIf
	
	If legcuffs
		FormListAdd(none, util.keywordList, libs.zad_Deviouslegcuffs, false)
	Else
		FormListRemove(none, util.keywordList, libs.zad_Deviouslegcuffs, true)
	EndIf
	
	If armcuffs
		FormListAdd(none, util.keywordList, libs.zad_Deviousarmcuffs, false)
	Else
		FormListRemove(none, util.keywordList, libs.zad_Deviousarmcuffs, true)
	EndIf
	
	If blindfold
		FormListAdd(none, util.keywordList, libs.zad_DeviousBlindfold, false)
	Else
		FormListRemove(none, util.keywordList, libs.zad_DeviousBlindfold, true)
	EndIf
	
	if harness
		FormListAdd(none, util.keywordList, libs.zad_DeviousHarness, false)
	Else
		FormListRemove(none, util.keywordList, libs.zad_DeviousHarness, true)
	EndIf
	
	if boots
		FormListAdd(none, util.keywordList, libs.zad_DeviousBoots, false)
	Else
		FormListRemove(none, util.keywordList, libs.zad_DeviousBoots, true)
	EndIf
	
	if heavybond
		FormListAdd(none, util.keywordList, libs.zad_DeviousHeavyBondage, false)
	Else
		FormListRemove(none, util.keywordList, libs.zad_DeviousHeavyBondage, true)	
	EndIf
	
EndFunction

Event OnConfigInit()
	InitPages()
EndEvent

Function SetDefaults()
	stripBelt = stripdefault
	CloakEnabled = CloakDefault
	armbinder = armbinderDefault
	cBelt = cBeltDefault
	bra = bradefault
	collar = collarDefault
	gag = gagdefault
	legcuffs = legcuffsdefault
	armcuffs = armcuffsdefault
	blindfold = blindfoldDefault
	onlyUnarmed = onlyUnarmedDefault
	WD_PlayerHasWeaponEquipped.SetValueInt(0)
	dropWeapons = dropWeaponsDefault
	messages = messagesDefault
	stealKeys = stealKeysDefault
	requireKeys = requireKeysDefault
	stealGear = stealGearDefault
	;capturedDreams = capturedDreamsDefault
	onlyAggressive = onlyAggressiveDefault
	randomEquip = randomEquipDefault
	restrictiveChance = restrictiveChanceDefault
	;creaturesEnabled = creaturesDefault
	whileSheathed = whileSheathedDefault
	followers = followersDefault
	stripArmbinder = stripArmbinderDefault
	allowedGender = allowedGenderDefault
	WD_SheathedTrigger.SetValueInt(0)
	overrideStrip = overrideStripDefault
	;priceBias = priceBiasDefault
	enemyItemChance = enemyItemChanceDefault
	noFast = noFastDefault
	harness = harnessDefault
	boots = bootsDefault
	heavybond = heavybondDefault
	primMat = 0
	primCol = 0
	secMat = 0
	secCol = 0
	allowBlind = allowBlindDefault
	allowBoots = allowBootsDefault
EndFunction


int Function GetVersion()
	return 52 ; 1.15d
EndFunction

Function InitPages()
	pages = new String[4]
	pages[0] = "Features"
	pages[1] = "Restraints equipping"
	pages[2] = "Triggers"
	pages[3] = "Maintenance"
	
	genders = new String[3]
	genders[0] = "Both"
	genders[1] = "Male"
	genders[2] = "Female"
	
	noFastOpt = new String[3]
	noFastOpt[0] = "Never"
	noFastOpt[1] = "With any device"
	noFastOpt[2] = "With blindfolds and armbinders"
	
	int mats = 4
	int cols = 5
	
;	bool exp = Game.GetModByName("Devious Devices - Expansion.esm") != 255
;	bool cd = Game.GetModByName("Captured Dreams.esp") != 255
;	If exp
;		mats += 1
;		cols += 2
;	EndIf
;	If cd
;		cols += 2
;	EndIf
	
	materials = sslUtility.StringArray(mats)
	displayMaterials = sslUtility.StringArray(mats)
	colors = sslUtility.StringArray(cols)
	displayColors = sslUtility.StringArray(cols)
	
	materials[0] = ""
	displayMaterials[0] = "Any"
	
	materials[1] = "metal"
	displayMaterials[1] = "Metal"
	
	materials[2] = "leather"
	displayMaterials[2] = "Leather"

	materials[3] = "ebonite"
	displayMaterials[3] = "Ebonite"
	int m = 4
	
	colors[0] = ""
	displayColors[0] = "Any"
	
	colors[1] = "padded"
	displayColors[1] = "Padded"
	
	colors[2] = "black"
	displayColors[2] = "Black"
	
	colors[3] = "white"
	displayColors[3] = "White"
	
	colors[4] = "red"
	displayColors[4] = "Red"
	int c = 5

EndFunction
	

Event OnVersionUpdate(int newVersion)
	util.log("OnVersionUpdate("+newVersion+"/"+currentVersion+")")
	If newVersion != currentVersion
		; There seems to be some issues spells and perks not being added to the player here
		; maybe this will help?
		Actor plr = Game.GetPlayer()
		SetDefaults()
		InitPages()
		util.clean()
		util.stop()
		;creatureQuest.stop()
		PopulateKeywordList()
		util.start()
		;creatureQuest.start()
		plr.RemoveSpell(cloakSpell)
		PlayerEventAlias.ForceRefTo(plr)
		If cloakEnabled
			Utility.Wait(2.0)
			plr.AddSpell(cloakSpell, false)
		EndIf
		util.UpdateMaintenance()
		PyUtils()
		devman.InitLists()
;		if SexLab.AllowedCreature(DraugrRace)
;			creaturesEnabled = true
;			WD_CreatureEnabler.SetValueInt(1)
;		else
;			creaturesEnabled = false
;			WD_CreatureEnabler.SetValueInt(0)
;		endIf
		if onlyUnarmed
			util.checkForWeapons()
		endif
		util.FindFollowers()
;		plr.RemovePerk(pricePerk)
;		If priceBias
;			plr.AddPerk(pricePerk)
;		EndIf
		SendModEvent("zadRegisterEvents")
		Debug.Notification("Deviously Helpless Redux updated")
	EndIf
EndEvent

Event OnPageReset(String page)
	SetCursorFillMode(TOP_TO_BOTTOM)
	if page == "" || page == pages[0] ; Features
		AddHeaderOption("Scene triggering")
		cloakOID = AddToggleOption("Attacks enabled", cloakEnabled)
		onlyUnarmedOID = AddToggleOption("...only with no weapons equipped", onlyUnarmed)
		whileSheathedOID = AddToggleOption("...only with no weapons out", whileSheathed)
;		if SexLab.AllowedCreature(DraugrRace)
;			creatureOID = AddToggleOption("Enable Draugr attacks", creaturesEnabled)
;		else
;			creaturesEnabled = false
;			WD_CreatureEnabler.SetValueInt(0)
;			creatureOID = AddToggleOption("Enable Draugr attacks", creaturesEnabled, OPTION_FLAG_DISABLED)
;		endIf
		AddHeaderOption("Scene options")
		allowedGenderOID = AddMenuOption("Allowed attacker sex", genders[allowedGender])
		onlyAggressiveOID = AddToggleOption("Only aggressive animations", onlyAggressive)
		stealGearOID = AddToggleOption("Attackers steal gold & gear", stealGear)
		stealKeysOID = AddToggleOption("Attackers steal keys", stealKeys)
		followersOID = AddToggleOption("Followers in scenes", followers)
		SetCursorPosition(1)
		AddHeaderOption("Equipment stripping")
		stripOID = AddToggleOption("Attackers strip chastity belts", stripBelt)
		requireKeysOID = AddToggleOption("...only with keys", requireKeys)
		stripArmbinderOID = AddToggleOption("Attackers strip armbinders ", stripArmbinder)
		overrideStripOID = AddToggleOption("Override sexlab stripping", overrideStrip)
		AddHeaderOption("Other")
		dropWeaponsOID = AddToggleOption("Device events drop weapons", dropWeapons)
		messagesOID = AddToggleOption("Enable status messages", messages)
;		priceBiasOID = AddToggleOption("Price bias", priceBias)
		If ( noFast == 1 && pl.WornHasKeyword(libs.zad_Lockable) ) || ( noFast == 2 && ( pl.WornHasKeyword(libs.zad_DeviousArmbinder) || pl.WornHasKeyword(libs.zad_DeviousBlindfold) ) )
			noFastOID = AddMenuOption("Restrict fast travel", noFastOpt[noFast], OPTION_FLAG_DISABLED)
		Else
			noFastOID = AddMenuOption("Restrict fast travel", noFastOpt[noFast])
		EndIf
	elseif page == pages[1] ; equipping
		randomEquipOID = AddToggleOption("Equip random devices", randomEquip)
		if randomEquip
			enemyItemChanceOID = AddSliderOption("Enemy item chance", enemyItemChance, "{0}%")
			restrictiveChanceOID = AddSliderOption("Restrictive item chance", restrictiveChance, "{0}%")
			allowBlindOID = AddToggleOption("Allow enemy blindfolds", allowBlind)
			allowBootsOID = AddToggleOption("Allow enemy boots", allowBoots)
		else
			enemyItemChanceOID = AddSliderOption("Enemy item chance", enemyItemChance, "{0}%", OPTION_FLAG_DISABLED)
			restrictiveChanceOID = AddSliderOption("Restrictive item chance", restrictiveChance, "{0}%", OPTION_FLAG_DISABLED)
			allowBlindOID = AddToggleOption("Allow enemy blindfolds", allowBlind, OPTION_FLAG_DISABLED)
			allowBootsOID = AddToggleOption("Allow enemy boots", allowBoots, OPTION_FLAG_DISABLED)
		endIf	
		SetCursorPosition(1)
		AddHeaderOption("Primary item preference")
		primMatOID = AddMenuOption("Material", displayMaterials[primMat])
		primColOID = AddMenuOption("Style", displayColors[primCol])
		AddHeaderOption("Secondary item preference")
		secMatOID = AddMenuOption("Material", displayMaterials[secMat])
		secColOID = AddMenuOption("Style", displayColors[secCol])
	elseif page == pages[2] ; Items
		AddHeaderOption("Equipped Devious Devices that trigger the attacks")
		armbinderOID = AddToggleOption("ARMBINDER", armbinder)
		cBeltOID = AddToggleOption("BELT", cBelt)
		braOID = AddToggleOption("BRA", bra)
		collarOID = AddToggleOption("COLLAR", collar)
		gagOID = AddToggleOption("GAG", gag)
		legcuffsOID = AddToggleOption("LEG CUFFS", legcuffs)
		armcuffsOID = AddToggleOption("ARM CUFFS", armcuffs)
		blindfoldOID = AddToggleOption("BLINDFOLD", blindfold)
		harnessOID = AddToggleOption("HARNESS", harness)
		bootsOID = AddToggleOption("BOOTS", boots)
		heavybondOID = AddToggleOption("Heavy Bondage", heavybond)
		SetCursorPosition(1)
		AddEmptyOption()
	elseif page == pages[3] ; Maintenance
		uninst = false
		panic = false
		loggingOID = AddToggleOption("Enable debug logging", logging)
		panicOID = AddTextOption("Reset running scenes", "Reset")
		uninstOID = AddTextOption("Uninstall", "not done")
		if util.WD_Debug.GetValueInt() == 1
			debugOID = AddTextOption("Clear follower list", "")
			debug02OID = AddTextOption("Find followers", "")
			debug03OID = AddTextOption("Clear keyword list", "")
		endIf
		
		SetCursorPosition(1)
		If util.WD_SuspendScenes.GetValueInt() == 1
			suspendOID = AddTextOption("Attack scenes suspended", "YES")
		Else
			suspendOID = AddTextOption("Attack scenes suspended", "NO")
		EndIf
		SetCursorPosition(19)
		AddHeaderOption("Deviously Helpless Redux " + util.GetVersionString())
		AddHeaderOption("Orignal By Srende & Slorm")
		AddHeaderOption("SE Conversion by Roggvir")
		AddHeaderOption("Redux By krzp & Taki17")
	endif
EndEvent

Event OnOptionDefault(int opt)
	if opt == restrictiveChanceOID
		restrictiveChance = restrictiveChanceDefault
		SetSliderOptionValue(restrictiveChanceOID, restrictiveChance, "{0}%")
		util.log("Restrictive item chance set to: " + restrictiveChance)
	endIf
EndEvent

Event OnOptionMenuOpen(int opt)
	If opt == allowedGenderOID
		SetMenuDialogOptions(genders)
		SetMenuDialogDefaultIndex(allowedGenderDefault)
		SetMenuDialogStartIndex(allowedGender)
	ElseIf opt == noFastOID
		SetMenuDialogOptions(noFastOpt)
		SetMenuDialogDefaultIndex(noFastDefault)
		SetMenuDialogStartIndex(noFast)
	ElseIf opt == primMatOID
		SetMenuDialogOptions(displayMaterials)
		SetMenuDialogDefaultIndex(0)
		SetMenuDialogStartIndex(primMat)
	ElseIf opt == primColOID
		SetMenuDialogOptions(displayColors)
		SetMenuDialogDefaultIndex(0)
		SetMenuDialogStartIndex(primCol)
	ElseIf opt == secMatOID
		SetMenuDialogOptions(displayMaterials)
		SetMenuDialogDefaultIndex(0)
		SetMenuDialogStartIndex(secMat)
	ElseIf opt == secColOID
		SetMenuDialogOptions(displayColors)
		SetMenuDialogDefaultIndex(0)
		SetMenuDialogStartIndex(secCol)
	EndIf
EndEvent

Event OnOptionMenuAccept(int opt, int index)
	If opt == allowedGenderOID
		allowedGender = index
		SetMenuOptionValue(opt, genders[allowedGender])
		util.log("Allowed gender set to: " + allowedGender)
	ElseIf opt == noFastOID
		noFast = index
		SetMenuOptionValue(opt, noFastOpt[noFast])
		util.log("Fast travel restriction set to: " + noFastOpt[noFast])
	ElseIf opt == primMatOID
		primMat = index
		SetMenuOptionValue(opt, displayMaterials[primMat])
	ElseIf opt == primColOID
		primCol = index
		SetMenuOptionValue(opt, displayColors[primCol])
	ElseIf opt == secMatOID
		secMat = index
		SetMenuOptionValue(opt, displayMaterials[secMat])
	ElseIf opt == secColOID
		secCol = index
		SetMenuOptionValue(opt, displayColors[secCol])
	EndIf
EndEvent

Event OnOptionSliderOpen(int opt)
	If opt == restrictiveChanceOID
		SetSliderDialogStartValue(restrictiveChance)
		SetSliderDialogDefaultValue(restrictiveChanceDefault)
		SetSliderDialogRange(0, 100)
		SetSliderDialogInterval(1)
	ElseIf opt == enemyItemChanceOID
		SetSliderDialogStartValue(enemyItemChance)
		SetSliderDialogDefaultValue(enemyItemChanceDefault)
		SetSliderDialogRange(0, 100)
		SetSliderDialogInterval(1)
	EndIf
EndEvent

Event OnOptionSliderAccept(int opt, float val)
	If opt == restrictiveChanceOID
		restrictiveChance = val as int
		SetSliderOptionValue(opt, restrictiveChance, "{0}%")
		util.log("Restrictive item chance set to: " + restrictiveChance)
	ElseIf opt == enemyItemChanceOID
		enemyItemChance = val as int
		SetSliderOptionValue(opt, enemyItemChance, "{0}%")
		util.log("Enemy item chance set to: " + enemyItemChance)
	EndIf
EndEvent

Event OnOptionSelect(int opt)
;	util.log("OnOptionSelect()")
	If opt == cloakOID
		CloakEnabled = !CloakEnabled
		SetToggleOptionValue(cloakOID, CloakEnabled)
		If CloakEnabled
			pl.AddSpell(cloakSpell, false)
			util.log("Cloak Enabled")
		Else
			pl.RemoveSpell(cloakSpell)
			util.log("Cloak Disabled")
		EndIf
	ElseIf opt == stripOID
		stripBelt = !stripBelt
		SetToggleOptionValue(stripOID, stripBelt)
		util.log("Belt stripping changed to: " + stripBelt)
	ElseIf opt == uninstOID
		If !uninst
			SetTextOptionValue(uninstOID, "Are you sure?")
			uninst = true
		Else
			SetTextOptionValue(uninstOID, "Done")
			uninstall()
		EndIf
	ElseIf opt == panicOID
		If !panic
			SetTextOptionValue(panicOID, "Are you sure?")
			panic = true
		Else
			SetTextOptionValue(panicOID, "Done")
			;creatureQuest.StopCreatureScene()
			util.StopAllFollowerThreads()
			util.SetFollowerAnimation()
			util.StopSceneAndClear()
		EndIf
	ElseIf opt == loggingOID
		logging = !logging
		SetToggleOptionValue(loggingOID, logging)
	ElseIf opt == armbinderOID
		armbinder = !armbinder
		SetToggleOptionValue(armbinderOID, armbinder)
	ElseIf opt == cBeltOID
		cBelt = !cBelt
		SetToggleOptionValue(cBeltOID, cBelt)
	ElseIf opt == braOID
		bra = !bra
		SetToggleOptionValue(braOID, bra)
	ElseIf opt == collarOID
		collar = !collar
		SetToggleOptionValue(collarOID, collar)
	ElseIf opt == gagOID
		gag = !gag
		SetToggleOptionValue(gagOID, gag)
	ElseIf opt == armcuffsOID
		armcuffs = !armcuffs
		SetToggleOptionValue(armcuffsOID, armcuffs)
	ElseIf opt == legcuffsOID
		legcuffs = !legcuffs
		SetToggleOptionValue(legcuffsOID, legcuffs)
	ElseIf opt == blindfoldOID
		blindfold = !blindfold
		SetToggleOptionValue(blindfoldOID, blindfold)
	ElseIf opt == harnessOID
		harness = !harness
		SetToggleOptionValue(harnessOID, harness)
	ElseIf opt == bootsOID
		boots = !boots
		SetToggleOptionValue(bootsOID, boots)
	ElseIf opt == heavybondOID
		heavybond = !heavybond
		SetToggleOptionValue(heavybondOID, heavybond)		
	ElseIf opt == onlyUnarmedOID
		onlyUnarmed = !onlyUnarmed
		SetToggleOptionValue(onlyUnarmedOID, onlyUnarmed)
		util.log("While unarmed set to: " + onlyUnarmed)
		if onlyUnarmed ; Only trigger attacks when player is unarmed, check for the armed status now
			util.checkForWeapons()
			whileSheathed = false
			SetToggleOptionValue(whileSheathedOID, whileSheathed)
			WD_SheathedTrigger.SetValueInt(0)
		else ; always trigger attacks, force the global to unarmed state
			WD_PlayerHasWeaponEquipped.SetValueInt(0)
		endIf
	ElseIf opt == whileSheathedOID
		whileSheathed = !whileSheathed
		SetToggleOptionValue(whileSheathedOID, whileSheathed)
		util.log("While sheathed set to: " + whileSheathed)
		if whileSheathed
			WD_SheathedTrigger.SetValueInt(1)
			onlyUnarmed = false
			SetToggleOptionValue(onlyUnarmedOID, onlyUnarmed)
			WD_PlayerHasWeaponEquipped.SetValueInt(0)
		else
			WD_SheathedTrigger.SetValueInt(0)
		endIf
	ElseIf opt == dropWeaponsOID
		dropWeapons = !dropWeapons
		SetToggleOptionValue(dropWeaponsOID, dropWeapons)
		util.RegisterWeaponDrop()
		util.log("Drop weapons set to: " + dropWeapons)
	ElseIf opt == messagesOID
		messages = !messages
		SetToggleOptionValue(messagesOID, messages)
	ElseIf opt == stealKeysOID
		stealKeys = !stealKeys
		SetToggleOptionValue(stealKeysOID, stealKeys)
		util.log("Steal keys set to: " + stealKeys)
	ElseIf opt == requireKeysOID
		requireKeys = !requireKeys
		SetToggleOptionValue(requireKeysOID, requireKeys)
		util.log("Require keys set to: " + requireKeys)
	ElseIf opt == stealGearOID
		stealGear = !stealGear
		SetToggleOptionValue(stealGearOID, stealGear)
		util.log("Gold stealing set to: " + stealGear)
	ElseIf opt == onlyAggressiveOID
		onlyAggressive = !onlyAggressive
		SetToggleOptionValue(onlyAggressiveOID, onlyAggressive)
		util.log("Only aggressive animations: " + onlyAggressive)
	ElseIf opt == debugOID
		SetTextOptionValue(debugOID, "done")
;		util.log("Debug random equip")
;		Utility.Wait(0.1)
;		devman.SplitItems(util.pl)
;		devman.StoreInventory(util.pl)
;		devman.EquipRandomDevices(util.pl, restrictiveChance)
;		devman.ClearStoredInventory(util.pl)
;		
;		util.FindFollowers()
;		util.EquipFollowers()
		StorageUtil.FormListClear(none, util.followerList)
	ElseIf opt == debug02OID
		util.FindFollowers()
		SetTextOptionValue(debug02OID, "done")
	ElseIf opt == debug03OID
		StorageUtil.FormListClear(none, util.keywordList)
		SetTextOptionValue(debug03OID, "done")
	ElseIf opt == randomEquipOID
		randomEquip = !randomEquip
		SetToggleOptionValue(randomEquipOID, randomEquip)
		util.log("Random equip set to: " + randomEquip)
		if randomEquip
			SetOptionFlags(restrictiveChanceOID, OPTION_FLAG_NONE)
			SetOptionFlags(enemyItemChanceOID, OPTION_FLAG_NONE)
			SetOptionFlags(allowBlindOID, OPTION_FLAG_NONE)
			SetOptionFlags(allowBootsOID, OPTION_FLAG_NONE)
		else
			SetOptionFlags(restrictiveChanceOID, OPTION_FLAG_DISABLED)
			SetOptionFlags(enemyItemChanceOID, OPTION_FLAG_DISABLED)
			SetOptionFlags(allowBlindOID, OPTION_FLAG_DISABLED)
			SetOptionFlags(allowBootsOID, OPTION_FLAG_DISABLED)
		endIf
;	ElseIf opt == creatureOID
;		creaturesEnabled = !creaturesEnabled
;		SetToggleOptionValue(creatureOID, creaturesEnabled)
;		if creaturesEnabled
;			WD_CreatureEnabler.SetValueInt(1)
;		else
;			WD_CreatureEnabler.SetValueInt(0)
;		EndIf
;		util.log("Creatures set to: " + creaturesEnabled)
	ElseIf opt == followersOID
		followers = !followers
		SetToggleOptionValue(followersOID, followers)
		util.log("Followers enabled: " + followers)
	ElseIf opt == stripArmbinderOID
		stripArmbinder = !stripArmbinder
		SetToggleOptionValue(stripArmbinderOID, stripArmbinder)
		util.log("Armbinder stripping set to: " + stripArmbinder)
	ElseIf opt == overrideStripOID
		overrideStrip = !overrideStrip
		SetToggleOptionValue(overrideStripOID, overrideStrip)
		util.log("Strip override set to: " + overrideStrip)
;	ElseIf opt == priceBiasOID
;		priceBias = !priceBias
;		SetToggleOptionValue(priceBiasOID, priceBias)
;		pl.RemovePerk(pricePerk)
;		If priceBias
;			pl.AddPerk(pricePerk)
;		EndIf
;		util.log("Price bias set to: " + priceBias)
	ElseIf opt == suspendOID
		util.WD_SuspendScenes.SetValueInt(0)
		SetTextOptionValue(suspendOID, "No")
	ElseIf opt == allowBlindOID
		allowBlind = !allowBlind
		SetToggleOptionValue(allowBlindOID, allowBlind)
	ElseIf opt == allowBootsOID
		allowBoots = !allowBoots
		SetToggleOptionValue(allowBootsOID, allowBoots)
	EndIf
EndEvent

Event OnOptionHighlight(int opt)
	If opt == stripOID
		SetInfoText("Attackers try to strip equipped chastity belts. ")
	ElseIf opt == cloakOID
		SetInfoText("Enables the attack scenes from this mod when wearing any of the selected items from the triggers page.\nDisable this temporarily if you have problems with brawls.")
	ElseIf opt == uninstOID
		SetInfoText("Uninstalls the mod.")
	ElseIf opt == loggingOID
		SetInfoText("Enables papyrus logging for troubleshooting")
	ElseIf opt == onlyUnarmedOID
		SetInfoText("With this on, attacks trigger only when you have no weapons or spells equipped.")
	ElseIf opt == whileSheathedOID
		SetInfoText("Attacks trigger only when you have no weapons or spells out.\nIn other words, when weapons and spells are sheathed or not equipped.\nFists do not count as weapons for this.")
	ElseIf opt == dropWeaponsOID
		SetInfoText("Certain device events such as plug vibrations might make you drop your weapons. ")
	ElseIf opt == messagesOID
		SetInfoText("Enables immersive messages during certain events like plug vibrations. ")
	ElseIf opt == stealKeysOID
		SetInfoText("Attackers will steal any chastity or restraint keys you have in your inventory.")
	ElseIf opt == requireKeysOID
		SetInfoText("Attackers strip the belt only if they have the proper key on them.")
	ElseIf opt == stealGearOID
		SetInfoText("Most of your gold & non-quest items will be stolen during scenes. ")
	;ElseIf opt == capturedDreamsOID
	;	SetInfoText("Enables integration with Captured Dreams.\nAttackers might steal any deliveries from the Captured Dreams shop. ")
	ElseIf opt == onlyAggressiveOID
		SetInfoText("With this enabled, only aggressive SexLab animations will play during scenes.\nDisabling allows for more animation variety, but can also lead to cuddling with the attackers.")
	ElseIf opt == randomEquipOID
		SetInfoText("Before letting you go, enemies will use random devices from your own inventory on you.\nRegardless of this setting they might add an armbinder.\nThis option can also add slightly longer delays on scene start and end.")
	ElseIf opt == restrictiveChanceOID
		SetInfoText("When equipping random items on you at scene end, gags, armbinders and blindfolds have this chance to be equipped. Rest of the items will always get equipped.\nDefault is 40%.")
	;ElseIf opt == creatureOID
	;	SetInfoText("Enables possible Draugr attacks. They behave a bit differently from human attackers\nand might not always respect all the other settings.")
	ElseIf opt == followersOID
		SetInfoText("Includes followers in the scenes. They won't trigger any attacks but human enemies will take advantage of any follower you have with you.")
	ElseIf opt == stripArmbinderOID
		SetInfoText("Attackers try to strip equipped armbinders.")
	ElseIf opt == allowedGenderOID
		SetInfoText("Limits the attacker sex to the selected one, the others will still gather around.")
	ElseIf opt == panicOID
		SetInfoText("Resets the scenes, clears all attackers making them hostile and removes player from the used temporary faction.\nWon't stop running SexLab animations.")
	ElseIf opt == overrideStripOID
		SetInfoText("Ignore SexLab armor strip options.")
;	ElseIf opt == priceBiasOID
;		SetInfoText("Worn devices affect buy and sell prices, making items more expensive to buy and cheaper to sell.")
	ElseIf opt == suspendOID
		SetInfoText("Other mods can temporarily suspend the attack scenes. Clicking this will reset the setting and resume starting the scenes.")
	ElseIf opt == enemyItemChanceOID
		SetInfoText("Per item chance for enemies to have items with them to equip on you when using the random equip option.")
	ElseIf opt == noFastOID
		SetInfoText("Disables fast travel when wearing restraints. ")
	ElseIf opt == primMatOID || opt == primColOID
		SetInfoText("Primary preference for the item types enemies might be carrying around.")
	ElseIf opt == secMatOID || opt == secColOID
		SetInfoText("Secondary preference for the item types enemies might be carrying around. This is used if the first preference is not applicable, for example if primary is set to metal, this one is used for armbinders.")
	ElseIf opt == allowBlindOID
		SetInfoText("Allows enemies to equip you with blindfolds as per the enemy item chance. Disabling this won't have any effect for blindfolds equipped from your own inventory.")
	ElseIf opt == allowBootsOID
		SetInfoText("Allows enemies to equip you with boots as per the enemy item chance. Disabling this won't have any effect for boots equipped from your own inventory.")
	EndIf
EndEvent

function uninstall()
	util.log("Uninstall()")
	ShowMessage("Close the menu and wait for a success message.\nThe mod is safe to remove afterwards.\nIf you plan to re-install, you need to do a clean save to have the mod properly start afterwards.", false)
	Utility.wait(0.1)
	pl.RemoveSpell(cloakSpell)
	;creatureQuest.StopCreatureScene()
	;pl.RemovePerk(pricePerk)
	util.Uninstall()
endFunction

event OnGameReload()
	parent.OnGameReload()
	If util == none || util.libs == none
		Debug.Trace("[Helpless]: *ERROR* corrupted installation, util: " + util + ", libs: " + util.libs)
		Debug.MessageBox("Your installation of Deviously Helpless is corrupted.\nOnly way to recover is to remove the mod completely, do a clean save without the mod and then reinstall it.")
		return
	EndIf
	compat.CompatibilityCheck()
	PyUtils()
;	if !util.libs.BoundAnimsAvailable || !libs.config.useBoundAnims
;		stripArmbinder = true
;	endif
;	if !SexLab.AllowedCreature(creatureQuest.DraugrRace)
;		creaturesEnabled = false
;		WD_CreatureEnabler.SetValueInt(0)
;	endif
	util.log("Deviously Helpless Redux " + util.GetVersionString() + " loaded.")
endEvent

Event OnConfigClose()
	util.log("OnConfigClose()")
	PopulateKeywordList()
	SendModEvent("dhlp-maintenance")
EndEvent
