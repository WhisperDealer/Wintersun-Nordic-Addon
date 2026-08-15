Scriptname WSN_Divine_NAMara_HearthWife_Script extends ActiveMagicEffect
{Mara devotee boon "Hearth-Wife's Protection": when the player is healed, a share of that
 healing flows to nearby followers. The share scales with favor - half your healing at devotee
 favor (100), rising to a full one-to-one share at maximum favor (200).

 There is no OnHeal event in Skyrim, so we poll the player's current Health actor value on a
 short real-time timer (RegisterForSingleUpdate). GetActorValue("Health") returns the CURRENT
 (damage-adjusted) health, so the rise since the last tick is the health the player just
 regained from any source - a potion, natural regen, or a healing spell. When that rise
 exceeds MinHealDelta we sweep for nearby followers and RestoreActorValue a share of the gain
 onto each. A fall in health (taking damage) yields a negative delta and is ignored.

 NOTE: this only fires when the PLAYER's own health rises. If the player is already at full
 health, self-healing produces no delta and followers receive nothing - inherent to the
 "share your own healing" design.

 Favor is read from WSN_Favor_Global_Fractional (Wintersun keeps it at current-deity favor x 0.1,
 i.e. favor/10 - see WSN_TrackerQuest_Quest.SetFavor). ShareFraction = favor10 / 20, so favor 100
 -> 0.5 and favor 200 -> 1.0, capped at MaxShareFraction.

 Followers are gathered with Game.FindRandomActorFromRef in a radius - the same sweep Orkey's
 "Count the Years" uses. We heal only the player's teammates (active followers), never spouses,
 housecarls, other friendly NPCs, or enemies. FindRandomActorFromRef can return the same actor
 repeatedly, so healed actors are recorded and skipped, and RestoreActorValue never exceeds an
 actor's maximum health. Compiles against base-game source only.}

;-- Properties -------------------------------------------------------------
GlobalVariable Property WSN_Favor_Global_Fractional Auto
{Wintersun global = current-deity favor x 0.1 (favor/10). FormKey 014A56.}

Float Property MaxShareFraction = 1.0 Auto
{Cap on the shared fraction (1.0 = one-to-one at maximum favor).}

Float Property UpdateInterval = 2.0 Auto
{Real-time seconds between health checks. Responsive in a fight, idle otherwise.}

Float Property Radius = 1200.0 Auto
{Search radius (game units) for followers to heal.}

Int Property MaxTargets = 10 Auto
{Cap on distinct followers healed per event. Must not exceed the 128 array below.}

Float Property MinHealDelta = 5.0 Auto
{Ignore health gains smaller than this, so trickle regen does not proc the share - only
 meaningful healing spills over to followers.}

EffectShader Property HealShader Auto
{Optional restoration shimmer played on each healed follower (HealFXS, 012FD9). Null-safe.}

;-- State ------------------------------------------------------------------
Float lastHealth = -1.0

;-- Events -----------------------------------------------------------------
Event OnEffectStart(Actor akTarget, Actor akCaster)
    If akTarget == None
        Return
    EndIf
    lastHealth = akTarget.GetActorValue("Health")
    RegisterForSingleUpdate(UpdateInterval)
EndEvent

Event OnUpdate()
    Actor player = GetTargetActor()
    If player == None
        Return
    EndIf

    Float current = player.GetActorValue("Health")
    Float delta = current - lastHealth
    lastHealth = current

    If delta >= MinHealDelta
        ShareHealing(player, delta * ShareFraction())
    EndIf

    RegisterForSingleUpdate(UpdateInterval)
EndEvent

Event OnEffectFinish(Actor akTarget, Actor akCaster)
    UnregisterForUpdate()
EndEvent

;-- Helpers ----------------------------------------------------------------
; Favor-scaled share: favor10/20 -> 0.5 at favor 100, 1.0 at favor 200. Capped at MaxShareFraction.
Float Function ShareFraction()
    If WSN_Favor_Global_Fractional == None
        Return 0.5
    EndIf
    Float favor10 = WSN_Favor_Global_Fractional.GetValue()
    Float frac = favor10 / 20.0
    If frac < 0.0
        frac = 0.0
    ElseIf frac > MaxShareFraction
        frac = MaxShareFraction
    EndIf
    Return frac
EndFunction

Function ShareHealing(Actor player, Float healAmount)
    If healAmount <= 0.0
        Return
    EndIf

    Actor[] healedActors = new Actor[128]
    Int healed = 0
    Int attempts = 0
    Int maxAttempts = MaxTargets * 8
    While attempts < maxAttempts && healed < MaxTargets
        Actor ally = Game.FindRandomActorFromRef(player, Radius)
        If ally != None && ally != player && !ally.IsDead() && ally.Is3DLoaded() && IsFollower(ally) && !AlreadyHealed(healedActors, ally, healed)
            ally.RestoreActorValue("Health", healAmount)
            If HealShader != None
                HealShader.Play(ally as ObjectReference, 1.0)
            EndIf
            healedActors[healed] = ally
            healed += 1
        EndIf
        attempts += 1
    EndWhile
EndFunction

Bool Function AlreadyHealed(Actor[] list, Actor a, Int count)
    Int i = 0
    While i < count
        If list[i] == a
            Return true
        EndIf
        i += 1
    EndWhile
    Return false
EndFunction

Bool Function IsFollower(Actor a)
    ; Only the player's active followers/teammates - not spouses, housecarls or other
    ; friendly NPCs. Standard follower frameworks flag followers as player teammates.
    Return a.IsPlayerTeammate()
EndFunction
