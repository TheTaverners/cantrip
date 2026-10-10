# Cantrip client

The Cantrip web client: an Elm 0.19.3 application built with [Vite](https://vite.dev) and [vite-plugin-elm](https://github.com/hmsk/vite-plugin-elm).

## Layout

- `index.html`: the Vite entry page.
- `src/main.ts`: the TypeScript bootstrap. It imports the global stylesheet and mounts the Elm `Main` module on `#app`.
- `src/style.css`: the global stylesheet. Theme tokens are CSS custom properties on `:root`; Elm views reference the class names.
- `src/Main.elm`: the Elm entry point.
- `src/Page/`: one Elm module per page.
- `src/elm.d.ts`: hand-written types for the Elm entry point, so the bootstrap type-checks. Update it when `Main` gains flags or ports.
- `tsconfig.json`: the strictest TypeScript settings. `tsc` only type-checks (Vite does the compiling).
- `eslint.config.ts`: ESLint, the only formatter and linter for non-Elm files. `eslint.format.config.ts` holds the formatting rules alone.
- `vite.config.ts`: compiles Elm with `--optimize` for `vite build` and with the Elm debugger for the dev server.

## Scripts

Run these here, or through the root `Makefile`.

| Script              | What it does                                                 |
| ------------------- | ------------------------------------------------------------ |
| `npm run dev`       | Start the dev server with hot reload.                        |
| `npm run build`     | Build the production bundle into `dist/`.                    |
| `npm run preview`   | Serve the production bundle from `dist/`.                    |
| `npm run fmt`       | Apply ESLint fixes (formatting included).                    |
| `npm run fmt-check` | Run ESLint's formatting rules only; fail on any violation.   |
| `npm run lint`      | Run ESLint, then the TypeScript type check (`tsc --noEmit`). |

## Toolchain

- Node is pinned by the `volta` field in `package.json`. CI reads the same pin.
- The Elm compiler is the `elm` npm package, pinned exactly in `devDependencies`. `.npmrc` makes npm save every dependency exactly.

## Formatting and linting

ESLint formats and lints everything that isn't Elm. There is no Prettier.

- TypeScript: typescript-eslint `strictTypeChecked` and `stylisticTypeChecked`, plus `@stylistic/eslint-plugin` for formatting (double quotes, semicolons, 2-space indent). Type assertions are banned.
- JSON, CSS and Markdown: `@eslint/json`, `@eslint/css` and `@eslint/markdown`. They are linted, but their whitespace formatting is not enforced.

`fmt`, `fmt-check` and `lint` aggregate per-tool scripts (`fmt:eslint`, `fmt-check:eslint`, `lint:eslint`, `lint:tsc`), so another tool plugs in as one more `<task>:<tool>` script.

## Known quirk

vite-plugin-elm 3.0.1 generates an invalid hot-reload snippet (`import.meta.hot.accept([""])`) when `Main.elm` imports no local module, and Vite's dev server then refuses to serve it. `Main.elm` must import at least one module from `src/`. The production build is not affected.
