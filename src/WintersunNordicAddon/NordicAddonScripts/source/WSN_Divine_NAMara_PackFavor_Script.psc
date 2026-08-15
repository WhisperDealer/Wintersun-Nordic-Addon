Scriptname WSN_Divine_NAMara_PackFavor_Script extends ActiveMagicEffect
{Grants favor while the player fights alongside a follower - backs Mara's
 "Fight alongside your followers" tenet.

 Skyrim has no misc-stat for followers, so the generic DynamicStat favor loop
 can't drive this; a small polling effect does instead. This effect rides
 Mara's Tenets ability, which is added on StartWorship and removed on
 StopWorship, so it is live only while Mara is being worshipped and
 QueueFavorChange always targets the current deity - no hardcoded deity index,
 so the same effect works in both the base and Wintersun-Tribunal load orders
 where every Nordic index shifts by three.}

;-- Properties -------------------------------------------------------------
WSN_TrackerQuest_Quest Property WSN_TrackerQuest Auto
{Wintersun's central quest (FormKey 005901). QueueFavorChange applies favor to the current deity.}

Actor Property PlayerRef Auto
{The player (000014). Polled for combat state each tick.}

GlobalVariable Property PlayerFollowerCount Auto
{Vanilla follower-count global (0BCC98). Favor only accrues while this is >= 1.}

GlobalVariable Property WSN_FavorPerTick Auto
{Favor granted per poll while fighting alongside a follower
 (WSN_ModifyFavor_Divine_NAMara_FavorPerCombatTick, 0008B8).}

Float Property PollInterval = 10.0 Auto
{Seconds between favor ticks. Tunable in the CK without recompiling.}

;-- Events -----------------------------------------------------------------
Event OnEffectStart(Actor akTarget, Actor akCaster)
    RegisterForSingleUpdate(PollInterval)
EndEvent

Event OnUpdate()
    ; Reward fighting as a pack: in combat (1) or searching (2) AND at least one follower present.
    If WSN_TrackerQuest && PlayerRef.GetCombatState() >= 1 && PlayerFollowerCount.GetValue() >= 1.0
        ; Silent income (no message/bar), like the DynamicStat favor sources.
        WSN_TrackerQuest.QueueFavorChange(WSN_FavorPerTick.GetValue(), false, false)
    EndIf
    ; Re-arm; the pending update is discarded automatically when the effect ends.
    RegisterForSingleUpdate(PollInterval)
EndEvent
