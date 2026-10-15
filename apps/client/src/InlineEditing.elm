module InlineEditing exposing
    ( State, init
    , Msg, update, Request(..)
    , viewCreate, viewRow
    )

{-| Inline editing of a list of titled items, such as Games or Scenes: a title
field to create one, and per row an inline rename (with cancel) and an inline
"Delete? Yes / Cancel" confirmation. No modals, no extra routes.

It knows nothing about what the items are: `id` is whatever identifies them.
It validates titles with `Title.fromString` and shows refusals itself; when a
change is valid, `update` hands the page a `Request` to apply to its items.
At most one row is being renamed or awaiting confirmation at a time.

The state is page-local: reset it with `init` when the route changes.

@docs State, init
@docs Msg, update, Request
@docs viewCreate, viewRow

-}

import Html exposing (Html)
import Html.Attributes
import Html.Events
import Title exposing (Title)


{-| The create field's draft, whether the last creation was refused, and the
row being edited, if any.
-}
type State id
    = State
        { draft : String
        , createRefused : Bool
        , row : Row id
        }


type Row id
    = Idle
    | Renaming { id : id, draft : String, refused : Bool }
    | ConfirmingDelete id


{-| Nothing typed, no row being edited.
-}
init : State id
init =
    State { draft = "", createRefused = False, row = Idle }


type Msg id
    = DraftChanged String
    | CreateSubmitted
    | RenameStarted id Title
    | RenameDraftChanged String
    | RenameSubmitted
    | RenameCancelled
    | DeleteRequested id
    | DeleteConfirmed
    | DeleteCancelled


{-| A valid change for the page to apply to its items.
-}
type Request id
    = Create Title
    | Rename id Title
    | Delete id


update : Msg id -> State id -> ( State id, Maybe (Request id) )
update msg (State state) =
    case msg of
        DraftChanged draft ->
            ( State { state | draft = draft, createRefused = False }, Nothing )

        CreateSubmitted ->
            case Title.fromString state.draft of
                Just title ->
                    ( State { state | draft = "", createRefused = False }, Just (Create title) )

                Nothing ->
                    ( State { state | createRefused = True }, Nothing )

        RenameStarted id title ->
            ( State { state | row = Renaming { id = id, draft = Title.toString title, refused = False } }, Nothing )

        RenameDraftChanged draft ->
            case state.row of
                Renaming renaming ->
                    ( State { state | row = Renaming { renaming | draft = draft, refused = False } }, Nothing )

                _ ->
                    ( State state, Nothing )

        RenameSubmitted ->
            case state.row of
                Renaming renaming ->
                    case Title.fromString renaming.draft of
                        Just title ->
                            ( State { state | row = Idle }, Just (Rename renaming.id title) )

                        Nothing ->
                            ( State { state | row = Renaming { renaming | refused = True } }, Nothing )

                _ ->
                    ( State state, Nothing )

        RenameCancelled ->
            ( State { state | row = Idle }, Nothing )

        DeleteRequested id ->
            ( State { state | row = ConfirmingDelete id }, Nothing )

        DeleteConfirmed ->
            case state.row of
                ConfirmingDelete id ->
                    ( State { state | row = Idle }, Just (Delete id) )

                _ ->
                    ( State state, Nothing )

        DeleteCancelled ->
            ( State { state | row = Idle }, Nothing )


{-| The create field. `label` names the field, e.g. "New game title".
-}
viewCreate : { label : String, toMsg : Msg id -> msg } -> State id -> Html msg
viewCreate { label, toMsg } (State state) =
    Html.form [ Html.Attributes.class "inline-form", Html.Events.onSubmit (toMsg CreateSubmitted) ]
        (Html.input
            [ Html.Attributes.class "inline-form__field"
            , Html.Attributes.attribute "aria-label" label
            , Html.Attributes.placeholder label
            , Html.Attributes.value state.draft
            , Html.Events.onInput (toMsg << DraftChanged)
            ]
            []
            :: Html.button [ Html.Attributes.type_ "submit", Html.Attributes.class "button" ] [ Html.text "Create" ]
            :: viewRefusal state.createRefused
        )


{-| The contents of one item's row.

  - `content` is what the row shows when it is not being renamed: typically the
    title, linking to the item, plus any badge or item-specific action.
  - While renaming, the row shows a title field (labelled "Title"), "Save" and
    "Cancel".
  - While awaiting confirmation, it shows `content`, then "Delete?", "Yes" and
    "Cancel".
  - Otherwise, it shows `content`, then "Rename" and "Delete".

-}
viewRow : { id : id, title : Title, content : List (Html msg), toMsg : Msg id -> msg } -> State id -> List (Html msg)
viewRow { id, title, content, toMsg } (State state) =
    case state.row of
        Renaming renaming ->
            if renaming.id == id then
                [ Html.form [ Html.Attributes.class "inline-form", Html.Events.onSubmit (toMsg RenameSubmitted) ]
                    (Html.input
                        [ Html.Attributes.class "inline-form__field"
                        , Html.Attributes.attribute "aria-label" "Title"
                        , Html.Attributes.value renaming.draft
                        , Html.Events.onInput (toMsg << RenameDraftChanged)
                        ]
                        []
                        :: Html.button [ Html.Attributes.type_ "submit", Html.Attributes.class "button" ] [ Html.text "Save" ]
                        :: actionButton (toMsg RenameCancelled) "Cancel"
                        :: viewRefusal renaming.refused
                    )
                ]

            else
                content ++ idleActions toMsg id title

        ConfirmingDelete confirming ->
            if confirming == id then
                content
                    ++ [ Html.span [ Html.Attributes.class "inline-confirm" ] [ Html.text "Delete?" ]
                       , actionButton (toMsg DeleteConfirmed) "Yes"
                       , actionButton (toMsg DeleteCancelled) "Cancel"
                       ]

            else
                content ++ idleActions toMsg id title

        Idle ->
            content ++ idleActions toMsg id title


idleActions : (Msg id -> msg) -> id -> Title -> List (Html msg)
idleActions toMsg id title =
    [ actionButton (toMsg (RenameStarted id title)) "Rename"
    , actionButton (toMsg (DeleteRequested id)) "Delete"
    ]


actionButton : msg -> String -> Html msg
actionButton msg label =
    Html.button
        [ Html.Attributes.type_ "button"
        , Html.Attributes.class "button button--quiet"
        , Html.Events.onClick msg
        ]
        [ Html.text label ]


viewRefusal : Bool -> List (Html msg)
viewRefusal refused =
    if refused then
        [ Html.p [ Html.Attributes.class "inline-error", Html.Attributes.attribute "role" "alert" ] [ Html.text "A title can't be empty." ] ]

    else
        []
