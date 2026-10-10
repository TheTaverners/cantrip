module Route exposing (Route(..), fromUrl, toPath)

{-| The client's pages, as addresses: parse a `Url` into a `Route` and
serialize a `Route` back into a path.
-}

import Url exposing (Url)
import Url.Parser exposing (Parser)


type Route
    = Home
    | NotFound


{-| Unknown paths parse to `NotFound`.
-}
fromUrl : Url -> Route
fromUrl url =
    Url.Parser.parse parser url
        |> Maybe.withDefault NotFound


toPath : Route -> String
toPath route =
    case route of
        Home ->
            "/"

        NotFound ->
            "/not-found"


parser : Parser (Route -> a) a
parser =
    Url.Parser.oneOf
        [ Url.Parser.map Home Url.Parser.top
        ]
