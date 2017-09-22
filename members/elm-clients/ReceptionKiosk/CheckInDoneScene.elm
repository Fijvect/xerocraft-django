
module ReceptionKiosk.CheckInDoneScene exposing (init, view, tick, CheckInDoneModel)

-- Standard
import Html exposing (Html, text, div)
import Time exposing (Time)

-- Third Party

-- Local
import ReceptionKiosk.Types exposing (..)
import Wizard.SceneUtils exposing (..)

-----------------------------------------------------------------------------
-- INIT
-----------------------------------------------------------------------------

type alias CheckInDoneModel =
  {
    displayTimeRemaining : Int
  }

-- This type alias describes the type of kiosk model that this scene requires.
type alias KioskModel a = (SceneUtilModel {a | checkInDoneModel : CheckInDoneModel})

init : Flags -> (CheckInDoneModel, Cmd Msg)
init flags = ({displayTimeRemaining=5}, Cmd.none)

-----------------------------------------------------------------------------
-- UPDATE
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- VIEW
-----------------------------------------------------------------------------

view : KioskModel a -> Html Msg
view kioskModel =
  let sceneModel = kioskModel.checkInDoneModel
  in genericScene kioskModel
    "You're Checked In"
    "Have fun!"
    ( div []
      [ vspace 40
      , sceneButton kioskModel <| ButtonSpec "Ok" (WizardVector <| Push <| Welcome)
      , vspace 70
      , (text (String.repeat sceneModel.displayTimeRemaining "●"))
      ]
    )
    []
    []

-----------------------------------------------------------------------------
-- TICK (called each second)
-----------------------------------------------------------------------------

tick : Time -> KioskModel a -> (CheckInDoneModel, Cmd Msg)
tick time kioskModel =
  let
    sceneModel = kioskModel.checkInDoneModel
    visible = sceneIsVisible kioskModel CheckInDone
    dec = if visible then 1 else 0
    newTimeRemaining = sceneModel.displayTimeRemaining - dec
    cmd =
      if newTimeRemaining <= 0 then
        segueTo Welcome
      else
        Cmd.none
  in
    ({sceneModel | displayTimeRemaining=newTimeRemaining}, cmd)

