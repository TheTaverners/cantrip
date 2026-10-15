module Page.GameList exposing (view)

{-| The Game list, in Game Master mode: every Game, in creation order.
-}

import Browser
import Games exposing (Game, Games)
import Html exposing (Html)
import Html.Attributes
import Title


view : Games -> Browser.Document msg
view games =
    { title = "Cantrip"
    , body =
        [ Html.main_ [ Html.Attributes.class "page" ]
            [ Html.h1 [ Html.Attributes.class "page__title" ] [ Html.text "Games" ]
            , Html.ul [ Html.Attributes.class "game-list" ]
                (List.map viewGame (Games.list games))
            ]
        ]
    }


viewGame : Game -> Html msg
viewGame game =
    Html.li [ Html.Attributes.class "game-list__item" ]
        [ Html.text (Title.toString (Games.title game)) ]
