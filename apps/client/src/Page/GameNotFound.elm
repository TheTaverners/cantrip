module Page.GameNotFound exposing (view)

{-| Shown when a valid Game path names no Game. It links nowhere, so both
modes can show it.
-}

import Browser
import Html
import Html.Attributes


view : Browser.Document msg
view =
    { title = "Game not found · Cantrip"
    , body =
        [ Html.main_ [ Html.Attributes.class "page" ]
            [ Html.h1 [ Html.Attributes.class "page__title" ] [ Html.text "Game not found" ]
            ]
        ]
    }
