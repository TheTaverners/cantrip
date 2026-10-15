module MainTest exposing (suite)

import Effect exposing (Effect)
import Expect
import Games
import Html.Attributes
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
        , Test.describe "creating a Game" creatingAGame
        , Test.describe "renaming a Game" renamingAGame
        , Test.describe "deleting a Game" deletingAGame
        , Test.describe "navigating away and back" navigatingAwayAndBack
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
        , Test.test "an unknown URL shows the not-found page under its own title" <|
            \() ->
                start "/no/such/page"
                    |> ProgramTest.ensureViewHas [ Test.Html.Selector.text "Page not found" ]
                    |> expectTitle "Page not found · Cantrip"
        ]


creatingAGame : List Test
creatingAGame =
    [ Test.test "adds it, trimmed, at the end of the list, and clears the field" <|
        \() ->
            start "/"
                |> createGame "  The Frozen Keep  "
                |> ProgramTest.ensureView (expectGameTitles [ "The Sunken Crypt", "Market Day in Brindle", "The Frozen Keep" ])
                |> ProgramTest.expectView (Test.Html.Query.find [ newGameField ] >> Test.Html.Query.has [ Test.Html.Selector.attribute (Html.Attributes.value "") ])
    , Test.test "with a whitespace-only title adds nothing and says it was refused" <|
        \() ->
            start "/"
                |> createGame "   "
                |> ProgramTest.ensureView (expectGameTitles [ "The Sunken Crypt", "Market Day in Brindle" ])
                |> ProgramTest.expectViewHas [ Test.Html.Selector.text "A title can't be empty." ]
    , Test.test "with an empty title adds nothing and says it was refused" <|
        \() ->
            start "/"
                |> ProgramTest.clickButton "Create"
                |> ProgramTest.ensureView (expectGameTitles [ "The Sunken Crypt", "Market Day in Brindle" ])
                |> ProgramTest.expectViewHas [ Test.Html.Selector.text "A title can't be empty." ]
    , Test.test "with a title another Game has adds a second Game" <|
        \() ->
            start "/"
                |> createGame "The Sunken Crypt"
                |> ProgramTest.expectView (expectGameTitles [ "The Sunken Crypt", "Market Day in Brindle", "The Sunken Crypt" ])
    ]


renamingAGame : List Test
renamingAGame =
    [ Test.test "updates its title in the list, trimmed, and on its Game page" <|
        \() ->
            start "/"
                |> withinGameRow 0 (ProgramTest.clickButton "Rename")
                |> ProgramTest.fillIn "" "Title" "  The Risen Crypt "
                |> ProgramTest.clickButton "Save"
                |> ProgramTest.ensureView (expectGameTitles [ "The Risen Crypt", "Market Day in Brindle" ])
                |> ProgramTest.clickLink "The Risen Crypt" (seededGamePath 0)
                |> ProgramTest.ensureViewHas [ Test.Html.Selector.tag "h1", Test.Html.Selector.containing [ Test.Html.Selector.text "The Risen Crypt" ] ]
                |> expectTitle "The Risen Crypt · Cantrip"
    , Test.test "starts from the current title" <|
        \() ->
            start "/"
                |> withinGameRow 1 (ProgramTest.clickButton "Rename")
                |> ProgramTest.expectView
                    (Test.Html.Query.find [ Test.Html.Selector.attribute (Html.Attributes.attribute "aria-label" "Title") ]
                        >> Test.Html.Query.has [ Test.Html.Selector.attribute (Html.Attributes.value "Market Day in Brindle") ]
                    )
    , Test.test "cancelled keeps the old title" <|
        \() ->
            start "/"
                |> withinGameRow 0 (ProgramTest.clickButton "Rename")
                |> ProgramTest.fillIn "" "Title" "The Risen Crypt"
                |> ProgramTest.clickButton "Cancel"
                |> ProgramTest.ensureViewHasNot [ Test.Html.Selector.text "The Risen Crypt" ]
                |> ProgramTest.expectView (expectGameTitles [ "The Sunken Crypt", "Market Day in Brindle" ])
    , Test.test "to a whitespace-only title is refused and keeps the old title" <|
        \() ->
            start "/"
                |> withinGameRow 0 (ProgramTest.clickButton "Rename")
                |> ProgramTest.fillIn "" "Title" "  "
                |> ProgramTest.clickButton "Save"
                |> ProgramTest.ensureViewHas [ Test.Html.Selector.text "A title can't be empty." ]
                |> ProgramTest.clickButton "Cancel"
                |> ProgramTest.expectView (expectGameTitles [ "The Sunken Crypt", "Market Day in Brindle" ])
    ]


deletingAGame : List Test
deletingAGame =
    [ Test.test "asks \"Delete? Yes / Cancel\" first" <|
        \() ->
            start "/"
                |> withinGameRow 0 (ProgramTest.clickButton "Delete")
                |> ProgramTest.ensureView (expectGameTitles [ "The Sunken Crypt", "Market Day in Brindle" ])
                |> ProgramTest.expectView
                    (Test.Html.Query.findAll [ Test.Html.Selector.tag "li" ]
                        >> Test.Html.Query.index 0
                        >> Test.Html.Query.has
                            [ Test.Html.Selector.text "Delete?"
                            , Test.Html.Selector.containing [ Test.Html.Selector.tag "button", Test.Html.Selector.containing [ Test.Html.Selector.text "Yes" ] ]
                            , Test.Html.Selector.containing [ Test.Html.Selector.tag "button", Test.Html.Selector.containing [ Test.Html.Selector.text "Cancel" ] ]
                            ]
                    )
    , Test.test "cancelled keeps the Game" <|
        \() ->
            start "/"
                |> withinGameRow 0 (ProgramTest.clickButton "Delete")
                |> ProgramTest.clickButton "Cancel"
                |> ProgramTest.ensureViewHasNot [ Test.Html.Selector.text "Delete?" ]
                |> ProgramTest.expectView (expectGameTitles [ "The Sunken Crypt", "Market Day in Brindle" ])
    , Test.test "confirmed removes the Game" <|
        \() ->
            start "/"
                |> withinGameRow 0 (ProgramTest.clickButton "Delete")
                |> ProgramTest.clickButton "Yes"
                |> ProgramTest.expectView (expectGameTitles [ "Market Day in Brindle" ])
    , Test.test "makes its Game page show \"Game not found\"" <|
        \() ->
            start "/"
                |> withinGameRow 0 (ProgramTest.clickButton "Delete")
                |> ProgramTest.clickButton "Yes"
                |> ProgramTest.routeChange (TestUrl.base ++ seededGamePath 0)
                |> ProgramTest.ensureViewHas [ Test.Html.Selector.text "Game not found" ]
                |> expectTitle "Game not found · Cantrip"
    , Test.test "of every Game shows \"No games yet\"" <|
        \() ->
            start "/"
                |> withinGameRow 0 (ProgramTest.clickButton "Delete")
                |> ProgramTest.clickButton "Yes"
                |> withinGameRow 0 (ProgramTest.clickButton "Delete")
                |> ProgramTest.clickButton "Yes"
                |> ProgramTest.expectViewHas [ Test.Html.Selector.text "No games yet" ]
    ]


navigatingAwayAndBack : List Test
navigatingAwayAndBack =
    [ Test.test "keeps the Games created, renamed and deleted" <|
        \() ->
            start "/"
                |> createGame "The Frozen Keep"
                |> withinGameRow 0 (ProgramTest.clickButton "Rename")
                |> ProgramTest.fillIn "" "Title" "The Risen Crypt"
                |> ProgramTest.clickButton "Save"
                |> withinGameRow 1 (ProgramTest.clickButton "Delete")
                |> ProgramTest.clickButton "Yes"
                |> ProgramTest.clickLink "The Risen Crypt" (seededGamePath 0)
                |> ProgramTest.ensureViewHas [ Test.Html.Selector.tag "h1", Test.Html.Selector.containing [ Test.Html.Selector.text "The Risen Crypt" ] ]
                |> ProgramTest.clickLink "← All games" "/"
                |> ProgramTest.expectView (expectGameTitles [ "The Risen Crypt", "The Frozen Keep" ])
    , Test.test "resets the create draft" <|
        \() ->
            start "/"
                |> ProgramTest.fillIn "" "New game title" "The Frozen Keep"
                |> ProgramTest.clickLink "Market Day in Brindle" (seededGamePath 1)
                |> ProgramTest.clickLink "← All games" "/"
                |> ProgramTest.expectView (Test.Html.Query.find [ newGameField ] >> Test.Html.Query.has [ Test.Html.Selector.attribute (Html.Attributes.value "") ])
    , Test.test "resets a refused creation" <|
        \() ->
            start "/"
                |> ProgramTest.clickButton "Create"
                |> ProgramTest.clickLink "Market Day in Brindle" (seededGamePath 1)
                |> ProgramTest.clickLink "← All games" "/"
                |> ProgramTest.expectViewHasNot [ Test.Html.Selector.text "A title can't be empty." ]
    , Test.test "resets the row being renamed" <|
        \() ->
            start "/"
                |> withinGameRow 0 (ProgramTest.clickButton "Rename")
                |> ProgramTest.clickLink "Market Day in Brindle" (seededGamePath 1)
                |> ProgramTest.clickLink "← All games" "/"
                |> ProgramTest.ensureViewHasNot [ Test.Html.Selector.attribute (Html.Attributes.attribute "aria-label" "Title") ]
                |> ProgramTest.expectView (expectGameTitles [ "The Sunken Crypt", "Market Day in Brindle" ])
    , Test.test "resets a pending confirmation" <|
        \() ->
            start "/"
                |> withinGameRow 0 (ProgramTest.clickButton "Delete")
                |> ProgramTest.clickLink "Market Day in Brindle" (seededGamePath 1)
                |> ProgramTest.clickLink "← All games" "/"
                |> ProgramTest.expectViewHasNot [ Test.Html.Selector.text "Delete?" ]
    ]


withinGameRow : Int -> (ProgramTest model msg effect -> ProgramTest model msg effect) -> ProgramTest model msg effect -> ProgramTest model msg effect
withinGameRow index =
    ProgramTest.within (Test.Html.Query.findAll [ Test.Html.Selector.tag "li" ] >> Test.Html.Query.index index)


{-| The titles of the Games in the list, in order.
-}
expectGameTitles : List String -> Test.Html.Query.Single msg -> Expect.Expectation
expectGameTitles titles =
    Test.Html.Query.findAll [ Test.Html.Selector.tag "li" ]
        >> Expect.all
            (Test.Html.Query.count (Expect.equal (List.length titles))
                :: List.indexedMap (\index title -> Test.Html.Query.index index >> Test.Html.Query.has [ Test.Html.Selector.text title ]) titles
            )


newGameField : Test.Html.Selector.Selector
newGameField =
    Test.Html.Selector.attribute (Html.Attributes.attribute "aria-label" "New game title")


createGame : String -> ProgramTest Main.Model Main.Msg effect -> ProgramTest Main.Model Main.Msg effect
createGame title =
    ProgramTest.fillIn "" "New game title" title
        >> ProgramTest.clickButton "Create"


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


{-| elm-program-test does not expose the document title, so read it from the
document the program would render.
-}
expectTitle : String -> ProgramTest Main.Model Main.Msg effect -> Expect.Expectation
expectTitle title =
    ProgramTest.expectModel (\model -> Expect.equal title (Main.view model).title)
