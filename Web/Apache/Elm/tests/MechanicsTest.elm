module MechanicsTest exposing (..)

import Mechanics as M

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Test exposing (..)
import Test.Html.Query as Query
import Test.Html.Selector as Selector

import Html exposing (Html, button, p, text, input, form, div, span)
import Html.Attributes exposing (attribute, class, style, type_, action, method, enctype, name, multiple, required, value)
import Html.Events exposing (onClick)
import Table

-- Things to test..
--      default => creates an 'initial' Model
--      init => Uses default with Cmd.
--      update => All possible Msg. 
--      view => Various combinations of Model. 
--      subscriptions? => idk..

suite : Test
suite =
    describe "The Mechanics Module"
        [ describe "Mechanics.default"
            [ test "Expected Default" <|
                \_ ->
                    let
                        expected = (M.Model [] (Table.initialSort "Account") (Table.initialSort "Start") "" "" M.Loading)
                    in
                        M.default
                            |> Expect.equal expected
            ]
        , describe "Mechanics.init"
            [ test "Init default model" <|
                \_ ->
                    let
                        (model, _) = M.init ()
                        expected = M.default
                    in
                        model 
                            |> Expect.equal expected
            , test "Init no commands" <|
                \_ ->
                    let
                        (_, command) = M.init ()
                        expected = Cmd.none
                    in
                        command 
                            |> Expect.equal expected
            ]
        , describe "Mechanics.subscriptions"
            [ test "No subscriptions" <|
                \_ ->
                    M.default 
                        |> M.subscriptions
                        |> Expect.equal Sub.none
            ]
        ]
