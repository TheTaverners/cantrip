module Page.Home exposing (view)

import Html exposing (Html)
import Html.Attributes


view : Html msg
view =
    Html.main_ [ Html.Attributes.class "page" ]
        [ Html.h1 [ Html.Attributes.class "page__title" ] [ Html.text "Hello, World" ]
        ]
