Scriptname WSN_Divine_NordicLaws_Script extends ActiveMagicEffect
{Enforces the "Never openly break the laws of Skyrim" tenet for the addon's Nordic deities.

 Attached (Script archetype) to each Nordic deity's Tenets ability, so it is live only while that
 deity is being worshipped - the tenet ability is added on StartWorship and removed on StopWorship.
 It mirrors Wintersun's own good-deity bounty penalty in
 WSN_EventProcessor_Quest.OnTrackedStatsEvent, which is hardcoded to a whitelist of good-deity
 WorshipIDs. When a hold bounty rises, favor with the current deity drops by WSN_PenaltyPerBounty
 per point of bounty gained. Wintersun's whitelist does not include our indices (52+, or 55+ under
 the Tribunal patch), so the penalty is delivered here instead, without editing the compiled
 TrackerQuest/EventProcessor .pex.

 Because the script rides the tenet ability, QueueFavorChange always targets whichever Nordic deity
 is currently active - no hardcoded deity index, so the same MagicEffect works in both the base and
 Wintersun-Tribunal load orders where every Nordic index shifts by three.}

;-- Properties -------------------------------------------------------------
WSN_TrackerQuest_Quest Property WSN_TrackerQuest Auto
{Wintersun's central quest (FormKey 005901). QueueFavorChange applies favor to the current deity.}

GlobalVariable Property WSN_PenaltyPerBounty Auto
{Favor change per point of bounty gained. Reuses Wintersun's
 WSN_ModifyFavor_Divine_AnyGoodDeity_FavorPerBounty (06AD14) = -0.1, so gaining a bounty loses favor.}

;-- Events -----------------------------------------------------------------
Event OnEffectStart(Actor akTarget, Actor akCaster)
    ; No-arg form registers for every tracked stat; we filter to hold bounties below.
    RegisterForTrackedStatsEvent()
EndEvent

Event OnEffectFinish(Actor akTarget, Actor akCaster)
    ; Fires when worship of this deity stops and the tenet ability is removed.
    UnregisterForTrackedStatsEvent()
EndEvent

Event OnTrackedStatsEvent(String asStat, Int aiValue)
    ; Only penalise when a bounty rises; paying a bounty off (delta <= 0) must not refund favor.
    If aiValue <= 0 || WSN_TrackerQuest == None
        Return
    EndIf
    If IsBountyStat(asStat)
        ; Mirrors Wintersun's good-deity branch verbatim (penalty * bounty amount).
        WSN_TrackerQuest.QueueFavorChange(WSN_PenaltyPerBounty.GetValue() * (aiValue as Float), true, false)
    EndIf
EndEvent

;-- Helpers ----------------------------------------------------------------
Bool Function IsBountyStat(String asStat)
    ; The ten hold-bounty tracked stats Wintersun watches (incl. the Orc Strongholds "Tribal Orcs").
    Return asStat == "Eastmarch Bounty" || asStat == "Falkreath Bounty" || asStat == "Haafingar Bounty" || asStat == "Hjaalmarch Bounty" || asStat == "The Pale Bounty" || asStat == "The Reach Bounty" || asStat == "The Rift Bounty" || asStat == "Tribal Orcs Bounty" || asStat == "Whiterun Bounty" || asStat == "Winterhold Bounty"
EndFunction
