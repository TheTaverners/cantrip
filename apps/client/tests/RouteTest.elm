module RouteTest exposing (suite)

import Expect
import Fuzz exposing (Fuzzer)
import Games
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
        , Test.test "a Game page path without an id parses to NotFound" <|
            \() ->
                TestUrl.fromPath "/games/"
                    |> Route.fromUrl
                    |> Expect.equal Route.NotFound
        , Test.test "a player view path without an id parses to NotFound" <|
            \() ->
                TestUrl.fromPath "/play"
                    |> Route.fromUrl
                    |> Expect.equal Route.NotFound
        ]


routeFuzzer : Fuzzer Route
routeFuzzer =
    Fuzz.oneOf
        [ Fuzz.oneOfValues [ Route.Home, Route.NotFound ]
        , Fuzz.map (Games.gameIdFromString >> Route.Game) gameIdFuzzer
        , Fuzz.map (Games.gameIdFromString >> Route.Play) gameIdFuzzer
        ]


{-| Any non-empty string: the collection never generates an empty id.
-}
gameIdFuzzer : Fuzzer String
gameIdFuzzer =
    Fuzz.map2 String.cons Fuzz.char Fuzz.string
