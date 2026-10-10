# Cantrip

Cantrip lets a tabletop RPG Game Master control a session's ambiance (display, lighting, sound, …) from a web client.

The repository is a monorepo. Each deployable component lives under `apps/`:

- `apps/client`: the web client, an Elm application built with Vite. See [its README](apps/client/README.md).

## Prerequisites

- macOS
- [Homebrew](https://brew.sh)

`make setup` installs everything else: [Volta](https://volta.sh) through the [Brewfile](Brewfile), then Node (pinned by Volta) and the client's npm dependencies. If you have never used Volta before, run `volta setup` once after the first `make setup` and restart your shell, so that `node` and `npm` resolve to Volta's pinned versions.

## Setup

```sh
make setup
```

## Commands

| Command          | What it does                                                        |
| ---------------- | ------------------------------------------------------------------- |
| `make setup`     | Install machine tools (Homebrew bundle) and npm dependencies.       |
| `make dev`       | Start the client dev server on http://localhost:5173.               |
| `make fmt`       | Format all code (ESLint fixes for TypeScript).                      |
| `make fmt-check` | Fail if any file is not formatted.                                  |
| `make lint`      | Run ESLint (TS, JSON, CSS, Markdown) and the TypeScript type check. |
| `make build`     | Build the optimised production bundle in `apps/client/dist`.        |
| `make check`     | Run every check CI runs, except browser tests.                      |

Run `make` (or `make help`) to list the targets.

## Continuous integration

GitHub Actions runs on every pull request and every push to `main`. The `client` job runs only when client files, CI configuration or the root `Makefile` change. The `ci-ok` job always runs and is the single status to require.
