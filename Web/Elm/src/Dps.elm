module Dps exposing (..)

import Browser
import Html as H
import Html.Attributes as HA
-- import Svg as S
import Chart as C
import Chart.Attributes as CA
import Chart.Events as CE
import Chart.Item as CI
import Chart.Svg as CS


main : Program () Model Msg
main =
  -- Html.program
  Browser.element
    { init = init
    , update = update
    , view = view
    , subscriptions = \_ -> Sub.none
    }

type alias Model =
  { hovering : List (CI.One { x : Float, y : Float } CI.Any) }


init : () -> (Model, Cmd Msg)
init _ =
  ({ hovering = [] }, Cmd.none)


type Msg
  = OnHover (List (CI.One { x : Float, y : Float } CI.Any))


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    OnHover hovering ->
      ({ model | hovering = hovering }, Cmd.none)


view : Model -> H.Html Msg
view model =
  H.div [HA.style "margin-top" "2%", HA.style "margin-left" "25%", HA.style "height" "50%", HA.style "width" "50%"]
  [

  C.chart
    [ CA.height 300
    , CA.width 300
    , CE.onMouseMove OnHover (CE.getNearest CI.any)
    , CE.onMouseLeave (OnHover [])
    ]
    [ C.xTicks []
    , C.xLabels []
    , C.yTicks []
    , C.yLabels []
    , C.list <|
        let heatmapItem index value =
              let x = toFloat (remainderBy 5 index) * 2
                  y = toFloat (index // 5) * 2
                  color =
                    if value > 8  then "#0E4D64" else
                    if value > 6  then "#137177" else
                    if value > 4  then "#188977" else
                    if value > 2  then "#1D9A6C" else
                    if value > 0  then "#74C67A" else
                    if value == 0 then "#99D492" else
                    "#0A2F51"
              in
              C.custom
                { name = "Temperature"
                , color = color
                , position = { x1 = x, x2 = x + 1, y1 = y, y2 = y + 1 }
                , format = .y >> String.fromFloat >> (\v -> v ++ " C°")
                , data = { x = toFloat index, y = value }
                , render = \p ->
                    CS.rect p
                      [ CA.x1 x
                      , CA.x2 (x + 2)
                      , CA.y1 y
                      , CA.y2 (y + 2)
                      , CA.color color
                      , CA.border "white"
                      ]
                }
        in
        List.indexedMap heatmapItem
          [ 2, 5, 8, 5, 3
          , 5, 7, 9, 0, 3
          , 2, 4, 6, 3, 5
          , 7, 9, 0, 3, 2
          , 4, 6, 7, 8, 10
          ]

    , C.each model.hovering <| \_ item ->
        [ C.tooltip item [ CA.center, CA.offset 0, CA.onTopOrBottom ] [] [] ]
    ]
  ]