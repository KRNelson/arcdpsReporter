module SelectTest exposing (..)

import Browser
import Select
import Select exposing (Action(..))
import Html exposing (Html)
import Html.Styled as Styled
import Set
-- import Select.Action exposing (Select, SelectBatch, Clear, Deselect, InputChange, FocusSet)

main =
  Browser.element
    { init = init
    , update = update
    , view = view
    , subscriptions = subscriptions -- .pickerState >> Picker.subscriptions PickerChanged
    }

type alias Model =
    {  selectState : Select.State
    ,  items : List (Select.MenuItem String)
    ,  selectedItems : List (Select.MenuItem String)
    }
type Msg 
    = SelectMsg (Select.Msg String)
    -- your other Msg's

init : () -> (Model, Cmd Msg)
init _ = (default, Cmd.none)


default : Model
default = 
    {  selectState =
            Select.initState (Select.selectIdentifier "CountrySelector")
    ,  items = 
           [ Select.basicMenuItem 
                { item = "Australia", label = "Australia?" }
           , Select.basicMenuItem
                { item = "Japan", label = "Japan?" }
           , Select.basicMenuItem
                { item = "Taiwan", label = "Taiwan?" }
           ]
    , selectedItems = []
    }

update : Msg -> Model -> (Model, Cmd Msg)
update msg model = 
    case msg of
        SelectMsg selectMsg ->
            let
                (maybeAction, selectState, selectCmds) = 
                    Select.update selectMsg model.selectState
                newModel =
                    case maybeAction of 

                        Just (Select item) ->
                            -- { model | selectedCountry = Just someCountry }
                            { model | selectedItems = Set.toList (Set.fromList (Select.basicMenuItem { item = item, label = item} :: model.selectedItems))}

                        Just (SelectBatch _) ->
                            -- handle multiple selected
                            model

                        Just (Clear) -> 
                            -- handle cleared 
                            model 

                        Just (Deselect _) ->
                            -- handle deselected 
                            model 

                        Just (InputChange _) -> 
                            -- handle InputChange
                            model 

                        Just (FocusSet) ->
                            -- handle focus set
                            model 

                        Nothing ->
                            model

            in
                ({newModel | selectState = selectState}, Cmd.map SelectMsg selectCmds)

view : Model -> Html Msg
view model = 
    Html.map SelectMsg <| Styled.toUnstyled <| Select.view (Select.multi model.selectedItems |> Select.menuItems model.items |> Select.state model.selectState)


subscriptions : Model -> Sub Msg
subscriptions _ = Sub.none