# Cantrip client

The Cantrip web client: an Elm 0.19.3 application built with [Vite](https://vite.dev) and [vite-plugin-elm](https://github.com/hmsk/vite-plugin-elm).

## Layout

- `index.html`: the Vite entry page.
- `src/main.ts`: the TypeScript bootstrap. It imports the global stylesheet and mounts the Elm `Main` module on `#app`.
- `src/style.css`: the global stylesheet. Theme tokens are CSS custom properties on `:root`; Elm views reference the class names.
- `src/Main.elm`: the Elm entry point.
- `src/Page/`: one Elm module per page.
- `vite.config.ts`: compiles Elm with `--optimize` for `vite build` and with the Elm debugger for the dev server.

## Scripts

Run these here, or through the root `Makefile`.

| Script              | What it does                              |
| ------------------- | ----------------------------------------- |
| `npm run dev`       | Start the dev server with hot reload.     |
| `npm run build`     | Build the production bundle into `dist/`. |
| `npm run preview`   | Serve the production bundle from `dist/`. |
| `npm run fmt`       | Format every Elm file with elm-format.    |
| `npm run fmt-check` | Fail if an Elm file is not formatted.     |
| `npm run lint`      | Run elm-review.                           |

## Toolchain

- Node is pinned by the `volta` field in `package.json`. CI reads the same pin.
- The Elm compiler is the `elm` npm package, pinned exactly in `devDependencies`. `.npmrc` makes npm save every dependency exactly.
- elm-format and elm-review are pinned the same way. `fmt` and `lint` delegate to per-tool scripts (`fmt:elm`, `fmt-check:elm`, `lint:elm`) so other tools can join them.
- elm-review's configuration lives in `review/`. It started from the [jfmengels application template](https://github.com/jfmengels/elm-review-config/tree/master/application); its `elm.json` was bumped from 0.19.1 to 0.19.3 by hand, since elm-review refuses to compile a review project for another Elm version. Elm packages there are updated by hand too.

## Known quirk

vite-plugin-elm 3.0.1 generates an invalid hot-reload snippet (`import.meta.hot.accept([""])`) when `Main.elm` imports no local module, and Vite's dev server then refuses to serve it. `Main.elm` must import at least one module from `src/`. The production build is not affected.
