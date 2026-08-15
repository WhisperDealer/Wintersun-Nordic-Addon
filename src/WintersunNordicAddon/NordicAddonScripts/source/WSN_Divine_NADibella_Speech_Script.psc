Scriptname WSN_Divine_NADibella_Speech_Script extends ActiveMagicEffect
{Dibella follower boon: raises the Speech skill by favor/10, tracking current favor.

 Reads WSN_Favor_Global_Fractional (Wintersun keeps this at current-deity favor x 0.1,
 i.e. favor/10 - see WSN_TrackerQuest_Quest.SetFavor) and mirrors it onto the Speechcraft
 actor value (the base skill AV, which is what shows in the Skills menu).

 Refreshes on a GAME-TIME tick (RegisterForSingleUpdateGameTime), the same low-overhead
 cadence Wintersun uses for favor itself - NOT a real-time OnUpdate loop. One game hour is
 ~3 real minutes at default timescale, which is plenty responsive for a slow favor value and
 keeps the script idle almost all the time.

 Uses a net-delta ModActorValue: it only ever adds the CHANGE since last tick and stores the
 running total in 'appliedSpeech'. Because script variables persist in the save, OnEffectFinish
 always removes exactly what was added - no stacking, no leak across reloads.}

;-- Properties -------------------------------------------------------------
GlobalVariable Property WSN_Favor_Global_Fractional Auto
{Wintersun global = current favor x 0.1 (favor/10). FormKey 014A56.}

Float Property UpdateIntervalHours = 1.0 Auto
{Game-time hours between refreshes.}

;-- State ------------------------------------------------------------------
Float appliedSpeech = 0.0

;-- Events -----------------------------------------------------------------
Event OnEffectStart(Actor akTarget, Actor akCaster)
    Refresh(akTarget)
    RegisterForSingleUpdateGameTime(UpdateIntervalHours)
EndEvent

Event OnUpdateGameTime()
    Refresh(GetTargetActor())
    RegisterForSingleUpdateGameTime(UpdateIntervalHours)
EndEvent

Event OnUpdate()
    ; Bridge: an existing save may still hold a real-time timer from an earlier build.
    ; Catch it once and hand off to the game-time tick. Harmless on fresh worships.
    Refresh(GetTargetActor())
    RegisterForSingleUpdateGameTime(UpdateIntervalHours)
EndEvent

Event OnEffectFinish(Actor akTarget, Actor akCaster)
    If akTarget != None && appliedSpeech != 0.0
        akTarget.ModActorValue("Speechcraft", -appliedSpeech)
        appliedSpeech = 0.0
    EndIf
EndEvent

;-- Helper -----------------------------------------------------------------
Function Refresh(Actor a)
    If a == None || WSN_Favor_Global_Fractional == None
        Return
    EndIf
    Float target = WSN_Favor_Global_Fractional.GetValue()
    If target < 0.0
        target = 0.0
    EndIf
    Float delta = target - appliedSpeech
    If delta != 0.0
        a.ModActorValue("Speechcraft", delta)
        appliedSpeech = target
    EndIf
EndFunction
