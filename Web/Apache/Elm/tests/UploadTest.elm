module UploadTest exposing (..)

import Upload as U

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Test exposing (..)
import Test.Html.Query as Query
import Test.Html.Selector as Selector

import Html exposing (Html, button, p, text, input, form, div)
import Html.Attributes exposing (style, type_, action, method, enctype, name, multiple, required, value)
import Html.Events exposing (onClick)

testBootstrapAlert : (String -> Html msg) -> Test
testBootstrapAlert html =
    describe "Test for Bootstrap alert. "
        [ test "Expect Cancel" <|
            \_ ->
                let
                    content = "Hello World!"
                    query = [ Selector.text "x", Selector.classes ["btn", "close"] ]
                in
                    html content
                        |> Query.fromHtml
                        |> Query.has query
        , fuzzWith { runs = 10000 } string "Fuzz expect cancel" <|
            \randomContent -> 
                let
                    query = [ Selector.text "x", Selector.classes ["btn", "close"] ]
                in
                    html randomContent
                        |> Query.fromHtml
                        |> Query.has query
        ]

suite : Test
suite =
    describe "The Upload Module"
        [ describe "Upload.default"
            [ test "Expected Default" <|
                \_ ->
                    let
                        expected = (U.Model [] Nothing)
                    in
                        U.default
                            |> Expect.equal expected
            ]
        , describe "Upload.init"
            [ test "Init default model" <|
                \_ ->
                    let
                        (model, _) = U.init ()
                        expected = U.default
                    in
                        model 
                            |> Expect.equal expected
            , test "Init no commands" <|
                \_ ->
                    let
                        (_, command) = U.init ()
                        expected = Cmd.none
                    in
                        command 
                            |> Expect.equal expected
            ]
        , describe "Upload.viewFileSelected"
            [ skip <| test "Expected File Selected" <|
                \_ ->
                    let
                        content = "Hello World"
                        expected = div [] [ text content ]
                    in
                        U.viewFileSelected content
                            |> Expect.equal expected
            , test "Expect Content" <|
                \_ ->
                    let
                        content = "Hello World"
                        query = [ Selector.text content ]
                    in
                        U.viewFileSelected content
                            |> Query.fromHtml
                            |> Query.has query
            , fuzz string "Fuzz Content" <|
                \randomContent ->
                    let
                        query = [ Selector.text randomContent ]
                    in
                        U.viewFileSelected randomContent
                            |> Query.fromHtml
                            |> Query.has query
            , let 
                content = "Hello World"
              in 
                testBootstrapAlert U.viewFileSelected
            ]

        , describe "Uplaod.viewFileUploading"
            [ todo "Write a test for the HTML while a file is uploading. "
            ]
        , describe "Upload.viewFileUploaded"
            [ todo "Write a test for the HTML after a file is uploaded. "
            ]
        , describe "Upload.viewFileUploadFailed"
            [ todo "Write a test for the HTML if the upload fails. "
            ]
        , describe "Upload.viewForm"
            [ test "Expected Form" <|
                \_ ->
                    let
                        expected =   form [] [ input [type_ "button", onClick U.LogRequested, value "Load Log"] [] ]
                    in
                        U.viewForm
                            |> Expect.equal expected
            ]
        , describe "Upload.viewContent"
            [ test "Expected Content" <|
                \_ ->
                    let
                        content = "Hello World"
                        expected = p [style "white-space" "pre" ] [ text content ]
                    in
                        U.viewContent content
                            |> Expect.equal expected 
            , fuzz string "Fuzzy Content" <|
                \randomContent ->
                    let
                        expected = p [style "white-space" "pre" ] [text randomContent]
                    in
                        U.viewContent randomContent
                            |> Expect.equal expected
            ]
        , describe "Upload.view"
            [ skip <| test "Expected Default" <|
                \_ -> 
                    let
                        expected = div [] [ U.viewForm ]
                        model = U.default
                    in 
                        U.view model
                            |> Expect.equal expected
            , skip <| test "Expected Nothing" <|
                \_ -> 
                    let
                        expected = div [] [ U.viewForm ]
                        model = U.Model Nothing []
                    in 
                        U.view model
                            |> Expect.equal expected
            , test "Expected Content" <|
                \_ -> 
                    let
                        content = "Hello World"
                        model = (U.Model (Just content) [])
                        expected = div [] [ U.viewContent content, U.viewForm ]
                    in 
                        U.view model
                            |> Expect.equal expected
            , fuzz string "Fuzzy Content" <|
                \randomContent ->
                    let
                        model = (U.Model (Just randomContent) [])
                        expected = div [] [U.viewContent randomContent, U.viewForm]
                    in 
                        U.view model
                            |> Expect.equal expected
            ]
        , describe "Upload.subscriptions"
            [ test "No subscriptions" <|
                \_ ->
                    U.default 
                        |> U.subscriptions
                        |> Expect.equal Sub.none
            ]
        ]
