module GamesTest exposing (suite)

import Expect
import Fuzz
import Games exposing (Game, Scene)
import Test exposing (Test)
import Title


suite : Test
suite =
    Test.describe "Games"
        [ Test.describe "the seed"
            [ Test.test "holds two Games, in creation order" <|
                \() ->
                    Games.list Games.seed
                        |> List.map gameTitle
                        |> Expect.equal [ "The Sunken Crypt", "Market Day in Brindle" ]
            , Test.test "gives the first Game three Scenes, in creation order" <|
                \() ->
                    seededGame 0
                        |> Maybe.map (Games.scenes >> List.map sceneTitle)
                        |> Expect.equal (Just [ "The Drowned Gate", "Hall of Echoes", "The Crypt Heart" ])
            , Test.test "gives the first Game an Active Scene" <|
                \() ->
                    seededGame 0
                        |> Maybe.andThen Games.activeScene
                        |> Maybe.map sceneTitle
                        |> Expect.equal (Just "Hall of Echoes")
            , Test.test "gives the second Game Scenes" <|
                \() ->
                    seededGame 1
                        |> Maybe.map (Games.scenes >> List.map sceneTitle)
                        |> Expect.equal (Just [ "The Square", "The Pickpocket's Alley" ])
            , Test.test "gives the second Game no Active Scene" <|
                \() ->
                    seededGame 1
                        |> Maybe.andThen Games.activeScene
                        |> Expect.equal Nothing
            ]
        , Test.describe "looking a Game up by id"
            [ Test.test "finds every listed Game" <|
                \() ->
                    Games.list Games.seed
                        |> List.map (\game -> Games.get (Games.gameId game) Games.seed |> Maybe.map gameTitle)
                        |> Expect.equal [ Just "The Sunken Crypt", Just "Market Day in Brindle" ]
            , Test.test "finds nothing for an unknown id" <|
                \() ->
                    Games.get (Games.gameIdFromString "no-such-game") Games.seed
                        |> Expect.equal Nothing
            ]
        , Test.describe "ids"
            [ Test.test "a Game id round-trips through its string form" <|
                \() ->
                    let
                        gameIds : List Games.GameId
                        gameIds =
                            Games.list Games.seed
                                |> List.map Games.gameId
                    in
                    gameIds
                        |> List.map (Games.gameIdToString >> Games.gameIdFromString)
                        |> Expect.equal gameIds
            , Test.test "a Scene id round-trips through its string form" <|
                \() ->
                    let
                        sceneIds : List Games.SceneId
                        sceneIds =
                            Games.list Games.seed
                                |> List.concatMap Games.scenes
                                |> List.map Games.sceneId
                    in
                    sceneIds
                        |> List.map (Games.sceneIdToString >> Games.sceneIdFromString)
                        |> Expect.equal sceneIds
            , Test.fuzz Fuzz.string "a string round-trips through a Game id" <|
                \raw ->
                    Games.gameIdFromString raw
                        |> Games.gameIdToString
                        |> Expect.equal raw
            , Test.fuzz Fuzz.string "a string round-trips through a Scene id" <|
                \raw ->
                    Games.sceneIdFromString raw
                        |> Games.sceneIdToString
                        |> Expect.equal raw
            , Test.test "the Games of the seed have distinct ids" <|
                \() ->
                    case Games.list Games.seed |> List.map Games.gameId of
                        [ first, second ] ->
                            Expect.notEqual first second

                        ids ->
                            Expect.fail ("expected two Games, got " ++ String.fromInt (List.length ids))
            ]
        ]


seededGame : Int -> Maybe Game
seededGame index =
    Games.list Games.seed
        |> List.drop index
        |> List.head


gameTitle : Game -> String
gameTitle =
    Games.title >> Title.toString


sceneTitle : Scene -> String
sceneTitle =
    Games.sceneTitle >> Title.toString
