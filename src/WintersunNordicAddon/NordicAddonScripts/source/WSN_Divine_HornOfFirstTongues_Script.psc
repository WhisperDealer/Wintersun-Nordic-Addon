Scriptname WSN_Divine_HornOfFirstTongues_Script extends ActiveMagicEffect
{Horn of First Tongues -- while the relic is carried (equipped), favor with Nordic-faith deities
 (DivineTypeID 7) drains 20% slower and prayers to them are 15% stronger.

 Implementation: writes the per-deity individual multiplier arrays the compiled TrackerQuest reads
 generically (WSN_DrainRateMultIndividual / WSN_PrayerRateMultIndividual). Keys on DivineTypeID == 7
 (a *type*, not an index) and loops every deity, so it stays correct across god-switches and is
 load-order-safe under the Tribunal index shift (52-59 vs 55-62). Never hardcode the Nordic indices.}

WSN_TrackerQuest_Quest Property WSN_TrackerQuest Auto
{The central Wintersun quest (FormKey 005901:Wintersun - Faiths of Skyrim.esp).}

Float Property DrainMult = 0.80 Auto
{Drain multiplier applied to Nordic deities while equipped (0.80 = favor drains 20% slower).}

Float Property PrayerMult = 1.15 Auto
{Prayer-gain multiplier applied to Nordic deities while equipped (1.15 = prayers 15% stronger).}

Int Property NordicTypeID = 7 Auto
{The DivineTypeID that marks a Nordic-faith deity.}

Event OnEffectStart(Actor akTarget, Actor akCaster)
	ApplyToNordicDeities(DrainMult, PrayerMult)
EndEvent

Event OnEffectFinish(Actor akTarget, Actor akCaster)
	ApplyToNordicDeities(1.0, 1.0)   ; restore vanilla defaults -- no other system owns these arrays
EndEvent

; Set the drain/prayer multipliers on every deity whose type is Nordic, then refresh the display
; so the change shows immediately for whichever god is currently active.
Function ApplyToNordicDeities(Float afDrain, Float afPrayer)
	If WSN_TrackerQuest == None
		Return
	EndIf
	Int i = 0
	Int count = WSN_TrackerQuest.WSN_DivineTypeID.Length
	While i < count
		If WSN_TrackerQuest.WSN_DivineTypeID[i] == NordicTypeID
			WSN_TrackerQuest.WSN_DrainRateMultIndividual[i] = afDrain
			WSN_TrackerQuest.WSN_PrayerRateMultIndividual[i] = afPrayer
		EndIf
		i += 1
	EndWhile
	WSN_TrackerQuest.ProcessFavorChanges(false)
EndFunction
