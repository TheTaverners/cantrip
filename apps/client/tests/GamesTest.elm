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
