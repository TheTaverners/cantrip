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
        , Test.describe "creating a Scene" creatingAScene
        , Test.describe "renaming a Scene" renamingAScene
        , Test.describe "deleting a Scene" deletingAScene
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
        , Test.test "each non-active Scene offers \"Make active\", and the Active Scene shows only the badge" <|
            \() ->
                start (seededGamePath 0)
                    |> ProgramTest.expectView
                        (Test.Html.Query.findAll [ Test.Html.Selector.tag "li" ]
                            >> Expect.all
                                [ Test.Html.Query.index 0 >> Test.Html.Query.has [ makeActiveButton ]
                                , Test.Html.Query.index 1 >> Expect.all [ Test.Html.Query.has [ Test.Html.Selector.text "Active" ], Test.Html.Query.hasNot [ makeActiveButton ] ]
                                , Test.Html.Query.index 2 >> Test.Html.Query.has [ makeActiveButton ]
                                ]
                        )
        , Test.test "making a Scene active moves the badge to it from the previous Active Scene" <|
            \() ->
                start (seededGamePath 0)
                    |> makeSceneActive "The Crypt Heart"
                    |> ProgramTest.expectView
                        (Test.Html.Query.findAll [ Test.Html.Selector.tag "li" ]
                            >> Expect.all
                                [ Test.Html.Query.index 0 >> Expect.all [ Test.Html.Query.hasNot [ Test.Html.Selector.text "Active" ], Test.Html.Query.has [ makeActiveButton ] ]
                                , Test.Html.Query.index 1 >> Expect.all [ Test.Html.Query.hasNot [ Test.Html.Selector.text "Active" ], Test.Html.Query.has [ makeActiveButton ] ]
                                , Test.Html.Query.index 2 >> Expect.all [ Test.Html.Query.has [ Test.Html.Selector.text "Active" ], Test.Html.Query.hasNot [ makeActiveButton ] ]
                                ]
                        )
        , Test.test "after making a Scene active, the player view shows it" <|
            \() ->
                start (seededGamePath 0)
                    |> makeSceneActive "The Drowned Gate"
                    |> ProgramTest.clickLink "Open player view" (seededPlayerPath 0)
                    |> ProgramTest.ensureViewHas [ Test.Html.Selector.tag "h1", Test.Html.Selector.containing [ Test.Html.Selector.text "The Drowned Gate" ] ]
                    |> ProgramTest.expectViewHasNot [ Test.Html.Selector.text "Hall of Echoes" ]
        , Test.test "after making a Scene active on a Game that had no Active Scene, the player view shows it instead of waiting" <|
            \() ->
                start (seededGamePath 1)
                    |> makeSceneActive "The Pickpocket's Alley"
                    |> ProgramTest.clickLink "Open player view" (seededPlayerPath 1)
                    |> ProgramTest.ensureViewHas [ Test.Html.Selector.tag "h1", Test.Html.Selector.containing [ Test.Html.Selector.text "The Pickpocket's Alley" ] ]
                    |> ProgramTest.expectViewHasNot [ Test.Html.Selector.text "Waiting for the Game Master…" ]
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


creatingAGame : List Test
creatingAGame =
    [ Test.test "adds it, trimmed, at the end of the list, and clears the field" <|
        \() ->
            start "/"
                |> createGame "  The Frozen Keep  "
                |> ProgramTest.ensureView (expectRowTitles [ "The Sunken Crypt", "Market Day in Brindle", "The Frozen Keep" ])
                |> ProgramTest.expectView (Test.Html.Query.find [ newGameField ] >> Test.Html.Query.has [ Test.Html.Selector.attribute (Html.Attributes.value "") ])
    , Test.test "with a whitespace-only title adds nothing and says it was refused" <|
        \() ->
            start "/"
                |> createGame "   "
                |> ProgramTest.ensureView (expectRowTitles [ "The Sunken Crypt", "Market Day in Brindle" ])
                |> ProgramTest.expectViewHas [ Test.Html.Selector.text "A title can't be empty." ]
    , Test.test "with an empty title adds nothing and says it was refused" <|
        \() ->
            start "/"
                |> ProgramTest.clickButton "Create"
                |> ProgramTest.ensureView (expectRowTitles [ "The Sunken Crypt", "Market Day in Brindle" ])
                |> ProgramTest.expectViewHas [ Test.Html.Selector.text "A title can't be empty." ]
    , Test.test "with a title another Game has adds a second Game" <|
        \() ->
            start "/"
                |> createGame "The Sunken Crypt"
                |> ProgramTest.expectView (expectRowTitles [ "The Sunken Crypt", "Market Day in Brindle", "The Sunken Crypt" ])
    ]


renamingAGame : List Test
renamingAGame =
    [ Test.test "updates its title in the list, trimmed, and on its Game page" <|
        \() ->
            start "/"
                |> withinRow 0 (ProgramTest.clickButton "Rename")
                |> ProgramTest.fillIn "" "Title" "  The Risen Crypt "
                |> ProgramTest.clickButton "Save"
                |> ProgramTest.ensureView (expectRowTitles [ "The Risen Crypt", "Market Day in Brindle" ])
                |> ProgramTest.clickLink "The Risen Crypt" (seededGamePath 0)
                |> ProgramTest.ensureViewHas [ Test.Html.Selector.tag "h1", Test.Html.Selector.containing [ Test.Html.Selector.text "The Risen Crypt" ] ]
                |> expectTitle "The Risen Crypt · Cantrip"
    , Test.test "starts from the current title" <|
        \() ->
            start "/"
                |> withinRow 1 (ProgramTest.clickButton "Rename")
                |> ProgramTest.expectView
                    (Test.Html.Query.find [ Test.Html.Selector.attribute (Html.Attributes.attribute "aria-label" "Title") ]
                        >> Test.Html.Query.has [ Test.Html.Selector.attribute (Html.Attributes.value "Market Day in Brindle") ]
                    )
    , Test.test "cancelled keeps the old title" <|
        \() ->
            start "/"
                |> withinRow 0 (ProgramTest.clickButton "Rename")
                |> ProgramTest.fillIn "" "Title" "The Risen Crypt"
                |> ProgramTest.clickButton "Cancel"
                |> ProgramTest.ensureViewHasNot [ Test.Html.Selector.text "The Risen Crypt" ]
                |> ProgramTest.expectView (expectRowTitles [ "The Sunken Crypt", "Market Day in Brindle" ])
    , Test.test "to a whitespace-only title is refused and keeps the old title" <|
        \() ->
            start "/"
                |> withinRow 0 (ProgramTest.clickButton "Rename")
                |> ProgramTest.fillIn "" "Title" "  "
                |> ProgramTest.clickButton "Save"
                |> ProgramTest.ensureViewHas [ Test.Html.Selector.text "A title can't be empty." ]
                |> ProgramTest.clickButton "Cancel"
                |> ProgramTest.expectView (expectRowTitles [ "The Sunken Crypt", "Market Day in Brindle" ])
    ]


deletingAGame : List Test
deletingAGame =
    [ Test.test "asks \"Delete? Yes / Cancel\" first" <|
        \() ->
            start "/"
                |> withinRow 0 (ProgramTest.clickButton "Delete")
                |> ProgramTest.ensureView (expectRowTitles [ "The Sunken Crypt", "Market Day in Brindle" ])
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
                |> withinRow 0 (ProgramTest.clickButton "Delete")
                |> ProgramTest.clickButton "Cancel"
                |> ProgramTest.ensureViewHasNot [ Test.Html.Selector.text "Delete?" ]
                |> ProgramTest.expectView (expectRowTitles [ "The Sunken Crypt", "Market Day in Brindle" ])
    , Test.test "confirmed removes the Game" <|
        \() ->
            start "/"
                |> withinRow 0 (ProgramTest.clickButton "Delete")
                |> ProgramTest.clickButton "Yes"
                |> ProgramTest.expectView (expectRowTitles [ "Market Day in Brindle" ])
    , Test.test "makes its Game page show \"Game not found\"" <|
        \() ->
            start "/"
                |> withinRow 0 (ProgramTest.clickButton "Delete")
                |> ProgramTest.clickButton "Yes"
                |> ProgramTest.routeChange (TestUrl.base ++ seededGamePath 0)
                |> ProgramTest.ensureViewHas [ Test.Html.Selector.text "Game not found" ]
                |> expectTitle "Game not found · Cantrip"
    , Test.test "makes its player view show \"Game not found\"" <|
        \() ->
            start "/"
                |> withinRow 0 (ProgramTest.clickButton "Delete")
                |> ProgramTest.clickButton "Yes"
                |> ProgramTest.routeChange (TestUrl.base ++ seededPlayerPath 0)
                |> ProgramTest.ensureViewHas [ Test.Html.Selector.text "Game not found" ]
                |> expectTitle "Game not found · Cantrip"
    , Test.test "of every Game shows \"No games yet\"" <|
        \() ->
            start "/"
                |> withinRow 0 (ProgramTest.clickButton "Delete")
                |> ProgramTest.clickButton "Yes"
                |> withinRow 0 (ProgramTest.clickButton "Delete")
                |> ProgramTest.clickButton "Yes"
                |> ProgramTest.expectViewHas [ Test.Html.Selector.text "No games yet" ]
    ]


navigatingAwayAndBack : List Test
navigatingAwayAndBack =
    [ Test.test "keeps the Games created, renamed and deleted" <|
        \() ->
            start "/"
                |> createGame "The Frozen Keep"
                |> withinRow 0 (ProgramTest.clickButton "Rename")
                |> ProgramTest.fillIn "" "Title" "The Risen Crypt"
                |> ProgramTest.clickButton "Save"
                |> withinRow 1 (ProgramTest.clickButton "Delete")
                |> ProgramTest.clickButton "Yes"
                |> ProgramTest.clickLink "The Risen Crypt" (seededGamePath 0)
                |> ProgramTest.ensureViewHas [ Test.Html.Selector.tag "h1", Test.Html.Selector.containing [ Test.Html.Selector.text "The Risen Crypt" ] ]
                |> ProgramTest.clickLink "← All games" "/"
                |> ProgramTest.expectView (expectRowTitles [ "The Risen Crypt", "The Frozen Keep" ])
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
                |> withinRow 0 (ProgramTest.clickButton "Rename")
                |> ProgramTest.clickLink "Market Day in Brindle" (seededGamePath 1)
                |> ProgramTest.clickLink "← All games" "/"
                |> ProgramTest.ensureViewHasNot [ Test.Html.Selector.attribute (Html.Attributes.attribute "aria-label" "Title") ]
                |> ProgramTest.expectView (expectRowTitles [ "The Sunken Crypt", "Market Day in Brindle" ])
    , Test.test "resets a pending confirmation" <|
        \() ->
            start "/"
                |> withinRow 0 (ProgramTest.clickButton "Delete")
                |> ProgramTest.clickLink "Market Day in Brindle" (seededGamePath 1)
                |> ProgramTest.clickLink "← All games" "/"
                |> ProgramTest.expectViewHasNot [ Test.Html.Selector.text "Delete?" ]
    ]


creatingAScene : List Test
creatingAScene =
    [ Test.test "adds it, trimmed, at the end of the Game's Scenes, and clears the field" <|
        \() ->
            start (seededGamePath 1)
                |> createScene "  The Town Hall  "
                |> ProgramTest.ensureView (expectRowTitles [ "The Square", "The Pickpocket's Alley", "The Town Hall" ])
                |> ProgramTest.expectView (Test.Html.Query.find [ newSceneField ] >> Test.Html.Query.has [ Test.Html.Selector.attribute (Html.Attributes.value "") ])
    , Test.test "with a whitespace-only title adds nothing and says it was refused" <|
        \() ->
            start (seededGamePath 1)
                |> createScene "   "
                |> ProgramTest.ensureView (expectRowTitles [ "The Square", "The Pickpocket's Alley" ])
                |> ProgramTest.expectViewHas [ Test.Html.Selector.text "A title can't be empty." ]
    , Test.test "with an empty title adds nothing and says it was refused" <|
        \() ->
            start (seededGamePath 1)
                |> ProgramTest.clickButton "Create"
                |> ProgramTest.ensureView (expectRowTitles [ "The Square", "The Pickpocket's Alley" ])
                |> ProgramTest.expectViewHas [ Test.Html.Selector.text "A title can't be empty." ]
    , Test.test "with a title another Scene of the Game has adds a second Scene" <|
        \() ->
            start (seededGamePath 1)
                |> createScene "The Square"
                |> ProgramTest.expectView (expectRowTitles [ "The Square", "The Pickpocket's Alley", "The Square" ])
    , Test.test "doesn't make it active, even when the Game has no Active Scene" <|
        \() ->
            start (seededGamePath 1)
                |> createScene "The Town Hall"
                |> ProgramTest.ensureViewHasNot [ Test.Html.Selector.text "Active" ]
                |> ProgramTest.clickLink "Open player view" (seededPlayerPath 1)
                |> ProgramTest.expectViewHas [ Test.Html.Selector.text "Waiting for the Game Master…" ]
    , Test.test "doesn't affect another Game's Scenes" <|
        \() ->
            start (seededGamePath 1)
                |> createScene "The Town Hall"
                |> ProgramTest.routeChange (TestUrl.base ++ seededGamePath 0)
                |> ProgramTest.expectView (expectRowTitles [ "The Drowned Gate", "Hall of Echoes", "The Crypt Heart" ])
    , Test.test "survives navigating away and back, and the draft is reset" <|
        \() ->
            start (seededGamePath 1)
                |> createScene "The Town Hall"
                |> ProgramTest.fillIn "" "New scene title" "The Bell Tower"
                |> ProgramTest.clickLink "← All games" "/"
                |> ProgramTest.clickLink "Market Day in Brindle" (seededGamePath 1)
                |> ProgramTest.ensureView (expectRowTitles [ "The Square", "The Pickpocket's Alley", "The Town Hall" ])
                |> ProgramTest.expectView (Test.Html.Query.find [ newSceneField ] >> Test.Html.Query.has [ Test.Html.Selector.attribute (Html.Attributes.value "") ])
    ]


renamingAScene : List Test
renamingAScene =
    [ Test.test "updates its title, trimmed, and starts from the current title" <|
        \() ->
            start (seededGamePath 0)
                |> withinRow 0 (ProgramTest.clickButton "Rename")
                |> ProgramTest.ensureView
                    (Test.Html.Query.find [ Test.Html.Selector.attribute (Html.Attributes.attribute "aria-label" "Title") ]
                        >> Test.Html.Query.has [ Test.Html.Selector.attribute (Html.Attributes.value "The Drowned Gate") ]
                    )
                |> ProgramTest.fillIn "" "Title" "  The Flooded Gate "
                |> ProgramTest.clickButton "Save"
                |> ProgramTest.expectView (expectRowTitles [ "The Flooded Gate", "Hall of Echoes", "The Crypt Heart" ])
    , Test.test "cancelled keeps the old title" <|
        \() ->
            start (seededGamePath 0)
                |> withinRow 0 (ProgramTest.clickButton "Rename")
                |> ProgramTest.fillIn "" "Title" "The Flooded Gate"
                |> ProgramTest.clickButton "Cancel"
                |> ProgramTest.ensureViewHasNot [ Test.Html.Selector.text "The Flooded Gate" ]
                |> ProgramTest.expectView (expectRowTitles [ "The Drowned Gate", "Hall of Echoes", "The Crypt Heart" ])
    , Test.test "to a whitespace-only title is refused and keeps the old title" <|
        \() ->
            start (seededGamePath 0)
                |> withinRow 0 (ProgramTest.clickButton "Rename")
                |> ProgramTest.fillIn "" "Title" "  "
                |> ProgramTest.clickButton "Save"
                |> ProgramTest.ensureViewHas [ Test.Html.Selector.text "A title can't be empty." ]
                |> ProgramTest.clickButton "Cancel"
                |> ProgramTest.expectView (expectRowTitles [ "The Drowned Gate", "Hall of Echoes", "The Crypt Heart" ])
    , Test.test "of the Active Scene changes what the player view shows" <|
        \() ->
            start (seededGamePath 0)
                |> withinRow 1 (ProgramTest.clickButton "Rename")
                |> ProgramTest.fillIn "" "Title" "Hall of Whispers"
                |> ProgramTest.clickButton "Save"
                |> ProgramTest.ensureView (Test.Html.Query.findAll [ Test.Html.Selector.tag "li" ] >> Test.Html.Query.index 1 >> Test.Html.Query.has [ Test.Html.Selector.text "Hall of Whispers", Test.Html.Selector.text "Active" ])
                |> ProgramTest.clickLink "Open player view" (seededPlayerPath 0)
                |> ProgramTest.ensureViewHas [ Test.Html.Selector.tag "h1", Test.Html.Selector.containing [ Test.Html.Selector.text "Hall of Whispers" ] ]
                |> ProgramTest.expectViewHasNot [ Test.Html.Selector.text "Hall of Echoes" ]
    ]


deletingAScene : List Test
deletingAScene =
    [ Test.test "asks \"Delete? Yes / Cancel\" first" <|
        \() ->
            start (seededGamePath 0)
                |> withinRow 0 (ProgramTest.clickButton "Delete")
                |> ProgramTest.ensureView (expectRowTitles [ "The Drowned Gate", "Hall of Echoes", "The Crypt Heart" ])
                |> ProgramTest.expectView
                    (Test.Html.Query.findAll [ Test.Html.Selector.tag "li" ]
                        >> Test.Html.Query.index 0
                        >> Test.Html.Query.has
                            [ Test.Html.Selector.text "Delete?"
                            , Test.Html.Selector.containing [ Test.Html.Selector.tag "button", Test.Html.Selector.containing [ Test.Html.Selector.text "Yes" ] ]
                            , Test.Html.Selector.containing [ Test.Html.Selector.tag "button", Test.Html.Selector.containing [ Test.Html.Selector.text "Cancel" ] ]
                            ]
                    )
    , Test.test "cancelled keeps the Scene" <|
        \() ->
            start (seededGamePath 0)
                |> withinRow 0 (ProgramTest.clickButton "Delete")
                |> ProgramTest.clickButton "Cancel"
                |> ProgramTest.ensureViewHasNot [ Test.Html.Selector.text "Delete?" ]
                |> ProgramTest.expectView (expectRowTitles [ "The Drowned Gate", "Hall of Echoes", "The Crypt Heart" ])
    , Test.test "confirmed removes the Scene" <|
        \() ->
            start (seededGamePath 0)
                |> withinRow 0 (ProgramTest.clickButton "Delete")
                |> ProgramTest.clickButton "Yes"
                |> ProgramTest.expectView (expectRowTitles [ "Hall of Echoes", "The Crypt Heart" ])
    , Test.test "of the Active Scene removes the badge, and the player view waits for the Game Master" <|
        \() ->
            start (seededGamePath 0)
                |> withinRow 1 (ProgramTest.clickButton "Delete")
                |> ProgramTest.clickButton "Yes"
                |> ProgramTest.ensureView (expectRowTitles [ "The Drowned Gate", "The Crypt Heart" ])
                |> ProgramTest.ensureViewHasNot [ Test.Html.Selector.text "Active" ]
                |> ProgramTest.clickLink "Open player view" (seededPlayerPath 0)
                |> ProgramTest.expectViewHas [ Test.Html.Selector.text "Waiting for the Game Master…" ]
    , Test.test "of every Scene shows \"No scenes yet\"" <|
        \() ->
            start (seededGamePath 1)
                |> withinRow 0 (ProgramTest.clickButton "Delete")
                |> ProgramTest.clickButton "Yes"
                |> withinRow 0 (ProgramTest.clickButton "Delete")
                |> ProgramTest.clickButton "Yes"
                |> ProgramTest.ensureView (Test.Html.Query.findAll [ Test.Html.Selector.tag "li" ] >> Test.Html.Query.count (Expect.equal 0))
                |> ProgramTest.expectViewHas [ Test.Html.Selector.text "No scenes yet" ]
    , Test.test "doesn't affect another Game's Scenes" <|
        \() ->
            start (seededGamePath 0)
                |> withinRow 1 (ProgramTest.clickButton "Delete")
                |> ProgramTest.clickButton "Yes"
                |> ProgramTest.routeChange (TestUrl.base ++ seededGamePath 1)
                |> ProgramTest.expectView (expectRowTitles [ "The Square", "The Pickpocket's Alley" ])
    , Test.test "a pending confirmation is reset by navigating away and back" <|
        \() ->
            start (seededGamePath 0)
                |> withinRow 0 (ProgramTest.clickButton "Delete")
                |> ProgramTest.clickLink "← All games" "/"
                |> ProgramTest.clickLink "The Sunken Crypt" (seededGamePath 0)
                |> ProgramTest.expectViewHasNot [ Test.Html.Selector.text "Delete?" ]
    ]


{-| Act within the list's row (a Game or a Scene) at this position.
-}
withinRow : Int -> (ProgramTest model msg effect -> ProgramTest model msg effect) -> ProgramTest model msg effect -> ProgramTest model msg effect
withinRow index =
    ProgramTest.within (Test.Html.Query.findAll [ Test.Html.Selector.tag "li" ] >> Test.Html.Query.index index)


{-| The titles of the list's rows (Games or Scenes), in order.
-}
expectRowTitles : List String -> Test.Html.Query.Single msg -> Expect.Expectation
expectRowTitles titles =
    Test.Html.Query.findAll [ Test.Html.Selector.tag "li" ]
        >> Expect.all
            (Test.Html.Query.count (Expect.equal (List.length titles))
                :: List.indexedMap (\index title -> Test.Html.Query.index index >> Test.Html.Query.has [ Test.Html.Selector.text title ]) titles
            )


newGameField : Test.Html.Selector.Selector
newGameField =
    Test.Html.Selector.attribute (Html.Attributes.attribute "aria-label" "New game title")


newSceneField : Test.Html.Selector.Selector
newSceneField =
    Test.Html.Selector.attribute (Html.Attributes.attribute "aria-label" "New scene title")


createScene : String -> ProgramTest Main.Model Main.Msg effect -> ProgramTest Main.Model Main.Msg effect
createScene title =
    ProgramTest.fillIn "" "New scene title" title
        >> ProgramTest.clickButton "Create"


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


{-| Click "Make active" in the row of the Scene with this title.
-}
makeSceneActive : String -> ProgramTest model msg effect -> ProgramTest model msg effect
makeSceneActive sceneTitle =
    ProgramTest.within
        (Test.Html.Query.find [ Test.Html.Selector.tag "li", Test.Html.Selector.containing [ Test.Html.Selector.text sceneTitle ] ])
        (ProgramTest.clickButton "Make active")


makeActiveButton : Test.Html.Selector.Selector
makeActiveButton =
    Test.Html.Selector.all [ Test.Html.Selector.tag "button", Test.Html.Selector.containing [ Test.Html.Selector.text "Make active" ] ]


{-| elm-program-test does not expose the document title, so read it from the
document the program would render.
-}
expectTitle : String -> ProgramTest Main.Model Main.Msg effect -> Expect.Expectation
expectTitle title =
    ProgramTest.expectModel (\model -> Expect.equal title (Main.view model).title)
