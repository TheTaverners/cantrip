module RouteTest exposing (suite)

import Expect
import Fuzz exposing (Fuzzer)
import Route exposing (Route)
import Test exposing (Test)
import TestUrl


suite : Test
suite =
    Test.describe "Route"
        [ Test.fuzz routeFuzzer "a route survives a round-trip through its path" <|
            \route ->
                Route.toPath route
                    |> TestUrl.fromPath
                    |> Route.fromUrl
                    |> Expect.equal route
        , Test.test "an unknown path parses to NotFound" <|
            \() ->
                TestUrl.fromPath "/no/such/page"
                    |> Route.fromUrl
                    |> Expect.equal Route.NotFound
        ]


routeFuzzer : Fuzzer Route
routeFuzzer =
    Fuzz.oneOfValues [ Route.Home, Route.NotFound ]
