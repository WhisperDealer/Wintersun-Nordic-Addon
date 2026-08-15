Scriptname WSN_Divine_Alduin_StormPower_Script extends ActiveMagicEffect
{Alduin devotee power - rains dragonfire meteors from the sky around the caster.
 Each meteor is a projectile that falls under gravity and detonates on the ground,
 so impacts always land on terrain rather than floating at the caster's elevation.

 Favor MUST be changed through the TrackerQuest's QueueFavorChange - writing the favor
 global directly is undone on the next favor tick, because ProcessFavorChanges recomputes
 favor from the deity's static income every update. QueueFavorChange feeds the persistent
 FavorChangeQueued accumulator, so the cost sticks. When favor falls below the favored
 threshold (100), Wintersun removes the power automatically.}

;-- Properties -------------------------------------------------------------
Projectile Property MeteorProjectile Auto
{The falling meteor. It carries its own Explosion (AoE damage) and detonates on impact.}

Activator Property MarkerBase Auto
{A small placeable used as the moving spawn point. Assign xMarkerActivator (06CD3D).}

Int Property Waves = 12 Auto
{How many meteors fall.}

Float Property WaveInterval = 0.3 Auto
{Seconds between meteors.}

Float Property Scatter = 2500.0 Auto
{Random horizontal spread (game units) around the caster - the storm's radius.}

Float Property SpawnHeight = 4000.0 Auto
{How far above the caster each meteor spawns before falling.}

Float Property SafeRadius = 500.0 Auto
{Meteors never land within this horizontal distance of the caster, so the storm
 never damages the player. Should exceed the explosion radius.}

Float Property TargetChance = 0.5 Auto
{Chance (0-1) that a given meteor seeks a hostile actor instead of landing randomly.}

Float Property TargetRadius = 3000.0 Auto
{How far out (game units) the storm searches for hostile actors to target.}

Float Property TargetJitter = 150.0 Auto
{Small spread around a targeted enemy so strikes feel organic rather than pixel-perfect.}

Weather Property StormWeather Auto
{Weather forced while the storm rages. Assign HelgenAttackWeather (0D9329).}

WSN_TrackerQuest_Quest Property WSN_TrackerQuest Auto
{Wintersun's central quest (FormKey 005901). QueueFavorChange spends favor here so the
 cost sticks past the next favor tick.}

Float Property FavorCost = 20.0 Auto
{Favor points deducted each time the power is cast.}

;-- Internal ---------------------------------------------------------------
ObjectReference spawnMarker
Int wavesLeft

Event OnEffectStart(Actor akTarget, Actor akCaster)
    If akCaster == None || MeteorProjectile == None || MarkerBase == None
        Return
    EndIf

    ; One reusable marker, high in the sky, that we reposition for every meteor.
    spawnMarker = akCaster.PlaceAtMe(MarkerBase, 1)
    ; Point it straight down so the meteor launches toward the ground.
    spawnMarker.SetAngle(90.0, 0.0, 0.0)

    ; Darken the sky to the World-Eater's attack weather (Helgen opening).
    ; Pass true so it overrides the default weather and won't transition away.
    If StormWeather != None
        StormWeather.ForceActive(True)
    EndIf

    ; Casting the storm costs favor with the World-Eater. Spend it through the
    ; TrackerQuest so the deduction survives the next favor tick (see class docs).
    If WSN_TrackerQuest != None
        WSN_TrackerQuest.QueueFavorChange(-FavorCost, true, true)
    EndIf

    wavesLeft = Waves
    RegisterForSingleUpdate(0.1)
EndEvent

Event OnUpdate()
    Actor caster = GetCasterActor()
    If caster == None
        Cleanup()
        Return
    EndIf

    ; Re-assert the storm weather every tick so it holds for the WHOLE power
    ; duration and never transitions back to natural weather early.
    If StormWeather != None
        StormWeather.ForceActive(True)
    EndIf

    ; Drop a meteor only while waves remain. Once they run out we keep ticking
    ; (to hold the weather) until OnEffectFinish ends the power.
    If wavesLeft > 0 && spawnMarker != None
        Float ix
        Float iy

        ; Half the time (TargetChance) try to seek a hostile actor in combat and
        ; rain a meteor on it; otherwise scatter randomly. This gives a mix of
        ; targeted strikes and random impacts across the storm.
        Actor enemy = None
        If Utility.RandomFloat(0.0, 1.0) < TargetChance
            enemy = FindHostileTarget(caster)
        EndIf

        If enemy != None
            ; Aim at the enemy's position with a little jitter.
            ix = enemy.GetPositionX() + Utility.RandomFloat(-TargetJitter, TargetJitter)
            iy = enemy.GetPositionY() + Utility.RandomFloat(-TargetJitter, TargetJitter)
        Else
            ; Scatter the impact around the caster's LIVE position, so the storm covers a
            ; wide area and follows the player wherever they move for the whole duration.
            ix = caster.GetPositionX() + Utility.RandomFloat(-Scatter, Scatter)
            iy = caster.GetPositionY() + Utility.RandomFloat(-Scatter, Scatter)
        EndIf

        ; Keep the impact outside a safe bubble around the caster's live position so
        ; the storm never lands close enough to hurt the player (even if they move).
        Float px = ix - caster.GetPositionX()
        Float py = iy - caster.GetPositionY()
        Float dist = Math.Sqrt(px * px + py * py)
        If dist < SafeRadius
            If dist < 1.0
                px = SafeRadius
                py = 0.0
            Else
                Float scale = SafeRadius / dist
                px = px * scale
                py = py * scale
            EndIf
            ix = caster.GetPositionX() + px
            iy = caster.GetPositionY() + py
        EndIf

        ; Fire a meteor straight down. Gravity + the downward aim make it fall
        ; and detonate wherever the terrain actually is below that point.
        spawnMarker.SetPosition(ix, iy, caster.GetPositionZ() + SpawnHeight)
        spawnMarker.SetAngle(90.0, 0.0, 0.0)
        spawnMarker.PlaceAtMe(MeteorProjectile, 1)

        wavesLeft -= 1
    EndIf

    RegisterForSingleUpdate(WaveInterval)
EndEvent

; Returns a nearby hostile actor (in combat / hostile to the caster), or None.
Actor Function FindHostileTarget(Actor caster)
    Actor found = Game.FindRandomActorFromRef(caster, TargetRadius)
    If found != None && found != caster && !found.IsDead() && found.Is3DLoaded()
        If found.IsHostileToActor(caster) || found.GetCombatState() == 1
            Return found
        EndIf
    EndIf
    Return None
EndFunction

Event OnEffectFinish(Actor akTarget, Actor akCaster)
    Cleanup()
EndEvent

Function Cleanup()
    If spawnMarker != None
        spawnMarker.Delete()
        spawnMarker = None
    EndIf
    ; Release the forced weather so the sky returns to normal.
    If StormWeather != None
        Weather.ReleaseOverride()
    EndIf
EndFunction
