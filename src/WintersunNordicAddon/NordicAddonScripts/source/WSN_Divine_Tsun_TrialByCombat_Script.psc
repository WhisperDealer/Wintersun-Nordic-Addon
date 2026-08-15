Scriptname WSN_Divine_Tsun_TrialByCombat_Script extends ActiveMagicEffect
{Tsun devotee power "Trial by Combat".

 On cast, summon a champion of Sovngarde in front of the player and fight them in single combat.
 The champion is added to a faction whose only enemy is the PlayerFaction, so it attacks only the
 player and town guards / bystanders neither attack it nor are attacked by it (an isolated duel).
 The player wins by putting the champion down (killed, or knocked into bleedout - the reused
 Sovngarde hero base is Essential and cannot die, so bleedout counts as a win). Winning grants a
 favor-scaled bundle of combat fortifications for RewardDuration seconds, then removes them. The
 champion is always cleaned up, whether the player wins, dies, or lets the trial time out.

 Favor is spent through the TrackerQuest's QueueFavorChange so the cost survives the next favor
 recompute (see wintersun-favor-cost-api). Reward magnitudes scale with favor/10, read from the
 actor value Wintersun mirrors favor onto (WSN_TrackerQuest.WSN_AV - see TrackerQuest.SetFavor).

 The owning magic effect carries a long duration (~900s) purely so this script instance stays alive
 across the fight and the reward window; the script Dispel()s itself as soon as it is finished.}

;-- Properties -------------------------------------------------------------
WSN_TrackerQuest_Quest Property WSN_TrackerQuest Auto
{Wintersun's central quest (FormKey 005901). Favor AV name + QueueFavorChange.}

Float Property FavorCost = 20.0 Auto
{Favor deducted on cast.}

ActorBase Property ChampionBase Auto
{The Sovngarde hero base to summon (096FFB MQ305SovngardeHeroMale).}

Faction Property TrialFaction Auto
{Faction whose only enemy is PlayerFaction; added to the champion so the duel stays isolated.}

Perk Property ChallengePerk Auto
{The activate-choice perk (0008B3) added to the player while the champion stands. Its "Challenge"
 option (fragment PRKF_WSN_Tsun_Challenge) turns the champion hostile and starts the duel. Removed
 when the trial ends.}

Perk Property DismissPerk Auto
{The activate-choice perk (0008B4) added to the player while the champion stands. Its "Dismiss"
 option (fragment PRKF_WSN_Tsun_Dismiss) sets DismissGlobal; this script then sends the champion
 back and refunds the summoning favor. Removed when the trial ends.}

GlobalVariable Property DismissGlobal Auto
{0008B5 - the Dismiss fragment sets this to 1; checked each poll to end the trial with a favor
 refund and no reward.}

Int Property ChampionLevelMod = 0 Auto
{Level offset passed to PlaceActorAtMe (the base is a fixed level, so difficulty is set below).}

Float Property MaxTrialTime = 300.0 Auto
{Seconds before an unfinished trial is abandoned with no reward.}

Float Property PollInterval = 2.0 Auto
{Seconds between checks of the champion's state during the fight.}

Float Property SpawnDistance = 220.0 Auto
{Game units in front of the player to place the champion.}

Float Property RewardDuration = 90.0 Auto
{Seconds the winner's fortifications last.}

Float Property ChampionHealthMult = 1.5 Auto
{Champion health is raised to at least the player's max Health times this, so it stays a threat.}

Float Property ChampionDamageBonus = 0.5 Auto
{AttackDamageMult added to the champion (+50% weapon damage by default).}

Float Property RewardDamageBase = 0.3 Auto
Float Property RewardDamagePerFavor = 0.03 Auto
Float Property RewardArmorBase = 40.0 Auto
Float Property RewardArmorPerFavor = 8.0 Auto
Float Property RewardHealthBase = 40.0 Auto
Float Property RewardHealthPerFavor = 6.0 Auto
Float Property RewardRegenBase = 1.0 Auto
Float Property RewardRegenPerFavor = 0.3 Auto

EffectShader Property RewardAura Auto
{Aura played on the player for the reward duration (assign HealFXS 012FD9). Stopped on removal.}

;-- Internal ---------------------------------------------------------------
Actor PlayerRef
Actor Champion
Float ElapsedTime
Bool RewardActive
Float appliedDamage
Float appliedArmor
Float appliedHealth
Float appliedRegen

;-- Events -----------------------------------------------------------------
Event OnEffectStart(Actor akTarget, Actor akCaster)
    If akCaster == None
        Dispel()
        Return
    EndIf
    PlayerRef = akCaster
    ElapsedTime = 0.0
    RewardActive = False

    ; Summon the champion first; if it cannot be placed, spend no favor.
    Champion = PlayerRef.PlaceActorAtMe(ChampionBase, ChampionLevelMod, None)
    If Champion == None
        Debug.Notification("Tsun does not answer the call.")
        Dispel()
        Return
    EndIf

    ; Put the champion a short distance directly in front of the player, turned to face them, rather
    ; than wherever PlaceActorAtMe dropped it.
    Float angZ = PlayerRef.GetAngleZ()
    Float fx = SpawnDistance * Math.Sin(angZ)
    Float fy = SpawnDistance * Math.Cos(angZ)
    Champion.SetPosition(PlayerRef.GetPositionX() + fx, PlayerRef.GetPositionY() + fy, PlayerRef.GetPositionZ())
    Champion.SetAngle(0.0, 0.0, angZ + 180.0)

    ; Spend favor through the quest so it survives the next favor recompute.
    If WSN_TrackerQuest != None
        WSN_TrackerQuest.QueueFavorChange(-FavorCost, true, true)
    EndIf

    ; Scale the champion so it is a threat regardless of the base's fixed level.
    Float pcHealth = PlayerRef.GetActorValue("Health")
    If pcHealth * ChampionHealthMult > Champion.GetActorValue("Health")
        Champion.SetActorValue("Health", pcHealth * ChampionHealthMult)
    EndIf
    Champion.ModActorValue("AttackDamageMult", ChampionDamageBonus)

    ; The champion waits, unaggressive, until the player Challenges it: auto-StartCombat right after a
    ; PlaceActorAtMe of this peaceful Sovngarde base proved unreliable (it just stood there until hit),
    ; so hostility is instead triggered by activating it. The Challenge perk (added below) shows a
    ; "Challenge" prompt on it and its fragment turns it hostile. Aggression 0 keeps it from wandering
    ; off to attack neutral wildlife while it waits. TrialFaction keeps guards/bystanders out of it.
    Champion.SetPlayerTeammate(false, false)
    If TrialFaction != None
        Champion.AddToFaction(TrialFaction)
    EndIf
    Champion.SetActorValue("Aggression", 0)
    If DismissGlobal != None
        DismissGlobal.SetValue(0.0)
    EndIf
    If ChallengePerk != None
        PlayerRef.AddPerk(ChallengePerk)
    EndIf
    If DismissPerk != None
        PlayerRef.AddPerk(DismissPerk)
    EndIf

    Debug.Notification("A champion of Sovngarde stands before you. Activate them to Challenge them - or Dismiss them to call it off.")
    RegisterForSingleUpdate(PollInterval)
EndEvent

Event OnUpdate()
    If RewardActive
        ; Reward window elapsed - remove the fortifications and finish.
        RemoveReward()
        Dispel()
        Return
    EndIf

    If PlayerRef == None || PlayerRef.IsDead()
        CleanupChampion()
        Dispel()
        Return
    EndIf

    If DismissGlobal != None && DismissGlobal.GetValue() >= 1.0
        ; The player dismissed the champion (e.g. a misclick). Refund the summoning favor, send the
        ; champion back, and end WITHOUT the victory reward.
        DismissGlobal.SetValue(0.0)
        If WSN_TrackerQuest != None
            WSN_TrackerQuest.QueueFavorChange(FavorCost, true, true)
        EndIf
        CleanupChampion()
        Debug.Notification("You dismiss the champion of Sovngarde. Tsun returns the favor you spent.")
        Dispel()
        Return
    EndIf

    If Champion == None || Champion.IsDead() || Champion.IsBleedingOut()
        ; The player won the trial.
        CleanupChampion()
        ApplyReward()
        RewardActive = True
        RegisterForSingleUpdate(RewardDuration)
        Return
    EndIf

    ElapsedTime += PollInterval
    If ElapsedTime >= MaxTrialTime
        CleanupChampion()
        Debug.Notification("The trial is left unfinished. Tsun turns away.")
        Dispel()
        Return
    EndIf

    RegisterForSingleUpdate(PollInterval)
EndEvent

Event OnEffectFinish(Actor akTarget, Actor akCaster)
    ; Safety net if the effect ends before the script tidies up on its own.
    CleanupChampion()
    If RewardActive
        RemoveReward()
    EndIf
    If RewardAura != None && PlayerRef != None
        RewardAura.Stop(PlayerRef as ObjectReference)
    EndIf
EndEvent

;-- Functions --------------------------------------------------------------
Function ApplyReward()
    Float favor10 = 0.0
    If WSN_TrackerQuest != None
        favor10 = PlayerRef.GetActorValue(WSN_TrackerQuest.WSN_AV)
        If favor10 < 0.0
            favor10 = 0.0
        EndIf
    EndIf
    appliedDamage = RewardDamageBase + favor10 * RewardDamagePerFavor
    appliedArmor = RewardArmorBase + favor10 * RewardArmorPerFavor
    appliedHealth = RewardHealthBase + favor10 * RewardHealthPerFavor
    appliedRegen = RewardRegenBase + favor10 * RewardRegenPerFavor

    PlayerRef.ModActorValue("AttackDamageMult", appliedDamage)
    PlayerRef.ModActorValue("DamageResist", appliedArmor)
    PlayerRef.ModActorValue("Health", appliedHealth)
    PlayerRef.ModActorValue("HealRateMult", appliedRegen)
    PlayerRef.ModActorValue("StaminaRateMult", appliedRegen)

    If RewardAura != None
        RewardAura.Play(PlayerRef as ObjectReference, RewardDuration)
    EndIf
    Debug.Notification("You have proven worthy. Tsun fills you with a hero's might!")
EndFunction

Function RemoveReward()
    If PlayerRef != None
        PlayerRef.ModActorValue("AttackDamageMult", -appliedDamage)
        PlayerRef.ModActorValue("DamageResist", -appliedArmor)
        PlayerRef.ModActorValue("Health", -appliedHealth)
        PlayerRef.ModActorValue("HealRateMult", -appliedRegen)
        PlayerRef.ModActorValue("StaminaRateMult", -appliedRegen)
        If RewardAura != None
            RewardAura.Stop(PlayerRef as ObjectReference)
        EndIf
    EndIf
    RewardActive = False
EndFunction

Function CleanupChampion()
    If PlayerRef != None
        If ChallengePerk != None
            PlayerRef.RemovePerk(ChallengePerk)
        EndIf
        If DismissPerk != None
            PlayerRef.RemovePerk(DismissPerk)
        EndIf
    EndIf
    If Champion != None
        Champion.StopCombat()
        Champion.Disable(false)
        Champion.Delete()
        Champion = None
    EndIf
EndFunction
