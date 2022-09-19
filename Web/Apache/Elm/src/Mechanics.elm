module Mechanics exposing (..)

import Browser
import Html exposing (Html, div, h1, input, text, button)
import Html.Attributes exposing (placeholder)
import Html.Events exposing (onInput, onClick)
import Table

import Json.Decode as Decode
import Http

import Logs exposing (..)

main =
  Browser.element
    { init = init
    , update = update
    , view = view
    , subscriptions = \_ -> Sub.none
    }

-- MODEL
type alias Mechanic =
    { account : String
    , character : String
    , profession : String
    , mechanics : String
    , total : Int 
    , descriptions : String
    }

type State = Loading 
           | Loaded

type alias Model =
  { mechanics : List Mechanic
  , tableState : Table.State
  , query : String
  , message : String
  , state : State
  }

default : Model
default = 
      { mechanics = []
      , tableState = Table.initialSort "Account"
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
  | GetMechanics
  | GotMechanics (Result Http.Error (List Mechanic))

mechanicDecoder : Decode.Decoder (List Mechanic)
mechanicDecoder =
  (Decode.at ["data"] (
    Decode.list (
        Decode.map6 Mechanic
            (Decode.at ["account"] Decode.string)
            (Decode.at ["character"] Decode.string)
            (Decode.at ["profession"] Decode.string)
            (Decode.at ["mechanics"] Decode.string)
            (Decode.at ["total"] Decode.int)
            (Decode.at ["descriptive"] Decode.string)
        )))

getMechanics : Cmd Msg
getMechanics =
    Http.get
        { url = "http://localhost:3000/mechanics"
        , expect = Http.expectJson GotMechanics mechanicDecoder
        }

getMechanicsFromLogs : List Logs.Log  -> Cmd Msg
getMechanicsFromLogs logs =
  Http.request
    { method = "POST"
    , headers = []
    , url = "http://localhost:3000/mechanics"
    , body = Http.multipartBody (List.map (\log -> (Http.stringPart "id") log.identifier) logs)
    , expect = Http.expectJson GotMechanics mechanicDecoder
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

    GetMechanics ->
      ( model, getMechanics )

    GotMechanics result ->
      case result of
        Ok mechanics ->
          ({model | mechanics = mechanics, state = Loaded}, Cmd.none)
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
view { mechanics, tableState, query, message, state } =
  let
    lowerQuery =
      String.toLower query

    acceptablePeople =
      List.filter (String.contains lowerQuery << String.toLower << .account) mechanics
  in
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
            , input [ placeholder "Search by Account", onInput SetQuery ] []
            , Table.view config tableState acceptablePeople
            ]

config : Table.Config Mechanic Msg
config =
  Table.config
    { toId = .account
    , toMsg = SetTableState
    , columns =
        [ Table.stringColumn "Account" .account
        , Table.stringColumn "Character" .character
        , Table.stringColumn "Profession" .profession
        , Table.intColumn "Total" .total
        , Table.stringColumn "Description" .descriptions
        ]
    }
