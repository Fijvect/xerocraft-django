module OpsCalendar exposing (..)

import Html exposing (Html, div, table, tr, td, th, text, span, button, br, p)
import Html.App as Html
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Http
import Task
import String
import Time exposing (Time)
import Date
import List
import Array
import DynamicStyle exposing (hover, hover')
import Mouse exposing (Position)

import Material
import Material.Button as Button
import Material.Icon as Icon
import Material.Options exposing (css)

import Json.Decode exposing((:=), maybe)
import Json.Decode as Dec
-- elm-package install --yes elm-community/elm-json-extra
import Json.Decode.Extra exposing ((|:))


-----------------------------------------------------------------------------
-- UTILITIES
-----------------------------------------------------------------------------

px : Int -> String
px number =
  toString number ++ "px"

toStr v =
  let
    str = toString v
  in
    if String.left 1 str == "\"" then
      String.dropRight 1 (String.dropLeft 1 str)
    else
      str

monthName : Int -> String
monthName x =
  case x of
    0 -> "January"
    1 -> "February"
    2 -> "March"
    3 -> "April"
    4 -> "May"
    5 -> "June"
    6 -> "July"
    7 -> "August"
    8 -> "September"
    9 -> "October"
    10 -> "November"
    11 -> "December"
    _ -> Debug.crash "Provide a value from 0 to 11, inclusive"


oneByThreeTable : Html Msg -> Html Msg -> Html Msg -> Html Msg
oneByThreeTable left center right =
  table [navHeaderStyle]
  [ tr []
    [ td [] [left]
    , td [] [center]
    , td [] [right]
    ]
  ]


-----------------------------------------------------------------------------
-- MAIN
-----------------------------------------------------------------------------

main =
  Html.programWithFlags
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }

-----------------------------------------------------------------------------
-- MODEL
-----------------------------------------------------------------------------

type alias OpsTask =
  { taskId: Int
  , isoDate: String
  , shortDesc: String
  , startTime: Maybe Time
  , endTime: Maybe Time
  , instructions: String
  , staffingStatus: String
  }

type alias DayOfTasks =
  { dayOfMonth: Int
  , isInTargetMonth: Bool
  , isToday: Bool
  , tasks: List OpsTask
  }

type alias WeekOfTasks = List DayOfTasks

type alias MonthOfTasks = List WeekOfTasks

-- These are params from the server. Elm docs tend to call them "flags".
type alias Flags =
  { tasks: MonthOfTasks
  , year: Int
  , month: Int
  }

type alias Model =
  { mdl: Material.Model
  , tasks: MonthOfTasks
  , year: Int
  , month: Int
  , selectedTaskId: Maybe Int
  , working: Bool
  , mouseX: Int
  , mouseY: Int
  , draggingDetail: Bool
  , detailX: Int
  , detailY: Int
  }

init : Flags -> (Model, Cmd Msg)
init {tasks, year, month} =
  ( Model
      Material.model
      tasks
      year
      month
      Nothing
      False
      0
      0
      False
      0
      0
  , Cmd.none
  )

-----------------------------------------------------------------------------
-- JSON Decoder
-----------------------------------------------------------------------------

decodeOpsTask : Dec.Decoder OpsTask
decodeOpsTask =
  Dec.succeed OpsTask
    |: ("taskId"           := Dec.int)
    |: ("isoDate"          := Dec.string)
    |: ("shortDesc"        := Dec.string)
    |: (maybe ("startTime" := Dec.float))
    |: (maybe ("endTime"   := Dec.float))
    |: ("instructions"     := Dec.string)
    |: ("staffingStatus"   := Dec.string)


decodeDayOfTasks : Dec.Decoder DayOfTasks
decodeDayOfTasks =
  Dec.succeed DayOfTasks
    |: ("dayOfMonth"      := Dec.int)
    |: ("isInTargetMonth" := Dec.bool)
    |: ("isToday"         := Dec.bool)
    |: ("tasks"           := Dec.list decodeOpsTask)


decodeFlags : Dec.Decoder Flags
decodeFlags =
  Dec.succeed Flags
    |: ("tasks" := Dec.list (Dec.list decodeDayOfTasks))
    |: ("year"  := Dec.int)
    |: ("month" := Dec.int)


-----------------------------------------------------------------------------
-- UPDATE
-----------------------------------------------------------------------------

type Msg
  = ToggleTaskDetail Int
  | HideTaskDetail
  | ClaimTask Int
  | PrevMonth
  | NextMonth
  | NewMonthSuccess Flags
  | NewMonthFailure Http.Error
  | Mdl Material.Msg
  | Position Int Int


update : Msg -> Model -> (Model, Cmd Msg)
update action model =
  case action of

    ToggleTaskDetail clickedTaskId ->
      let
        detailModel =
          { model
          | selectedTaskId = Just clickedTaskId
          , detailX = model.mouseX
          , detailY = model.mouseY
          }
      in
        case model.selectedTaskId of
          Nothing -> (detailModel, Cmd.none)
          Just selectedTaskId' ->
            if selectedTaskId' == clickedTaskId
              then ({model | selectedTaskId = Nothing}, Cmd.none)
              else (detailModel, Cmd.none)

    HideTaskDetail ->
      ({model | selectedTaskId = Nothing}, Cmd.none)

    ClaimTask taskId ->
      (model, Cmd.none)  -- TODO

    PrevMonth ->
      ({model | working = True}, getNewMonth model (-))

    NextMonth ->
      ({model | working = True}, getNewMonth model (+))

    NewMonthSuccess flags ->
      init flags

    NewMonthFailure err ->
      -- TODO: Display some sort of error message.
      case err of
        Http.Timeout -> (model, Cmd.none)
        Http.NetworkError -> (model, Cmd.none)
        Http.UnexpectedPayload _ -> (model, Cmd.none)
        Http.BadResponse _ _ -> (model, Cmd.none)

    Position newX newY ->
      ({model | mouseX = newX, mouseY = newY} , Cmd.none)

    Mdl msg' ->
      Material.update Mdl msg' model


getNewMonth : Model -> (Int -> Int -> Int) -> Cmd Msg
getNewMonth model op =
  let
    -- TODO: These should be passed in from Django, not hard-coded here.
    url = "/tasks/ops-calendar-json/" ++ toStr(year) ++ "-" ++ toStr(month) ++ "/"
    opMonth = op model.month 1
    year = case opMonth of
      13 -> model.year + 1
      0 -> model.year - 1
      _ -> model.year
    month = case opMonth of
      13 -> 1
      0 -> 12
      _ -> opMonth
  in
    Task.perform
      NewMonthFailure
      NewMonthSuccess
      (Http.get decodeFlags url)


-----------------------------------------------------------------------------
-- VIEW
-----------------------------------------------------------------------------

detailView : Model -> OpsTask -> Html Msg
detailView model ot =
  let
    left = px (model.detailX - 200)
    top = px (model.detailY + 12)
  in
    div [taskDetailStyle, style ["left" => left, "top" => top]]
      [ p [taskDetailParaStyle] [text ("Task ID: "++(toStr ot.taskId))]
      , p [taskDetailParaStyle] [text ot.shortDesc]
      , p [taskDetailParaStyle] [text ot.instructions]
      , button [detailButtonStyle, onClick HideTaskDetail] [text "Close"]
  --  , if task.staffingStatus == "U"
  --      then button [detailButtonStyle, (onClick (ClaimTask task.taskId))] [text "Claim"]
  --      else text ""
      ]

taskView : Model -> OpsTask -> Html Msg
taskView model ot =
  let
    theStyle = case ot.staffingStatus of
      "S" -> staffedStyle
      "U" -> unstaffedStyle
      "P" -> provisionalStyle
      _   -> Debug.crash "Only S, U, and P are allowed."
  in
    div []
      [ div (List.concat [theStyle, [onClick (ToggleTaskDetail ot.taskId)]]) [text ot.shortDesc]
      , if (model.selectedTaskId == Just ot.taskId)
           then detailView model ot
           else text ""
      ]


dayView : Model -> DayOfTasks -> Html Msg
dayView model dayOfTasks =
  let
    monthStyle = case dayOfTasks.isInTargetMonth of
      False -> dayOtherMonthStyle
      True -> dayTargetMonthStyle
    colorStyle = case dayOfTasks.isToday of
      False -> monthStyle
      True -> dayTodayStyle
  in
    td [tdStyle, colorStyle]
      ( List.concat
          [ [div [dayNumStyle] [text (toString dayOfTasks.dayOfMonth)]]
          , List.map (taskView model) dayOfTasks.tasks
          ]
      )

weekView : Model -> WeekOfTasks -> Html Msg
weekView model weekOfTasks =
  tr []
    (List.map (dayView model) weekOfTasks)

monthView : Model -> Html Msg
monthView model =
  let
    daysOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    headify = \x -> (th [thStyle] [text x])
  in
     table [tableStyle, unselectable]
       (List.concat
         [ [tr [] (List.map headify daysOfWeek)]
         , (List.map (weekView model) model.tasks)
         ])


headerView : Model -> Html Msg
headerView model =
    if model.working then
      oneByThreeTable (text "") (text "Working") (text "")
    else
      oneByThreeTable
        (Button.render Mdl [0] model.mdl
          ([ Button.fab, Button.onClick PrevMonth ] ++ navButtonCss)
          [ Icon.i "navigate_before" ])
        (text (monthName (model.month-1) ++ " " ++ (toStr model.year)))
        (Button.render Mdl [1] model.mdl
          ([ Button.fab, Button.onClick NextMonth ] ++ navButtonCss)
          [ Icon.i "navigate_next" ])


view : Model -> Html Msg
view model =
  div [containerStyle]
    [ headerView model
    , monthView model
    ]


-----------------------------------------------------------------------------
-- SUBSCRIPTIONS
-----------------------------------------------------------------------------

subscriptions: Model -> Sub Msg
subscriptions model =
  Mouse.moves (\{x, y} -> Position x y)


-----------------------------------------------------------------------------
-- STYLES
-----------------------------------------------------------------------------

(=>) = (,)

navButtonCss =
    [ css "margin" "0 10px"
    , css "padding" "5px"
    , css "min-width" "25px"
    , css "width" "25px"
    , css "height" "25px"
    ]

navHeaderStyle = style
  [ "font-family" => "Roboto Condensed, Arial, Helvetica"
  , "font-size" => "2em"
  , "height" => "35px"
  , "margin-left" => "auto"
  , "margin-right" => "auto"
  ]


taskDetailStyle =
  let r = "5px"
  in style
    [ "width" => "400px"
    , "background-color" => "#f0f0f0"
    , "position" => "absolute"
    , "text-align" => "left"
    , "padding" => "30px"
    , "border" => "1px solid black"
    , "border-radius" => r
    , "moz-border-radius" => r
    , "-webkit-border-radius" => r
    , "margin-right" => "auto"
    ]

taskDetailParaStyle = style
  [ "line-height" => "1.15"
  ]

unselectable = style
  [ "-moz-user-select" => "-moz-none"
  , "-khtml-user-select" => "none"
  , "-webkit-user-select" => "none"
  , "-ms-user-select" => "none"
  , "user-select" => "none"
  ]

containerStyle = style
  [ "padding" => "0 0"
  , "padding-top" => "3%"
  , "margin-top" => "0"
  , "width" => "100%"
  , "height" => "100%"
  , "text-align" => "center"
  , "font-family" => "Roboto Condensed, Arial, Helvetica"
  , "font-size" => "1em"
  ]

tableStyle = style
  [ "border-spacing" => "0"
  , "border-collapse" => "collapse"
  , "margin" => "0 auto"
  , "margin-top" => "2%"
  , "display" => "table"
  ]

buttonStyle = style
  [ "font-size" => "1.2em"
  , "margin" => "12px 7px" -- vert, horiz
  , "padding" => "7px 13px"
  ]

tdStyle = style
  [ "border" => "1px solid black"
  , "padding" => "10px"
  , "vertical-align" => "top"
  , "text-align" => "left"
  , "line-height" => "1.1"
  , "height" => "90px"
  , "width" => "120px"
  ]

thStyle = style
  [ "padding" => "5px"
  , "vertical-align" => "top"
  , "font-family" => "Arial, Helvetica"
  , "font-size" => "1.2em"
  , "font-weight" => "normal"
  ]

dayNumStyle = style
  [ "font-family" => "Arial, Helvetica"
  , "font-size" => "1.25em"
  , "margin-bottom" => "5px"
  ]

taskNameCss =
  [ "font-family" => "Roboto Condensed"
  , "font-size" => "1.1em"
  , "margin" => "0"
  , "overflow" => "hidden"
  , "white-space" => "nowrap"
  , "text-overflow" => "ellipsis"
  , "width" => "120px"
  , "cursor" => "pointer"
  ]

rollover = [ ("background-color", "transparent", "#b3ff99") ]

staffedStyle = hover' (List.concat [[("color", "green")], taskNameCss]) rollover

unstaffedStyle = hover' (List.concat [[("color", "red")], taskNameCss]) rollover

provisionalStyle = hover' (List.concat [[("color", "#c68e17")], taskNameCss]) rollover

dayOtherMonthStyle = style
  [ "background-color" => "#eeeeee"
  ]

dayTargetMonthStyle = style
  [ "background-color" => "white"
  ]

dayTodayStyle = style
  [ "background-color" => "#f0ffff"  -- azure
  ]

detailButtonStyle = style
  [ "font-family" => "Roboto Condensed"
  , "font-size" => "1.2em"
  , "cursor" => "pointer"
  , "margin-right" => "10px"
  ]
