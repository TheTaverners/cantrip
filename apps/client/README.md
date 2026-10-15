# Cantrip client

The Cantrip web client: an Elm 0.19.3 application built with [Vite](https://vite.dev) and [vite-plugin-elm](https://github.com/hmsk/vite-plugin-elm).

## Layout

- `index.html`: the Vite entry page.
- `src/main.ts`: the TypeScript bootstrap. It imports the global stylesheet and mounts the Elm `Main` module on `#app`.
- `src/style.css`: the global stylesheet. Theme tokens are CSS custom properties on `:root`; Elm views reference the class names.
- `src/Main.elm`: the Elm entry point (see Architecture).
- `src/Route.elm`, `src/Effect.elm`: routing and side effects (see Architecture).
- `src/Games.elm`, `src/Title.elm`: the domain (see Architecture).
- `src/Page/`: one Elm module per page.
- `src/InlineEditing.elm`: the inline editing rows shared by the lists of titled items (see Architecture).
- `tests/`: Elm unit and program tests, run by elm-test-rs.
- `src/elm.d.ts`: hand-written types for the Elm entry point, so the bootstrap type-checks. Update it when `Main` gains flags or ports.
- `tsconfig.json`: the strictest TypeScript settings. `tsc` only type-checks (Vite does the compiling).
- `eslint.config.ts`: ESLint, the only formatter and linter for non-Elm files. `eslint.format.config.ts` holds the formatting rules alone.
- `vite.config.ts`: compiles Elm with `--optimize` for `vite build` and with the Elm debugger for the dev server.

## Architecture

- **`Main`** is a `Browser.application`: it owns the URL. Clicking an internal link asks for a `PushUrl` effect; the URL change that follows is parsed by `Route` and decides which page `view` renders. External links ask for `LoadUrl`. Back and forward fire the same URL change, so they need no extra code.
- **`Route`** is the single place that knows URLs. `Route.fromUrl` parses a `Url` into a `Route` (`Home | Game GameId | Play GameId | NotFound`); unknown paths become `NotFound`. Game ids are percent-encoded in paths. A parseable Game or player path whose id names no Game is still `Game id` or `Play id`: `Main` shows `Page.GameNotFound` for it, not the generic `Page.NotFound`. `Route.toPath` turns a `Route` back into a path; use it for every `href`. To add a page, add a constructor, a parser branch and a `toPath` branch.
- **`Games`** owns the collection of Games and their Scenes, behind opaque types so the rules in `GLOSSARY.md` can't be bypassed. It starts from `Games.seed` (in memory, reset on reload) and generates the opaque `GameId`s and `SceneId`s, which convert to and from strings for URLs. **`Title`** is a valid title: built with `Title.fromString`, which trims and refuses empty input. `Main` keeps the collection in its model, next to the route, so it survives navigation. Games are created with `Games.createGame`, renamed with `Games.renameGame` and deleted (with their Scenes) with `Games.deleteGame`; these take an already-valid `Title`, and an unknown id leaves the collection unchanged. Deleted ids are never handed out again.
- **Pages** live in `src/Page/`, one module per page. Each `view` returns a `Browser.Document`: its own document title and its body. Today: `GameList` (`/`), `Game` (`/games/:gameId`), `Player` (`/play/:gameId`, Player mode: no management controls and no link into Game Master mode), `GameNotFound` and `NotFound`. A page with page-local UI state (today `GameList`) exposes `Model`, `init`, `Msg`, an `update` that takes and returns the Games (no effects), and `view`; `Main` keeps that model next to the Games and resets it with the page's `init` on every URL change, so drafts and pending confirmations don't survive navigation.
- **`InlineEditing`** is the inline editing of a list of titled items, generic over the item id so Games and Scenes share it: a create field (`viewCreate`), and per row (`viewRow`) an inline rename with "Save" / "Cancel" and an inline "Delete? Yes / Cancel" confirmation. It validates drafts with `Title.fromString` and shows "A title can't be empty." itself. `update` returns the new `State` and, for a valid change, a `Request` (`Create title`, `Rename id title` or `Delete id`) for the page to apply to the domain. At most one row is renamed or awaiting confirmation at a time.
- **`Effect`** is the Effect pattern. `init` and `update` return `( Model, Effect Msg )`, never a `Cmd`. `Effect` is a custom type listing every side effect the app may request (`None`, `Batch`, `PushUrl`, `LoadUrl`). Only `Main` turns an effect into a real `Cmd`, with `Effect.toCmd` and the navigation key, which `Main` keeps next to the model rather than in it. Tests turn effects into elm-program-test simulated effects with `tests/SimulatedEffects.elm`; it lives under `tests/` because elm-program-test is a test-only dependency. Add a branch to both functions whenever you add a constructor.
- **TypeScript bootstrap**: `src/main.ts` imports the global stylesheet and mounts `Elm.Main` on `#app`. There are no flags or ports yet.

## Tests

- `tests/RouteTest.elm` tests the `Route` interface: a fuzz test that route → path → route round-trips (Game and player routes with arbitrary non-empty ids), and checks that unknown paths, `/games/` and `/play` parse to `NotFound`.
- `tests/TitleTest.elm` and `tests/GamesTest.elm` test the domain through its public interface: title trimming and refusal, the seed, lookup by id, creating, renaming and deleting Games (creation order, cascade to Scenes, unknown ids), making a Scene active (including a fuzz test over sequences of "make active"), and ids round-tripping through strings.
- `tests/MainTest.elm` runs the whole program with [elm-program-test](https://package.elm-lang.org/packages/avh4/elm-program-test/latest/), starting from a URL and asserting on what the page shows, including the inline create, rename and delete of Games. elm-program-test has no title assertion, so `expectTitle` reads the title from `Main.view`.
- `e2e/smoke.spec.ts` is the browser smoke test: the production bundle, served by `vite preview`, lists the seeded Games under the title "Cantrip" in Chromium and WebKit. `playwright.config.ts` builds and starts the server itself. Single test: `npx playwright test e2e/smoke.spec.ts`, with `-g "<title>"` or `--project=webkit` to narrow it; reports land in `playwright-report/`.
- Test dependencies are listed by hand in the `test-dependencies` block of `elm.json` (elm-json does not work with Elm 0.19.3).

## Scripts

Run these here, or through the root `Makefile`.

| Script                | What it does                                                   |
| --------------------- | -------------------------------------------------------------- |
| `npm run dev`         | Start the dev server with hot reload.                          |
| `npm run build`       | Build the production bundle into `dist/`.                      |
| `npm run preview`     | Serve the production bundle from `dist/`.                      |
| `npm run fmt`         | Format Elm with elm-format, then apply ESLint fixes.           |
| `npm run fmt-check`   | Fail if an Elm file or a TypeScript file is not formatted.     |
| `npm run lint`        | Run elm-review, ESLint, then the type check (`tsc --noEmit`).  |
| `npm test`            | Run the Elm tests with elm-test-rs.                            |
| `npm run e2e`         | Build, serve with `vite preview`, run Playwright (2 browsers). |
| `npm run e2e:install` | Install the Chromium and WebKit browsers for Playwright.       |

## Toolchain

- Node is pinned by the `volta` field in `package.json`. CI reads the same pin.
- The Elm compiler is the `elm` npm package, pinned exactly in `devDependencies`. `.npmrc` makes npm save every dependency exactly.
- elm-format and elm-review are pinned the same way. `fmt` and `lint` delegate to per-tool scripts (`fmt:elm`, `fmt-check:elm`, `lint:elm`) so other tools can join them.
- elm-test-rs is pinned the same way. Pass a file to run only its tests: `npm test -- tests/RouteTest.elm`.
- elm-review's configuration lives in `review/`. It started from the [jfmengels application template](https://github.com/jfmengels/elm-review-config/tree/master/application); its `elm.json` was bumped from 0.19.1 to 0.19.3 by hand, since elm-review refuses to compile a review project for another Elm version. Elm packages there are updated by hand too.

## Formatting and linting

ESLint formats and lints everything that isn't Elm. There is no Prettier.

- TypeScript: typescript-eslint `strictTypeChecked` and `stylisticTypeChecked`, plus `@stylistic/eslint-plugin` for formatting (double quotes, semicolons, 2-space indent). Type assertions are banned.
- JSON, CSS and Markdown: `@eslint/json`, `@eslint/css` and `@eslint/markdown`. They are linted, but their whitespace formatting is not enforced.

The ESLint and TypeScript parts of `fmt`, `fmt-check` and `lint` are the `fmt:eslint`, `fmt-check:eslint`, `lint:eslint` and `lint:tsc` scripts.

## Known quirk

vite-plugin-elm 3.0.1 generates an invalid hot-reload snippet (`import.meta.hot.accept([""])`) when `Main.elm` imports no local module, and Vite's dev server then refuses to serve it. `Main.elm` must import at least one module from `src/`. The production build is not affected.
