Scriptname WSN_Divine_Tsun_Boon1_LevelSync_Script extends ActiveMagicEffect
{Tsun follower boon "Test of the Worthy" - support effect.

 The boon's perk (WSN_Divine_Tsun_Boon1_Perk) grants more outgoing / less incoming damage against
 foes whose level is above the player's. A perk entry-point condition can only compare an actor's
 GetLevel to a fixed value or a global variable - it cannot read the player's live level directly.
 So this effect keeps a global (PlayerLevelGlob) synced to the player's current level, and the perk
 compares the foe's GetLevel to that global.

 The player's level changes rarely, so a slow periodic poll is plenty.}

;-- Properties -------------------------------------------------------------
GlobalVariable Property PlayerLevelGlob Auto
{Global the Boon1 perk compares foe levels against. Kept equal to the player's level.}

Float Property UpdateInterval = 20.0 Auto
{Seconds between level re-syncs.}

;-- Events -----------------------------------------------------------------
Event OnEffectStart(Actor akTarget, Actor akCaster)
    Sync()
    RegisterForSingleUpdate(UpdateInterval)
EndEvent

Event OnUpdate()
    Sync()
    RegisterForSingleUpdate(UpdateInterval)
EndEvent

Function Sync()
    If PlayerLevelGlob != None
        PlayerLevelGlob.SetValue(Game.GetPlayer().GetLevel() as Float)
    EndIf
EndFunction
