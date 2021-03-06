
module CheckInDoneScene exposing
  ( init
  , update
  , view
  , CheckInDoneModel
  )

-- Standard
import Html exposing (Html, text, div)
import Time exposing (Time)

-- Third Party
import Material
import List.Nonempty exposing (Nonempty)

-- Local
import Types exposing (..)
import Wizard.SceneUtils exposing (..)
import XisRestApi as XisApi exposing (Member)


-----------------------------------------------------------------------------
-- CONSTANTS
-----------------------------------------------------------------------------


-----------------------------------------------------------------------------
-- INIT
-----------------------------------------------------------------------------

-- This type alias describes the type of kiosk model that this scene requires.
type alias KioskModel a =
  { a
  ------------------------------------
  | mdl : Material.Model
  , flags : Flags
  , sceneStack : Nonempty Scene
  ------------------------------------
  , checkInDoneModel : CheckInDoneModel
  , xisSession : XisApi.Session Msg
  }


type alias CheckInDoneModel =
  { member : Maybe Member
  }


init : Flags -> (CheckInDoneModel, Cmd Msg)
init flags =
  ( {member = Nothing}
  , Cmd.none
  )


-----------------------------------------------------------------------------
-- UPDATE
-----------------------------------------------------------------------------

update : CheckInDoneMsg -> KioskModel a -> (CheckInDoneModel, Cmd Msg)
update msg kioskModel =
  let
    sceneModel = kioskModel.checkInDoneModel
    xis = kioskModel.xisSession

  in case msg of
    CID_Segue member ->
      ( { sceneModel | member = Just member}
      , send <| WizardVector <| Push CheckInDone
      )


-----------------------------------------------------------------------------
-- VIEW
-----------------------------------------------------------------------------

view : KioskModel a -> Html Msg
view kioskModel =
  let sceneModel = kioskModel.checkInDoneModel
  in genericScene kioskModel
    "You're Checked In"
    "Have fun!"
    (vspace 40)
    [ButtonSpec "Ok" (WizardVector <| Reset) True]
    [] -- Never any bad news for this scene


-----------------------------------------------------------------------------
-- TICK (called each second)
-----------------------------------------------------------------------------


