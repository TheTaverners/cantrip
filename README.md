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
| `make setup`          | Install Homebrew tools, npm packages, Playwright browsers and the git hooks.    |
| `make setup-hooks`    | Only activate the versioned git hooks (`git config core.hooksPath .githooks`).  |
| `make dev`            | Start the client dev server on http://localhost:5173.                           |
| `make fmt`            | Format all code (elm-format, ESLint fixes).                                     |
| `make fmt-check`      | Fail if any file is not formatted.                                              |
| `make lint`           | Run elm-review, ESLint (TS, JSON, CSS, Markdown) and the TypeScript type check. |
| `make test`           | Run the Elm unit and program tests (elm-test-rs).                               |
| `make e2e`            | Build the client and run the Playwright smoke test on Chromium and WebKit.      |
| `make build`          | Build the optimised production bundle in `apps/client/dist`.                    |
| `make lint-workflows` | Lint the GitHub Actions workflows with actionlint.                              |
| `make test-hooks`     | Test the git hooks in a throwaway copy of the repository.                       |
| `make check`          | Run every check CI runs (except browser tests), plus the hook tests.            |

Run `make` (or `make help`) to list the targets.

`make e2e` serves the production build with `vite preview` (never the dev server); WebKit stands in for Safari. To run a single Playwright test, from `apps/client`: `npx playwright test e2e/smoke.spec.ts`, narrowed with `-g "<test title>"` or `--project=webkit`. After a failure, `npx playwright show-report` opens the HTML report.

## Git hooks

The hooks live in [`.githooks/`](.githooks) and `make setup` activates them (it sets `git config core.hooksPath .githooks`).

- `commit-msg` rejects a commit whose subject isn't a [Conventional Commit](https://www.conventionalcommits.org): `<type>(<optional scope>): <description>`, with type one of `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `build`, `ci`, `perf`, `revert`, and `!` before the colon for a breaking change. Subjects Git writes itself (merges, reverts, `fixup!`, `squash!`, `amend!`) are accepted.
- `pre-commit` checks the client files you staged: elm-format for Elm files, ESLint (lint and formatting) for TS, JSON, CSS and Markdown files. It only checks, never modifies or re-stages anything. When it fails, run `make fmt`, fix any remaining lint error by hand, and stage the files again. It checks the staged content, so a partially staged file is judged on what you are committing. Problems in files you didn't stage don't block the commit.

`git commit --no-verify` skips both hooks. CI still runs the format and lint checks on the whole client, and checks the PR title.

## Continuous integration

GitHub Actions runs on every pull request and every push to `main`. The `client` job sets up the client through the shared `.github/actions/setup-client` action and runs `make fmt-check lint test build test-hooks`. It runs only when client files, CI configuration (workflows and local actions), the git hooks, `scripts/` or the root `Makefile` change; so does `client-e2e`, which runs after it, installs Chromium and WebKit, runs `make e2e`, and uploads the Playwright HTML report as the `playwright-report` artifact when it fails. The `repo` job runs on every change: it lints the workflows with actionlint and, on pull requests, checks that the PR title is a [Conventional Commit](https://www.conventionalcommits.org) (`<type>(<optional scope>): <description>`, with the same types as the commit-msg hook), because squash merges turn the title into the commit on `main`. The `ci-ok` job always runs and is the single status to require.

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
