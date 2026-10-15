module Page.Player exposing (view)

{-| The player view, in Player mode: one Game's title, small, and its Active
Scene's title, large. It has no management controls and no link into Game
Master mode.
-}

import Browser
import Games exposing (Game)
import Html
import Html.Attributes
import Title


view : Game -> Browser.Document msg
view game =
    let
        gameTitle : String
        gameTitle =
            Title.toString (Games.title game)
    in
    { title = gameTitle ++ " · Cantrip"
    , body =
        [ Html.main_ [ Html.Attributes.class "player" ]
            [ Html.p [ Html.Attributes.class "player__game" ] [ Html.text gameTitle ]
            , case Games.activeScene game of
                Just scene ->
                    Html.h1 [ Html.Attributes.class "player__scene" ] [ Html.text (Title.toString (Games.sceneTitle scene)) ]

                Nothing ->
                    Html.p [ Html.Attributes.class "player__waiting" ] [ Html.text "Waiting for the Game Master…" ]
            ]
        ]
    }
