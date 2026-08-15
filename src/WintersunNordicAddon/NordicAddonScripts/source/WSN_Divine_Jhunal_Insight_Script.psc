Scriptname WSN_Divine_Jhunal_Insight_Script extends ActiveMagicEffect
{Jhunal devotee power - Scholar's Insight. This effect rides a constant devotee ability that is
 gated (in the spell) on the prayer-sit effect, so OnEffectStart fires when the player kneels to
 pray. It presents a paged skill-selection menu, permanently raises the chosen skill by one level,
 then spends favor.

 The chosen skill's base value is raised by one via SetActorValue (the same pattern Wintersun's
 Satakal Ouroboros power uses to shift attributes) - a guaranteed, permanent +1 level.

 Favor MUST be spent through the TrackerQuest's QueueFavorChange - writing the favor global
 directly is undone on the next favor tick. When favor falls below the favored threshold (100),
 Wintersun removes the power automatically.}

;-- Properties -------------------------------------------------------------
Message Property SkillMenu1 Auto
{Page 1: skills 0-7 (buttons 0-7), "More Skills..." (8), "Cancel" (9).}

Message Property SkillMenu2 Auto
{Page 2: skills 8-15 (buttons 0-7), "More Skills..." (8), "Back" (9).}

Message Property SkillMenu3 Auto
{Page 3: skills 16-17 (buttons 0-1), "Back" (2), "Cancel" (3).}

WSN_TrackerQuest_Quest Property WSN_TrackerQuest Auto
{Wintersun's central quest (FormKey 005901). QueueFavorChange spends favor here.}

Float Property FavorCost = 20.0 Auto
{Favor points deducted each time a skill is raised.}

Actor Property PlayerRef Auto
{PlayerRef (FormKey 000014).}

Event OnEffectStart(Actor akTarget, Actor akCaster)
    If PlayerRef == None || SkillMenu1 == None || SkillMenu2 == None || SkillMenu3 == None
        Return
    EndIf

    ; Paged skill picker with Back/Cancel navigation. page 0 = done, skillIndex -1 = cancelled.
    Int page = 1
    Int skillIndex = -1
    Int b = 0
    While page > 0
        If page == 1
            b = SkillMenu1.Show()
            If b == 9
                page = 0            ; Cancel
            ElseIf b == 8
                page = 2            ; More Skills
            Else
                skillIndex = b
                page = 0
            EndIf
        ElseIf page == 2
            b = SkillMenu2.Show()
            If b == 9
                page = 1            ; Back
            ElseIf b == 8
                page = 3            ; More Skills
            Else
                skillIndex = 8 + b
                page = 0
            EndIf
        Else
            b = SkillMenu3.Show()
            If b == 3
                page = 0            ; Cancel
            ElseIf b == 2
                page = 2            ; Back
            Else
                skillIndex = 16 + b
                page = 0
            EndIf
        EndIf
    EndWhile

    If skillIndex < 0 || skillIndex > 17
        Return                       ; cancelled - no skill raised, no favor spent
    EndIf

    ; Permanently raise the chosen skill's base value by one level.
    String skillAV = SkillActorValue(skillIndex)
    Float current = PlayerRef.GetBaseActorValue(skillAV)
    PlayerRef.SetActorValue(skillAV, current + 1.0)

    ; Spend favor through the TrackerQuest so the cost sticks.
    If WSN_TrackerQuest != None
        WSN_TrackerQuest.QueueFavorChange(-FavorCost, true, true)
    EndIf

    Debug.Notification("Jhunal's insight raises your " + SkillDisplayName(skillIndex) + ".")
EndEvent

; Papyrus actor-value string for each skill index (0-17).
String Function SkillActorValue(Int i)
    String[] av = New String[18]
    av[0]  = "OneHanded"
    av[1]  = "TwoHanded"
    av[2]  = "Marksman"
    av[3]  = "Block"
    av[4]  = "Smithing"
    av[5]  = "HeavyArmor"
    av[6]  = "Destruction"
    av[7]  = "Restoration"
    av[8]  = "Conjuration"
    av[9]  = "Alteration"
    av[10] = "Illusion"
    av[11] = "Enchanting"
    av[12] = "LightArmor"
    av[13] = "Sneak"
    av[14] = "Lockpicking"
    av[15] = "Pickpocket"
    av[16] = "Speechcraft"
    av[17] = "Alchemy"
    Return av[i]
EndFunction

; Human-readable skill name for the confirmation notification.
String Function SkillDisplayName(Int i)
    String[] nm = New String[18]
    nm[0]  = "One-Handed"
    nm[1]  = "Two-Handed"
    nm[2]  = "Archery"
    nm[3]  = "Block"
    nm[4]  = "Smithing"
    nm[5]  = "Heavy Armor"
    nm[6]  = "Destruction"
    nm[7]  = "Restoration"
    nm[8]  = "Conjuration"
    nm[9]  = "Alteration"
    nm[10] = "Illusion"
    nm[11] = "Enchanting"
    nm[12] = "Light Armor"
    nm[13] = "Sneak"
    nm[14] = "Lockpicking"
    nm[15] = "Pickpocket"
    nm[16] = "Speech"
    nm[17] = "Alchemy"
    Return nm[i]
EndFunction
