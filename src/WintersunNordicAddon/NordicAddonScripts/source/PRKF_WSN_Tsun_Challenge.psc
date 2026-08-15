scriptName PRKF_WSN_Tsun_Challenge extends Perk hidden
{Perk fragment for the "Challenge" activate option shown on a summoned Trial by Combat champion.
 Runs when the player activates the champion. It strips the champion's inherited (peaceful
 Sovngarde) factions - which can leave it treating the player as an ally and quietly refusing to
 fight even after StartCombat - then re-adds the isolated-duel faction, turns it fully hostile and
 begins the duel. Because activation happens with the champion fully loaded and the player right
 beside it, StartCombat lands reliably here in a way the immediate-post-spawn call did not.}

Faction Property TrialFaction Auto
{0008AE - the champion's isolated-duel faction (enemy to PlayerFaction only).}

function Fragment_0(ObjectReference akTargetRef, Actor akActor)
    Actor champ = akTargetRef as Actor
    If champ == None
        Return
    EndIf
    champ.RemoveFromAllFactions()
    If TrialFaction != None
        champ.AddToFaction(TrialFaction)
    EndIf
    champ.SetActorValue("Assistance", 0)
    champ.SetActorValue("Aggression", 2)
    champ.StartCombat(akActor)
    champ.EvaluatePackage()
endFunction
