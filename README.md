# Cantrip

Cantrip lets a tabletop RPG Game Master control a session's ambiance (display, lighting, sound, …) from a web client.

The repository is a monorepo. Each deployable component lives under `apps/`:

- `apps/client`: the web client, an Elm application built with Vite. See [its README](apps/client/README.md).

## Prerequisites

- macOS
- [Homebrew](https://brew.sh)

`make setup` installs everything else: [Volta](https://volta.sh) and [actionlint](https://github.com/rhysd/actionlint) through the [Brewfile](Brewfile), then Node (pinned by Volta) and the client's npm dependencies. If you have never used Volta before, run `volta setup` once after the first `make setup` and restart your shell, so that `node` and `npm` resolve to Volta's pinned versions.

## Setup

```sh
make setup
```

## Commands

| Command               | What it does                                                                    |
| --------------------- | ------------------------------------------------------------------------------- |
| `make setup`          | Install Homebrew tools, npm dependencies and the Playwright browsers.           |
| `make dev`            | Start the client dev server on http://localhost:5173.                           |
| `make fmt`            | Format all code (elm-format, ESLint fixes).                                     |
| `make fmt-check`      | Fail if any file is not formatted.                                              |
| `make lint`           | Run elm-review, ESLint (TS, JSON, CSS, Markdown) and the TypeScript type check. |
| `make test`           | Run the Elm unit and program tests (elm-test-rs).                               |
| `make e2e`            | Build the client and run the Playwright smoke test on Chromium and WebKit.      |
| `make build`          | Build the optimised production bundle in `apps/client/dist`.                    |
| `make lint-workflows` | Lint the GitHub Actions workflows with actionlint.                              |
| `make check`          | Run every check CI runs, except browser tests.                                  |

Run `make` (or `make help`) to list the targets.

`make e2e` serves the production build with `vite preview` (never the dev server); WebKit stands in for Safari. To run a single Playwright test, from `apps/client`: `npx playwright test e2e/smoke.spec.ts`, narrowed with `-g "<test title>"` or `--project=webkit`. After a failure, `npx playwright show-report` opens the HTML report.

## Continuous integration

GitHub Actions runs on every pull request and every push to `main`. The `client` job runs only when client files, CI configuration or the root `Makefile` change; so does `client-e2e`, which runs after it, installs Chromium and WebKit, runs `make e2e`, and uploads the Playwright HTML report as the `playwright-report` artifact when it fails. The `repo` job runs on every change: it lints the workflows with actionlint and, on pull requests, checks that the PR title is a [Conventional Commit](https://www.conventionalcommits.org) (`<type>(<optional scope>): <description>`, with the same types as the commit-msg hook), because squash merges turn the title into the commit on `main`. The `ci-ok` job always runs and is the single status to require.

Every action is pinned by full commit SHA with the version in a trailing comment (Docker actions: `docker://image:<version>@sha256:<digest>`). Keep it that way when adding or updating an action.
