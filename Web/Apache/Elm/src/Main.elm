module Main exposing (..)

import Browser
import Html exposing (Html, div, h1, text, button)
import Html.Attributes exposing (placeholder, classList)
import Html.Events exposing (onInput, onClick)

import Logs exposing (..)
import Upload exposing (..)
import Players exposing (..)
import Mechanics exposing (..)

main =
  -- Html.program
  Browser.element
    { init = init
    , update = update
    , view = view
    , subscriptions = \_ -> Sub.none
    }

-- MODEL
type alias Model =
  { message : String
  , logs : Logs.Model
  , upload : Upload.Model
  , players : Players.Model
  , mechanics : Mechanics.Model
  }

init : () -> ( Model, Cmd Msg )
init _ =
  let
    model =
      { message = "Main!"
      , logs = Logs.default
      , upload = Upload.default
      , players = Players.default
      , mechanics = Mechanics.default
      }
  in
    ( model, Cmd.batch [Cmd.map LogMsg Logs.getLogs, Cmd.map MechanicsMsg Mechanics.getMechanics] )

-- UPDATE
type Msg
  = Default
  | LoadPlayersFromLogs
  | LoadMechanicsFromLogs
  | LogMsg Logs.Msg
  | UploadMsg Upload.Msg
  | PlayersMsg Players.Msg
  | MechanicsMsg Mechanics.Msg
  
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    Default -> 
      ( model, Cmd.none )
    LoadPlayersFromLogs ->
      ( model, Cmd.map PlayersMsg (Players.getPlayersFromLogs (List.filter .selected model.logs.logs)))
    LoadMechanicsFromLogs ->
      ( model, Cmd.map MechanicsMsg (Mechanics.getMechanicsFromLogs (List.filter .selected model.logs.logs)))
    LogMsg logmsg ->
      let
        (logmodel, logcmd) = Logs.update logmsg model.logs
      in
        ({model | logs = logmodel}, Cmd.map LogMsg logcmd)
    UploadMsg uploadmsg ->
      let
        (uploadmodel, uploadcmd) = Upload.update uploadmsg model.upload
      in
        ({model | upload = uploadmodel}, Cmd.map UploadMsg uploadcmd)
    PlayersMsg playersmsg ->
      let
        (playersmodel, playerscmd) = Players.update playersmsg model.players
      in
        ({model | players = playersmodel}, Cmd.map PlayersMsg playerscmd)
    MechanicsMsg mechanicsmsg ->
      let
        (mechanicsmodel, mechanicscmd) = Mechanics.update mechanicsmsg model.mechanics
      in
        ({model | mechanics = mechanicsmodel}, Cmd.map MechanicsMsg mechanicscmd)

-- VIEW
view : Model -> Html Msg
view { message , logs, upload, players, mechanics} =
  div [classList [("test", True)] ]
    [ h1 [] [ text message ]
    , Html.map UploadMsg (Upload.view upload)
    , Html.map LogMsg (Logs.view logs)
    , button [ onClick LoadPlayersFromLogs ] [ text "Get players from selected logs" ]
    , button [ onClick LoadMechanicsFromLogs ] [ text "Get mechanics from selected logs" ]
    , Html.map PlayersMsg (Players.view players)
    , Html.map MechanicsMsg (Mechanics.view mechanics)
  ]
