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
| `make setup`          | Install machine tools (Homebrew bundle) and npm dependencies.                   |
| `make dev`            | Start the client dev server on http://localhost:5173.                           |
| `make fmt`            | Format all code (elm-format, ESLint fixes).                                     |
| `make fmt-check`      | Fail if any file is not formatted.                                              |
| `make lint`           | Run elm-review, ESLint (TS, JSON, CSS, Markdown) and the TypeScript type check. |
| `make test`           | Run the Elm unit and program tests (elm-test-rs).                               |
| `make build`          | Build the optimised production bundle in `apps/client/dist`.                    |
| `make lint-workflows` | Lint the GitHub Actions workflows with actionlint.                              |
| `make check`          | Run every check CI runs, except browser tests.                                  |

Run `make` (or `make help`) to list the targets.

## Continuous integration

GitHub Actions runs on every pull request and every push to `main`. The `client` job runs only when client files, CI configuration or the root `Makefile` change. The `repo` job runs on every change: it lints the workflows with actionlint and, on pull requests, checks that the PR title is a [Conventional Commit](https://www.conventionalcommits.org) (`<type>(<optional scope>): <description>`, with the same types as the commit-msg hook), because squash merges turn the title into the commit on `main`. The `ci-ok` job always runs and is the single status to require.

Every action is pinned by full commit SHA with the version in a trailing comment (Docker actions: `docker://image:<version>@sha256:<digest>`). Keep it that way when adding or updating an action.

## Dependency updates

[Renovate](https://docs.renovatebot.com) keeps dependencies fresh, configured in [`renovate.json`](renovate.json):

- Update PRs open once a week (before 4am on Monday, Paris time), with Conventional Commit titles (`chore(deps): …`). A "Dependency Dashboard" issue lists pending and open updates.
- Related packages are grouped into one PR: Elm tooling (elm, elm-format, elm-review, elm-test-rs), ESLint ecosystem, Vite ecosystem, Playwright, and GitHub Actions.
- Minor, patch, pin and digest updates of devDependencies automerge once CI is green. Major updates, and everything else, wait for a human review.
- GitHub Actions stay pinned by digest: Renovate updates the SHA and the version comment together.
- TypeScript is held below 6.1.0, the highest version typescript-eslint supports.

Automerge uses GitHub's native auto-merge, so it needs two repository settings (maintainers): "Allow auto-merge" enabled, and `ci-ok` set as a required status check on `main`. Without the required check, a PR could merge before CI finishes.

**Elm packages are updated by hand.** Renovate has no manager for `elm.json` (and `elm-json` is broken on Elm ≥ 0.19.2), so the Elm dependencies in `apps/client/elm.json` (elm/core, elm-explorations/test, elm-program-test, …) are bumped manually.

To check the config after editing it, run the official validator from the repo root (it is not a project dependency, and the first run downloads Renovate, which takes about a minute):

```sh
npx --yes --package renovate@44.149.1 -- renovate-config-validator --strict
```
