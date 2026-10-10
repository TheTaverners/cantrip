module Page.Home exposing (view)

import Browser
import Html
import Html.Attributes
import Route


view : Browser.Document msg
view =
    { title = "Cantrip"
    , body =
        [ Html.main_ [ Html.Attributes.class "page" ]
            [ Html.h1 [ Html.Attributes.class "page__title" ] [ Html.text "Hello, World" ]
            , Html.p []
                [ Html.a [ Html.Attributes.href (Route.toPath Route.NotFound) ]
                    [ Html.text "Wander off the map" ]
                ]
            ]
        ]
    }
