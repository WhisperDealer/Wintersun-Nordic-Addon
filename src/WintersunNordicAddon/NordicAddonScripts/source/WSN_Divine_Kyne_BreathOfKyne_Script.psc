Scriptname WSN_Divine_Kyne_BreathOfKyne_Script extends ActiveMagicEffect
{Kyne devotee power - Breath of Kyne. The magic effect's ShoutRecoveryMult fortify
 (magnitude 100) does the shout-cooldown reduction for its duration; this script spends
 favor on cast and plays the activation visuals - a shout-area burst plus a storm aura
 that lingers on the body for the whole duration, so the buff reads on the player and not
 only as a corner icon.

 Favor MUST be changed through the TrackerQuest's QueueFavorChange - writing the favor
 global directly is undone on the next favor tick, because ProcessFavorChanges recomputes
 favor from the deity's static income (Kyne's stamina) every update. QueueFavorChange
 feeds the persistent FavorChangeQueued accumulator, so the cost sticks. When favor falls
 below the favored threshold (100), Wintersun removes the power automatically.}

;-- Properties -------------------------------------------------------------
WSN_TrackerQuest_Quest Property WSN_TrackerQuest Auto
{Wintersun's central quest (FormKey 005901). QueueFavorChange spends favor here.}

Float Property FavorCost = 20.0 Auto
{Favor points deducted each time the power is cast.}

Explosion Property CastExplosion Auto
{Cosmetic burst placed on the caster when the power fires. Assign WSN_Explosion_Favored
 (019BB1) - the same shout-area pop shown when you become favored.}

EffectShader Property AuraShader Auto
{Storm aura played on the caster for the power's duration. Assign ShockPlayerCloakFXShader
 (10F9A6).}

Event OnEffectStart(Actor akTarget, Actor akCaster)
    If akCaster == None
        Return
    EndIf

    ; Visual/audio feedback: a shout-area burst on cast, then a lingering storm aura
    ; that Stop()s in OnEffectFinish so it tracks the power's lifetime exactly.
    If CastExplosion != None
        akCaster.PlaceAtMe(CastExplosion as Form, 1, false, false)
    EndIf
    If AuraShader != None
        AuraShader.Play(akCaster as ObjectReference)
    EndIf

    ; Spend favor through the TrackerQuest so the cost sticks (see class docs above).
    If WSN_TrackerQuest != None
        WSN_TrackerQuest.QueueFavorChange(-FavorCost, true, true)
    EndIf
EndEvent

Event OnEffectFinish(Actor akTarget, Actor akCaster)
    If AuraShader != None && akCaster != None
        AuraShader.Stop(akCaster as ObjectReference)
    EndIf
EndEvent
