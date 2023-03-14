module Logs exposing (..)

import Browser
import Html exposing (Html, Attribute, div, h1, input, text, span, img, br)
import Html.Attributes exposing (checked, style, type_, src, for, id, value, multiple, selected, class)
import Html.Events exposing (onClick)
import Table exposing (defaultCustomizations, State)
import DateRangePicker as Picker
import DateRangePicker.Range as Range
import Dict exposing (Dict)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (required, hardcoded)
import Http

import Iso8601
import Time
import Parser

import Bootstrap.Alert as Alert
import Bootstrap.Form as Form
import Bootstrap.Form.Checkbox as Checkbox
import Bootstrap.Form.Select as Select
import Bootstrap.Button as Button
import Bootstrap.CDN as CDN
import Bootstrap.Spinner as Spinner
import Bootstrap.Text as Text
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Row as Row
import Bootstrap.Grid.Col as Col

import Select
import Select exposing (Action(..))
import Css exposing (backgroundColor, color, ColorValue, rgb)
import Css.Global as Global
import Html.Styled as Styled
import Html.Styled.Attributes exposing (css)

main =
  Browser.element
    { init = init
    , update = update
    , view = view
    , subscriptions = subscriptions -- .pickerState >> Picker.subscriptions PickerChanged
    }

-- MODEL
type alias Log =
    { identifier : String
    , elite_version : String
    , trigger_id : Int 
    , ei_encounter_id : Int 
    , fight : String
    , fight_icon : String
    , arc_version : String
    , gw2_version : String
    , language : String
    , language_nr : Int
    , recorded_by : String
    , start : Result (List Parser.DeadEnd) Time.Posix
    , end : Result (List Parser.DeadEnd) Time.Posix
    , duration : String
    , duration_ms : Int
    , log_start_offset : Int
    , is_win : Bool
    , is_cm : Bool

    , selected : Bool
    , hidden : Bool
    }

type State = Loading 
           | Loaded

type alias Model =
  { logs : List Log
  , tableState : Table.State
  , pickerState : Picker.State
  , selectState : Select.State
  , selectCommanderState : Select.State
  , message : String
  , state : State
  , bosses : Dict String (String, Bool)
  , commanders : Dict String Bool
  , show_wins : Maybe Bool
  , show_cms : Maybe Bool
  }

default : Model
default = 
    let
      defaultConfig = Picker.defaultConfig
    in
      { logs = []
      , tableState = Table.initialSort "Start"
      , pickerState = Picker.init { defaultConfig | allowFuture = False, applyRangeImmediately = True, noRangeCaption = "Log date range", class = "dateRangePicker", inputClass = "", sticky = False} Nothing
      , selectState = Select.initState (Select.selectIdentifier "boss-select")
      , selectCommanderState = Select.initState (Select.selectIdentifier "commander-select")
      , message = ""
      , state = Loading
      , bosses = Dict.empty
      , commanders = Dict.empty
      , show_wins = Nothing
      , show_cms = Nothing
      }

init : () -> ( Model, Cmd Msg )
init _ =
  let
    model =
        default
  in
    ( model, Cmd.batch [getLogs, Picker.now PickerChanged model.pickerState] )

type Msg
  = SetTableState Table.State
  | PickerChanged Picker.State
  | GetLogs
  | GotLogs (Result Http.Error (List Log))
  | ToggleSelected String
  | ToggleWins (Maybe Bool)
  | ToggleCMs (Maybe Bool)
  | SelectMsg (Select.Msg String)
  | SelectCommanderMsg (Select.Msg String)
  | SelectAllBosses
  | DeselectAllBosses

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
        |> required "elite_version" Decode.string
        |> required "trigger_id" Decode.int
        |> required "ei_encounter_id" Decode.int
        |> required "fight" Decode.string
        |> required "fight_icon" Decode.string
        |> required "arc_version" Decode.string
        |> required "gw2_version" Decode.string
        |> required "language" Decode.string
        |> required "language_nr" Decode.int
        |> required "recorded_by" Decode.string
        |> required "start" decodeTime
        |> required "end" decodeTime
        |> required "duration" Decode.string
        |> required "duration_ms" Decode.int
        |> required "log_start_offset" Decode.int
        |> required "is_win" Decode.bool
        |> required "is_cm" Decode.bool
        |> hardcoded False -- "selected" Decode.bool
        |> hardcoded False -- "hidden" Decode.bool

getLogs : Cmd Msg
getLogs =
    Http.get
        { url = "/api/logs"
        , expect = Http.expectJson GotLogs logsDecoder
        }

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    SetTableState newState ->
      ( { model | tableState = newState}
      , Cmd.none
      )

    PickerChanged state ->
      ({model | pickerState = state}, Cmd.none)

    GetLogs ->
      ( model, getLogs )

    GotLogs result ->
      case result of
        Ok logs ->
          ({model | logs = logs, state = Loaded, bosses = List.foldr (\log -> Dict.update log.fight <| \m -> Just <| Maybe.withDefault (log.fight_icon, True) m) Dict.empty logs
                                                , commanders = List.foldr (\log -> Dict.update log.recorded_by <| \m -> Just <| Maybe.withDefault True m) Dict.empty logs}, Cmd.none)
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
    
    ToggleWins mblnWins ->
        ({model | show_wins = mblnWins}, Cmd.none)

    ToggleCMs mblnCMs ->
        ({model | show_cms = mblnCMs}, Cmd.none)

    SelectMsg selectMsg ->
        let
            (maybeAction, selectState, selectCmds) = 
                Select.update selectMsg model.selectState

            newModel =
                case maybeAction of 

                    Just (Select selectedBoss) ->
                        {model | bosses = List.foldr (\boss -> \dict -> Dict.update boss (Maybe.map (\(icon, _) -> (icon, True))) dict ) model.bosses (selectedBoss :: [])}

                    Just (SelectBatch selectedBosses) ->
                        {model | bosses = List.foldr (\boss -> \dict -> Dict.update boss (Maybe.map (\(icon, _) -> (icon, True))) dict ) model.bosses selectedBosses}

                    Just (Clear) -> 
                        {model | bosses = List.foldr (\boss -> \dict -> Dict.update boss (Maybe.map (\(icon, _) -> (icon, False))) dict ) model.bosses (Dict.keys model.bosses)}

                    Just (Deselect deselectedBosses) ->
                        {model | bosses = List.foldr (\boss -> \dict -> Dict.update boss (Maybe.map (\(icon, _) -> (icon, False))) dict ) model.bosses deselectedBosses}

                    Just (InputChange value) -> 
                        model

                    Just (FocusSet) ->
                        model

                    Nothing ->
                        model
        in
            ({newModel | selectState = selectState}, Cmd.map SelectMsg selectCmds)

    SelectCommanderMsg selectCommanderMsg ->
        let
            (maybeAction, selectState, selectCmds) = 
                Select.update selectCommanderMsg model.selectCommanderState

            newModel =
                case maybeAction of 

                    Just (Select selectedCommander) ->
                        {model | commanders = List.foldr (\boss -> \dict -> Dict.update boss (Maybe.map (\_ -> True)) dict ) model.commanders (selectedCommander :: [])}

                    Just (SelectBatch selectedCommanders) ->
                        {model | commanders = List.foldr (\boss -> \dict -> Dict.update boss (Maybe.map (\_ -> True)) dict ) model.commanders selectedCommanders}

                    Just (Clear) -> 
                        {model | commanders = List.foldr (\boss -> \dict -> Dict.update boss (Maybe.map (\_ -> False)) dict ) model.commanders (Dict.keys model.commanders)}

                    Just (Deselect deselectedCommanders) ->
                        {model | commanders = List.foldr (\boss -> \dict -> Dict.update boss (Maybe.map (\_ -> False)) dict ) model.commanders deselectedCommanders}

                    Just (InputChange value) -> 
                        model

                    Just (FocusSet) ->
                        model

                    Nothing ->
                        model
        in
            ({newModel | selectCommanderState = selectState}, Cmd.map SelectMsg selectCmds)


    SelectAllBosses -> 
      ({model | bosses = List.foldr (\boss -> \dict -> Dict.update boss (Maybe.map (\(icon, _) -> (icon, True))) dict ) model.bosses (Dict.keys model.bosses)}, Cmd.none)

    DeselectAllBosses ->
      ({model | bosses = List.foldr (\boss -> \dict -> Dict.update boss (Maybe.map (\(icon, _) -> (icon, False))) dict ) model.bosses (Dict.keys model.bosses)}, Cmd.none)


toggle : String -> Log -> Log
toggle identifier log =
    if log.identifier == identifier then
        { log | selected = not log.selected}
    else
        log

viewToggleButton : String -> (Maybe Bool -> Msg) -> Maybe Bool -> Html Msg
viewToggleButton strButtonName msg mblnToggle = 
  case mblnToggle of
      Nothing -> 
        Form.form [ class "custom-switch" ] [ 
          Checkbox.advancedCustom [ Checkbox.id ("all_"++strButtonName), Checkbox.checked True,  Checkbox.onCheck (\checked -> if(checked) then (msg Nothing) else (msg (Just True)))] (Checkbox.label [ for ("all_"++strButtonName) ] [ text "Show All" ])
          , Checkbox.advancedCustom [ Checkbox.id ("only_"++strButtonName), Checkbox.disabled True ] (Checkbox.label [ for ("only_"++strButtonName) ] [ span [style "text-decoration" "line-through"] [text <| "Show " ++ strButtonName]])
        ]
      Just blnToggle ->
        if (blnToggle) then
          -- div [] [ text (strButtonName ++ "_True") ]
          Form.form [class "custom-switch"] [ 
            Checkbox.advancedCustom [ Checkbox.id ("all_"++strButtonName), Checkbox.checked False,  Checkbox.onCheck (\checked -> if(checked) then (msg Nothing) else (msg (Just True)))] (Checkbox.label [ for ("all_"++strButtonName) ] [ span [ style "text-decoration" "line-through"] [text "Show All"]])
            , Checkbox.advancedCustom [ Checkbox.id ("only_"++strButtonName), Checkbox.checked True,  Checkbox.onCheck (\checked -> (msg (Just checked)))] (Checkbox.label [ for ("only_"++strButtonName) ] [ text <| "Show " ++ strButtonName])
          ]
        else
          -- div [] [ text (strButtonName ++"_False")]
          Form.form [class "custom-switch"] [ 
            Checkbox.advancedCustom [ Checkbox.id ("all_"++strButtonName), Checkbox.checked False,  Checkbox.onCheck (\checked -> if(checked) then (msg Nothing) else (msg (Just True)))] (Checkbox.label [ for ("all_"++strButtonName) ] [ span [ style "text-decoration" "line-through"] [text "Show All"]])
            , Checkbox.advancedCustom [ Checkbox.id ("only_"++strButtonName), Checkbox.checked False,  Checkbox.onCheck (\checked -> (msg (Just checked)))] (Checkbox.label [ for ("only_"++strButtonName) ] [ text <| "Show " ++ strButtonName ])
          ]

viewSelect : Select.State -> Dict String (String, Bool) -> Html Msg
viewSelect selectState bosses =
  let
    selected_boss_list = Dict.toList bosses |> List.filter (\(_, (_, selected)) -> selected) |> List.map (\(boss, _) -> boss)
    boss_list = Dict.toList bosses |> List.map (\(boss, _) -> boss)
    selected_items = List.map (\boss -> Select.basicMenuItem {item = boss, label = boss}) selected_boss_list
    items = List.map (\boss -> Select.basicMenuItem {item = boss, label = boss}) boss_list
  in
    Html.map SelectMsg <| Styled.toUnstyled <| Select.view (Select.multi selected_items |> Select.menuItems items |> Select.state selectState)

viewSelectCommanders : Select.State -> Dict String Bool -> Html Msg
viewSelectCommanders selectState commanders =
  let
    selected_commander_list = Dict.toList commanders |> List.filter (\(_, selected) -> selected) |> List.map (\(commander, _) -> commander)
    commander_list = Dict.toList commanders |> List.map (\(commander, _) -> commander)
    selected_items = List.map (\commander -> Select.basicMenuItem {item = commander, label = commander}) selected_commander_list
    items = List.map (\commander -> Select.basicMenuItem {item = commander, label = commander}) commander_list
  in
    Html.map SelectCommanderMsg <| Styled.toUnstyled <| Select.view (Select.multi selected_items |> Select.menuItems items |> Select.state selectState)


-- VIEW
view : Model -> Html Msg
view { logs, tableState, pickerState, selectState, selectCommanderState, bosses, commanders, message, state, show_wins, show_cms } =
  let
    resetHidden =
      (\log -> {log | hidden = False})
    hiddenBosses =
      (\log -> {log | hidden = log.hidden || not (Dict.get log.fight bosses |> Maybe.withDefault ("", True) |> Tuple.second)})
    hiddenCommanders =
      (\log -> {log | hidden = log.hidden || not (Dict.get log.recorded_by commanders |> Maybe.withDefault True)})
    hiddenCMs = 
      case show_cms of
          Nothing ->
            (\log -> log)
          Just blnToggle -> 
            (\log -> {log | hidden = log.hidden || blnToggle && not log.is_cm })
    hiddenLosses =
      case show_wins of
          Nothing ->
            (\log -> log)
          Just blnToggle -> 
            (\log -> {log | hidden = log.hidden || blnToggle && not log.is_win })
    hiddenDateRange =
      case Picker.getRange pickerState of
          Just range ->
                  (\log -> {log | hidden = log.hidden || (
                    case log.start of
                      Ok begin ->
                        -- Falls within the date range, maintain hidden value
                        if (Range.between begin range) then
                          log.hidden
                        -- Falls outside the date range, change hidden value to True
                        else 
                          True
                      Err _ ->
                        log.hidden
                  )})
          Nothing ->
            (\log -> log)
    hiddenLogs =
      resetHidden >> hiddenDateRange >> hiddenCMs >> hiddenLosses >> hiddenBosses >> hiddenCommanders
  in
    case state of
      Loading ->
        div []
            [ CDN.stylesheet
                , h1 [] [text "Arc Logs"]
                , h1 [] [ text message ]
                , text "loading..."
            ]
      Loaded ->
          div []
              [ CDN.stylesheet
              , Styled.toUnstyled 
                <| Global.global 
                  [ Global.class "EDRPCalendar" 
                    [ -- Css.display Css.none
                    ]
                  , Global.selector ".dateRangePicker>input" 
                    [ Css.width (Css.auto)
                    ]
                  , Global.selector ".dateRangePicker>div" 
                    [ Css.float Css.left
                    , Css.position Css.absolute
                    , Css.color (Css.rgb 255 255 255)
                    , Css.backgroundColor (Css.rgb 0 0 0)
                    , Css.zIndex (Css.int 1)
                    ]
                  ]
              , Grid.containerFluid [] 
                [ Grid.row [ Row.topXs ]
                  [ Grid.col [ Col.xs6 ]
                    [ viewSelectCommanders selectCommanderState commanders
                    , viewSelect selectState bosses

                    , Button.button [ Button.success, Button.onClick SelectAllBosses ] [ text "All Bosses" ]
                    , Button.button [ Button.danger, Button.onClick DeselectAllBosses ] [ text "Remove Bosses" ]

                    , viewToggleButton "Wins" ToggleWins show_wins
                    , viewToggleButton "CMs" ToggleCMs show_cms

                    , Picker.view PickerChanged pickerState
                    ]
                  , Grid.col [ Col.xs6 ]
                    [ h1 [] [ text "Logs" ]
                    , div[style "height" "500px", style "overflow" "auto"] 
                        [ logs |> List.map hiddenLogs |> Table.view config tableState 
                        ]
                    ]
                  ]
                ]

              ]

fightColumn : Table.Column Log Msg
fightColumn = Table.veryCustomColumn
              { name = "Fight"
              , viewData = viewFightColumn
              , sorter = Table.unsortable
              }

viewFightColumn : Log -> Table.HtmlDetails Msg
viewFightColumn log = Table.HtmlDetails [style "height" "100px", style "width" "100px"]
                  [ img [ src log.fight_icon, style "height" "50px", style "width" "50px" ] []
                  , br [] []
                  , span [] [ text log.fight ]
                  ]

recorded_byColumn : Table.Column Log Msg
recorded_byColumn = Table.stringColumn "Recorded By" .recorded_by

durationColumn : Table.Column Log Msg
durationColumn = Table.customColumn -- Table.stringColumn "Duration" .duration
              { name = "Duration"
              , viewData = (\data -> .duration data)
              , sorter = Table.unsortable
              }

startColumn : Table.Column Log Msg
startColumn = Table.customColumn
            { name = "Start"
            , viewData = (\data -> case (.start data) of 
                            Ok t ->
                                case (List.head (String.split "T" (Iso8601.fromTime t))) of
                                  Just date ->
                                      (Iso8601.fromTime t)
                                      -- date
                                      -- String.fromInt (Time.posixToMillis t)
                                  Nothing ->
                                      "Something went wrong!"
                            _ ->
                                "Error"
            )
            , sorter = Table.increasingBy (\data -> case (.start data) of
                                            Ok t ->
                                              case (.hidden data) of
                                                  True -> 
                                                      (1, (Time.posixToMillis t))
                                                  False -> 
                                                      (0, (Time.posixToMillis t))
                                            _ -> (0, Time.toMillis Time.utc (Time.millisToPosix 0))
              )
            } 

config : Table.Config Log Msg
config =
  Table.customConfig
    { toId = .identifier
    , toMsg = SetTableState
    , columns =
        [ fightColumn
        , startColumn
        , durationColumn
        ]
    , customizations =
        { defaultCustomizations | tableAttrs = tableAttrs, rowAttrs = toRowAttrs }
    }

tableAttrs : List (Attribute msg)
tableAttrs = [style "height" "200px", style "overflow" "auto"]

toRowAttrs : Log -> List (Attribute Msg)
toRowAttrs log =
    [ onClick (ToggleSelected log.identifier)
    , style "background" (if log.selected then "#CEFAF8" else "white")
    , style "color" (if log.is_win then "green" else "red")
    , style "font-weight" (if log.is_cm then "bold" else "")
    , style "opacity" (if log.hidden then "50%" else "100%")
    ]

subscriptions : Model -> Sub Msg
subscriptions model = Picker.subscriptions PickerChanged model.pickerState -- model.pickerState >> Picker.subscriptions PickerChanged