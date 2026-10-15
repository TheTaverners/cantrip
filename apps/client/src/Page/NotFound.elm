module Page.NotFound exposing (view)

import Browser
import Html
import Html.Attributes
import Page


view : Browser.Document msg
view =
    { title = Page.documentTitle "Page not found"
    , body =
        [ Html.main_ [ Html.Attributes.class "page" ]
            [ Html.h1 [ Html.Attributes.class "page__title" ] [ Html.text "Page not found" ]
            ]
        ]
    }
