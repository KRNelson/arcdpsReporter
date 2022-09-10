module Upload exposing (..)

import Browser
import Html exposing (Html, button, div, text, form, input, iframe)
import Html.Events exposing (onClick)

import File exposing (File)
import File.Select as Select
import Html exposing (Html, button, p, text)
import Html.Attributes exposing (style, type_, action, method, enctype, name, multiple, required, value)
import Html.Events exposing (onClick)
-- import Task
import Json.Decode as Decode
import Http


-- MAIN
main : Program () Model Msg
main =
  Browser.element
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }

-- MODEL
type alias Model =
  { log : Maybe String
  , files : List File
  }

init : () -> (Model, Cmd Msg)
init _ =
  ( Model Nothing [], Cmd.none )

-- UPDATE
type Msg
  = LogRequested
  -- | LogSelected File
  | LogLoaded File (List File)
  | LogUploaded (Result Http.Error (String))

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    LogRequested ->
      ( model
      , Select.files ["application/zevtc"] LogLoaded -- LogSelected
      )

    LogLoaded file files ->
      ( model
      , Http.request
        { method = "POST"
        , headers = []
        , url = "http://localhost:3000/upload"
        , body = Http.multipartBody (Http.filePart "logs" file :: (List.map (\f -> Http.filePart "logs" f) files))
        , expect = Http.expectJson LogUploaded (Decode.field "message" Decode.string)
        , timeout = Nothing
        , tracker = Nothing
        }
      )

    LogUploaded result ->
      case result of
          Ok message ->
            ({model | log = Just message}, Cmd.none)
          Err error ->
            case error of
                Http.BadUrl url ->
                  ({model | log = Just url}, Cmd.none)
                Http.Timeout ->
                  ({model | log = Just "Timeout"}, Cmd.none)
                Http.NetworkError ->
                  ({model | log = Just "NetworkError"}, Cmd.none)
                Http.BadStatus _ -> 
                  ({model | log = Just "BadStatus"}, Cmd.none)
                Http.BadBody body -> 
                  ({model | log = Just body}, Cmd.none)

-- VIEW
view : Model -> Html Msg
view model =
  case model.log of
    Nothing ->
      form []
      [
        input [ type_ "button", onClick LogRequested, value "Load Log" ] []
      ]

    Just content ->
      p [ style "white-space" "pre" ] [ text content ]

-- SUBSCRIPTIONS
subscriptions : Model -> Sub Msg
subscriptions _ =
  Sub.none