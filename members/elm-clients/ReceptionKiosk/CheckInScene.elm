
module ReceptionKiosk.CheckInScene exposing (init, view, update, CheckInModel)

-- Standard
import Html exposing (..)
import Http

-- Third Party
import Material
import Material.Chip as Chip
import Material.Options as Options exposing (css)

-- Local
import ReceptionKiosk.Types exposing (..)
import ReceptionKiosk.SceneUtils exposing (..)
import ReceptionKiosk.Backend as Backend

-----------------------------------------------------------------------------
-- INIT
-----------------------------------------------------------------------------

type alias CheckInModel =
  { flexId : String  -- UserName or surname.
  , matches : List Backend.MatchingAcct  -- Matches to username/surname
  , badNews : List String
  }

-- This type alias describes the type of kiosk model that this scene requires.
type alias KioskModel a = (SceneUtilModel {a | checkInModel : CheckInModel})

init : Flags -> (CheckInModel, Cmd Msg)
init flags =
  let model =
    { flexId = ""
    , matches = []
    , badNews = []
    }
  in (model, Cmd.none)

-----------------------------------------------------------------------------
-- UPDATE
-----------------------------------------------------------------------------

update : CheckInMsg -> KioskModel a -> (CheckInModel, Cmd Msg)
update msg kioskModel =
  let sceneModel = kioskModel.checkInModel
  in case msg of

    UpdateFlexId rawId ->
      let
        id = Backend.djangoizeId rawId
        getMatchingAccts = Backend.getMatchingAccts kioskModel.flags
      in
        if (String.length id) > 1
        then
          ({sceneModel | flexId = id}, getMatchingAccts id (CheckInVector << UpdateMatchingAccts))
        else
          ({sceneModel | matches = [], flexId = id}, Cmd.none )

    UpdateMatchingAccts (Ok {target, matches}) ->
      if target == sceneModel.flexId
      then ({sceneModel | matches = matches, badNews = []}, Cmd.none)
      else (sceneModel, Cmd.none)

    UpdateMatchingAccts (Err error) ->
      ({sceneModel | badNews = [toString error]}, Cmd.none)

    LogCheckIn memberNum ->
      -- TODO: Log the visit. Might be last feature to be implemented to avoid collecting bogus visits during alpha testing.
      (sceneModel, send (WizardVector <| Push <| ReasonForVisit))

-----------------------------------------------------------------------------
-- VIEW
-----------------------------------------------------------------------------

view : KioskModel a -> Html Msg
view kioskModel =
  let
    sceneModel = kioskModel.checkInModel
    acct2chip = \acct ->
      Chip.button
        [Options.onClick (CheckInVector <| LogCheckIn <| acct.memberNum)]
        [Chip.content [] [text acct.userName]]

  in genericScene kioskModel
    "Let's Get You Checked-In!"
    "Who are you?"
    ( div []
        (List.concat
          [ [sceneTextField kioskModel 1 "Your Username or Surname" sceneModel.flexId (CheckInVector << UpdateFlexId), vspace 0]
          , if List.length sceneModel.matches > 0
             then [vspace 30, text "Tap your userid, below:", vspace 20]
             else [vspace 0]
          , List.map acct2chip sceneModel.matches
          , [ vspace (if List.length sceneModel.badNews > 0 then 40 else 0) ]
          , [ formatBadNews sceneModel.badNews ]
          ]
        )
    )
    []  -- No buttons

-----------------------------------------------------------------------------
-- STYLES
-----------------------------------------------------------------------------

sceneChipCss =
  [ css "margin-left" "3px"
  , css "margin-right" "3px"
  ]
