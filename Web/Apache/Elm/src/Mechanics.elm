module Mechanics exposing (Model, main, default, init, Msg, getMechanicsFromLogs, update, view, subscriptions)

import Browser
import Html exposing (Html, div, h1, input, text, button, p)
import Html.Attributes exposing (placeholder, style)
import Html.Events exposing (onInput, onClick)
import Table
import Dict exposing (Dict)
import Set exposing(Set)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (required, hardcoded)

import Http

import Iso8601
import Time
import Parser

import Logs exposing (..)

import Chart as C
import Chart.Attributes as CA
import Chart.Events as CE
import Chart.Item as CI
import Chart.Svg as CS

main =
  Browser.element
    { init = init
    , update = update
    , view = view
    , subscriptions = subscriptions
    }

-- MODEL
type alias Mechanic =
    { identifier : String
    , fight : String
    , fight_icon : String
    , start : Result (List Parser.DeadEnd) Time.Posix
    , account : String
    , character : String
    , profession : String
    , mechanic : String
    , description : String
    , total : Int 
    }

type alias Identifier = String

type alias AccountDetails = {account : String, character : String, profession : String}
type alias MechanicDetail = {mechanic : String, description : String}
type alias MechanicStats =
  { mechanic : String
  , description : String
  , playerStats : Dict String {account : AccountDetails, total : Int}
  }
type alias PlayerStats = 
  { account : String
  , character : String
  , profession : String
  , mechanicStats : Dict String {mechanic : MechanicDetail, total : Int}
  }

type alias Mechanics = 
  { identifier : Identifier
    , fight : String
    , fight_icon : String
    , start : Result (List Parser.DeadEnd) Time.Posix

    , player_stats : Dict String PlayerStats
    , player_stats_state : Table.State
    , mechanics_stats : Dict String MechanicStats
    }



type State = Loading 
           | Loaded

type alias Model =
  { mechanics : List Mechanics
  , tableState : Table.State
  , newTableState : Table.State
  , query : String
  , message : String
  , state : State
  }

default : Model
default = 
      { mechanics = []
      , tableState = Table.initialSort "Account"
      , newTableState = Table.initialSort "Start"
      , query = ""
      , message = ""
      , state = Loading
      }


init : () -> ( Model, Cmd Msg )
init _ =
  let
    model = default
  in
    ( model, getMechanics )

type Msg
  = SetQuery String
  | SetTableState Table.State
  | SetNewDetailsTableState String Table.State
  | SetNewTableState Table.State
  | GetMechanics
  | GotMechanics (Result Http.Error (List Mechanic))

mechanicsDecoder : Decode.Decoder (List Mechanic)
mechanicsDecoder =
  (Decode.at ["data"] (
    Decode.list (
      mechanicDecoder
        )))

mechanicDecoder : Decode.Decoder Mechanic
mechanicDecoder = 
    Decode.succeed Mechanic
        |> required "identifier" Decode.string
        |> required "fight" Decode.string
        |> required "fight_icon" Decode.string
        |> required "start" decodeTime 
        |> required "account" Decode.string
        |> required "character" Decode.string
        |> required "profession" Decode.string
        |> required "mechanic" Decode.string
        |> required "description" Decode.string
        |> required "total" Decode.int

decodeTime : Decode.Decoder (Result (List Parser.DeadEnd) Time.Posix)
decodeTime = 
    Decode.string
        |> Decode.andThen (\time ->
            Decode.succeed (Iso8601.toTime time)
        )

getMechanics : Cmd Msg
getMechanics =
    Http.get
        { url = "/api/mechanics"
        , expect = Http.expectJson GotMechanics mechanicsDecoder
        }

getMechanicsFromLogs : List Logs.Log  -> Cmd Msg
getMechanicsFromLogs logs =
  Http.request
    { method = "POST"
    , headers = []
    , url = "/api/mechanics"
    , body = Http.multipartBody (List.map (\log -> (Http.stringPart "id") log.identifier) logs)
    , expect = Http.expectJson GotMechanics mechanicsDecoder
    , timeout = Nothing
    , tracker = Nothing
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

    SetNewDetailsTableState identifier newState ->
      ( { model | mechanics = List.map (\m -> if (m.identifier == identifier) then {m | player_stats_state = newState} else m) model.mechanics}
      , Cmd.none
      )

    SetNewTableState newState ->
      ( { model | newTableState = newState }
      , Cmd.none
      )

    GetMechanics ->
      ( model, getMechanics )

    GotMechanics result ->
      case result of
        Ok mechanics ->
          ({model | mechanics = (collapseMechanics mechanics), state = Loaded}, Cmd.none)
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

-- VIEW
view : Model -> Html Msg
view { mechanics, tableState, newTableState, query, message, state } =
  case state of
    Loading ->
      div []
          [
              h1 [] [text "Player Mechanics"]
              , text "loading..."
              , text message
          ]
    Loaded ->
      div []
          [ h1 [] [ text "Player Mechanics" ]
          -- , input [ placeholder "Search by Account", onInput SetQuery ] []
          -- , Table.view config tableState acceptablePeople
          , Table.view newConfig newTableState mechanics
          ]

updatePlayerStats : Mechanic -> Maybe PlayerStats -> Maybe PlayerStats
updatePlayerStats mechanic maybe_player_stat = 
  case maybe_player_stat of
      -- First entry
      Nothing -> Just (PlayerStats mechanic.account mechanic.character mechanic.profession (Dict.singleton mechanic.mechanic {mechanic = (MechanicDetail mechanic.mechanic mechanic.description), total = mechanic.total}))
      -- Update current entry
      Just player_stat -> Just ({player_stat | 
          mechanicStats = (Dict.update mechanic.mechanic (\m_mechanicStats ->
            case m_mechanicStats of
                -- First entry
                Nothing -> Just {mechanic = (MechanicDetail mechanic.mechanic mechanic.description), total = mechanic.total}
                -- Update curren entry
                Just mechanicStats -> Just {mechanicStats | total = mechanic.total + mechanicStats.total}
          ) player_stat.mechanicStats)
        })

updateMechanicStats : Mechanic -> Maybe MechanicStats -> Maybe MechanicStats
updateMechanicStats mechanic maybe_mechanic_stat = maybe_mechanic_stat

updateMechanic : Mechanic -> Maybe Mechanics -> Maybe Mechanics
updateMechanic mechanic maybe_mechanics = 
  case maybe_mechanics of
      -- First entry for a new log. 
      Nothing -> Just (Mechanics mechanic.identifier mechanic.fight mechanic.fight_icon mechanic.start
        (Dict.singleton mechanic.account 
          (PlayerStats 
            mechanic.account mechanic.character mechanic.profession 
            (Dict.singleton mechanic.mechanic {mechanic = {mechanic = mechanic.mechanic, description = mechanic.description}, total = mechanic.total})))
        (Table.initialSort "Character")
        (Dict.singleton mechanic.mechanic 
          (MechanicStats 
            mechanic.mechanic mechanic.description 
            (Dict.singleton mechanic.account {account = {account = mechanic.account, character = mechanic.character, profession = mechanic.profession}, total = mechanic.total}))))
      -- Updating the details inside a current log. 
      Just mechanics -> Just ({
        mechanics 
        | player_stats = 
            Dict.update mechanic.account (updatePlayerStats mechanic) mechanics.player_stats
        , mechanics_stats = 
            Dict.update mechanic.mechanic (updateMechanicStats mechanic) mechanics.mechanics_stats
        })

collapseMechanics : List Mechanic -> List Mechanics
collapseMechanics mechanics = 
  List.map (\(fst, snd) -> snd) (Dict.toList (
    List.foldr (\mechanic -> \dict -> 
      Dict.update mechanic.identifier (updateMechanic mechanic) dict
    ) Dict.empty mechanics
  ))

config : Table.Config Mechanic Msg
config =
  Table.config
    { toId = .account
    , toMsg = SetTableState
    , columns =
        [ Table.stringColumn "Profession" .profession
        , Table.stringColumn "Mechanic" .mechanic
        , Table.stringColumn "Description" .description
        , Table.intColumn "Total" .total
        ]
    }

newConfig : Table.Config Mechanics Msg
newConfig = 
  Table.config
  { toId = .identifier
  , toMsg = SetNewTableState
  , columns = 
    [ fightColumn
    , startColumn
    , playerStatsColumn
    ]
  }

fightColumn : Table.Column Mechanics Msg
fightColumn = Table.customColumn
            { name = "Fight"
            , viewData = .fight
            , sorter = Table.unsortable
            } 


startColumn : Table.Column Mechanics Msg
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
            -- , sorter = Table.unsortable
            , sorter = Table.increasingBy (\data -> case (.start data) of
                                            Ok t -> Time.posixToMillis t
                                            _ -> Time.toMillis Time.utc (Time.millisToPosix 0))
            } 


playerStatsColumn : Table.Column Mechanics Msg
playerStatsColumn = Table.veryCustomColumn
          { name = ""
          , viewData = playerStatsTable
          , sorter = Table.unsortable
          }

playerStatsTable : Mechanics -> Table.HtmlDetails Msg
playerStatsTable mechanics = 
  let
    player_stats_list = Dict.values mechanics.player_stats
    -- Set.toList will sort. 
    mechanics_list = Set.toList (Set.fromList (List.concatMap (\p_stat -> Dict.keys p_stat.mechanicStats) (Dict.values mechanics.player_stats)))
    player_stats_columns = Table.stringColumn "Character" .character 
      :: Table.intColumn "Total" 
        (\data -> 
          case (Dict.get data.account mechanics.player_stats) of
              Nothing -> 0
              Just stat -> List.sum (List.map (\{total} -> total) (Dict.values stat.mechanicStats))
        )
      -- TODO: (1/21/2023) Change this from intColumn to customColumn that display's mechanic description onHover. 
      :: (List.map (\mechanic_name -> Table.intColumn mechanic_name 
        (\data -> 
          case (Dict.get data.account mechanics.player_stats) of
              Nothing -> 0
              Just stat -> 
                case (Dict.get mechanic_name stat.mechanicStats) of
                    Nothing -> 0 -- None. 
                    Just { total } -> total
        )
      ) mechanics_list)
  in
    Table.HtmlDetails [] [
      Table.view (Table.config { toId = .account
                               , toMsg = (SetNewDetailsTableState mechanics.identifier)
                               , columns = player_stats_columns
                               }) mechanics.player_stats_state player_stats_list
      ]

subscriptions : Model -> Sub Msg
subscriptions _ = Sub.none