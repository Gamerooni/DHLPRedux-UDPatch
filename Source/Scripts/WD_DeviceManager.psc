Scriptname WD_DeviceManager extends Quest
{Manipulates Devious Devices in actor inventory}
; This would be so much easier with at the very least some 2d arrays >.>

import StorageUtil

zadLibs Property libs Auto
WD_Util Property util Auto
WD_Compatibility Property compat Auto
WD_Config Property config Auto
string Property modName = "deviceinv" Auto
{This name should be unique to your mod, to avoid conflicts with other mods using this script}

; Sublists
string beltlist
string bralist
string collarlist
string armcufflist
string legcufflist
string gaglist
string vagpluglist
string anpluglist
string armbinderlist
string blindfoldlist
string bootslist
string[] lists

Function InitLists()
{This should be called first before doing anything else, to make sure all the lists are named properly and available.
Running this once on mod install or version update is enough}
	beltlist 		= modName + "belt"
	bralist 		= modName + "bra"
	collarlist 	= modName + "collar"
	armcufflist 	= modName + "armcuff"
	legcufflist 	= modName + "legcuff"
	gaglist 		= modName + "gag"
	vagpluglist 	= modName + "vagplug"
	anpluglist		= modName + "anplug"
	armbinderlist	= modName + "armbinder"
	blindfoldlist	= modName + "blindfold"
	bootslist		= modName + "bootslist"
	
	lists = new string[11]
	lists[0] = vagpluglist
	lists[1] = anpluglist
	lists[2] = beltlist
	lists[3] = bralist
	lists[4] = legcufflist
	lists[5] = armcufflist
	lists[6] = collarlist
	lists[7] = bootslist
	lists[8] = gaglist
	lists[9] = armbinderlist
	lists[10] = blindfoldlist
EndFunction

Function SplitItems(Actor akActor)
{Splits cuff and plug sets into individual items to allow easier management}
	
	; Padded cuff set
	int num = akActor.GetItemCount(libs.cuffsPaddedComplete)
	num -= akActor.GetItemCount(libs.cuffsPaddedCompleteRendered)
	if num > 0
		akActor.RemoveItem(libs.cuffsPaddedComplete, num, true)
		akActor.AddItem(libs.cuffsPaddedCollar, num, true)
		akActor.AddItem(libs.cuffsPaddedArms, num, true)
		akActor.AddItem(libs.cuffsPaddedLegs, num, true)
	EndIf
	
	; Iron plugs
	num = akActor.GetItemCount(libs.plugIron)
	num -= akActor.GetItemCount(libs.plugIronRendered)
	if num > 0
		akActor.RemoveItem(libs.plugIron, num, true)
		akActor.AddItem(libs.plugIronAn, num, true)
		akActor.AddItem(libs.plugIronVag, num, true)
	EndIf
	
	; Primitive plugs
	num = akActor.GetItemCount(libs.plugPrimitive)
	num -= akActor.GetItemCount(libs.plugPrimitiveRendered)
	if num > 0
		akActor.RemoveItem(libs.plugPrimitive, num, true)
		akActor.AddItem(libs.plugPrimitiveAn, num, true)
		akActor.AddItem(libs.plugPrimitiveVag, num, true)
	EndIf
	
	; Inflatable plugs
	num = akActor.GetItemCount(libs.pluginflatable)
	num -= akActor.GetItemCount(libs.pluginflatableRendered)
	if num > 0
		akActor.RemoveItem(libs.pluginflatable, num, true)
		akActor.AddItem(libs.pluginflatableAn, num, true)
		akActor.AddItem(libs.pluginflatableVag, num, true)
	EndIf

	; Soulgem plugs
	num = akActor.GetItemCount(libs.plugsoulgem)
	num -= akActor.GetItemCount(libs.plugsoulgemRendered)
	if num > 0
		akActor.RemoveItem(libs.plugsoulgem, num, true)
		akActor.AddItem(libs.plugsoulgemAn, num, true)
		akActor.AddItem(libs.plugsoulgemVag, num, true)
	EndIf
EndFunction

Function StoreInventory(Actor akActor, bool ignoreWornType = true)
{Stores any devices the actor has in her inventory in the appropriate lists, count is ignored. If ignoreWornType is set, worn item types are skipped}
	util.log("StoreInventory()")
	int i = akActor.GetNumItems()
	Form f
	zadEquipScript device
	While i > 0
		i -= 1
		f = akActor.GetNthForm(i)
		If f.HasKeyword(libs.zad_InventoryDevice) && !f.HasKeyword(libs.zad_BlockGeneric)
			device = akActor.placeAtMe(f, abInitiallyDisabled = true) as zadEquipScript
			if device
				If device.zad_DeviousDevice == libs.zad_deviousBelt && (!ignoreWornType || !akActor.WornHasKeyword(libs.zad_DeviousBelt))
					FormListAdd(akActor, beltlist, f, false)		
				ElseIf device.zad_DeviousDevice == libs.zad_DeviousBra && (!ignoreWornType || !akActor.WornHasKeyword(libs.zad_DeviousBra))
					FormListAdd(akActor, bralist, f, false)
				ElseIf device.zad_DeviousDevice == libs.zad_DeviousCollar && (!ignoreWornType || !akActor.WornHasKeyword(libs.zad_DeviousCollar))
					FormListAdd(akActor, collarlist, f, false)
				ElseIf device.zad_DeviousDevice == libs.zad_DeviousArmCuffs && (!ignoreWornType || !akActor.WornHasKeyword(libs.zad_DeviousArmCuffs))
					FormListAdd(akActor, armcufflist, f, false)
				ElseIf device.zad_DeviousDevice == libs.zad_DeviousLegCuffs && (!ignoreWornType || !akActor.WornHasKeyword(libs.zad_DeviousLegCuffs))
					FormListAdd(akActor, legcufflist, f, false)
				ElseIf device.zad_DeviousDevice == libs.zad_DeviousGag && (!ignoreWornType || !akActor.WornHasKeyword(libs.zad_DeviousGag))
					FormListAdd(akActor, gaglist, f, false)
				ElseIf device.zad_DeviousDevice == libs.zad_DeviousPlugVaginal && (!ignoreWornType || !akActor.WornHasKeyword(libs.zad_DeviousPlugVaginal))
					FormListAdd(akActor, vagpluglist, f, false)
				ElseIf device.zad_DeviousDevice == libs.zad_DeviousPlugAnal && (!ignoreWornType || !akActor.WornHasKeyword(libs.zad_DeviousPlugAnal))
					FormListAdd(akActor, anpluglist, f, false)
				ElseIf device.zad_DeviousDevice == libs.zad_DeviousArmbinder && (!ignoreWornType || !akActor.WornHasKeyword(libs.zad_DeviousArmbinder))
					FormListAdd(akActor, armbinderlist, f, false)
				ElseIf device.zad_DeviousDevice == libs.zad_deviousBlindfold && (!ignoreWornType || !akActor.WornHasKeyword(libs.zad_deviousBlindfold))
					FormListAdd(akActor, blindfoldlist, f, false)
				ElseIf device.zad_DeviousDevice == libs.zad_DeviousBoots && (!ignoreWornType || !akActor.WornHasKeyword(libs.zad_DeviousBoots))
					FormListAdd(akActor, bootslist, f, false)
				EndIf
			endif
			device.delete()
		EndIf				
	EndWhile
	
	; Special cases, which have the generic blocking keyword
;	if akActor.GetItemCount(util.beltRusted) > 0 && (!ignoreWornType || !akActor.WornHasKeyword(libs.zad_DeviousBelt))
;		FormListAdd(akActor, beltlist, util.beltRusted, false)
;	EndIf
	
	; Enemies might have some items on them as well...
	If (!ignoreWornType || !akActor.WornHasKeyword(libs.zad_DeviousBra)) && Utility.RandomInt(0, 99) < config.enemyItemChance
		FormListAdd(akActor, bralist, GetPreferredDevice(libs.zad_DeviousBra), false)
	EndIf
	If (!ignoreWornType || !akActor.WornHasKeyword(libs.zad_DeviousCollar)) && Utility.RandomInt(0, 99) < config.enemyItemChance
		FormListAdd(akActor, collarlist, GetPreferredDevice(libs.zad_DeviousCollar), false)
	EndIf
	If (!ignoreWornType || !akActor.WornHasKeyword(libs.zad_DeviousArmCuffs)) && Utility.RandomInt(0, 99) < config.enemyItemChance
		FormListAdd(akActor, armcufflist, GetPreferredDevice(libs.zad_DeviousArmCuffs), false)
	EndIf
	If (!ignoreWornType || !akActor.WornHasKeyword(libs.zad_DeviousLegCuffs)) && Utility.RandomInt(0, 99) < config.enemyItemChance
		FormListAdd(akActor, legcufflist, GetPreferredDevice(libs.zad_DeviousLegCuffs), false)
	EndIf
	If (!ignoreWornType || !akActor.WornHasKeyword(libs.zad_DeviousGag)) && Utility.RandomInt(0, 99) < config.enemyItemChance
		FormListAdd(akActor, gaglist, GetPreferredDevice(libs.zad_DeviousGag), false)
	EndIf
	If (!ignoreWornType || !akActor.WornHasKeyword(libs.zad_DeviousPlugVaginal)) && Utility.RandomInt(0, 99) < config.enemyItemChance
		FormListAdd(akActor, vagpluglist, libs.GetDeviceByTags(libs.zad_DeviousPlugVaginal, "soulgem, pump", false, "littlehelper"), false)
	EndIf
	If (!ignoreWornType || !akActor.WornHasKeyword(libs.zad_DeviousPlugAnal)) && Utility.RandomInt(0, 99) < config.enemyItemChance
		FormListAdd(akActor, anpluglist, libs.GetDeviceByTags(libs.zad_DeviousPlugAnal, "simple, pump", false), false)
	EndIf
	If (!ignoreWornType || !akActor.WornHasKeyword(libs.zad_deviousBlindfold)) && Utility.RandomInt(0, 99) < config.enemyItemChance && config.allowBlind
		FormListAdd(akActor, blindfoldlist, GetPreferredDevice(libs.zad_deviousBlindfold), false)
	EndIf
	If (!ignoreWornType || !akActor.WornHasKeyword(libs.zad_DeviousBoots)) && Utility.RandomInt(0, 99) < config.enemyItemChance && config.allowBoots
		FormListAdd(akActor, bootslist, GetPreferredDevice(libs.zad_DeviousBoots, "pony"), false)
	EndIf
	If (!ignoreWornType || !akActor.WornHasKeyword(libs.zad_DeviousBelt)) && ( Utility.RandomInt(0, 99) < config.enemyItemChance || ( FormListCount(akActor, beltlist) < 1 && ( FormListCount(akActor, vagpluglist) > 0 || FormListCount(akActor, anpluglist) > 0 ) ) )
		; Always add a belt if the beltlist is empty but there are plugs to be equipped
		Armor belt = GetPreferredDevice(libs.zad_DeviousBelt)
		FormListAdd(akActor, beltlist, belt, false)
		
		; If no plugs on the lists, high chance to add some
		If FormListCount(akActor, vagpluglist) < 1 && Utility.RandomInt(0, 99) < 60
			FormListAdd(akActor, vagpluglist, libs.GetDeviceByTags(libs.zad_DeviousPlugVaginal, "soulgem,pump", false, "littlehelper"), false)
		EndIf
		
		If libs.HasTag(belt, "full") && FormListCount(akActor, anpluglist) < 1 && Utility.RandomInt(0, 99) < 60
			FormListAdd(akActor, anpluglist, libs.GetDeviceByTags(libs.zad_DeviousPlugAnal, "simple,pump", false), false)
		EndIf
	EndIf
EndFunction

Armor Function GetPreferredDevice(Keyword kw, String extraTags = "")
	If config.primMat == 0 && config.primCol == 0
		return libs.GetGenericDeviceByKeyword(kw)
	EndIf
	
	String tags = ""
	If config.primMat > 0
		tags += config.materials[config.primMat]
	EndIf
	If config.primCol > 0
		If tags != ""
			tags += ","
		EndIf
		tags += config.colors[config.primCol]
	EndIf
	If extraTags != ""
		If tags != ""
			tags += ","
		EndIf
		tags += extraTags
	EndIf
	bool fallBack = config.secMat == 0 && config.secCol == 0
	Armor device = libs.GetDeviceByTags(kw, tags, true, "", fallBack)
	If device == none
		if config.secMat > 0
			tags = config.materials[config.secMat]
		EndIf
		if config.secCol > 0
			If tags != ""
				tags += ","
			EndIf

			tags += config.colors[config.secCol]
		EndIf 
		If extraTags != ""
			If tags != ""
				tags += ","
			EndIf
			tags += extraTags
		EndIf
		device = libs.GetDeviceByTags(kw, tags)	
	EndIf
	return device
EndFunction

Function EquipRandomDevices(Actor akActor, int restrictiveChance = 40)
{Equips the actor with random devices from her inventory, based on data stored with StoreInventory().
restrictiveChance sets the probablity to equip gags, armbinders and blindfolds.}

	; The lists array should be traversed from start to end to equip plugs before belts
	int i = 0
	int count
;	bool skipEvents = false
	While i < lists.length
		count = FormListCount(akActor, lists[i])
		if count > 0 && ( i < 8 || Utility.RandomInt(0, 99) < restrictiveChance ) && ( i > 1 || !akActor.WornHasKeyword(libs.zad_DeviousBelt) )  
			; Configurable chance for gags, armbinders and blindfolds, rest are always equipped
			; Prevent trying to equip plugs if a belt is equipped
			Armor device = FormListGet(akActor, lists[i], Utility.RandomInt(0, count - 1)) as Armor
			if device 
				util.log("Equipping " + akActor.GetLeveledActorBase().GetName() + " with " + device.GetName() + ".")
			;	util.ManipulateDevice(akActor, device, true, skipEvents = false)
				libs.LockDevice( akActor, device )
			endIf
			; Possible conflict if equipping the body harness, and collars afterward
		EndIf	
		i += 1
	EndWhile
EndFunction

Function ClearStoredInventory(Actor akActor)
{Clears the stored device inventory for the given actor}
	int i = lists.length
	While i > 0
		i -= 1
		FormListClear(akActor, lists[i])
	EndWhile
EndFunction

Function RemoveUnusedItems(Actor akActor, ObjectReference transferTo = none)
{Removes any devices not worn from the given actor and optionally transfers them to the given container (or actor).}

	; Belts
	int num = akActor.GetItemCount(libs.beltPadded) - akActor.GetItemCount(libs.beltPaddedRendered)
	if num > 0
		akActor.RemoveItem(libs.beltPadded, num, true, transferTo)
	EndIf
	num = akActor.GetItemCount(libs.beltPaddedOpen) - akActor.GetItemCount(libs.beltPaddedOpenRendered)
	if num > 0
		akActor.RemoveItem(libs.beltPaddedOpen, num, true, transferTo)
	EndIf
	num = akActor.GetItemCount(libs.beltIron) - akActor.GetItemCount(libs.beltIronRendered)
	if num > 0
		akActor.RemoveItem(libs.beltIron, num, true, transferTo)
	EndIf
	num = akActor.GetItemCount(libs.harnessBody) - akActor.GetItemCount(libs.harnessBodyRendered)
	if num > 0
		akActor.RemoveItem(libs.harnessBody, num, true, transferTo)
	EndIf
	
	; Bra
	num = akActor.GetItemCount(libs.braPadded) - akActor.GetItemCount(libs.braPaddedRendered)
	if num > 0
		akActor.RemoveItem(libs.braPadded, num, true, transferTo)
	EndIf
	
	; Collars
	num = akActor.GetItemCount(libs.cuffsPaddedCollar) - akActor.GetItemCount(libs.cuffsPaddedCollarRendered)
	if num > 0
		akActor.RemoveItem(libs.cuffsPaddedCollar, num, true, transferTo)
	EndIf
	num = akActor.GetItemCount(libs.cuffsLeatherCollar) - akActor.GetItemCount(libs.cuffsLeatherCollarRendered)
	if num > 0
		akActor.RemoveItem(libs.cuffsLeatherCollar, num, true, transferTo)
	EndIf
	num = akActor.GetItemCount(libs.collarPosture) - akActor.GetItemCount(libs.collarPostureRendered)
	if num > 0
		akActor.RemoveItem(libs.collarPosture, num, true, transferTo)
	EndIf
	num = akActor.GetItemCount(libs.harnessCollar) - akActor.GetItemCount(libs.harnessCollarRendered)
	if num > 0
		akActor.RemoveItem(libs.harnessCollar, num, true, transferTo)
	EndIf
	
	; Arm cuffs
	num = akActor.GetItemCount(libs.cuffsPaddedArms) - akActor.GetItemCount(libs.cuffsPaddedArmsRendered)
	if num > 0
		akActor.RemoveItem(libs.cuffsPaddedArms, num, true, transferTo)
	EndIf
	num = akActor.GetItemCount(libs.cuffsLeatherArms) - akActor.GetItemCount(libs.cuffsLeatherArmsRendered)
	if num > 0
		akActor.RemoveItem(libs.cuffsLeatherArms, num, true, transferTo)
	EndIf
	
	; Leg cuffs
	num = akActor.GetItemCount(libs.cuffsPaddedLegs) - akActor.GetItemCount(libs.cuffsPaddedLegsRendered)
	if num > 0
		akActor.RemoveItem(libs.cuffsPaddedLegs, num, true, transferTo)
	EndIf
	num = akActor.GetItemCount(libs.cuffsLeatherLegs) - akActor.GetItemCount(libs.cuffsLeatherLegsRendered)
	if num > 0
		akActor.RemoveItem(libs.cuffsLeatherLegs, num, true, transferTo)
	EndIf
	
	; Gags
	num = akActor.GetItemCount(libs.gagBall) - akActor.GetItemCount(libs.gagBallRendered)
	if num > 0
		akActor.RemoveItem(libs.gagBall, num, true, transferTo)
	EndIf
	num = akActor.GetItemCount(libs.gagPanel) - akActor.GetItemCount(libs.gagPanelRendered)
	if num > 0
		akActor.RemoveItem(libs.gagPanel, num, true, transferTo)
	EndIf
	num = akActor.GetItemCount(libs.gagRing) - akActor.GetItemCount(libs.gagRingRendered)
	if num > 0
		akActor.RemoveItem(libs.gagRing, num, true, transferTo)
	EndIf
	num = akActor.GetItemCount(libs.gagStrapBall) - akActor.GetItemCount(libs.gagStrapBallRendered)
	if num > 0
		akActor.RemoveItem(libs.gagStrapBall, num, true, transferTo)
	EndIf
	num = akActor.GetItemCount(libs.gagStrapRing) - akActor.GetItemCount(libs.gagStrapRingRendered)
	if num > 0
		akActor.RemoveItem(libs.gagStrapRing, num, true, transferTo)
	EndIf
	
	; Vaginal plugs
	num = akActor.GetItemCount(libs.plugIronVag) - akActor.GetItemCount(libs.plugIronVagRendered)
	if num > 0
		akActor.RemoveItem(libs.plugIronVag, num, true, transferTo)
	EndIf
	num = akActor.GetItemCount(libs.plugPrimitiveVag) - akActor.GetItemCount(libs.plugPrimitiveVagRendered)
	if num > 0
		akActor.RemoveItem(libs.plugPrimitiveVag, num, true, transferTo)
	EndIf
	num = akActor.GetItemCount(libs.plugSoulgemVag) - akActor.GetItemCount(libs.plugSoulgemVagRendered)
	if num > 0
		akActor.RemoveItem(libs.plugSoulgemVag, num, true, transferTo)
	EndIf
	num = akActor.GetItemCount(libs.plugInflatableVag) - akActor.GetItemCount(libs.plugInflatableVagRendered)
	if num > 0
		akActor.RemoveItem(libs.plugInflatableVag, num, true, transferTo)
	EndIf
	num = akActor.GetItemCount(libs.plugChargeableVag) - akActor.GetItemCount(libs.plugChargeableRenderedVag)
	if num > 0
		akActor.RemoveItem(libs.plugChargeableVag, num, true, transferTo)
	EndIf
	
	; Anal plugs
	num = akActor.GetItemCount(libs.plugIronAn) - akActor.GetItemCount(libs.plugIronAnRendered)
	if num > 0
		akActor.RemoveItem(libs.plugIronAn, num, true, transferTo)
	EndIf
	num = akActor.GetItemCount(libs.plugPrimitiveAn) - akActor.GetItemCount(libs.plugPrimitiveAnRendered)
	if num > 0
		akActor.RemoveItem(libs.plugPrimitiveAn, num, true, transferTo)
	EndIf
	num = akActor.GetItemCount(libs.plugSoulgemAn) - akActor.GetItemCount(libs.plugSoulgemAnRendered)
	if num > 0
		akActor.RemoveItem(libs.plugSoulgemAn, num, true, transferTo)
	EndIf
	num = akActor.GetItemCount(libs.plugInflatableAn) - akActor.GetItemCount(libs.plugInflatableAnRendered)
	if num > 0
		akActor.RemoveItem(libs.plugInflatableAn, num, true, transferTo)
	EndIf
	
	; Armbinders
	num = akActor.GetItemCount(libs.armbinder) - akActor.GetItemCount(libs.armbinderRendered)
	if num > 0
		akActor.RemoveItem(libs.armbinder, num, true, transferTo)
	EndIf
	
	; Blindfolds
	num = akActor.GetItemCount(libs.blindfold) - akActor.GetItemCount(libs.blindfoldRendered)
	if num > 0
		akActor.RemoveItem(libs.blindfold, num, true, transferTo)
	EndIf
EndFunction
