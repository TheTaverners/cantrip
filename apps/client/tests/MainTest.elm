module MainTest exposing (suite)

import Effect exposing (Effect)
import Expect
import Main
import ProgramTest exposing (ProgramTest)
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


{-| elm-program-test does not expose the document title, so read it from the
document the program would render.
-}
expectTitle : String -> ProgramTest Main.Model Main.Msg effect -> Expect.Expectation
expectTitle title =
    ProgramTest.expectModel (\model -> Expect.equal title (Main.view model).title)
