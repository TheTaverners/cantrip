module Page.GameList exposing (view)

{-| The Game list, in Game Master mode: every Game, in creation order, each
linking to its Game page.
-}

import Browser
import Games exposing (Game, Games)
import Html exposing (Html)
import Html.Attributes
import Route
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
        [ Html.a [ Html.Attributes.href (Route.toPath (Route.Game (Games.gameId game))) ]
            [ Html.text (Title.toString (Games.title game)) ]
        ]
