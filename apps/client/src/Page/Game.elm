module Page.Game exposing (view)

{-| The Game page, in Game Master mode: one Game's title and its Scenes, in
creation order, with a badge on the Active Scene and a "Make active" action on
every other Scene, and a link to the Game's player view.
-}

import Browser
import Games exposing (Game, Scene, SceneId)
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Route
import Title


{-| `onMakeActive` is the message sent when the Game Master makes a Scene the
Active Scene.
-}
view : { onMakeActive : SceneId -> msg } -> Game -> Browser.Document msg
view { onMakeActive } game =
    let
        gameTitle : String
        gameTitle =
            Title.toString (Games.title game)
    in
    { title = gameTitle ++ " · Cantrip"
    , body =
        [ Html.main_ [ Html.Attributes.class "page" ]
            [ Html.a [ Html.Attributes.class "page__back", Html.Attributes.href (Route.toPath Route.Home) ] [ Html.text "← All games" ]
            , Html.h1 [ Html.Attributes.class "page__title" ] [ Html.text gameTitle ]
            , Html.a [ Html.Attributes.class "page__action", Html.Attributes.href (Route.toPath (Route.Play (Games.gameId game))) ] [ Html.text "Open player view" ]
            , Html.ul [ Html.Attributes.class "scene-list" ]
                (List.map (viewScene onMakeActive (Maybe.map Games.sceneId (Games.activeScene game))) (Games.scenes game))
            ]
        ]
    }


viewScene : (SceneId -> msg) -> Maybe SceneId -> Scene -> Html msg
viewScene onMakeActive activeSceneId scene =
    Html.li [ Html.Attributes.class "scene-list__item" ]
        (Html.span [ Html.Attributes.class "scene-list__title" ] [ Html.text (Title.toString (Games.sceneTitle scene)) ]
            :: (if activeSceneId == Just (Games.sceneId scene) then
                    [ Html.span [ Html.Attributes.class "badge" ] [ Html.text "Active" ] ]

                else
                    [ Html.button [ Html.Attributes.class "scene-list__action", Html.Events.onClick (onMakeActive (Games.sceneId scene)) ] [ Html.text "Make active" ] ]
               )
        )
