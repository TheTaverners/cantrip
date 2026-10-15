module Route exposing (Route(..), fromUrl, toPath)

{-| The client's pages, as addresses: parse a `Url` into a `Route` and
serialize a `Route` back into a path.
-}

import Games exposing (GameId)
import Url exposing (Url)
import Url.Builder
import Url.Parser exposing ((</>), Parser)


type Route
    = Home
    | Game GameId
    | Play GameId
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

        Game id ->
            Url.Builder.absolute [ "games", Url.percentEncode (Games.gameIdToString id) ] []

        Play id ->
            Url.Builder.absolute [ "play", Url.percentEncode (Games.gameIdToString id) ] []

        NotFound ->
            "/not-found"


parser : Parser (Route -> a) a
parser =
    Url.Parser.oneOf
        [ Url.Parser.map Home Url.Parser.top
        , Url.Parser.map Game (Url.Parser.s "games" </> gameId)
        , Url.Parser.map Play (Url.Parser.s "play" </> gameId)
        ]


{-| A path segment, percent-decoded, as a Game id. Empty segments never reach
it: the parser drops them.
-}
gameId : Parser (GameId -> a) a
gameId =
    Url.Parser.custom "GAME_ID" (Url.percentDecode >> Maybe.map Games.gameIdFromString)
