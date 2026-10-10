module MainTest exposing (suite)

import Effect exposing (Effect)
import Expect
import Main
import ProgramTest exposing (ProgramTest)
import SimulatedEffects
import Test exposing (Test)
import Test.Html.Selector


suite : Test
suite =
    Test.describe "Main"
        [ Test.test "the home page says Hello, World under its own title" <|
            \() ->
                start "/"
                    |> ProgramTest.ensureViewHas [ Test.Html.Selector.text "Hello, World" ]
                    |> expectTitle "Cantrip"
        , Test.test "an unknown URL shows the not-found page under its own title" <|
            \() ->
                start "/no/such/page"
                    |> ProgramTest.ensureViewHas [ Test.Html.Selector.text "Page not found" ]
                    |> expectTitle "Page not found · Cantrip"
        , Test.test "following the home page link leads to the not-found page" <|
            \() ->
                start "/"
                    |> ProgramTest.clickLink "Wander off the map" "/not-found"
                    |> ProgramTest.ensureBrowserUrl (Expect.equal "https://cantrip.test/not-found")
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
        |> ProgramTest.withBaseUrl ("https://cantrip.test" ++ path)
        |> ProgramTest.withSimulatedEffects SimulatedEffects.simulate
        |> ProgramTest.start ()


{-| elm-program-test does not expose the document title, so read it from the
document the program would render.
-}
expectTitle : String -> ProgramTest Main.Model Main.Msg effect -> Expect.Expectation
expectTitle title =
    ProgramTest.expectModel (\model -> Expect.equal title (Main.view model).title)
