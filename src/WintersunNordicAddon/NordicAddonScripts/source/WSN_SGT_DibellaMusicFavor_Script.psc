Scriptname WSN_SGT_DibellaMusicFavor_Script extends ActiveMagicEffect
{Dibella's Skyrim's Got Talent tenet: grants favor the first time the player learns each
 instrument (drum, flute, lute).

 SGT has no discrete "learned" flag - each instrument has an expertise global
 (_Talent_Drum / _Talent_Flute / _Talent_Lute) that starts at 0 and climbs as the player
 performs on, or is taught, that instrument. Its tiers: <26 clueless, <46 beginner (both of
 which SGT flags as "performing terrible"), then at 46 and up the audience reacts to a good
 performance (SGT's _Talent_IsPerformingGood). So "has learned to play this instrument
 successfully" is read as "its expertise global has reached LearnedThreshold (46)" - the point
 where clumsy first attempts become competent performances, not merely the first time the
 instrument is picked up. Each grant is latched by a persistent GlobalShort (…Learned) in this
 patch, so it fires exactly once per instrument for the playthrough even across worship
 sessions - re-worshipping Dibella cannot farm it.

 Rides Dibella's Tenets ability (added on StartWorship, removed on StopWorship), so
 QueueFavorChange always targets whichever deity is currently worshipped - no hardcoded deity
 index, working in both the base and Wintersun-Tribunal load orders where the Nordic indices
 shift by three. This mirrors the pattern used by WSN_Divine_NordicLaws_Script, which shares
 this same effect.}

;-- Properties -------------------------------------------------------------
WSN_TrackerQuest_Quest Property WSN_TrackerQuest Auto
{Wintersun's central quest (FormKey 005901). QueueFavorChange applies favor to the current deity.}

GlobalVariable Property DrumExpertise Auto
{SGT _Talent_Drum expertise global (000D63). Climbs 0..100 as the drum is played; reaches
 LearnedThreshold once the player can perform on it successfully.}

GlobalVariable Property FluteExpertise Auto
{SGT _Talent_Flute expertise global (000D61).}

GlobalVariable Property LuteExpertise Auto
{SGT _Talent_Lute expertise global (000D62).}

GlobalVariable Property DrumLearned Auto
{Patch latch (000800): set to 1 once the drum favor has been granted, so it never repeats.}

GlobalVariable Property FluteLearned Auto
{Patch latch (000801).}

GlobalVariable Property LuteLearned Auto
{Patch latch (000802).}

Float Property FavorPerInstrument = 15.0 Auto
{Favor granted the first time each instrument is learned. Tunable in the CK.}

Float Property LearnedThreshold = 46.0 Auto
{Expertise value at which an instrument counts as "learned to play successfully". 46 is SGT's
 own boundary between "performing terrible" (<46) and "performing good" (>=46). Tunable in the CK.}

Float Property PollInterval = 15.0 Auto
{Real seconds between checks while worshipping Dibella. Tunable in the CK.}

;-- Events -----------------------------------------------------------------
Event OnEffectStart(Actor akTarget, Actor akCaster)
    CheckAll()
    If !AllLearned()
        RegisterForSingleUpdate(PollInterval)
    EndIf
EndEvent

Event OnUpdate()
    CheckAll()
    ; Stop polling once every instrument has been rewarded; re-arm otherwise.
    If !AllLearned()
        RegisterForSingleUpdate(PollInterval)
    EndIf
EndEvent

;-- Helpers ----------------------------------------------------------------
Function CheckAll()
    If WSN_TrackerQuest == None
        Return
    EndIf
    CheckOne(DrumExpertise, DrumLearned)
    CheckOne(FluteExpertise, FluteLearned)
    CheckOne(LuteExpertise, LuteLearned)
EndFunction

Function CheckOne(GlobalVariable expertise, GlobalVariable learned)
    If expertise == None || learned == None
        Return
    EndIf
    ; "Learned" = the expertise global has reached LearnedThreshold (a competent, successful
    ; performance - not merely the first clumsy attempt) and we have not already paid out for it.
    If learned.GetValue() == 0.0 && expertise.GetValue() >= LearnedThreshold
        learned.SetValue(1.0)
        WSN_TrackerQuest.QueueFavorChange(FavorPerInstrument, true, true)
    EndIf
EndFunction

Bool Function AllLearned()
    Return DrumLearned != None && FluteLearned != None && LuteLearned != None && DrumLearned.GetValue() != 0.0 && FluteLearned.GetValue() != 0.0 && LuteLearned.GetValue() != 0.0
EndFunction
