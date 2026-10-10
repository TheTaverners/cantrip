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
| `make setup`          | Install machine tools (Homebrew bundle), npm dependencies and the git hooks.    |
| `make setup-hooks`    | Only activate the versioned git hooks (`git config core.hooksPath .githooks`).  |
| `make dev`            | Start the client dev server on http://localhost:5173.                           |
| `make fmt`            | Format all code (elm-format, ESLint fixes).                                     |
| `make fmt-check`      | Fail if any file is not formatted.                                              |
| `make lint`           | Run elm-review, ESLint (TS, JSON, CSS, Markdown) and the TypeScript type check. |
| `make build`          | Build the optimised production bundle in `apps/client/dist`.                    |
| `make lint-workflows` | Lint the GitHub Actions workflows with actionlint.                              |
| `make test-hooks`     | Test the git hooks in a throwaway copy of the repository.                       |
| `make check`          | Run every check CI runs (except browser tests), plus the hook tests.            |

Run `make` (or `make help`) to list the targets.

## Git hooks

The hooks live in [`.githooks/`](.githooks) and `make setup` activates them (it sets `git config core.hooksPath .githooks`).

- `commit-msg` rejects a commit whose subject isn't a [Conventional Commit](https://www.conventionalcommits.org): `<type>(<optional scope>): <description>`, with type one of `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `build`, `ci`, `perf`, `revert`, and `!` before the colon for a breaking change. Subjects Git writes itself (merges, reverts, `fixup!`, `squash!`, `amend!`) are accepted.
- `pre-commit` checks the client files you staged: elm-format for Elm files, ESLint (lint and formatting) for TS, JSON, CSS and Markdown files. It only checks, never modifies or re-stages anything. When it fails, run `make fmt`, fix any remaining lint error by hand, and stage the files again. It checks the working-tree copy of each staged file, so stage whole files rather than parts of them. Problems in files you didn't stage don't block the commit.

`git commit --no-verify` skips both hooks. CI still runs the format and lint checks on the whole client, and checks the PR title.

## Continuous integration

GitHub Actions runs on every pull request and every push to `main`. The `client` job runs only when client files, CI configuration or the root `Makefile` change. The `repo` job runs on every change: it lints the workflows with actionlint and, on pull requests, checks that the PR title is a [Conventional Commit](https://www.conventionalcommits.org) (`<type>(<optional scope>): <description>`, with the same types as the commit-msg hook), because squash merges turn the title into the commit on `main`. The `ci-ok` job always runs and is the single status to require.

Every action is pinned by full commit SHA with the version in a trailing comment (Docker actions: `docker://image:<version>@sha256:<digest>`). Keep it that way when adding or updating an action.
