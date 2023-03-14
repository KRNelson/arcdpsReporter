module ChartTest exposing (..)

import Browser
import Html exposing (Html, div)
import Html.Attributes exposing (style)
import Chart as C
import Chart.Attributes as CA
import Html.Attributes

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
  {}


init : () -> (Model, Cmd Msg)
init _ =
  ({}, Cmd.none)


type Msg
  = Nill


update : Msg -> Model -> (Model, Cmd Msg)
update _ model = (model, Cmd.none)

viewPanel : Model -> Html msg
viewPanel _ =
  Html.div []
    [
      Html.nav []
        [
          Html.div [Html.Attributes.classList [("nav", True), ("nav-tabs", True)], Html.Attributes.id "nav-tab", Html.Attributes.attribute "role" "tablist"]
            [
              Html.button [Html.Attributes.classList [("nav-link", True), ("active", True)], Html.Attributes.id "nav-one-tab", Html.Attributes.attribute "role" "tab", Html.Attributes.attribute "data-bs-toggle" "tab", Html.Attributes.attribute "data-bs-target" "#nav-one", Html.Attributes.attribute "aria-selected" "true"] [Html.text "One"]
            , Html.button [Html.Attributes.classList [("nav-link", True), ("active", True)], Html.Attributes.id "nav-two-tab", Html.Attributes.attribute "role" "tab", Html.Attributes.attribute "data-bs-toggle" "tab", Html.Attributes.attribute "data-bs-target" "#nav-two", Html.Attributes.attribute "aria-selected" "false"] [Html.text "Two"]
            ]
        ]
    , Html.div [Html.Attributes.classList [("tab-content", True)], Html.Attributes.id "nav-tabContent"]
      [
        Html.div [Html.Attributes.classList [("tab-pane", True), ("fade", True), ("show", True), ("active", True)], Html.Attributes.id "nav-one", Html.Attributes.attribute "role" "tabpanel", Html.Attributes.attribute "aria-labelledby" "nav-one-tab"] [Html.text "One!!!"]
      , Html.div [Html.Attributes.classList [("tab-pane", True), ("fade", True)], Html.Attributes.id "nav-two", Html.Attributes.attribute "role" "tabpanel", Html.Attributes.attribute "aria-labelledby" "nav-two-tab"] [Html.text "Two!!!"]
      ]
    ]

view : Model -> Html msg
view _ =
  C.chart
      [ CA.width 300
      , CA.height 300
      -- , CA.htmlAttrs [(style "width" "100%")]
      , CA.padding { top = 10, bottom = 5, left = 10, right = 10 }
      ]
      [ C.xLabels []
      , C.yLabels [ CA.withGrid ]
      , C.series .x 
        [ C.interpolatedMaybe .y [ ] [ CA.circle ]
        , C.interpolated .z [ CA.monotone ] [ CA.square ]
        ]
        [ {x = 1, y = Just 2, z = 3}
        , {x = 3, y = Nothing, z = 1}
        , {x =10, y = Just 3, z = 4}
        ]
      ]