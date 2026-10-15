module Main exposing (Model, Msg, init, main, onUrlChange, onUrlRequest, update, view)

import Browser
import Browser.Navigation
import Effect exposing (Effect)
import Games exposing (Games)
import Html
import Page.Game
import Page.GameList
import Page.GameNotFound
import Page.NotFound
import Route exposing (Route)
import Url exposing (Url)


{-| The Games live next to the route, not inside a page, so they survive
navigation. Page-local state (`gameList`) is reset on every route change.
-}
type alias Model =
    { route : Route
    , games : Games
    , gameList : Page.GameList.Model
    }


type Msg
    = UrlRequested Browser.UrlRequest
    | UrlChanged Url
    | GameListMsg Page.GameList.Msg


{-| The navigation key lives next to the model, outside of it, so that `init`,
`update` and `view` stay runnable under elm-program-test, which has no key.
-}
type alias KeyedModel =
    ( Browser.Navigation.Key, Model )


main : Program () KeyedModel Msg
main =
    Browser.application
        { init = applicationInit
        , view = \( _, model ) -> view model
        , update = applicationUpdate
        , subscriptions = \_ -> Sub.none
        , onUrlRequest = onUrlRequest
        , onUrlChange = onUrlChange
        }


applicationInit : () -> Url -> Browser.Navigation.Key -> ( KeyedModel, Cmd Msg )
applicationInit flags url key =
    withKey key (init flags url ())


applicationUpdate : Msg -> KeyedModel -> ( KeyedModel, Cmd Msg )
applicationUpdate msg ( key, model ) =
    withKey key (update msg model)


withKey : Browser.Navigation.Key -> ( Model, Effect Msg ) -> ( KeyedModel, Cmd Msg )
withKey key ( model, effect ) =
    ( ( key, model ), Effect.toCmd key effect )


init : () -> Url -> () -> ( Model, Effect Msg )
init () url () =
    ( { route = Route.fromUrl url, games = Games.seed, gameList = Page.GameList.init }, Effect.None )


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        UrlRequested (Browser.Internal url) ->
            ( model, Effect.PushUrl (Url.toString url) )

        UrlRequested (Browser.External href) ->
            ( model, Effect.LoadUrl href )

        UrlChanged url ->
            ( { model | route = Route.fromUrl url, gameList = Page.GameList.init }, Effect.None )

        GameListMsg pageMsg ->
            let
                ( gameList, games ) =
                    Page.GameList.update pageMsg model.gameList model.games
            in
            ( { model | gameList = gameList, games = games }, Effect.None )


view : Model -> Browser.Document Msg
view model =
    case model.route of
        Route.Home ->
            mapDocument GameListMsg (Page.GameList.view model.games model.gameList)

        Route.Game id ->
            case Games.get id model.games of
                Just game ->
                    Page.Game.view game

                Nothing ->
                    Page.GameNotFound.view

        Route.NotFound ->
            Page.NotFound.view


mapDocument : (a -> msg) -> Browser.Document a -> Browser.Document msg
mapDocument toMsg document =
    { title = document.title
    , body = List.map (Html.map toMsg) document.body
    }


onUrlRequest : Browser.UrlRequest -> Msg
onUrlRequest =
    UrlRequested


onUrlChange : Url -> Msg
onUrlChange =
    UrlChanged
