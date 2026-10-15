module Page.Game exposing (Model, Msg, init, update, view)

{-| The Game page, in Game Master mode: one Game's title (read-only) and its
Scenes, in creation order, with a badge on the Active Scene and a "Make active"
action on every other Scene, and a link to the Game's player view. Scenes are
created, renamed and deleted here, inline.
-}

import Browser
import Games exposing (Game, GameId, Games, Scene, SceneId)
import Html exposing (Html)
import Html.Attributes
import InlineEditing
import Route
import Title


{-| Page-local editing state. `Main` resets it on every route change.
-}
type Model
    = Model (InlineEditing.State SceneId)


init : Model
init =
    Model InlineEditing.init


type Msg
    = Editing (InlineEditing.Msg SceneId)
    | MakeActiveClicked SceneId


{-| Apply a message to the Scenes of the Game with this id.
-}
update : GameId -> Msg -> Model -> Games -> ( Model, Games )
update id msg (Model editing) games =
    case msg of
        Editing editingMsg ->
            let
                ( newEditing, request ) =
                    InlineEditing.update editingMsg editing
            in
            ( Model newEditing
            , InlineEditing.apply
                { create = Games.createScene id
                , rename = Games.renameScene id
                , delete = Games.deleteScene id
                }
                request
                games
            )

        MakeActiveClicked sceneId ->
            ( Model editing, Games.makeActive id sceneId games )


view : Game -> Model -> Browser.Document Msg
view game (Model editing) =
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
            , InlineEditing.viewCreate { label = "New scene title", toMsg = Editing } editing
            , case Games.scenes game of
                [] ->
                    Html.p [ Html.Attributes.class "empty" ] [ Html.text "No scenes yet" ]

                sceneList ->
                    Html.ul [ Html.Attributes.class "scene-list" ]
                        (List.map (viewScene editing game) sceneList)
            ]
        ]
    }


viewScene : InlineEditing.State SceneId -> Game -> Scene -> Html Msg
viewScene editing game scene =
    Html.li [ Html.Attributes.class "scene-list__item" ]
        (InlineEditing.viewRow
            { id = Games.sceneId scene
            , title = Games.sceneTitle scene
            , content =
                Html.span [ Html.Attributes.class "scene-list__title" ] [ Html.text (Title.toString (Games.sceneTitle scene)) ]
                    :: (if Games.isActive game scene then
                            [ Html.span [ Html.Attributes.class "badge" ] [ Html.text "Active" ] ]

                        else
                            [ InlineEditing.actionButton (MakeActiveClicked (Games.sceneId scene)) "Make active" ]
                       )
            , toMsg = Editing
            }
            editing
        )
