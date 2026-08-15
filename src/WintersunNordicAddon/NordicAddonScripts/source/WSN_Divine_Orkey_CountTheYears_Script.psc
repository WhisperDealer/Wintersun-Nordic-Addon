Scriptname WSN_Divine_Orkey_CountTheYears_Script extends ActiveMagicEffect
{Orkey devotee power "Count the Years" - a prayer that curses the living around the caster with
 rapid aging: a heavy, favor-scaled drain of Health and Stamina plus a weapon-damage penalty, as
 though decades drain out of them in seconds. Undead, Daedra and Dwarven automatons are not
 "living" and are skipped.

 Magnitude scales with favor/10, read from the actor value Wintersun mirrors favor onto
 (WSN_TrackerQuest.WSN_AV - see TrackerQuest.SetFavor, which does ForceActorValue(WSN_AV, favor*0.1)).

 Favor MUST be spent through the TrackerQuest's QueueFavorChange - writing the favor global directly
 is undone on the next favor tick because ProcessFavorChanges recomputes favor from static income.
 QueueFavorChange feeds the persistent accumulator so the cost sticks; when favor falls below the
 favored threshold Wintersun removes the power automatically.

 Health and Stamina are drained with DamageActorValue, so they recover naturally over time (the aging
 "wearing off"). The AttackDamageMult penalty does NOT auto-recover, so we record every actor we hit
 and restore it in OnEffectFinish - which fires when the effect's duration (the aging duration) ends.}

;-- Properties -------------------------------------------------------------
WSN_TrackerQuest_Quest Property WSN_TrackerQuest Auto
{Wintersun's central quest (FormKey 005901). Source of the favor AV name and QueueFavorChange.}

Float Property FavorCost = 15.0 Auto
{Favor points deducted each cast.}

Float Property Radius = 1500.0 Auto
{Horizontal search radius (game units) for living hostiles.}

Int Property MaxTargets = 20 Auto
{Cap on distinct actors aged per cast. Must not exceed the fixed array size (128) below.}

Float Property HealthPerFavor = 6.0 Auto
{Health drained per point of favor/10 (favorAV * HealthPerFavor).}

Float Property StaminaPerFavor = 6.0 Auto
{Stamina drained per point of favor/10.}

Float Property DamagePerFavor = 0.03 Auto
{AttackDamageMult reduction per point of favor/10 (0.03 -> -30% weapon damage at favorAV 10).}

Float Property MaxDamageReduction = 0.6 Auto
{Cap on the AttackDamageMult reduction so a strong devotee cannot zero out enemy weapon damage.}

Keyword Property ActorTypeUndead Auto
{013796 - excluded from "living".}

Keyword Property ActorTypeDaedra Auto
{013797 - excluded from "living".}

Keyword Property ActorTypeDwarven Auto
{01397A - Dwarven automatons, excluded from "living".}

Explosion Property CastExplosion Auto
{Cosmetic burst placed on the caster when the power fires. Assign WSN_Explosion_Favored (019BB1) -
 the same shout-area pop used by Kyne's Breath of Kyne, so casting reads with a visible burst.}

EffectShader Property CasterAura Auto
{Soul-wisp aura played on the caster for the effect's duration, so Orkey's death magic reads on
 the body the way Kyne's storm aura does. Assign SoulTrapFXShader (0506D7). Stopped in OnEffectFinish.}

EffectShader Property VictimShader Auto
{Brief life-drain shimmer played on each aged victim to sell the withering. Assign AbsorbHealthFXS
 (0ABEFF). Self-limited by VictimShaderDuration so no explicit Stop is needed.}

Float Property VictimShaderDuration = 4.0 Auto
{Seconds the victim shimmer plays on each aged actor.}

;-- Internal ---------------------------------------------------------------
Actor[] hitActors
Float[] hitDamageCut

Event OnEffectStart(Actor akTarget, Actor akCaster)
    If akCaster == None || WSN_TrackerQuest == None
        Return
    EndIf

    ; favor/10 = the value Wintersun mirrors favor onto (see TrackerQuest.SetFavor).
    Float favor10 = akCaster.GetActorValue(WSN_TrackerQuest.WSN_AV)
    If favor10 < 0.0
        favor10 = 0.0
    EndIf

    Float healthHit = favor10 * HealthPerFavor
    Float staminaHit = favor10 * StaminaPerFavor
    Float dmgCut = favor10 * DamagePerFavor
    If dmgCut > MaxDamageReduction
        dmgCut = MaxDamageReduction
    EndIf

    hitActors = new Actor[128]
    hitDamageCut = new Float[128]
    Int found = 0

    ; Spend favor first, through the quest so it survives the next favor tick.
    WSN_TrackerQuest.QueueFavorChange(-FavorCost, true, true)

    ; A shout-area burst on cast, then the lingering death aura for the whole duration.
    If CastExplosion != None
        akCaster.PlaceAtMe(CastExplosion as Form, 1, false, false)
    EndIf

    ; Death aura on the caster for the whole duration (Stop()ed in OnEffectFinish).
    If CasterAura != None
        CasterAura.Play(akCaster as ObjectReference)
    EndIf

    ; Sweep for hostile living actors in range and age them. FindRandomActorFromRef samples one
    ; nearby actor at a time, so we try several times the cap to gather distinct victims and dedup.
    Int attempts = 0
    Int maxAttempts = MaxTargets * 6
    While attempts < maxAttempts && found < MaxTargets
        Actor victim = Game.FindRandomActorFromRef(akCaster, Radius)
        If victim != None && victim != akCaster && !victim.IsDead() && victim.Is3DLoaded()
            If (victim.IsHostileToActor(akCaster) || victim.GetCombatState() == 1) && IsLiving(victim) && !AlreadyHit(victim, found)
                victim.DamageActorValue("Health", healthHit)
                victim.DamageActorValue("Stamina", staminaHit)
                If dmgCut > 0.0
                    victim.ModActorValue("AttackDamageMult", -dmgCut)
                EndIf
                If VictimShader != None
                    VictimShader.Play(victim as ObjectReference, VictimShaderDuration)
                EndIf
                hitActors[found] = victim
                hitDamageCut[found] = dmgCut
                found += 1
            EndIf
        EndIf
        attempts += 1
    EndWhile
EndEvent

; Restore the weapon-damage penalty when the aging wears off (effect duration ends).
Event OnEffectFinish(Actor akTarget, Actor akCaster)
    If CasterAura != None && akCaster != None
        CasterAura.Stop(akCaster as ObjectReference)
    EndIf
    If hitActors == None
        Return
    EndIf
    Int i = 0
    While i < hitActors.Length
        Actor a = hitActors[i]
        If a != None && hitDamageCut[i] > 0.0
            a.ModActorValue("AttackDamageMult", hitDamageCut[i])
        EndIf
        i += 1
    EndWhile
    hitActors = None
    hitDamageCut = None
EndEvent

Bool Function IsLiving(Actor a)
    Return !a.HasKeyword(ActorTypeUndead) && !a.HasKeyword(ActorTypeDaedra) && !a.HasKeyword(ActorTypeDwarven)
EndFunction

Bool Function AlreadyHit(Actor a, Int count)
    Int i = 0
    While i < count
        If hitActors[i] == a
            Return true
        EndIf
        i += 1
    EndWhile
    Return false
EndFunction
