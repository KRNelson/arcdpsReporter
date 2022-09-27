module Upload exposing (..)

import Browser

import File exposing (File)
import File.Select as Select

import Html exposing (Html, button, div, text, form, input, iframe, p, span)
import Html.Attributes exposing (attribute, class, style, type_, value, hidden)
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
  { files : List File
  , result : Maybe (Result Http.Error (String))
  }

default : Model
default = Model [] Nothing

init : () -> (Model, Cmd Msg)
init _ =
  ( default , Cmd.none )

-- UPDATE
type Msg
  = LogRequested
  | LogLoaded File (List File)
  | LogUpload
  | LogUploaded (Result Http.Error (String))
  | RemoveFile String

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    LogRequested ->
      ( model
      , Select.files ["application/zevtc"] LogLoaded
      )

    LogLoaded file files ->
      ( {model | files = file :: (files ++ model.files)}, Cmd.none)

    LogUpload -> 
      (model
      , Http.request
        { method = "POST"
        , headers = []
        , url = "http://localhost:3000/upload"
        , body = Http.multipartBody ((List.map (\f -> Http.filePart "logs" f) model.files))
        , expect = Http.expectJson LogUploaded (Decode.field "message" Decode.string)
        , timeout = Nothing
        , tracker = Nothing
        }
      )

    LogUploaded result ->
      ({model | result = Just result}, Cmd.none)
  
{-
      case result of
          Ok message ->
            ({model | log = Just message}, Cmd.none)
          Err error ->
            case error of
                Http.BadUrl url ->
                  ({model | log = Just ("BadUrl: " ++ url)}, Cmd.none)
                Http.Timeout ->
                  ({model | log = Just "Timeout"}, Cmd.none)
                Http.NetworkError ->
                  ({model | log = Just "NetworkError"}, Cmd.none)
                Http.BadStatus _ -> 
                  ({model | log = Just "BadStatus"}, Cmd.none)
                Http.BadBody body -> 
                  ({model | log = Just ("BadBody: " ++ body)}, Cmd.none)
-}

    RemoveFile filename ->
      ({model | files = List.filter(\file -> File.name file /= filename) model.files }, Cmd.none )

-- VIEW

viewFileSelected : String -> Html Msg
viewFileSelected filename = 
  div [ class "alert alert-success alert-dismissible fade show w-50" 
      , attribute "role" "alert"
      ]
    [ text filename
    , button [type_ "button"
             , class "btn close"
             , attribute "data-dismiss" "alert"
             , attribute "aria-label" "Close"
             , onClick <| RemoveFile filename
             ]
        [ span [attribute "aria-hidden" "true"] [ text "x" ]
        ]
    ]

viewForm : Html Msg
viewForm = 
  form []
    [ input [type_ "button", onClick LogRequested, value "Load Log"] []
    ]

viewUpload : Bool -> Html Msg
viewUpload hide =
  div [ hidden hide ]
    [ button [type_ "button", onClick LogUpload ] [ text "Upload!"]
    ]

viewContent : String -> Html Msg
viewContent content =
  p [style "white-space" "pre" ] [ text content ]

view : Model -> Html Msg
view model =
  case model.result of
    Nothing ->
        div []
        [ viewForm 
        , div [class ""] <| List.map (\file -> viewFileSelected <| File.name file) model.files
        , viewUpload <| List.isEmpty model.files
        ]

    Just result ->
      case result of
        Ok message ->
          div []
          [ viewContent message
          , viewForm
          ]
        Err _ ->
          div []
          [ viewContent "Error"
          , viewForm
          ]

-- SUBSCRIPTIONS
subscriptions : Model -> Sub Msg
subscriptions _ =
  Sub.none