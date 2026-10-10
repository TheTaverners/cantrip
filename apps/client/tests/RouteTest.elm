module RouteTest exposing (suite)

import Expect
import Fuzz exposing (Fuzzer)
import Route exposing (Route)
import Test exposing (Test)
import Url exposing (Url)


suite : Test
suite =
    Test.describe "Route"
        [ Test.fuzz routeFuzzer "a route survives a round-trip through its path" <|
            \route ->
                Route.toPath route
                    |> urlFromPath
                    |> Route.fromUrl
                    |> Expect.equal route
        , Test.test "an unknown path parses to NotFound" <|
            \() ->
                urlFromPath "/no/such/page"
                    |> Route.fromUrl
                    |> Expect.equal Route.NotFound
        ]


routeFuzzer : Fuzzer Route
routeFuzzer =
    Fuzz.oneOfValues [ Route.Home, Route.NotFound ]


urlFromPath : String -> Url
urlFromPath path =
    { protocol = Url.Https
    , host = "cantrip.test"
    , port_ = Nothing
    , path = path
    , query = Nothing
    , fragment = Nothing
    }
