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
    { moves : Array String
    , beatCount : Int
    , clicks : List Time
    , bpm : Int
    , currentMove : Maybe String
    , active : Bool
    , currentBeat : Int
    }


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
            , intInput { min = 30, max = 1024, step = 1 }
                [ onInput <| parseInt UpdateBpm
                , value <| toString model.bpm
                ]
            , button [ onClick BpmButtonClicked ]
                [ text "Calculate"
                ]
            ]
        , div []
            [ text "Every "
            , intInput { min = 4, max = 1024, step = 4 }
                [ onInput <| parseInt UpdateBeatCount
                , value <| toString model.beatCount
                ]
            , text <|
                if model.beatCount /= 1 then
                    " beats"
                else
                    " beat"
            ]
        , beatTicker model
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


beatTicker : Model -> Html Msg
beatTicker model =
    let
        n =
            model.beatCount

        k =
            if model.currentBeat % n == 0 then
                n
            else
                model.currentBeat
    in
        span []
            [ span [ style [ ( "color", "black" ) ] ] [ text <| String.join "" <| List.repeat k "·" ]
            , span [ style [ ( "color", "gray" ) ] ] [ text <| String.join "" <| List.repeat (n - k) "·" ]
            ]


intInput : { min : Int, max : Int, step : Int } -> List (Html.Attribute msg) -> Html msg
intInput range attrs =
    input
        ([ type_ "number"
         , Html.Attributes.min <| toString range.min
         , Html.Attributes.max <| toString range.max
         , Html.Attributes.step <| toString range.step
         ]
            ++ attrs
        )
        []



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
            ( { model | currentBeat = (model.currentBeat + 1) % model.beatCount }
            , if model.currentBeat == 0 then
                Random.generate DisplayMove (randomMove model)
              else
                Cmd.none
            )

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
        Time.every (minute / toFloat model.bpm) (always Tick)
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
      , active = True
      , currentBeat = 0
      }
    , Cmd.none
    )
