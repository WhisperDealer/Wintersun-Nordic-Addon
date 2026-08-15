Scriptname WSN_Divine_Stuhn_Boon1_Script extends ActiveMagicEffect
{Stuhn follower boon "Whale-Bone Shield" - a favor-scaled armor bonus. Armor rating in Skyrim is
 the DamageResist actor value, which has no clean perk entry point, so genuine favor-scaling is done
 here: on a short real-time timer we read the player's current favor with Stuhn and re-apply the
 matching armor bonus with ModActorValue.

 Favor is read from WSN_Favor_Global_Fractional (Wintersun keeps it at current-deity favor x 0.1,
 i.e. favor/10 - see WSN_TrackerQuest_Quest.SetFavor). While this Follower boon is active the player
 is worshipping Stuhn, so the current-deity favor IS Stuhn's favor. Armor = favor10 * ArmorPerFavor,
 capped at MaxArmor (so favor 100 -> 40 armor, favor 200 -> 80 armor at the default ratio of 4).

 The bonus is applied as a delta: we remember the amount currently granted (currentBonus) and each
 tick ModActorValue only the difference, so the armor tracks favor up and down without stacking. When
 the boon is removed (unworship) OnEffectFinish subtracts whatever is still granted, leaving no
 residual armor. Compiles against base-game source only.}

;-- Properties -------------------------------------------------------------
GlobalVariable Property WSN_Favor_Global_Fractional Auto
{Wintersun global = current-deity favor x 0.1 (favor/10). FormKey 014A56.}

Float Property ArmorPerFavor = 4.0 Auto
{Armor rating granted per point of favor/10 (favor10 * ArmorPerFavor).}

Float Property MaxArmor = 80.0 Auto
{Cap on the granted armor rating, so favor-scaled armor plus normal gear stays well under the
 567 armor soft-cap.}

Float Property UpdateInterval = 5.0 Auto
{Real-time seconds between favor re-checks. Armor rarely needs to change fast, so this is cheap.}

;-- State ------------------------------------------------------------------
Float currentBonus = 0.0

;-- Events -----------------------------------------------------------------
Event OnEffectStart(Actor akTarget, Actor akCaster)
    If akTarget == None
        Return
    EndIf
    ApplyBonus(akTarget)
    RegisterForSingleUpdate(UpdateInterval)
EndEvent

Event OnUpdate()
    Actor player = GetTargetActor()
    If player == None
        Return
    EndIf
    ApplyBonus(player)
    RegisterForSingleUpdate(UpdateInterval)
EndEvent

Event OnEffectFinish(Actor akTarget, Actor akCaster)
    UnregisterForUpdate()
    If akTarget != None && currentBonus != 0.0
        akTarget.ModActorValue("DamageResist", -currentBonus)
    EndIf
    currentBonus = 0.0
EndEvent

;-- Helpers ----------------------------------------------------------------
; Re-apply the favor-scaled armor as a delta against whatever is currently granted.
Function ApplyBonus(Actor player)
    Float favor10 = 0.0
    If WSN_Favor_Global_Fractional != None
        favor10 = WSN_Favor_Global_Fractional.GetValue()
    EndIf
    If favor10 < 0.0
        favor10 = 0.0
    EndIf

    Float target = favor10 * ArmorPerFavor
    If target > MaxArmor
        target = MaxArmor
    EndIf

    Float delta = target - currentBonus
    If delta != 0.0
        player.ModActorValue("DamageResist", delta)
        currentBonus = target
    EndIf
EndFunction
