module Rotations exposing (..)

import Browser
import Html exposing (Html, div, h1, input, text, button)
import Html.Attributes exposing (placeholder)
import Html.Events exposing (onInput, onClick)
import Table
import Dict exposing (Dict)

import Logs exposing (..)
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (required, hardcoded)

import Http

import Iso8601
import Time
import Parser
import Html exposing (a)
import Html exposing (b)

main =
  -- Html.program
  Browser.element
    { init = init
    , update = update
    , view = view
    , subscriptions = \_ -> Sub.none
    }



-- MODEL
type Note = A
          | B
          | C
          | D
          | E
          | F
          | G

type Duration = Sixteenth
              | Eighth
              | Quarter
              | Half
              | Whole


type alias Model =
  { rotations : List Rotation
  , skillMap : Dict String (Note, List Duration)
  , tableState : Table.State
  , skillMapTableState : Table.State
  , query : String
  , message : String
  }

default : Model
default = 
      { rotations = []
      , skillMap = Dict.empty
      , tableState = Table.initialSort "Account"
      , skillMapTableState = Table.initialSort "Skill"
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
  | SetSkillMapTableState Table.State
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
        { url = "/api/rotations"
        , expect = Http.expectJson GotRotations rotationsDecoder
        }

getRotationsFromLogs : List Logs.Log  -> Cmd Msg
getRotationsFromLogs logs =
  Http.request
    { method = "POST"
    , headers = []
    , url = "/api/rotations"
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

    SetSkillMapTableState newState ->
      ( { model | skillMapTableState = newState }
      , Cmd.none
      )

    GetRotations ->
      ( model, getRotations )

    GotRotations result ->
      case result of
        Ok rotations ->
          let
            frotations = List.filter (\rotation -> rotation.account == "Account 1") rotations
          in
            ({model | rotations = frotations, skillMap = generateSkillMap frotations , message = "Ok!"}, Cmd.none)
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

generateSkillMap : List Rotation -> Dict String (Note, List Duration)
-- generateSkillMap _ = Dict.empty
generateSkillMap rotation = 
  let
    reduceRotationToNumbers skill skillMap =
      Dict.update skill.skill_id (\mNote -> case mNote of
                                    Just (duration, count) -> Just (duration + toFloat skill.duration, count + 1)
                                    Nothing -> Just (toFloat skill.duration, 1)
          ) skillMap
    createSkillMap skillMap =
      List.map (\(id, (duration, count))-> if duration / count <= 64 then
                                            (id, (A, [Sixteenth]))
                                           else if duration / count <= 125 then
                                            (id, (B, [Eighth]))
                                           else if duration / count <= 250 then
                                            (id, (D, [Quarter]))
                                           else if duration / count <= 500 then
                                            (id, (E, [Half]))
                                           else 
                                            (id, (C, [Whole]))
      ) (Dict.toList skillMap)
  in
    Dict.fromList (createSkillMap (List.foldr reduceRotationToNumbers Dict.empty rotation))

-- VIEW
view : Model -> Html Msg
view { rotations, tableState, skillMapTableState, skillMap } =
  div []
    [ Table.view skillMapConfig skillMapTableState (Dict.toList skillMap)
    -- , text ("account1 = " ++ (List.foldl (\(_, skill_id) string -> string ++ skill_id ++ "|>") "" (List.sort (List.map (\rotation -> (rotation.cast, rotation.skill_id)) rotations))))
    , text ("account1 = " ++ String.join "|>" (List.map (\(_, skill_id) -> skill_id) (List.sort (List.map (\rotation -> (rotation.cast, rotation.skill_id)) rotations))))
    , Table.view config tableState rotations
    ]
    
skillMapConfig : Table.Config (String, (Note, List Duration)) Msg
skillMapConfig =
  Table.config
    { toId = Tuple.first -- toId = (\model -> model.identifier ++ model.account ++ model.skill_id ++ String.fromInt model.cast)
    , toMsg = SetSkillMapTableState
    , columns =
        [ 
        -- Table.stringColumn "Skill" Tuple.first
        -- , Table.intColumn "Cast" .cast
        -- , noteColumn 
        -- , durationColumn
        skillRenderColumn
        ]
    }
  
noteColumn : Table.Column (String, (Note, List Duration)) Msg
noteColumn = Table.customColumn
            { name = "Note"
            , viewData = (\(_, (note, _)) -> case note of 
                                              A -> "A"
                                              B -> "B"
                                              C -> "C"
                                              D -> "D"
                                              E -> "E"
                                              F -> "F"
                                              G -> "G"

            )
            , sorter = Table.unsortable
            } 

durationColumn : Table.Column (String, (Note, List Duration)) Msg
durationColumn = Table.customColumn
            { name = "Duration"
            , viewData = (\(_, (_, duration)) -> case Maybe.withDefault Whole (List.head duration) of 
                                              Sixteenth -> "Sixteenth"
                                              Eighth -> "Eighth"
                                              Quarter -> "Quarter"
                                              Half -> "Half"
                                              Whole -> "Whole"
            )
            , sorter = Table.unsortable
            } 

skillRenderColumn : Table.Column (String, (Note, List Duration)) Msg
skillRenderColumn = Table.customColumn
            { name = "Haskell"
            , viewData = (\(skill_id, (note, duration)) -> 
              let
                hduration = case Maybe.withDefault Whole (List.head duration) of 
                  Sixteenth -> "|*(1/16)"
                  Eighth -> "|*(1/8)"
                  Quarter -> "|*(1/4)"
                  Half -> "|*(1/2)"
                  Whole -> ""
                hnote = case note of 
                  A -> "a"
                  B -> "b"
                  C -> "c"
                  D -> "d"
                  E -> "e"
                  F -> "f"
                  G -> "g"
              in
               skill_id ++ " = " ++ hnote ++ hduration 
            )
            , sorter = Table.unsortable
            } 

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

subscriptions : Model -> Sub Msg
subscriptions _ = Sub.none