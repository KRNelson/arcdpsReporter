module Players exposing (..)

import Browser
import Html exposing (Html, div, h1, input, text, button)
import Html.Attributes exposing (placeholder)
import Html.Events exposing (onInput, onClick)
import Table

import Json.Decode as Decode
import Http

import Logs exposing (..)

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
  { players : List Player
  , tableState : Table.State
  , query : String
  , message : String
  }

default : Model
default = 
      { players = []
      , tableState = Table.initialSort "Account"
      , query = ""
      , message = ""
      }


init : () -> ( Model, Cmd Msg )
init _ =
  let
    model =
      default
  in
    ( model, Cmd.none )



-- UPDATE


type Msg
  = SetQuery String
  | SetTableState Table.State
  | GetPlayers
  | GotPlayers (Result Http.Error (List Player))

playerDecoder : Decode.Decoder (List Player)
playerDecoder =
  (Decode.at ["data"] (Decode.list (Decode.map Player (Decode.at ["account"] Decode.string))))

getPlayers : Cmd Msg
getPlayers =
    Http.get
        { url = "http://localhost:3000/players"
        , expect = Http.expectJson GotPlayers playerDecoder
        }

getPlayersFromLogs : List Logs.Log  -> Cmd Msg
getPlayersFromLogs logs =
  Http.request
    { method = "POST"
    , headers = []
    , url = "http://localhost:3000/players"
    , body = Http.multipartBody (List.map (\log -> (Http.stringPart "id") log.identifier) logs)
    , expect = Http.expectJson GotPlayers playerDecoder
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

    GetPlayers ->
      ( model, getPlayers )

    GotPlayers result ->
      case result of
        Ok players ->
          ({model | players = players, message = "Ok!"}, Cmd.none)
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
view { players, tableState, query, message } =
  let
    lowerQuery =
      String.toLower query
    acceptablePeople =
      List.filter (String.contains lowerQuery << String.toLower << .account) players
  in
    div []
      [ h1 [] [ text "Player Accounts" ]
      , input [ placeholder "Search by Account", onInput SetQuery ] []
      , Table.view config tableState acceptablePeople
      ]


config : Table.Config Player Msg
config =
  Table.config
    { toId = .account
    , toMsg = SetTableState
    , columns =
        [ Table.stringColumn "Account" .account
        ]
    }



-- PLAYER
type alias Player =
  { account : String
  }