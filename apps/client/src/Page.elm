module Page exposing (documentTitle)

{-| What the pages in `Page/` share.

@docs documentTitle

-}


{-| A page's document title: its own title, then the app's name. The Game list
is titled by the app's name alone.
-}
documentTitle : String -> String
documentTitle pageTitle =
    pageTitle ++ " · Cantrip"
