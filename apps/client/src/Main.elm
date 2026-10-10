module Main exposing (Model, Msg, init, main, onUrlChange, onUrlRequest, update, view)

import Browser
import Browser.Navigation
import Effect exposing (Effect)
import Page.Home
import Page.NotFound
import Route exposing (Route)
import Url exposing (Url)


type alias Model =
    { route : Route }


type Msg
    = UrlRequested Browser.UrlRequest
    | UrlChanged Url


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
    ( { route = Route.fromUrl url }, Effect.None )


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        UrlRequested (Browser.Internal url) ->
            ( model, Effect.PushUrl (Url.toString url) )

        UrlRequested (Browser.External href) ->
            ( model, Effect.LoadUrl href )

        UrlChanged url ->
            ( { model | route = Route.fromUrl url }, Effect.None )


view : Model -> Browser.Document Msg
view model =
    case model.route of
        Route.Home ->
            Page.Home.view

        Route.NotFound ->
            Page.NotFound.view


onUrlRequest : Browser.UrlRequest -> Msg
onUrlRequest =
    UrlRequested


onUrlChange : Url -> Msg
onUrlChange =
    UrlChanged
