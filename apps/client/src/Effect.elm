module Effect exposing (Effect(..), toCmd)

{-| Every side effect the app can ask for. `update` functions return an
`Effect` instead of a `Cmd`, so the whole program can run under
elm-program-test.

  - `toCmd` performs an effect for real. Only `Main` calls it.
  - `SimulatedEffects.simulate` (under `tests/`) is its test-side twin. Add a
    branch there whenever you add a constructor here.

-}

import Browser.Navigation


type Effect msg
    = None
    | Batch (List (Effect msg))
    | PushUrl String
    | LoadUrl String


toCmd : Browser.Navigation.Key -> Effect msg -> Cmd msg
toCmd key effect =
    case effect of
        None ->
            Cmd.none

        Batch effects ->
            Cmd.batch (List.map (toCmd key) effects)

        PushUrl url ->
            Browser.Navigation.pushUrl key url

        LoadUrl url ->
            Browser.Navigation.load url
