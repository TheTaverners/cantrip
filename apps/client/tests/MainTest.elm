module MainTest exposing (suite)

import Effect exposing (Effect)
import Expect
import Games
import Main
import ProgramTest exposing (ProgramTest)
import Route
import SimulatedEffects
import Test exposing (Test)
import Test.Html.Query
import Test.Html.Selector
import TestUrl


suite : Test
suite =
    Test.describe "Main"
        [ Test.test "the home page lists the seeded Games under its own title" <|
            \() ->
                start "/"
                    |> ProgramTest.ensureView
                        (Test.Html.Query.findAll [ Test.Html.Selector.tag "li" ]
                            >> Expect.all
                                [ Test.Html.Query.count (Expect.equal 2)
                                , Test.Html.Query.index 0 >> Test.Html.Query.has [ Test.Html.Selector.text "The Sunken Crypt" ]
                                , Test.Html.Query.index 1 >> Test.Html.Query.has [ Test.Html.Selector.text "Market Day in Brindle" ]
                                ]
                        )
                    |> expectTitle "Cantrip"
        , Test.test "a Game in the list links to its Game page, under the Game's title" <|
            \() ->
                start "/"
                    |> ProgramTest.clickLink "The Sunken Crypt" (seededGamePath 0)
                    |> ProgramTest.ensureBrowserUrl (Expect.equal (TestUrl.base ++ seededGamePath 0))
                    |> ProgramTest.ensureViewHas [ Test.Html.Selector.tag "h1", Test.Html.Selector.containing [ Test.Html.Selector.text "The Sunken Crypt" ] ]
                    |> expectTitle "The Sunken Crypt · Cantrip"
        , Test.test "the Game page lists the Scenes in creation order, with a badge on the Active Scene" <|
            \() ->
                start (seededGamePath 0)
                    |> ProgramTest.expectView
                        (Test.Html.Query.findAll [ Test.Html.Selector.tag "li" ]
                            >> Expect.all
                                [ Test.Html.Query.count (Expect.equal 3)
                                , Test.Html.Query.index 0 >> Expect.all [ Test.Html.Query.has [ Test.Html.Selector.text "The Drowned Gate" ], Test.Html.Query.hasNot [ Test.Html.Selector.text "Active" ] ]
                                , Test.Html.Query.index 1 >> Test.Html.Query.has [ Test.Html.Selector.text "Hall of Echoes", Test.Html.Selector.text "Active" ]
                                , Test.Html.Query.index 2 >> Expect.all [ Test.Html.Query.has [ Test.Html.Selector.text "The Crypt Heart" ], Test.Html.Query.hasNot [ Test.Html.Selector.text "Active" ] ]
                                ]
                        )
        , Test.test "a Game page without an Active Scene shows no badge" <|
            \() ->
                start (seededGamePath 1)
                    |> ProgramTest.expectView
                        (Expect.all
                            [ Test.Html.Query.findAll [ Test.Html.Selector.tag "li" ]
                                >> Expect.all
                                    [ Test.Html.Query.count (Expect.equal 2)
                                    , Test.Html.Query.index 0 >> Test.Html.Query.has [ Test.Html.Selector.text "The Square" ]
                                    , Test.Html.Query.index 1 >> Test.Html.Query.has [ Test.Html.Selector.text "The Pickpocket's Alley" ]
                                    ]
                            , Test.Html.Query.hasNot [ Test.Html.Selector.text "Active" ]
                            ]
                        )
        , Test.test "\"← All games\" returns from a Game page to the Game list" <|
            \() ->
                start (seededGamePath 1)
                    |> ProgramTest.clickLink "← All games" "/"
                    |> ProgramTest.ensureBrowserUrl (Expect.equal (TestUrl.base ++ "/"))
                    |> ProgramTest.ensureViewHas [ Test.Html.Selector.text "Market Day in Brindle", Test.Html.Selector.text "The Sunken Crypt" ]
                    |> expectTitle "Cantrip"
        , Test.test "a Game page for an unknown Game shows the Game-not-found page under its own title" <|
            \() ->
                start (Route.toPath (Route.Game (Games.gameIdFromString "no-such-game")))
                    |> ProgramTest.ensureViewHas [ Test.Html.Selector.text "Game not found" ]
                    |> ProgramTest.ensureViewHasNot [ Test.Html.Selector.text "Page not found" ]
                    |> expectTitle "Game not found · Cantrip"
        , Test.test "\"Open player view\" opens the player view, which shows the Game title and the Active Scene title" <|
            \() ->
                start (seededGamePath 0)
                    |> ProgramTest.clickLink "Open player view" (seededPlayerPath 0)
                    |> ProgramTest.ensureBrowserUrl (Expect.equal (TestUrl.base ++ seededPlayerPath 0))
                    |> ProgramTest.ensureViewHas [ Test.Html.Selector.text "The Sunken Crypt" ]
                    |> ProgramTest.ensureViewHas [ Test.Html.Selector.tag "h1", Test.Html.Selector.containing [ Test.Html.Selector.text "Hall of Echoes" ] ]
                    |> expectTitle "The Sunken Crypt · Cantrip"
        , Test.test "the player view is pushed onto the history, so going back returns to the Game page" <|
            \() ->
                start (seededGamePath 0)
                    |> ProgramTest.clickLink "Open player view" (seededPlayerPath 0)
                    |> ProgramTest.ensureBrowserHistory (List.head >> Expect.equal (Just (TestUrl.base ++ seededGamePath 0)))
                    |> ProgramTest.routeChange (TestUrl.base ++ seededGamePath 0)
                    |> ProgramTest.ensureViewHas [ Test.Html.Selector.text "Open player view" ]
                    |> expectTitle "The Sunken Crypt · Cantrip"
        , Test.test "the player view of a Game without an Active Scene shows that the Players wait for the Game Master" <|
            \() ->
                start (seededPlayerPath 1)
                    |> ProgramTest.ensureViewHas [ Test.Html.Selector.text "Market Day in Brindle", Test.Html.Selector.text "Waiting for the Game Master…" ]
                    |> ProgramTest.ensureViewHasNot [ Test.Html.Selector.text "The Square" ]
                    |> expectTitle "Market Day in Brindle · Cantrip"
        , Test.test "the player view has no management actions and no link into Game Master mode" <|
            \() ->
                start (seededPlayerPath 0)
                    |> ProgramTest.expectView
                        (Expect.all
                            [ Test.Html.Query.findAll [ Test.Html.Selector.tag "a" ] >> Test.Html.Query.count (Expect.equal 0)
                            , Test.Html.Query.findAll [ Test.Html.Selector.tag "button" ] >> Test.Html.Query.count (Expect.equal 0)
                            , Test.Html.Query.findAll [ Test.Html.Selector.tag "input" ] >> Test.Html.Query.count (Expect.equal 0)
                            , Test.Html.Query.findAll [ Test.Html.Selector.tag "form" ] >> Test.Html.Query.count (Expect.equal 0)
                            ]
                        )
        , Test.test "the player view for an unknown Game shows the Game-not-found page under its own title" <|
            \() ->
                start (Route.toPath (Route.Play (Games.gameIdFromString "no-such-game")))
                    |> ProgramTest.ensureViewHas [ Test.Html.Selector.text "Game not found" ]
                    |> ProgramTest.ensureViewHasNot [ Test.Html.Selector.text "Page not found" ]
                    |> expectTitle "Game not found · Cantrip"
        , Test.test "an unknown URL shows the not-found page under its own title" <|
            \() ->
                start "/no/such/page"
                    |> ProgramTest.ensureViewHas [ Test.Html.Selector.text "Page not found" ]
                    |> expectTitle "Page not found · Cantrip"
        ]


start : String -> ProgramTest Main.Model Main.Msg (Effect Main.Msg)
start path =
    ProgramTest.createApplication
        { init = Main.init
        , view = Main.view
        , update = Main.update
        , onUrlRequest = Main.onUrlRequest
        , onUrlChange = Main.onUrlChange
        }
        |> ProgramTest.withBaseUrl (TestUrl.base ++ path)
        |> ProgramTest.withSimulatedEffects SimulatedEffects.simulate
        |> ProgramTest.start ()


{-| The path of the seeded Game at this position in the Game list, built
through `Route` so the tests don't depend on the id format.
-}
seededGamePath : Int -> String
seededGamePath index =
    Games.list Games.seed
        |> List.drop index
        |> List.head
        |> Maybe.map (Games.gameId >> Route.Game >> Route.toPath)
        |> Maybe.withDefault "/no-such-seeded-game"


{-| The player view path of the seeded Game at this position in the Game
list.
-}
seededPlayerPath : Int -> String
seededPlayerPath index =
    Games.list Games.seed
        |> List.drop index
        |> List.head
        |> Maybe.map (Games.gameId >> Route.Play >> Route.toPath)
        |> Maybe.withDefault "/no-such-seeded-game"


{-| elm-program-test does not expose the document title, so read it from the
document the program would render.
-}
expectTitle : String -> ProgramTest Main.Model Main.Msg effect -> Expect.Expectation
expectTitle title =
    ProgramTest.expectModel (\model -> Expect.equal title (Main.view model).title)
