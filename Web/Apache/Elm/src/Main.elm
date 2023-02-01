module Main exposing (..)

import Browser
import Html exposing (Html, div, h1, text, button)
import Html.Attributes exposing (classList)
import Html.Events exposing (onClick, onMouseDown)

import Logs exposing (..)
import Upload exposing (..)
import Rotations exposing (..)
import Mechanics exposing (..)

import DateRangePicker as Picker
import DateRangePicker.Range as Range

import Bootstrap.Alert as Alert
import Bootstrap.Form as Form
import Bootstrap.Button as Button
import Bootstrap.CDN as CDN
import Bootstrap.Spinner as Spinner
import Bootstrap.Text as Text
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Row as Row
import Bootstrap.Grid.Col as Col
import Bootstrap.Tab as Tab

main =
  -- Html.program
  Browser.element
    { init = init
    , update = update
    , view = view
    , subscriptions = subscriptions
    }

-- MODEL
type alias Model =
  { message : String
  , logs : Logs.Model
  , tabState : Tab.State
  , upload : Upload.Model
  -- , players : Players.Model
  , mechanics : Mechanics.Model
  }

init : () -> ( Model, Cmd Msg )
init _ =
  let
    model =
      { message = "Main!"
      , logs = Logs.default
      , tabState = Tab.initialState
      , upload = Upload.default
      -- , players = Rotations.default
      , mechanics = Mechanics.default
      }
  in
    ( model, Cmd.batch [Cmd.map LogMsg Logs.getLogs, Cmd.map LogMsg <| Picker.now Logs.PickerChanged model.logs.pickerState] )

-- UPDATE
type Msg
  = Default
  -- | LoadPlayersFromLogs
  | LoadMechanicsFromLogs
  | TabMsg Tab.State
  | LogMsg Logs.Msg
  | UploadMsg Upload.Msg
  -- | PlayersMsg Players.Msg
  | MechanicsMsg Mechanics.Msg
  
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    Default -> 
      ( model, Cmd.none )
    -- LoadPlayersFromLogs ->
    --   ( model, Cmd.map RotationsMsg <| Rotations.getPlayersFromLogs <| List.filter .selected model.logs.logs)
    LoadMechanicsFromLogs ->
      ( model, Cmd.map MechanicsMsg <| Mechanics.getMechanicsFromLogs <|List.filter .selected model.logs.logs)
    TabMsg tabState ->
      ({model | tabState = tabState}, Cmd.none)
    LogMsg logmsg ->
      let
        (logmodel, logcmd) = Logs.update logmsg model.logs
      in
        ({model | logs = logmodel}, Cmd.map LogMsg logcmd)
    UploadMsg uploadmsg ->
      let
        (uploadmodel, uploadcmd) = Upload.update uploadmsg model.upload
      in
        case uploadmsg of
            LogUploaded _ -> 
              ({model | upload = uploadmodel}, Cmd.batch [Cmd.map UploadMsg uploadcmd, Cmd.map LogMsg getLogs])
            _ ->
              ({model | upload = uploadmodel}, Cmd.map UploadMsg uploadcmd)
    -- PlayersMsg playersmsg ->
    --   let
    --     (playersmodel, playerscmd) = Rotations.update playersmsg model.players
    --   in
    --     ({model | players = playersmodel}, Cmd.map RotationsMsg playerscmd)
    MechanicsMsg mechanicsmsg ->
      let
        (mechanicsmodel, mechanicscmd) = Mechanics.update mechanicsmsg model.mechanics
      in
        ({model | mechanics = mechanicsmodel}, Cmd.map MechanicsMsg mechanicscmd)

-- VIEW
view : Model -> Html Msg
view { message , tabState, logs, upload, mechanics} =
  div []
    [ CDN.stylesheet
    , Grid.containerFluid []
      [Grid.row [Row.topXs ]
        [ Grid.col [Col.xs12 ]
          [
            Tab.config TabMsg
              |> Tab.withAnimation
              |> Tab.items
                [ Tab.item
                  { id = "logs"
                  , link = Tab.link [] [ text "Logs" ]
                  , pane = Tab.pane [] [ 
                      Html.map LogMsg <| Logs.view logs
                    ]
                  }
                , Tab.item
                  { id = "upload"
                  , link = Tab.link [] [ text "Upload" ]
                  , pane = Tab.pane [] [ 
                      Html.map UploadMsg <| Upload.view upload
                    ]
                  }
                , Tab.item
                  { id = "mechanics"
                  , link = Tab.link [ onMouseDown LoadMechanicsFromLogs ] [ text "Mechanics" ]
                  , pane = Tab.pane [] [ 
                      Html.map MechanicsMsg <| Mechanics.view mechanics
                    ]
                  }
                ]
              |> Tab.view tabState
          ]
        ]
      ]
    ]

subscriptions : Model -> Sub Msg
subscriptions model = Sub.batch [Sub.map LogMsg <| Logs.subscriptions model.logs, Sub.map UploadMsg <| Upload.subscriptions model.upload, Tab.subscriptions model.tabState TabMsg]