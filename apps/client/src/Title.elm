module Title exposing (Title, fromString, toString)

{-| The title of a Game or a Scene: trimmed, and never empty.
-}


type Title
    = Title String


{-| Trim the raw text; refuse it when nothing is left.
-}
fromString : String -> Maybe Title
fromString raw =
    case String.trim raw of
        "" ->
            Nothing

        trimmed ->
            Just (Title trimmed)


toString : Title -> String
toString (Title text) =
    text
