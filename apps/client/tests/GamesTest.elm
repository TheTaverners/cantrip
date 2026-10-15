module GamesTest exposing (suite)

import Expect
import Fuzz
import Games exposing (Game, Games, Scene)
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
        , Test.describe "making a Scene active"
            [ Test.test "replaces the previous Active Scene" <|
                \() ->
                    makeSeededSceneActive 0 2 Games.seed
                        |> seededGameOf 0
                        |> Maybe.andThen Games.activeScene
                        |> Maybe.map sceneTitle
                        |> Expect.equal (Just "The Crypt Heart")
            , Test.test "gives an Active Scene to a Game that had none" <|
                \() ->
                    makeSeededSceneActive 1 1 Games.seed
                        |> seededGameOf 1
                        |> Maybe.andThen Games.activeScene
                        |> Maybe.map sceneTitle
                        |> Expect.equal (Just "The Pickpocket's Alley")
            , Test.test "leaves the other Games' Active Scenes alone" <|
                \() ->
                    makeSeededSceneActive 1 1 Games.seed
                        |> seededGameOf 0
                        |> Maybe.andThen Games.activeScene
                        |> Maybe.map sceneTitle
                        |> Expect.equal (Just "Hall of Echoes")
            , Test.test "leaves the Active Scene unchanged for an unknown Scene" <|
                \() ->
                    seededGame 0
                        |> Maybe.map (\game -> Games.makeActive (Games.gameId game) (Games.sceneIdFromString "no-such-scene") Games.seed)
                        |> Maybe.andThen (seededGameOf 0)
                        |> Maybe.andThen Games.activeScene
                        |> Maybe.map sceneTitle
                        |> Expect.equal (Just "Hall of Echoes")
            , Test.test "leaves the Active Scene unchanged for a Scene of another Game" <|
                \() ->
                    Maybe.map2 (\game otherScene -> Games.makeActive (Games.gameId game) (Games.sceneId otherScene) Games.seed)
                        (seededGame 0)
                        (seededGame 1 |> Maybe.map Games.scenes |> Maybe.andThen List.head)
                        |> Maybe.andThen (seededGameOf 0)
                        |> Maybe.andThen Games.activeScene
                        |> Maybe.map sceneTitle
                        |> Expect.equal (Just "Hall of Echoes")
            , Test.test "leaves the collection unchanged for an unknown Game" <|
                \() ->
                    seededGame 0
                        |> Maybe.andThen (Games.scenes >> List.head)
                        |> Maybe.map (\scene -> Games.makeActive (Games.gameIdFromString "no-such-game") (Games.sceneId scene) Games.seed)
                        |> Expect.equal (Just Games.seed)
            , Test.fuzz (Fuzz.list makeActiveOperation) "any sequence of operations leaves each Game at most one Active Scene, among its own Scenes" <|
                \operations ->
                    List.foldl (\( id, activeId ) -> Games.makeActive id activeId) Games.seed operations
                        |> Games.list
                        |> List.map
                            (\game ->
                                Games.scenes game
                                    |> List.filter (\scene -> Just (Games.sceneId scene) == Maybe.map Games.sceneId (Games.activeScene game))
                                    |> List.length
                            )
                        |> List.all (\count -> count <= 1)
                        |> Expect.equal True
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


seededGameOf : Int -> Games -> Maybe Game
seededGameOf index games =
    Games.list games
        |> List.drop index
        |> List.head


{-| Make active, in `games`, the Scene at `sceneIndex` of the seeded Game at
`gameIndex`.
-}
makeSeededSceneActive : Int -> Int -> Games -> Games
makeSeededSceneActive gameIndex sceneIndex games =
    case seededGame gameIndex of
        Just game ->
            case Games.scenes game |> List.drop sceneIndex |> List.head of
                Just scene ->
                    Games.makeActive (Games.gameId game) (Games.sceneId scene) games

                Nothing ->
                    games

        Nothing ->
            games


{-| A "make active" operation on any seeded Game or Scene, mixed with unknown
ids and Scenes of another Game.
-}
makeActiveOperation : Fuzz.Fuzzer ( Games.GameId, Games.SceneId )
makeActiveOperation =
    let
        gameIds : List Games.GameId
        gameIds =
            Games.gameIdFromString "no-such-game" :: List.map Games.gameId (Games.list Games.seed)

        sceneIds : List Games.SceneId
        sceneIds =
            Games.sceneIdFromString "no-such-scene" :: List.map Games.sceneId (List.concatMap Games.scenes (Games.list Games.seed))
    in
    Fuzz.pair (Fuzz.oneOfValues gameIds) (Fuzz.oneOfValues sceneIds)
