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
        , Test.describe "creating a Game"
            [ Test.test "adds it at the end of the list, with its title" <|
                \() ->
                    Games.seed
                        |> Games.createGame (validTitle "The Frozen Keep")
                        |> Games.list
                        |> List.map gameTitle
                        |> Expect.equal [ "The Sunken Crypt", "Market Day in Brindle", "The Frozen Keep" ]
            , Test.test "keeps creation order across several creations" <|
                \() ->
                    Games.seed
                        |> Games.createGame (validTitle "The Frozen Keep")
                        |> Games.createGame (validTitle "A Night at the Inn")
                        |> Games.list
                        |> List.map gameTitle
                        |> Expect.equal [ "The Sunken Crypt", "Market Day in Brindle", "The Frozen Keep", "A Night at the Inn" ]
            , Test.test "gives it no Scenes and no Active Scene" <|
                \() ->
                    Games.seed
                        |> Games.createGame (validTitle "The Frozen Keep")
                        |> Games.list
                        |> List.drop 2
                        |> List.map (\game -> ( Games.scenes game, Games.activeScene game ))
                        |> Expect.equal [ ( [], Nothing ) ]
            , Test.test "allows a title another Game already has, as a distinct Game" <|
                \() ->
                    let
                        games : List Game
                        games =
                            Games.seed
                                |> Games.createGame (validTitle "The Sunken Crypt")
                                |> Games.list
                    in
                    ( List.map gameTitle games, games |> List.map Games.gameId |> distinctCount )
                        |> Expect.equal ( [ "The Sunken Crypt", "Market Day in Brindle", "The Sunken Crypt" ], 3 )
            , Test.test "trims its title" <|
                \() ->
                    Title.fromString "  The Frozen Keep  "
                        |> Maybe.map (\valid -> Games.createGame valid Games.seed |> Games.list |> List.map gameTitle)
                        |> Expect.equal (Just [ "The Sunken Crypt", "Market Day in Brindle", "The Frozen Keep" ])
            ]
        , Test.describe "renaming a Game"
            [ Test.test "changes its title and keeps its place" <|
                \() ->
                    Games.seed
                        |> Games.renameGame (seededGameId 0) (validTitle "The Risen Crypt")
                        |> Games.list
                        |> List.map gameTitle
                        |> Expect.equal [ "The Risen Crypt", "Market Day in Brindle" ]
            , Test.test "keeps its Scenes and its Active Scene" <|
                \() ->
                    Games.seed
                        |> Games.renameGame (seededGameId 0) (validTitle "The Risen Crypt")
                        |> Games.get (seededGameId 0)
                        |> Maybe.map (\game -> ( Games.scenes game |> List.map sceneTitle, Games.activeScene game |> Maybe.map sceneTitle ))
                        |> Expect.equal (Just ( [ "The Drowned Gate", "Hall of Echoes", "The Crypt Heart" ], Just "Hall of Echoes" ))
            , Test.test "with an unknown id changes nothing" <|
                \() ->
                    Games.seed
                        |> Games.renameGame (Games.gameIdFromString "no-such-game") (validTitle "The Risen Crypt")
                        |> Expect.equal Games.seed
            ]
        , Test.describe "deleting a Game"
            [ Test.test "removes it from the list" <|
                \() ->
                    Games.seed
                        |> Games.deleteGame (seededGameId 0)
                        |> Games.list
                        |> List.map gameTitle
                        |> Expect.equal [ "Market Day in Brindle" ]
            , Test.test "makes its id name no Game" <|
                \() ->
                    Games.seed
                        |> Games.deleteGame (seededGameId 0)
                        |> Games.get (seededGameId 0)
                        |> Expect.equal Nothing
            , Test.test "deletes its Scenes too" <|
                \() ->
                    Games.seed
                        |> Games.deleteGame (seededGameId 0)
                        |> Games.list
                        |> List.concatMap Games.scenes
                        |> List.map sceneTitle
                        |> Expect.equal [ "The Square", "The Pickpocket's Alley" ]
            , Test.test "with an unknown id changes nothing" <|
                \() ->
                    Games.seed
                        |> Games.deleteGame (Games.gameIdFromString "no-such-game")
                        |> Expect.equal Games.seed
            , Test.test "never hands its id to a Game created afterwards" <|
                \() ->
                    Games.seed
                        |> Games.deleteGame (seededGameId 1)
                        |> Games.createGame (validTitle "Market Day in Brindle")
                        |> Games.get (seededGameId 1)
                        |> Expect.equal Nothing
            , Test.test "of every Game leaves an empty list" <|
                \() ->
                    Games.seed
                        |> Games.deleteGame (seededGameId 0)
                        |> Games.deleteGame (seededGameId 1)
                        |> Games.list
                        |> Expect.equal []
            ]
        , Test.describe "creating a Scene"
            [ Test.test "adds it at the end of its Game's Scenes, with its title" <|
                \() ->
                    Games.seed
                        |> Games.createScene (seededGameId 1) (validTitle "The Town Hall")
                        |> seededSceneTitlesOf 1
                        |> Expect.equal (Just [ "The Square", "The Pickpocket's Alley", "The Town Hall" ])
            , Test.test "keeps creation order across several creations" <|
                \() ->
                    Games.seed
                        |> Games.createScene (seededGameId 1) (validTitle "The Town Hall")
                        |> Games.createScene (seededGameId 1) (validTitle "The Bell Tower")
                        |> seededSceneTitlesOf 1
                        |> Expect.equal (Just [ "The Square", "The Pickpocket's Alley", "The Town Hall", "The Bell Tower" ])
            , Test.test "doesn't make it active, even when its Game has no Active Scene" <|
                \() ->
                    Games.seed
                        |> Games.createScene (seededGameId 1) (validTitle "The Town Hall")
                        |> seededGameOf 1
                        |> Maybe.map Games.activeScene
                        |> Expect.equal (Just Nothing)
            , Test.test "keeps its Game's Active Scene" <|
                \() ->
                    Games.seed
                        |> Games.createScene (seededGameId 0) (validTitle "The Ossuary")
                        |> seededGameOf 0
                        |> Maybe.andThen Games.activeScene
                        |> Maybe.map sceneTitle
                        |> Expect.equal (Just "Hall of Echoes")
            , Test.test "allows a title another Scene of the Game already has, as a distinct Scene" <|
                \() ->
                    let
                        sceneList : List Scene
                        sceneList =
                            Games.seed
                                |> Games.createScene (seededGameId 1) (validTitle "The Square")
                                |> seededGameOf 1
                                |> Maybe.map Games.scenes
                                |> Maybe.withDefault []
                    in
                    ( List.map sceneTitle sceneList, sceneList |> List.map (Games.sceneId >> Games.sceneIdToString) |> distinctStrings )
                        |> Expect.equal ( [ "The Square", "The Pickpocket's Alley", "The Square" ], 3 )
            , Test.test "trims its title" <|
                \() ->
                    Title.fromString "  The Town Hall "
                        |> Maybe.andThen (\valid -> Games.createScene (seededGameId 1) valid Games.seed |> seededSceneTitlesOf 1)
                        |> Expect.equal (Just [ "The Square", "The Pickpocket's Alley", "The Town Hall" ])
            , Test.test "leaves the other Games' Scenes alone" <|
                \() ->
                    Games.seed
                        |> Games.createScene (seededGameId 1) (validTitle "The Town Hall")
                        |> seededSceneTitlesOf 0
                        |> Expect.equal (Just [ "The Drowned Gate", "Hall of Echoes", "The Crypt Heart" ])
            , Test.test "in an unknown Game changes nothing" <|
                \() ->
                    Games.seed
                        |> Games.createScene (Games.gameIdFromString "no-such-game") (validTitle "The Town Hall")
                        |> Expect.equal Games.seed
            ]
        , Test.describe "renaming a Scene"
            [ Test.test "changes its title and keeps its place" <|
                \() ->
                    Games.seed
                        |> Games.renameScene (seededGameId 0) (seededSceneId 0 0) (validTitle "The Flooded Gate")
                        |> seededSceneTitlesOf 0
                        |> Expect.equal (Just [ "The Flooded Gate", "Hall of Echoes", "The Crypt Heart" ])
            , Test.test "of the Active Scene changes the Active Scene's title" <|
                \() ->
                    Games.seed
                        |> Games.renameScene (seededGameId 0) (seededSceneId 0 1) (validTitle "Hall of Whispers")
                        |> seededGameOf 0
                        |> Maybe.andThen Games.activeScene
                        |> Maybe.map sceneTitle
                        |> Expect.equal (Just "Hall of Whispers")
            , Test.test "in an unknown Game changes nothing" <|
                \() ->
                    Games.seed
                        |> Games.renameScene (Games.gameIdFromString "no-such-game") (seededSceneId 0 0) (validTitle "The Flooded Gate")
                        |> Expect.equal Games.seed
            , Test.test "with an unknown Scene changes nothing" <|
                \() ->
                    Games.seed
                        |> Games.renameScene (seededGameId 0) (Games.sceneIdFromString "no-such-scene") (validTitle "The Flooded Gate")
                        |> Expect.equal Games.seed
            , Test.test "with a Scene of another Game changes nothing" <|
                \() ->
                    Games.seed
                        |> Games.renameScene (seededGameId 0) (seededSceneId 1 0) (validTitle "The Flooded Gate")
                        |> Expect.equal Games.seed
            ]
        , Test.describe "deleting a Scene"
            [ Test.test "removes it from its Game's Scenes" <|
                \() ->
                    Games.seed
                        |> Games.deleteScene (seededGameId 0) (seededSceneId 0 0)
                        |> seededSceneTitlesOf 0
                        |> Expect.equal (Just [ "Hall of Echoes", "The Crypt Heart" ])
            , Test.test "keeps the Active Scene when deleting another Scene" <|
                \() ->
                    Games.seed
                        |> Games.deleteScene (seededGameId 0) (seededSceneId 0 2)
                        |> seededGameOf 0
                        |> Maybe.andThen Games.activeScene
                        |> Maybe.map sceneTitle
                        |> Expect.equal (Just "Hall of Echoes")
            , Test.test "of the Active Scene leaves its Game with no Active Scene" <|
                \() ->
                    Games.seed
                        |> Games.deleteScene (seededGameId 0) (seededSceneId 0 1)
                        |> seededGameOf 0
                        |> Maybe.map Games.activeScene
                        |> Expect.equal (Just Nothing)
            , Test.test "of the Active Scene, then creating a Scene, still leaves no Active Scene" <|
                \() ->
                    Games.seed
                        |> Games.deleteScene (seededGameId 0) (seededSceneId 0 1)
                        |> Games.createScene (seededGameId 0) (validTitle "Hall of Echoes")
                        |> seededGameOf 0
                        |> Maybe.map Games.activeScene
                        |> Expect.equal (Just Nothing)
            , Test.test "of every Scene leaves its Game with none" <|
                \() ->
                    Games.seed
                        |> Games.deleteScene (seededGameId 1) (seededSceneId 1 0)
                        |> Games.deleteScene (seededGameId 1) (seededSceneId 1 1)
                        |> seededSceneTitlesOf 1
                        |> Expect.equal (Just [])
            , Test.test "leaves the other Games' Scenes alone" <|
                \() ->
                    Games.seed
                        |> Games.deleteScene (seededGameId 1) (seededSceneId 1 0)
                        |> seededSceneTitlesOf 0
                        |> Expect.equal (Just [ "The Drowned Gate", "Hall of Echoes", "The Crypt Heart" ])
            , Test.test "in an unknown Game changes nothing" <|
                \() ->
                    Games.seed
                        |> Games.deleteScene (Games.gameIdFromString "no-such-game") (seededSceneId 0 0)
                        |> Expect.equal Games.seed
            , Test.test "with an unknown Scene changes nothing" <|
                \() ->
                    Games.seed
                        |> Games.deleteScene (seededGameId 0) (Games.sceneIdFromString "no-such-scene")
                        |> Expect.equal Games.seed
            , Test.test "with a Scene of another Game changes nothing" <|
                \() ->
                    Games.seed
                        |> Games.deleteScene (seededGameId 0) (seededSceneId 1 0)
                        |> Expect.equal Games.seed
            ]
        , Test.describe "telling whether a Scene is active"
            [ Test.test "is true only for the Active Scene" <|
                \() ->
                    seededGame 0
                        |> Maybe.map (\game -> List.map (Games.isActive game) (Games.scenes game))
                        |> Expect.equal (Just [ False, True, False ])
            , Test.test "is false for every Scene of a Game without an Active Scene" <|
                \() ->
                    seededGame 1
                        |> Maybe.map (\game -> List.map (Games.isActive game) (Games.scenes game))
                        |> Expect.equal (Just [ False, False ])
            , Test.test "is false for a Scene of another Game" <|
                \() ->
                    Maybe.map2 Games.isActive
                        (seededGame 1)
                        (seededGame 0 |> Maybe.andThen Games.activeScene)
                        |> Expect.equal (Just False)
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


{-| A title the tests know to be valid; an invalid one fails loudly by turning
into a title no test expects.
-}
validTitle : String -> Title.Title
validTitle raw =
    case Title.fromString raw of
        Just valid ->
            valid

        Nothing ->
            validTitle ("invalid title: " ++ raw)


distinctCount : List Games.GameId -> Int
distinctCount ids =
    ids
        |> List.map Games.gameIdToString
        |> distinctStrings


distinctStrings : List String -> Int
distinctStrings ids =
    ids
        |> List.foldl
            (\id seen ->
                if List.member id seen then
                    seen

                else
                    id :: seen
            )
            []
        |> List.length


seededGameId : Int -> Games.GameId
seededGameId index =
    seededGame index
        |> Maybe.map Games.gameId
        |> Maybe.withDefault (Games.gameIdFromString "no-such-seeded-game")


{-| The id of the Scene at `sceneIndex` of the seeded Game at `gameIndex`.
-}
seededSceneId : Int -> Int -> Games.SceneId
seededSceneId gameIndex sceneIndex =
    seededGame gameIndex
        |> Maybe.map Games.scenes
        |> Maybe.andThen (List.drop sceneIndex >> List.head)
        |> Maybe.map Games.sceneId
        |> Maybe.withDefault (Games.sceneIdFromString "no-such-seeded-scene")


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


{-| The titles of the Scenes, in `games`, of the seeded Game at this position.
-}
seededSceneTitlesOf : Int -> Games -> Maybe (List String)
seededSceneTitlesOf index games =
    Games.get (seededGameId index) games
        |> Maybe.map (Games.scenes >> List.map sceneTitle)


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
