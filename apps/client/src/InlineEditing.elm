module InlineEditing exposing
    ( State, init
    , Msg, update, Request, apply
    , viewCreate, viewRow, actionButton
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
@docs Msg, update, Request, apply
@docs viewCreate, viewRow, actionButton

-}

import Html exposing (Html)
import Html.Attributes
import Html.Events
import Title exposing (Title)


{-| The create field's draft and the row being edited, if any.
-}
type State id
    = State
        { create : TitleDraft
        , row : Row id
        }


type Row id
    = Idle
    | Renaming { id : id, draft : TitleDraft }
    | ConfirmingDelete id


{-| A title being typed, and whether its last submission was refused.
-}
type alias TitleDraft =
    { text : String
    , refused : Bool
    }


{-| Nothing typed, no row being edited.
-}
init : State id
init =
    State { create = typing "", row = Idle }


typing : String -> TitleDraft
typing text =
    { text = text, refused = False }


{-| The valid title, or the draft marked as refused.
-}
submitDraft : TitleDraft -> Result TitleDraft Title
submitDraft draft =
    case Title.fromString draft.text of
        Just title ->
            Ok title

        Nothing ->
            Err { draft | refused = True }


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


{-| A valid change for the page to apply to its items, with `apply`.
-}
type Request id
    = Create Title
    | Rename id Title
    | Delete id


{-| Apply the request `update` returned, if any, to the page's items with the
matching function.
-}
apply :
    { create : Title -> items -> items
    , rename : id -> Title -> items -> items
    , delete : id -> items -> items
    }
    -> Maybe (Request id)
    -> items
    -> items
apply { create, rename, delete } request items =
    case request of
        Just (Create title) ->
            create title items

        Just (Rename id title) ->
            rename id title items

        Just (Delete id) ->
            delete id items

        Nothing ->
            items


update : Msg id -> State id -> ( State id, Maybe (Request id) )
update msg (State state) =
    case msg of
        DraftChanged text ->
            ( State { state | create = typing text }, Nothing )

        CreateSubmitted ->
            case submitDraft state.create of
                Ok title ->
                    ( State { state | create = typing "" }, Just (Create title) )

                Err refused ->
                    ( State { state | create = refused }, Nothing )

        RenameStarted id title ->
            ( State { state | row = Renaming { id = id, draft = typing (Title.toString title) } }, Nothing )

        RenameDraftChanged text ->
            case state.row of
                Renaming renaming ->
                    ( State { state | row = Renaming { renaming | draft = typing text } }, Nothing )

                _ ->
                    ( State state, Nothing )

        RenameSubmitted ->
            case state.row of
                Renaming renaming ->
                    case submitDraft renaming.draft of
                        Ok title ->
                            ( State { state | row = Idle }, Just (Rename renaming.id title) )

                        Err refused ->
                            ( State { state | row = Renaming { renaming | draft = refused } }, Nothing )

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
    viewForm
        { fieldAttributes = [ Html.Attributes.attribute "aria-label" label, Html.Attributes.placeholder label ]
        , onInput = toMsg << DraftChanged
        , onSubmit = toMsg CreateSubmitted
        , submitLabel = "Create"
        , extraButtons = []
        }
        state.create


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
    case rowMode id state.row of
        Renaming renaming ->
            [ viewForm
                { fieldAttributes = [ Html.Attributes.attribute "aria-label" "Title" ]
                , onInput = toMsg << RenameDraftChanged
                , onSubmit = toMsg RenameSubmitted
                , submitLabel = "Save"
                , extraButtons = [ actionButton (toMsg RenameCancelled) "Cancel" ]
                }
                renaming.draft
            ]

        ConfirmingDelete _ ->
            content
                ++ [ Html.span [ Html.Attributes.class "inline-confirm" ] [ Html.text "Delete?" ]
                   , actionButton (toMsg DeleteConfirmed) "Yes"
                   , actionButton (toMsg DeleteCancelled) "Cancel"
                   ]

        Idle ->
            content
                ++ [ actionButton (toMsg (RenameStarted id title)) "Rename"
                   , actionButton (toMsg (DeleteRequested id)) "Delete"
                   ]


{-| What the row with this id is doing: another row's edit leaves it idle.
-}
rowMode : id -> Row id -> Row id
rowMode id row =
    case row of
        Renaming renaming ->
            if renaming.id == id then
                row

            else
                Idle

        ConfirmingDelete confirming ->
            if confirming == id then
                row

            else
                Idle

        Idle ->
            Idle


{-| A title field, its submit button, any `extraButtons`, then the refusal if
the draft was refused.
-}
viewForm :
    { fieldAttributes : List (Html.Attribute msg)
    , onInput : String -> msg
    , onSubmit : msg
    , submitLabel : String
    , extraButtons : List (Html msg)
    }
    -> TitleDraft
    -> Html msg
viewForm config draft =
    Html.form [ Html.Attributes.class "inline-form", Html.Events.onSubmit config.onSubmit ]
        (Html.input
            (Html.Attributes.class "inline-form__field"
                :: config.fieldAttributes
                ++ [ Html.Attributes.value draft.text
                   , Html.Events.onInput config.onInput
                   ]
            )
            []
            :: Html.button [ Html.Attributes.type_ "submit", Html.Attributes.class "button" ] [ Html.text config.submitLabel ]
            :: config.extraButtons
            ++ viewRefusal draft.refused
        )


{-| A button styled like the row's own actions, for an item-specific action
in a row's `content`.
-}
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
