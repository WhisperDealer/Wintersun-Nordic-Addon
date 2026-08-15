Scriptname WSN_Divine_Tsun_TrialNode_Script extends ActiveMagicEffect
{Tsun devotee "Trial by Combat" - prayer node. Rides the devotee ability, gated (in the spell) on
 Wintersun's prayer-sit effect (023DD5), so it starts when the player kneels to pray. It places a
 selectable "Face the Trial" activator in front of the player - exactly as Wintersun's WSN_Sit_Script
 does for Kynareth and as Jhunal's Scholar's Insight does - and removes it when prayer ends.
 Selecting the node runs WSN_ActivatorNode_Script, which casts the persistent Trial by Combat spell
 on the player (summoning the champion). Self-contained: no override of Wintersun's compiled sit
 script.}

Activator Property PrayerNodeActivator Auto
{The selectable node placed while praying. Uses WSN_ActivatorNode_Script -> casts the trial spell.}

Float Property DistanceInFront = 64.0 Auto
{Horizontal distance in front of the player to place the node (Wintersun uses 64).}

Float Property HeightOffset = 64.0 Auto
{Vertical offset above the player's feet (Wintersun uses 64).}

ObjectReference TheNode

Event OnEffectStart(Actor akTarget, Actor akCaster)
    If akTarget == None || PrayerNodeActivator == None
        Return
    EndIf
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
