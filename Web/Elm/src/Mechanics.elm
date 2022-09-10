module Mechanics exposing (..)

import Browser
import Html exposing (Html, div, h1, input, text, button)
import Html.Attributes exposing (placeholder)
import Html.Events exposing (onInput, onClick)
import Table

import Json.Decode as Decode
import Http

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

init : () -> ( Model, Cmd Msg )
init _ =
  let
    model =
      { mechanics = []
      , tableState = Table.initialSort "Account"
      , query = ""
      , message = ""
      , state = Loading
      }
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
            (Decode.at ["LOG_ACC_NA"] Decode.string)
            (Decode.at ["LOG_CHR_NA"] Decode.string)
            (Decode.at ["LOG_PRO_NA"] Decode.string)
            (Decode.at ["LOG_MCH_TE"] Decode.string)
            (Decode.at ["TOT_NR"] Decode.int)
            (Decode.at ["TOT_DSC_TE"] Decode.string)
        )))

getMechanics : Cmd Msg
getMechanics =
    Http.get
        { url = "http://localhost:3000/mechanics"
        , expect = Http.expectJson GotMechanics mechanicDecoder
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
                h1 [] [text "Player Accounts"]
                , text "loading..."
            ]
      Loaded ->
        div []
            [ h1 [] [ text "Player Accounts" ]
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
