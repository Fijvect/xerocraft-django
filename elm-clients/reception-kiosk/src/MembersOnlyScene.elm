
module MembersOnlyScene exposing
  ( init
  , update
  , view
  , MembersOnlyModel
  )

-- Standard
import Html exposing (..)
import Html.Attributes exposing (..)
import Regex exposing (regex)
import Time exposing (Time)
import Date exposing (Date)

-- Third Party
import String.Extra exposing (..)
import Material
import List.Nonempty exposing (Nonempty)

-- Local
import XerocraftApi as XcApi
import XisRestApi as XisApi exposing (..)
import Wizard.SceneUtils exposing (..)
import Types exposing (..)
import CalendarDate
import PointInTime exposing (PointInTime)


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
  , membersOnlyModel : MembersOnlyModel
  , currTime : Time
  , xisSession : XisApi.Session Msg
  }


type PaymentInfoState
  = PresentingOptions
  | ExplainingHowToPayNow
  | PaymentInfoSent
  | SendingPaymentInfo


type alias MembersOnlyModel =
  -------------- Req'd arguments:
  { member : Maybe Member
  -------------- Other state:
  , paymentInfoState : PaymentInfoState
  , badNews : List String
  }


init : Flags -> (MembersOnlyModel, Cmd Msg)
init flags =
  let sceneModel =
    { member = Nothing
    , paymentInfoState = PresentingOptions
    , badNews = []
    }
  in (sceneModel, Cmd.none)


-----------------------------------------------------------------------------
-- UPDATE
-----------------------------------------------------------------------------

{- Will keep this simple, for now. This scene will appear if all of the following are true:
   (1) We know what type of time block we're in.
   (2) The time block is tagged as being for Supporting Members Only.
   (3) We have the user's membership info.
-}
membersOnlyButNotMember :
  XisApi.Session a -> Member -> PointInTime -> Maybe TimeBlock -> List TimeBlockType -> Bool
membersOnlyButNotMember
  xis member now nowBlock allTypes =

  let
    membersOnlyStr = "Members Only"
    defaultBlockTypeName = case xis.defaultBlockType allTypes of
      Just bt -> bt.data.name
      Nothing -> ""
    isCurrent = case member.data.latestNonfutureMembership of
      Just m -> xis.coverTime [m] now
      Nothing -> False
    isMembersOnly = case nowBlock of
      Just nb -> xis.blockHasType membersOnlyStr allTypes nb
      Nothing -> defaultBlockTypeName == membersOnlyStr
  in
    isMembersOnly && not isCurrent


update : MembersOnlyMsg -> KioskModel a -> (MembersOnlyModel, Cmd Msg)
update msg kioskModel =

  let
    sceneModel = kioskModel.membersOnlyModel
    xis = kioskModel.xisSession

  in case msg of

    MO_Segue member nowBlock allTypes ->

      let
        newSceneModel = { sceneModel | member = Just member }
      in
        if membersOnlyButNotMember xis member kioskModel.currTime nowBlock allTypes then
          -- We need to talk, so push this scene.

          (newSceneModel, send <| WizardVector <| Push <| MembersOnly)
        else
          -- Nothing to say, so skip this scene.
          (newSceneModel, send <| OldBusinessVector <| OB_SegueA CheckInSession member)


    SendPaymentInfo ->
      let
        newModel = {sceneModel | paymentInfoState = SendingPaymentInfo}
        cmd = case sceneModel.member of
          Just m -> xis.emailMembershipInfo m.id (MembersOnlyVector << ServerSentPaymentInfo)
          Nothing -> send <| ErrorVector <| ERR_Segue missingArguments
      in
        (newModel, cmd)

    ServerSentPaymentInfo (Ok msg) ->
      let
        newModel = {sceneModel | paymentInfoState = PaymentInfoSent}
      in
        (newModel, Cmd.none)

    PayNowAtFrontDesk ->
      ({sceneModel | paymentInfoState = ExplainingHowToPayNow}, Cmd.none)

    -- FAILURES --------------------

    ServerSentPaymentInfo (Err error) ->
      -- We will pretend it worked but will log the error.
      let
        msg = toString error |> Debug.log "Error trying to send payment info"
      in
        ( {sceneModel | paymentInfoState = PaymentInfoSent}
        , Cmd.none
        )


-----------------------------------------------------------------------------
-- VIEW
-----------------------------------------------------------------------------

view : KioskModel a -> Html Msg
view kioskModel =
  let
    sceneModel = kioskModel.membersOnlyModel
    xis = kioskModel.xisSession
  in
    case sceneModel.member of

      Nothing ->
        errorView kioskModel missingArguments

      Just m ->

        genericScene kioskModel
          "Supporting Members Only"
          "We are not currently open to the public"
          (
          case sceneModel.paymentInfoState of
            PresentingOptions -> optionsContent kioskModel sceneModel xis m
            SendingPaymentInfo -> optionsContent kioskModel sceneModel xis m
            PaymentInfoSent -> paymentInfoSentContent kioskModel sceneModel xis m
            ExplainingHowToPayNow -> howToPayNowContent kioskModel sceneModel xis m
          )
          []  -- No buttons here. They will be woven into content.
          []  -- No bad news. Scene will fail silently, but should log somewhere.


optionsContent : KioskModel a -> MembersOnlyModel -> XisApi.Session Msg -> Member -> Html Msg
optionsContent kioskModel sceneModel xis member =
  let
    paymentMsg = case member.data.latestNonfutureMembership of
      Just mship ->
        "Our records show that your most recent membership expired on "
        ++ CalendarDate.format "%d-%b-%Y" mship.data.endDate
        ++ "."
      Nothing ->
        "We have no record of previous payments by you."
  in
    div [sceneTextStyle, sceneTextBlockStyle]
        [ vspace 20
        , text (paymentMsg)
        , vspace 40
        , text "Do you believe that you've already purchased a membership that covers today's visit?"
        , vspace 60
        , sceneButton kioskModel
            <| ButtonSpec
               "Yes"
               (OldBusinessVector <| OB_SegueA CheckInSession member)
               True
        , sceneButton kioskModel
            <| ButtonSpec
               "No"
               (OldBusinessVector <| OB_SegueA CheckInSession member)
               True

        ]

--        , text "choose one of the following:"
--        , vspace 20
--          -- TODO: Should display other options for Work Traders.
--          -- TODO: Payment options should come from a single source on the backend.
--        , sceneButton kioskModel (ButtonSpec "Send Me Payment Info" (MembersOnlyVector <| SendPaymentInfo) True)
--        , vspace 20
--        , sceneButton kioskModel (ButtonSpec "Pay Now at Front Desk" (MembersOnlyVector <| PayNowAtFrontDesk) True)
--          -- TODO: If visitor is a keyholder, offer them 1day for $10
--        , vspace 40
--        , text "If your membership is current, thanks!"
--        , vspace 0
--        , text "Just click below."
--        , vspace 20
--        , sceneButton kioskModel
--            <| ButtonSpec
--               "I have paid"
--               (OldBusinessVector <| OB_SegueA CheckInSession member)
--               True


paymentInfoSentContent : KioskModel a -> MembersOnlyModel -> XisApi.Session Msg -> Member -> Html Msg
paymentInfoSentContent kioskModel sceneModel xis member =
  let
    sceneModel = kioskModel.membersOnlyModel
  in
    div [sceneTextStyle, sceneTextBlockStyle]
      [ vspace 80
      , img [src "/static/bzw_ops/EmailSent.png", emailSentImgStyle] []
      , vspace 20
      , text "We've sent payment information to you via email!"
      , vspace 0
      , text "Please be sure to renew before visiting another"
      , vspace 0
      , text "\"Supporting Members Only\" session."
      , vspace 40
      , sceneButton kioskModel
          <| ButtonSpec
              "OK"
              (OldBusinessVector <| OB_SegueA CheckInSession member)
              True
      ]

howToPayNowContent : KioskModel a -> MembersOnlyModel -> XisApi.Session Msg -> Member -> Html Msg
howToPayNowContent kioskModel sceneModel xis member =
  div [sceneTextStyle, sceneTextBlockStyle]
    [ vspace 60
    , img [src "/static/bzw_ops/VisaMcDiscAmexCashCheck.png", payTypesImgStyle] []
    , vspace 40
    , text "We accept credit card, cash, and checks."
    , vspace 0
    , text "Please ask a Staffer for assistance."
    , vspace 0
    , text "Thanks!"
    , vspace 60
    , sceneButton kioskModel
        <| ButtonSpec
             "OK"
             (OldBusinessVector <| OB_SegueA CheckInSession member)
             True
    ]


-----------------------------------------------------------------------------
-- STYLES
-----------------------------------------------------------------------------

emailSentImgStyle = style
  [ "text-align" => "center"
  , "width" => px 200
  , "margin-left" => px -80
  ]

payTypesImgStyle = style
  [ "text-align" => "center"
  , "width" => px 400
  ]
