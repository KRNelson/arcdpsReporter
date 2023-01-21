module Upload exposing (..)

import Browser

import File exposing (File)
import File.Select as Select
import Bootstrap.Alert as Alert
import Bootstrap.Form as Form
import Bootstrap.Button as Button
import Bootstrap.CDN as CDN
import Bootstrap.Spinner as Spinner
import Bootstrap.Text as Text

import Html exposing (Html, button, div, text, form, input, iframe, p, span)
import Html.Attributes exposing (attribute, class, style, type_, value, hidden, disabled)
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

type alias Visible = Alert.Visibility

type UploadStatus
  = Selecting
  | Selected
  | Uploading
  | Uploaded

-- MODEL
type alias Model =
  { files : List (File, Visible)
  , result : Maybe (Result Http.Error (String))
  , upload : Maybe UploadStatus
  , alertErrorVisibility : Visible
  , alertSuccessVisibility : Visible
  }

default : Model
default = Model [] Nothing Nothing Alert.closed Alert.closed

init : () -> (Model, Cmd Msg)
init _ =
  ( default , Cmd.none )

visibleFiles : List (File, Visible) -> List (File, Visible)
visibleFiles =
  List.filter (\f -> Tuple.second f == Alert.shown)

-- UPDATE
type Msg
  = LogRequested
  | LogLoaded File (List File)
  | LogUpload
  | LogUploaded (Result Http.Error (String))
  | AlertFileMsg File Alert.Visibility
  | AlertSuccessMsg Alert.Visibility
  | AlertErrorMsg Alert.Visibility

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    LogRequested ->
      ( {model | result = Nothing, upload = Just Selecting}
      , Select.files ["application/zevtc"] LogLoaded
      )

    LogLoaded file files ->
      ( {model | files = (file, Alert.shown) :: (List.map (\f -> (f, Alert.shown)) files ++ model.files), upload = Just Selected}, Cmd.none)

    LogUpload -> 
      ({model | upload = Just Uploading}
      , Http.request
        { method = "POST"
        , headers = []
        , url = "http://localhost:8080/api/upload"
        , body = Http.multipartBody <| List.map (Tuple.first>>(Http.filePart "logs"))  <| visibleFiles model.files
        , expect = Http.expectJson LogUploaded (Decode.field "message" Decode.string)
        , timeout = Nothing
        , tracker = Nothing
        }
      )

    LogUploaded result ->
      case result of
          Ok _ -> 
            ({model | result = Just result, alertSuccessVisibility = Alert.shown, upload = Just Uploaded, files = []}, Cmd.none)
          Err _ ->
            ({model | result = Just result, alertErrorVisibility = Alert.shown, upload = Nothing, files = []}, Cmd.none)
  
    AlertFileMsg file visibility ->
        ({model | files = List.map(\f -> if File.name (Tuple.first f) == File.name file then ((Tuple.first f), visibility) else f) model.files }, Cmd.none )

    AlertSuccessMsg visibility -> 
      ({model | alertSuccessVisibility = visibility }, Cmd.none )

    AlertErrorMsg visibility -> 
      ({model | alertErrorVisibility = visibility }, Cmd.none )

-- VIEW
viewFileSelected : (File, Visible) -> Html Msg
viewFileSelected (file, visible) = 
  Alert.config
    |> Alert.dismissableWithAnimation (AlertFileMsg file)
    |> Alert.info
    |> Alert.children
      [ p [] [ text <| File.name file]
      ]
    |> Alert.view visible

viewFileUploading : (File, Visible) -> Html Msg
viewFileUploading (file, visible) = 
  let
    loading = Spinner.spinner [Spinner.small, Spinner.color Text.info] [ Spinner.srMessage "Uploading..."]
  in
    Alert.config
      |> Alert.dismissableWithAnimation (AlertFileMsg file)
      |> Alert.info
      |> Alert.children
        [ p [] [ loading, text (File.name file)]
        ]
      |> Alert.view visible


viewForm : Html Msg
viewForm = 
  Form.form []
    [ Button.button [ Button.primary, Button.onClick LogRequested ] [ text "Load Log" ]
    ]

viewUpload : Bool -> Html Msg
viewUpload disable =
  Form.form [ ]
    [ Button.button [ Button.secondary, Button.onClick LogUpload, Button.attrs [disabled disable]] [ text "Upload!" ]
    ]

viewSuccess : Visible -> String -> Html Msg
viewSuccess visible content =
  Alert.config
    |> Alert.dismissableWithAnimation AlertSuccessMsg
    |> Alert.success
    |> Alert.children
      [ p [] [ text content]
      ]
    |> Alert.view visible

viewError : Visible -> String -> Html Msg
viewError visible content =
  Alert.config
    |> Alert.dismissableWithAnimation AlertErrorMsg
    |> Alert.warning
    |> Alert.children
      [ p [] [ text content]
      ]
    |> Alert.view visible

view : Model -> Html Msg
view model =
  case model.result of
    Nothing ->
      case model.upload of
          Just uploadStatus ->
            case uploadStatus of
              Uploading ->
                div []
                [ CDN.stylesheet
                , viewForm 
                , viewUpload True
                , div [class ""] <| List.map viewFileUploading model.files
                ]
              _ ->
                div []
                [ CDN.stylesheet
                , viewForm 
                , viewUpload <| List.isEmpty <| visibleFiles model.files
                , div [class ""] <| List.map viewFileSelected model.files
                ]

          Nothing ->
            div []
            [ CDN.stylesheet
            , viewForm 
            , viewUpload <| List.isEmpty <| visibleFiles model.files
            , div [class ""] <| List.map viewFileSelected model.files
            ]

    Just result ->
      case result of
        Ok message ->
          div []
          [ CDN.stylesheet
          , viewSuccess model.alertSuccessVisibility message
          , viewForm
          , viewUpload True
          ]
        Err _ ->
          div []
          [ CDN.stylesheet
          , viewError model.alertSuccessVisibility "Error"
          , viewForm
          , viewUpload True
          ]

-- SUBSCRIPTIONS
subscriptions : Model -> Sub Msg
subscriptions { files, alertSuccessVisibility, alertErrorVisibility} =
  Sub.batch (List.concat [List.map (\f -> Alert.subscriptions (Tuple.second f) (AlertFileMsg (Tuple.first f))) files, [ Alert.subscriptions alertSuccessVisibility AlertSuccessMsg ], [ Alert.subscriptions alertErrorVisibility AlertErrorMsg ]])