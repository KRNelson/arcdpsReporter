module Rotations exposing (..)

import Browser
import Html exposing (Html, div, h1, input, text, button)
import Html.Attributes exposing (placeholder)
import Html.Events exposing (onInput, onClick)
import Table

import Logs exposing (..)
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (required, hardcoded)

import Http

import Iso8601
import Time
import Parser

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
  { rotations : List Rotation
  , tableState : Table.State
  , query : String
  , message : String
  }

default : Model
default = 
      { rotations = []
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
    ( model, getRotations )



-- UPDATE


type Msg
  = SetQuery String
  | SetTableState Table.State
  | GetRotations
  | GotRotations (Result Http.Error (List Rotation))

rotationsDecoder : Decode.Decoder (List Rotation)
rotationsDecoder =
  (Decode.at ["data"] (
    Decode.list (
      rotationDecoder
        )))

decodeTime : Decode.Decoder (Result (List Parser.DeadEnd) Time.Posix)
decodeTime = 
    Decode.string
        |> Decode.andThen (\time ->
            Decode.succeed (Iso8601.toTime time)
        )

rotationDecoder : Decode.Decoder Rotation
rotationDecoder = 
    Decode.succeed Rotation
        |> required "identifier" Decode.string
        |> required "fight" Decode.string
        |> required "fight_icon" Decode.string
        |> required "start" decodeTime 
        |> required "account" Decode.string
        |> required "character" Decode.string
        |> required "profession" Decode.string
        |> required "skill_id" Decode.string
        |> required "cast" Decode.int
        |> required "duration" Decode.int

getRotations : Cmd Msg
getRotations =
    Http.get
        { url = "http://localhost:8080/api/rotations"
        , expect = Http.expectJson GotRotations rotationsDecoder
        }

getRotationsFromLogs : List Logs.Log  -> Cmd Msg
getRotationsFromLogs logs =
  Http.request
    { method = "POST"
    , headers = []
    , url = "http://localhost:8080/api/rotations"
    , body = Http.multipartBody (List.map (\log -> (Http.stringPart "id") log.identifier) logs)
    , expect = Http.expectJson GotRotations rotationsDecoder
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

    GetRotations ->
      ( model, getRotations )

    GotRotations result ->
      case result of
        Ok rotations ->
          ({model | rotations = rotations, message = "Ok!"}, Cmd.none)
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
view { rotations, tableState } =
  div []
    [ Table.view config tableState rotations
    ]

config : Table.Config Rotation Msg
config =
  Table.config
    { toId = (\model -> model.identifier ++ model.account ++ model.skill_id ++ String.fromInt model.cast)
    , toMsg = SetTableState
    , columns =
        [ Table.stringColumn "Account" .account
        , Table.stringColumn "Skill" .skill_id
        , Table.intColumn "Cast" .cast
        ]
    }



-- PLAYER
type alias Rotation =
    { identifier : String
    , fight : String
    , fight_icon : String
    , start : Result (List Parser.DeadEnd) Time.Posix
    , account : String
    , character : String
    , profession : String
    , skill_id : String
    , cast : Int
    , duration : Int 
    }
