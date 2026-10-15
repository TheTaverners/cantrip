module TitleTest exposing (suite)

import Expect
import Fuzz exposing (Fuzzer)
import Test exposing (Test)
import Title


suite : Test
suite =
    Test.describe "Title"
        [ Test.test "a title keeps its text" <|
            \() ->
                Title.fromString "The Sunken Crypt"
                    |> Maybe.map Title.toString
                    |> Expect.equal (Just "The Sunken Crypt")
        , Test.test "a title is trimmed" <|
            \() ->
                Title.fromString "  The Sunken Crypt\n\t"
                    |> Maybe.map Title.toString
                    |> Expect.equal (Just "The Sunken Crypt")
        , Test.fuzz2 whitespaceFuzzer whitespaceFuzzer "a title surrounded by whitespace trims to the same title" <|
            \before after ->
                Title.fromString (before ++ "Hall of Echoes" ++ after)
                    |> Expect.equal (Title.fromString "Hall of Echoes")
        , Test.test "an empty title is rejected" <|
            \() ->
                Title.fromString ""
                    |> Expect.equal Nothing
        , Test.fuzz whitespaceFuzzer "a whitespace-only title is rejected" <|
            \blank ->
                Title.fromString blank
                    |> Expect.equal Nothing
        ]


whitespaceFuzzer : Fuzzer String
whitespaceFuzzer =
    Fuzz.oneOfValues [ ' ', '\t', '\n', '\u{000D}', '\u{00A0}' ]
        |> Fuzz.list
        |> Fuzz.map String.fromList
