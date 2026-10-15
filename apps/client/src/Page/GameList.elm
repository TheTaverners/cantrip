module Page.GameList exposing (Model, Msg, init, update, view)

{-| The Game list, in Game Master mode: every Game, in creation order, each
linking to its Game page. Games are created, renamed and deleted here, inline.
-}

import Browser
import Games exposing (Game, GameId, Games)
import Html exposing (Html)
import Html.Attributes
import InlineEditing
import Route
import Title


{-| Page-local editing state. `Main` resets it on every route change.
-}
type Model
    = Model (InlineEditing.State GameId)


init : Model
init =
    Model InlineEditing.init


type Msg
    = Editing (InlineEditing.Msg GameId)


update : Msg -> Model -> Games -> ( Model, Games )
update (Editing msg) (Model editing) games =
    let
        ( newEditing, request ) =
            InlineEditing.update msg editing
    in
    ( Model newEditing
    , case request of
        Just (InlineEditing.Create title) ->
            Games.createGame title games

        Just (InlineEditing.Rename id title) ->
            Games.renameGame id title games

        Just (InlineEditing.Delete id) ->
            Games.deleteGame id games

        Nothing ->
            games
    )


view : Games -> Model -> Browser.Document Msg
view games (Model editing) =
    { title = "Cantrip"
    , body =
        [ Html.main_ [ Html.Attributes.class "page" ]
            [ Html.h1 [ Html.Attributes.class "page__title" ] [ Html.text "Games" ]
            , InlineEditing.viewCreate { label = "New game title", toMsg = Editing } editing
            , case Games.list games of
                [] ->
                    Html.p [ Html.Attributes.class "empty" ] [ Html.text "No games yet" ]

                list ->
                    Html.ul [ Html.Attributes.class "game-list" ]
                        (List.map (viewGame editing) list)
            ]
        ]
    }


viewGame : InlineEditing.State GameId -> Game -> Html Msg
viewGame editing game =
    Html.li [ Html.Attributes.class "game-list__item" ]
        (InlineEditing.viewRow
            { id = Games.gameId game
            , title = Games.title game
            , content =
                [ Html.a [ Html.Attributes.class "game-list__title", Html.Attributes.href (Route.toPath (Route.Game (Games.gameId game))) ]
                    [ Html.text (Title.toString (Games.title game)) ]
                ]
            , toMsg = Editing
            }
            editing
        )
