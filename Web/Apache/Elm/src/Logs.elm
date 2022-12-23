module Logs exposing (..)

import Browser
import Html exposing (Html, Attribute, div, h1, input, text, button)
import Html.Attributes exposing (checked, style, type_)
import Html.Events exposing (onInput, onClick)
import Table exposing (defaultCustomizations)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (required, optional, hardcoded)
import Http

import Iso8601
import Time
import Parser

main =
  Browser.element
    { init = init
    , update = update
    , view = view
    , subscriptions = \_ -> Sub.none
    }

-- MODEL
type alias Log =
    { identifier : String
    , is_cm : Bool
    , is_win : Bool
    , elite_version : String
    , trigger_id : Int 
    , fight : String
    , arc_version : String
    , gw2_version : Maybe String
    , language : String
    , language_nr : Int
    , recorded_by : String
    , start : Result (List Parser.DeadEnd) Time.Posix
    , end : Result (List Parser.DeadEnd) Time.Posix
    , duration : String
    , selected : Bool
    }

type State = Loading 
           | Loaded

type alias Model =
  { logs : List Log
  , tableState : Table.State
  , query : String
  , message : String
  , state : State
  }

default : Model
default = 
      { logs = []
      , tableState = Table.initialSort "Identifier"
      , query = ""
      , message = ""
      , state = Loading
      }


init : () -> ( Model, Cmd Msg )
init _ =
  let
    model =
        default
  in
    ( model, getLogs )

type Msg
  = SetQuery String
  | SetTableState Table.State
  | GetLogs
  | GotLogs (Result Http.Error (List Log))
  | ToggleSelected String

decodeTime : Decode.Decoder (Result (List Parser.DeadEnd) Time.Posix)
decodeTime = 
    Decode.string
        |> Decode.andThen (\time ->
            Decode.succeed (Iso8601.toTime time)
        )

logsDecoder : Decode.Decoder (List Log)
logsDecoder = 
    (Decode.at ["data"] (
        Decode.list (
            logDecoder
        )
    ))

logDecoder : Decode.Decoder Log
logDecoder = 
    Decode.succeed Log
        |> required "identifier" Decode.string
        |> required "is_cm" Decode.bool
        |> required "is_win" Decode.bool
        |> required "elite_version" Decode.string
        |> required "trigger_id" Decode.int
        |> required "fight" Decode.string
        |> required "arc_version" Decode.string
        |> required "gw2_version" (Decode.nullable Decode.string)
        |> required "language" Decode.string
        |> required "language_nr" Decode.int
        |> required "recorded_by" Decode.string
        |> required "start" decodeTime
        |> required "end" decodeTime
        |> required "duration" Decode.string
        |> hardcoded False -- "selected" Decode.bool

getLogs : Cmd Msg
getLogs =
    Http.get
        { url = "/api/logs"
        , expect = Http.expectJson GotLogs logsDecoder
        }

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    SetQuery newQuery ->
      ( { model | query = newQuery }
      , Cmd.none
      )

    SetTableState newState ->
      ( { model | tableState = newState }
      , Cmd.none
      )

    GetLogs ->
      ( model, getLogs )

    GotLogs result ->
      case result of
        Ok logs ->
          ({model | logs = logs, state = Loaded}, Cmd.none)
        Err error ->
          case error of
              Http.BadUrl url ->
                ({model | message = "URL"}, Cmd.none)
              Http.Timeout ->
                ({model | message = "Timeout"}, Cmd.none)
              Http.NetworkError ->
                ({model | message = "NetworkError"}, Cmd.none)
              Http.BadStatus _ -> 
                ({model | message = "BadStatus"}, Cmd.none)
              Http.BadBody body -> 
                ({model | message = body}, Cmd.none)
    ToggleSelected log ->
        ({model | logs = List.map (toggle log) model.logs}, Cmd.none)

toggle : String -> Log -> Log
toggle identifier log =
    if log.identifier == identifier then
        { log | selected = not log.selected}
    else
        log

-- VIEW
view : Model -> Html Msg
view { logs, tableState, query, message, state } =
  let
    lowerQuery =
      String.toLower query

    acceptablePeople =
      List.filter (String.contains lowerQuery << String.toLower << .identifier) logs 
  in
    case state of
      Loading ->
        div []
            [
                h1 [] [text "Arc Logs"]
                , h1 [] [ text message ]
                , text "loading..."
            ]
      Loaded ->
        div []
            [ h1 [] [ text "Arc Logs" ]
            , h1 [] [ text message ]
            -- , input [ placeholder "Search by whatever", onInput SetQuery ] []
            , Table.view config tableState acceptablePeople
            ]

fightColumn : Table.Column Log Msg
fightColumn = Table.stringColumn "Fight" .fight

recorded_byColumn : Table.Column Log Msg
recorded_byColumn = Table.stringColumn "Recorded By" .recorded_by

durationColumn : Table.Column Log Msg
durationColumn = Table.stringColumn "Duration" .duration

startColumn : Table.Column Log Msg
startColumn = Table.customColumn
            { name = "Start"
            , viewData = (\data -> case (.start data) of 
                            Ok t ->
                                case (List.head (String.split "T" (Iso8601.fromTime t))) of
                                    Just date ->
                                        date
                                    Nothing ->
                                        "Something went wrong!"
                            _ ->
                                "Error"
            )
            , sorter = Table.increasingOrDecreasingBy (\data -> case (.start data) of
                                            Ok t ->
                                                Time.toMillis Time.utc t 
                                            _ ->
                                                Time.toMillis Time.utc (Time.millisToPosix 0)
            )
            } 

is_cmColumn : Table.Column Log Msg
is_cmColumn = Table.customColumn
            { name = "CM?"
            , viewData = (\data -> case (.is_cm data) of
                            True -> "CM!"
                            False -> "Normal"
            )
            , sorter = Table.increasingOrDecreasingBy (\data -> case (.is_cm data) of
                                                        True -> 0
                                                        False -> 1
            )
            }

is_winColumn : Table.Column Log Msg
is_winColumn = Table.customColumn
            { name = "Success?"
            , viewData = (\data -> case (.is_win data) of
                            True -> "Success!"
                            False -> "Failure!"
            )
            , sorter = Table.increasingOrDecreasingBy (\data -> case (.is_win data) of
                                                        True -> 0
                                                        False -> 1
            )
            }

checkboxColumn : Table.Column Log Msg
checkboxColumn = 
    Table.veryCustomColumn
    { name = ""
    , viewData = viewCheckbox
    , sorter = Table.unsortable
    }

viewCheckbox : Log -> Table.HtmlDetails Msg
viewCheckbox {selected} = 
    Table.HtmlDetails []
    [ input [ type_ "checkbox", checked selected ] []
    ]

config : Table.Config Log Msg
config =
  Table.customConfig
    { toId = .identifier
    , toMsg = SetTableState
    , columns =
        [ checkboxColumn
        , fightColumn
        , is_cmColumn
        , is_winColumn
        , startColumn
        , durationColumn
        ]
    , customizations =
        { defaultCustomizations | rowAttrs = toRowAttrs }
    }

toRowAttrs : Log -> List (Attribute Msg)
toRowAttrs log =
    [ onClick (ToggleSelected log.identifier)
    , style "background" (if log.selected then "#CEFAF8" else "white")
    ]
