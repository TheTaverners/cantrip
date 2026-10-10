module SimulatedEffects exposing (simulate)

{-| Turns the app's `Effect`s into elm-program-test simulated effects. It is
the test-side twin of `Effect.toCmd` and lives under `tests/` because
elm-program-test is a test-only dependency.
-}

import Effect exposing (Effect(..))
import ProgramTest exposing (SimulatedEffect)
import SimulatedEffect.Cmd
import SimulatedEffect.Navigation


simulate : Effect msg -> SimulatedEffect msg
simulate effect =
    case effect of
        None ->
            SimulatedEffect.Cmd.none

        Batch effects ->
            SimulatedEffect.Cmd.batch (List.map simulate effects)

        PushUrl url ->
            SimulatedEffect.Navigation.pushUrl url

        LoadUrl url ->
            SimulatedEffect.Navigation.load url
