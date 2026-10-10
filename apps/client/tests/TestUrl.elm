module TestUrl exposing (base, fromPath)

{-| The made-up origin the tests run the app under.
-}

import Url exposing (Url)


host : String
host =
    "cantrip.test"


{-| The origin as a string, without a trailing slash: `"https://cantrip.test"`.
-}
base : String
base =
    "https://" ++ host


{-| The URL of a path under the test origin.
-}
fromPath : String -> Url
fromPath path =
    { protocol = Url.Https
    , host = host
    , port_ = Nothing
    , path = path
    , query = Nothing
    , fragment = Nothing
    }
