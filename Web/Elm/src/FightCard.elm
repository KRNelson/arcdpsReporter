module FightCard exposing (..)

import Browser
import Html exposing (Html, text, span, div, img)
import Html.Attributes exposing (href, class, classList, src)
import Dict exposing (Dict)

import Bootstrap.Grid as Grid
import Bootstrap.Grid.Row as Row
import Bootstrap.Grid.Col as Col

import Bootstrap.Card as Card
import Bootstrap.Card.Block as Block

main =
  Browser.element
    { init = init
    , update = update
    , view = view
    , subscriptions = subscriptions
    }

type alias Character = 
    { profession : String
    -- , icon : String
    }

type alias Model = 
    { fight : String
    , icon : String
    , players : List Character
    , subgroups : Dict Int (List Character)
    , start : String
    , duration : String
    }

default : Model 
default = { fight = ""
          , icon = ""
          , players = []
          , subgroups = Dict.empty
          , start = ""
          , duration = ""
          }

test_default : Model
test_default = { fight = "Vale Guardian"
               , icon = ""
               , players = [{ profession = "Engineer"}, { profession = "Weaver" }, { profession = "Mirage" }, { profession = "Weaver" }, { profession = "Mirage" }]
               , subgroups = Dict.insert 2 [{ profession = "Engineer" }, { profession = "Weaver" }] <| Dict.insert 1 [{ profession = "Mirage" }] Dict.empty
               , start = "16:00"
               , duration = "2 minutes"
               }

init : () -> (Model, Cmd Msg)
init _ = (test_default, Cmd.none)
-- init _ = (default, Cmd.none)

type Msg = None

update : Msg -> Model -> (Model, Cmd Msg)
update _ model = (model, Cmd.none)

view : Model -> Html Msg
view model = Grid.row [ Row.attrs [ class "justify-content-center" ]] 
                [ Grid.col [ Col.lg8 ] [
                    viewFightCard model
                ]]

viewFightCard : Model -> Html msg 
viewFightCard { fight, start, duration, players } = 
        Card.config [ Card.attrs [ class "fight"] ]
        |> Card.headerH1 [] [ text fight ]
        |> Card.footer [] [ text <| "Start: " ++ start ++ " Duration: " ++ duration ]
        |> Card.block []
            [ viewSubgroup 1 players
            , viewSubgroup 2 players
            ]
            -- , Block.link [ href "#"] [ text "MyLink" ]
        |> Card.view

viewSubgroup : Int -> List Character -> Block.Item msg
viewSubgroup subgroup players = 
    Block.custom <| div [ classList [ ("card-custom", True)]] 
        [
            div [classList [("subgroup", True)]]
                [ span [class "subgroup-number"] [text <| String.fromInt subgroup], div [classList [("players", True)]] <| List.map viewPlayer players]
        ]

-- Similar to squad look
--      Use green box with profession icon
--      Mark the commander with tag
--      High level stats
--          DPS, Target + Cleave
--          Boon uptime + Boon generation
--          Rez time
--          Downed count -- Use the red downed (as opposed to green) look
--          Time lived if died -- Use the dead player look if someone died
viewPlayer : Character -> Html msg 
viewPlayer { profession } = 
    div [ class "player"] 
    [   viewPlayerIcon "https://render.guildwars2.com/file/67EC28331F55782A7FFC386E455F5EE6913A126E/2479355.png"
        , viewPlayerProfession profession
        , viewPlayerDPS 9001
        , viewPlayerTime "4m20s"
        , viewPlayerRez "5m32s"
        , viewPlayerDowns 42
        , viewPlayerBoons 1009
    ]

viewPlayerIcon : String -> Html msg 
viewPlayerIcon icon = 
    img [ class "icon", src icon ] []

viewPlayerProfession : String -> Html msg 
viewPlayerProfession profession = 
    span [ class "profession" ] [ text profession ]

viewPlayerDPS : Int -> Html msg 
viewPlayerDPS dps = 
    span [ class "dps" ] [ text <| "DPS: " ++ String.fromInt dps ]

viewPlayerTime : String -> Html msg 
viewPlayerTime duration = 
    span [ class "time"] [ text <| "Survived: " ++ duration ]

viewPlayerRez : String -> Html msg 
viewPlayerRez duration =
    span [ class "rez" ] [ text <| "Rez: " ++ duration ]

viewPlayerDowns : Int -> Html msg 
viewPlayerDowns downs =
    span [ class "downs"] [ text <| "Downs: " ++ String.fromInt downs ]

viewPlayerBoons : Int -> Html msg 
viewPlayerBoons boons =
    span [ class "boons"] [ text <| "Boons: " ++ String.fromInt boons ]



subscriptions : Model -> Sub Msg
subscriptions _ = Sub.none