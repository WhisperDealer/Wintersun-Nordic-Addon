Scriptname WSN_Divine_Stuhn_Ransom_Script extends ActiveMagicEffect
{Stuhn devotee power "Stuhn's Ransom" - once a day, the shield-god's mercy makes beatable foes yield
 and flee, and those who surrender buy their lives with gold. On cast we sweep for hostile actors in
 range whose level is within LevelMargin of the player (the ones Stuhn deems already beaten), break
 their combat and cast a Demoralize on each so they flee, then award the player ransom gold scaled by
 how many yielded and their level.

 "Once a day" is enforced with a persistent global (LastDayGlobal): we compare GameDaysPassed against
 the day the power was last used and refuse a second use inside 24 game-hours. There is no favor cost
 by design (FavorCost defaults to 0); the daily gate is the only limiter. If a cost is ever wanted it
 is spent through the TrackerQuest's QueueFavorChange so the deduction survives the next favor tick.

 FindRandomActorFromRef samples one nearby actor per call, so we try several times the target cap and
 dedup. Feedback is shown with Debug.Notification so no extra Message records are needed. Compiles
 against base-game source plus Wintersun (for the TrackerQuest type).}

;-- Properties -------------------------------------------------------------
WSN_TrackerQuest_Quest Property WSN_TrackerQuest Auto
{Wintersun's central quest (FormKey 005901). Only used if FavorCost > 0, to spend favor via
 QueueFavorChange so the cost sticks past the next favor tick.}

Spell Property FleeSpell Auto
{Hostile Demoralize cast on each yielding actor so they flee. Assign
 WSN_Divine_Stuhn_Boon2_FleeSpell (000828).}

GlobalVariable Property LastDayGlobal Auto
{Persistent store of the GameDaysPassed value when the power was last used - the once-a-day gate.
 Assign WSN_Divine_Stuhn_Ransom_LastDay_Global (0008AC).}

GlobalVariable Property GameDaysPassed Auto
{Base-game running day count. FormKey 000039.}

MiscObject Property Gold001 Auto
{Gold. FormKey 00000F.}

Float Property Radius = 1500.0 Auto
{Horizontal search radius (game units) for foes who might yield.}

Int Property MaxTargets = 15 Auto
{Cap on distinct actors made to yield per cast. Must not exceed the 128 array below.}

Int Property LevelMargin = 10 Auto
{A foe yields only if its level is at most (player level + LevelMargin) - "in level range".}

Int Property GoldPerTarget = 25 Auto
{Base ransom gold per yielding foe.}

Int Property GoldPerLevel = 3 Auto
{Extra ransom gold per level of each yielding foe.}

Float Property FavorCost = 0.0 Auto
{Favor spent per cast. Defaults to 0 - the power is gated by the daily cooldown, not by favor.}

Explosion Property CastExplosion Auto
{Cosmetic burst placed on the player when the power fires. Assign WSN_Explosion_Favored (019BB1) -
 the same shout-area pop shown when you become favored. Null-safe.}

EffectShader Property CasterAura Auto
{Warm shimmer played on the player for the effect's duration, so Stuhn's mercy reads on the body the
 way Kyne's storm aura and Orkey's soul aura do. Assign HealFXS (012FD9). Stopped in OnEffectFinish.}

;-- Events -----------------------------------------------------------------
Event OnEffectStart(Actor akTarget, Actor akCaster)
    If akCaster == None
        Return
    EndIf

    ; --- Once-a-day gate -------------------------------------------------
    Float today = 0.0
    If GameDaysPassed != None
        today = GameDaysPassed.GetValue()
    EndIf
    If LastDayGlobal != None && LastDayGlobal.GetValue() > 0.0 && (today - LastDayGlobal.GetValue()) < 1.0
        Debug.Notification("Stuhn grants his mercy but once a day.")
        Return
    EndIf
    If LastDayGlobal != None
        LastDayGlobal.SetValue(today)
    EndIf

    ; --- Optional favor cost (0 by default) ------------------------------
    If FavorCost > 0.0 && WSN_TrackerQuest != None
        WSN_TrackerQuest.QueueFavorChange(-FavorCost, true, true)
    EndIf

    ; --- Activation visuals ---------------------------------------------
    ; A burst on cast, then a shimmer that lingers on the player for the whole effect duration
    ; (Stop()ed in OnEffectFinish) so the power reads on the body, not only as a corner icon.
    If CastExplosion != None
        akCaster.PlaceAtMe(CastExplosion as Form, 1, false, false)
    EndIf
    If CasterAura != None
        CasterAura.Play(akCaster as ObjectReference)
    EndIf

    ; --- Sweep for beatable foes and make them yield ---------------------
    Int maxLevel = akCaster.GetLevel() + LevelMargin
    Actor[] hit = new Actor[128]
    Int found = 0
    Int totalGold = 0

    Int attempts = 0
    Int maxAttempts = MaxTargets * 8
    While attempts < maxAttempts && found < MaxTargets
        Actor victim = Game.FindRandomActorFromRef(akCaster, Radius)
        If victim != None && victim != akCaster && !victim.IsDead() && victim.Is3DLoaded()
            If (victim.IsHostileToActor(akCaster) || victim.GetCombatState() == 1) && victim.GetLevel() <= maxLevel && !AlreadyHit(hit, victim, found)
                ; Make the victim cast the Demoralize on ITSELF. FleeSpell is Self-delivery, so a
                ; self-cast always lands (no projectile to whiff, and IgnoreResistance means it can't
                ; be shrugged off) - a ranged Aimed cast from the player would miss with no projectile.
                If FleeSpell != None
                    FleeSpell.Cast(victim as ObjectReference)
                EndIf
                victim.StopCombat()
                totalGold += GoldPerTarget + victim.GetLevel() * GoldPerLevel
                hit[found] = victim
                found += 1
            EndIf
        EndIf
        attempts += 1
    EndWhile

    ; --- Pay the ransom --------------------------------------------------
    If found > 0 && totalGold > 0 && Gold001 != None
        akCaster.AddItem(Gold001 as Form, totalGold, true)
        Debug.Notification("Stuhn's Ransom: " + found + " yield and pay " + totalGold + " gold.")
    Else
        Debug.Notification("No foe here yields to Stuhn.")
    EndIf
EndEvent

; Stop the lingering aura when the effect's duration ends.
Event OnEffectFinish(Actor akTarget, Actor akCaster)
    If CasterAura != None && akCaster != None
        CasterAura.Stop(akCaster as ObjectReference)
    EndIf
EndEvent

;-- Helpers ----------------------------------------------------------------
Bool Function AlreadyHit(Actor[] list, Actor a, Int count)
    Int i = 0
    While i < count
        If list[i] == a
            Return true
        EndIf
        i += 1
    EndWhile
    Return false
EndFunction
