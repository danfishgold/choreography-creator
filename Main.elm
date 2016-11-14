port module MoveJuggler exposing (..)

import Html exposing (Html, programWithFlags, input, button, div, span, p, text)
import Html.Events exposing (onClick, onInput)
import Html.Attributes exposing (type_, min, max, step, defaultValue, value, style, id)
import Time exposing (Time, minute, second)
import Task
import String
import Random
import Array exposing (Array)
import Regex exposing (regex)


-- MODEL


type alias Model =
    { moves : Array String, beatCount : Int, clicks : List Time, bpm : Int, currentMove : Maybe String, active : Bool }


type Msg
    = UpdateMoves (Array String)
    | UpdateBeatCount Int
    | UpdateBpm Int
    | DisplayMove (Maybe String)
    | Tick
    | BpmButtonClicked
    | AddClick Time
    | StartOrStop
    | Nop


parseInt : (Int -> Msg) -> String -> Msg
parseInt fn str =
    case String.toInt str of
        Ok int ->
            fn int

        Err _ ->
            Nop


diff : List Float -> List Float
diff xs =
    List.map2 ((-)) (List.drop 1 xs) xs


avg : List Float -> Maybe Float
avg xs =
    let
        n =
            toFloat (List.length xs)
    in
        if n == 0 then
            Nothing
        else
            Just (List.sum xs / n)


parseMoves : String -> Array String
parseMoves str =
    if String.isEmpty str then
        Array.empty
    else
        str
            |> Regex.split Regex.All (regex "\\s*,\\s*")
            |> Array.fromList



-- VIEW


view : Model -> Html Msg
view model =
    div [ id "main-div" ]
        [ div [ id "moves-div" ]
            [ text "Moves: "
            , input [ style [ ( "flex", "1 1 auto" ) ], onInput (parseMoves >> UpdateMoves), defaultValue <| String.join ", " <| Array.toList model.moves ] []
            ]
        , div []
            [ text "BPM: "
            , input
                [ onInput <| parseInt UpdateBpm
                , type_ "number"
                , Html.Attributes.min "30"
                , Html.Attributes.max "1024"
                , Html.Attributes.step "1"
                , value <| toString model.bpm
                ]
                []
            , button [ onClick BpmButtonClicked ]
                [ text "Calculate"
                ]
            ]
        , div []
            [ text "Every "
            , input
                [ onInput <| parseInt UpdateBeatCount
                , type_ "number"
                , Html.Attributes.min "4"
                , Html.Attributes.max "1024"
                , Html.Attributes.step "4"
                , value <| toString model.beatCount
                ]
                []
            , text " "
            , text <|
                if model.beatCount /= 1 then
                    "beats"
                else
                    "beat"
            ]
        , div []
            [ button [ onClick StartOrStop ]
                [ text <|
                    if model.active then
                        "Stop"
                    else
                        "Start"
                ]
            ]
        , div [ id "move-display" ]
            [ text (model.currentMove |> Maybe.withDefault "")
            ]
        ]



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UpdateMoves moves ->
            { model | moves = moves } |> saveModel

        UpdateBeatCount count ->
            { model | beatCount = count } |> saveModel

        UpdateBpm bpm ->
            { model | bpm = bpm } |> saveModel

        DisplayMove move ->
            ( { model | currentMove = move }, Cmd.none )

        Tick ->
            ( model, Random.generate DisplayMove (randomMove model) )

        BpmButtonClicked ->
            ( model, Task.perform AddClick Time.now )

        AddClick click ->
            let
                clicks =
                    click :: model.clicks |> List.take 4 |> List.filter (\t -> click - t < 2 * second)

                clickBpm =
                    clicks |> List.reverse |> diff |> avg |> Maybe.map (\dt -> round (minute / dt))

                model_ =
                    { model | clicks = clicks }

                command =
                    case clickBpm of
                        Just bpm ->
                            message (UpdateBpm bpm)

                        Nothing ->
                            Cmd.none
            in
                ( model_, command )

        StartOrStop ->
            ( { model | active = not model.active }
            , if not model.active then
                message Tick
              else
                Cmd.none
            )

        Nop ->
            ( model, Cmd.none )


message : msg -> Cmd msg
message x =
    Task.perform identity (Task.succeed x)



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    if model.active then
        Time.every (toFloat model.beatCount * minute / toFloat model.bpm) (always Tick)
    else
        Sub.none



-- RANDOM


randomMove : Model -> Random.Generator (Maybe String)
randomMove model =
    Random.int 0 (Array.length model.moves - 1)
        |> Random.map (\i -> Array.get i model.moves)



-- MAIN


main : Program Flags Model Msg
main =
    programWithFlags
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- PORTS


saveModel : Model -> ( Model, Cmd msg )
saveModel model =
    ( model
    , save
        { moves = model.moves |> Array.toList |> String.join ", "
        , bpm = model.bpm
        , beatCount = model.beatCount
        }
    )


type alias Flags =
    { moves : String, bpm : Int, beatCount : Int }


port save : Flags -> Cmd msg


init : Flags -> ( Model, Cmd Msg )
init { moves, bpm, beatCount } =
    ( { moves = parseMoves moves
      , beatCount = beatCount
      , clicks = []
      , bpm = bpm
      , currentMove = Nothing
      , active = False
      }
    , Cmd.none
    )
