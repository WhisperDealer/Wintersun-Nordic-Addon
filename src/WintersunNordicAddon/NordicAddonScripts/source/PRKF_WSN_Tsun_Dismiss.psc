scriptName PRKF_WSN_Tsun_Dismiss extends Perk hidden
{Perk fragment for the "Dismiss" activate option on a summoned Trial by Combat champion. Runs when
 the player activates the champion and chooses Dismiss (e.g. after a misclick). It only raises a
 signal global; the trial's ActiveMagicEffect (WSN_Divine_Tsun_TrialByCombat_Script) sees the signal
 on its next poll and does the actual work - refund the summoning favor, remove the champion, and end
 the trial WITHOUT granting the victory reward. Centralising it there avoids the champion vanishing
 being mistaken for a win.}

GlobalVariable Property DismissGlobal Auto
{0008B5 - set to 1 to tell the trial script the player dismissed the champion.}

function Fragment_0(ObjectReference akTargetRef, Actor akActor)
    If DismissGlobal != None
        DismissGlobal.SetValue(1.0)
    EndIf
endFunction
