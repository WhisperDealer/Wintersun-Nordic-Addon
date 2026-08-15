Scriptname WSN_Divine_Jhunal_PrayerNode_Script extends ActiveMagicEffect
{Jhunal devotee - Scholar's Insight. This effect rides the devotee ability, gated (in the spell) on
 the prayer-sit effect (023DD5), so it starts when the player kneels to pray. It places a selectable
 "Contemplate" activator in front of the player - exactly as Wintersun's WSN_Sit_Script does for
 Kynareth (WorshipID 17) - and removes it when prayer ends. Selecting the node casts the ProcOnSelf
 spell, which runs the skill picker. Self-contained: no override of Wintersun's compiled sit script.}

Activator Property PrayerNodeActivator Auto
{The selectable node placed while praying. Uses WSN_ActivatorNode_Script -> casts the ProcOnSelf spell.}

Float Property DistanceInFront = 64.0 Auto
{Horizontal distance in front of the player to place the node (Wintersun uses 64).}

Float Property HeightOffset = 64.0 Auto
{Vertical offset above the player's feet (Wintersun uses 64).}

ObjectReference TheNode

Event OnEffectStart(Actor akTarget, Actor akCaster)
    If akTarget == None || PrayerNodeActivator == None
        Return
    EndIf
    ; Place the node a short distance in front of where the player is facing (mirrors WSN_Sit_Script).
    Float angZ = akTarget.GetAngleZ()
    Float ex = DistanceInFront * Math.Sin(angZ)
    Float ey = DistanceInFront * Math.Cos(angZ)
    TheNode = akTarget.PlaceAtMe(PrayerNodeActivator as Form, 1, false, true)
    TheNode.SetPosition(akTarget.GetPositionX() + ex, akTarget.GetPositionY() + ey, akTarget.GetPositionZ() + HeightOffset)
    TheNode.Enable(false)
EndEvent

Event OnEffectFinish(Actor akTarget, Actor akCaster)
    If TheNode
        TheNode.BlockActivation(true)
        Utility.Wait(0.25)
        TheNode.Disable(true)
        TheNode.Delete()
        TheNode = None
    EndIf
EndEvent
