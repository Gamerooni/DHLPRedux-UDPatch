Scriptname WD_RustedBeltAlias extends ReferenceAlias

WD_Util Property util Auto
GlobalVariable Property keyChanceNone Auto
Location Property DefaultLocation Auto
Location startLocation

Function SetUp(Actor akActor)
	ForceRefTo(akActor)
	startLocation = akActor.GetCurrentLocation()
	if startLocation == none
		startLocation = DefaultLocation
	endif
	util.log("Starting location monitoring for rusty key drops, started from: " + startLocation.GetName())
EndFunction

Event OnLocationChange(Location akOldLoc, Location akNewLoc)
	if akNewLoc != startLocation && keyChanceNone.GetValueInt() == 100 ; Make sure the drop chance is 0%, to not reset it back to 5% on every loc change
		string locName = "Skyrim"
		if akNewLoc
			locname = akNewLoc.GetName()
		endif
		util.log("Location changed, allowing key drops. New location: " + locname)
		keyChanceNone.SetValueInt(95)
		RegisterForSingleUpdateGameTime(18)
	elseif akNewLoc == startLocation && keyChanceNone.GetValueInt() > 94 ; Prevent just quickly going outside and returning to get key drops
		util.log("Returned to starting location (" + startLocation.GetName() + "), stopping drops.")
		keyChanceNone.SetValueInt(100)
		UnregisterForUpdateGameTime()
	endIf
EndEvent

Function StopDrops()
	util.log("Rusted belt removed, stopping key drops.")
	startLocation = none
	UnregisterForUpdateGameTime()
	keyChanceNone.SetValueInt(100)
	clear()
EndFunction

Event OnUpdateGameTime()
	if keyChanceNone.GetValueInt() > 85
		keyChanceNone.Mod(-1)
		RegisterForSingleUpdateGameTime(18)
	endIf
EndEvent
