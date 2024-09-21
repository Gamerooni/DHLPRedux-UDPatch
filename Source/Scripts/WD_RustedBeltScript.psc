Scriptname WD_RustedBeltScript extends zadBeltScript

;GlobalVariable Property keyChanceNone Auto
Message Property keyDestroyMsg Auto
WD_RustedBeltAlias Property dropAlias Auto

Function OnEquippedPost(Actor akActor)
	parent.OnEquippedPost(akActor)
	
	If akActor == Game.GetPlayer()
		dropAlias.SetUp(akActor)
	EndIf
EndFunction

Function OnRemoveDevice(Actor akActor)
	parent.OnRemoveDevice(akActor)
	
	If akActor == Game.GetPlayer()
		dropAlias.StopDrops()

	EndIf
EndFunction

bool Function RemoveDeviceWithKey(actor akActor = none, bool destroyDevice=false)
	bool ret = parent.RemoveDeviceWithKey(akActor, destroyDevice)
	If ret
		keyDestroyMsg.show()
		Game.GetPlayer().RemoveItem(deviceKey, 1, true)
	EndIf
	return ret
EndFunction
