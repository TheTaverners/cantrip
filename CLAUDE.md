# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project layout

Monorepo. Deployable components live under `apps/` (only `apps/client`, an Elm 0.19.3 SPA built with Vite, exists today). The root stays language-agnostic: no root `package.json`, only the `Makefile`, `Brewfile`, `renovate.json`, `.editorconfig` and `.gitignore`. CI lives in `.github/workflows/ci.yml`; the client jobs share their setup (Node, npm and Elm caches, `npm ci`) through the local composite action `.github/actions/setup-client`.

## Commands

Run from the repo root. `dev`, `fmt`, `fmt-check`, `lint`, `test`, `e2e` and `build` each delegate to the same-named npm script in `apps/client` (run `npm run <script>` there for the same thing). The others don't: `setup` and `setup-hooks` install tools and configure git, `lint-workflows` runs actionlint, `test-hooks` runs a bash script, and `check` chains other targets.

- `make setup`: `brew bundle` (Brewfile), then `npm ci` in the client, then the Playwright Chromium and WebKit browsers (`npm run e2e:install`), then `make setup-hooks`.
- `make setup-hooks`: `git config core.hooksPath .githooks`. Worktrees share git config, so this affects every checkout of the repo.
- `make dev`: Vite dev server on http://localhost:5173 (`npm run dev`).
- `make build`: production bundle in `apps/client/dist`, Elm compiled with `--optimize` (`npm run build`).
- `make fmt`: elm-format on every Elm file, then ESLint fixes on the non-Elm files (`npm run fmt`).
- `make fmt-check`: fail on unformatted Elm files, or on ESLint formatting rules (`eslint.format.config.ts`) (`npm run fmt-check`).
- `make lint`: elm-review with the jfmengels application rules, config in `apps/client/review/`; then ESLint on TS/JSON/CSS/Markdown; then `tsc --noEmit` (`npm run lint`). `npx elm-review --fix` in `apps/client` applies automatic fixes; `npx eslint <path>` lints a single file.
- `make test`: Elm unit and program tests with elm-test-rs (`npm test`). Single file: `cd apps/client && npm test -- tests/RouteTest.elm`. Reproduce a fuzz run with `--seed <n>` from the output.
- `make e2e`: Playwright smoke test (`e2e/smoke.spec.ts`) on Chromium and WebKit against `vite preview` of a fresh production build, which `playwright.config.ts` starts itself (`npm run e2e`). Single test, in `apps/client`: `npx playwright test e2e/smoke.spec.ts`, narrowed with `-g "<test title>"` or `--project=webkit`. HTML report in `apps/client/playwright-report/` (`npx playwright show-report`).
- `make lint-workflows`: actionlint on `.github/workflows/` (installed by the Brewfile; uses shellcheck on `run:` scripts when it is on the PATH). Not an npm script.
- `make test-hooks`: `scripts/test-hooks.sh`, which commits in a throwaway copy of the repo to test both git hooks. Not an npm script. CI's `client` job runs it.
- `make check`: `fmt-check`, `lint`, `test`, `build`, `lint-workflows`, `test-hooks`: everything CI runs except e2e and the PR-title check (CI-only, it needs a pull request). Keep it in sync with the `client` and `repo` jobs.

Git hooks (`.githooks/`, plain bash): `commit-msg` enforces Conventional Commits on the subject (skips Git-generated `Merge `/`Revert `/`fixup! `/`squash! `/`amend! ` subjects); `pre-commit` runs elm-format `--validate` on staged client Elm files and `eslint` on staged client TS/JSON/CSS/Markdown files. It is check-only (never modifies or re-stages) and checks the staged content (index blobs piped to the tools via stdin), not the working-tree copy.

CI jobs: `changes`, path-filtered `client` and `client-e2e` (needs `client`; uploads the Playwright report artifact on failure), unfiltered `repo` (actionlint, plus the PR-title Conventional Commits check on pull requests, whose regex must stay identical to the commit-msg hook's), and the `ci-ok` aggregator; add every new job to `ci-ok.needs`. Pin every third-party `uses:` (in workflows and in `.github/actions/`) by full commit SHA with the version in a trailing comment (`docker://` images: `image:<version>@sha256:<digest>`).

Each aggregate script chains per-tool scripts: `fmt:elm`/`fmt:eslint`, `fmt-check:elm`/`fmt-check:eslint`, `lint:elm`/`lint:eslint`/`lint:tsc`.

Elm test dependencies are edited by hand in `apps/client/elm.json` (`test-dependencies`); elm-json is broken on Elm 0.19.3. Client architecture (Route, pages, Effect pattern) is described in `apps/client/README.md`.

Renovate (`renovate.json`) groups weekly updates and automerges non-major devDependency updates. When editing it, validate with `npx --yes --package renovate@44.149.1 -- renovate-config-validator --strict` from the repo root (not a dependency, not in `make check`). Keep the `typescript` `allowedVersions` cap in sync with typescript-eslint's peer range. Elm packages in `elm.json` aren't managed by Renovate; bump them by hand.

TypeScript (the bootstrap `src/main.ts`, the Playwright tests in `e2e/` and the `*.ts` config files) uses the strictest tsconfig; every linted `.ts` file must be in its `include`. The Elm entry point is typed by hand in `src/elm.d.ts`: update it when `Main` gains flags or ports. ESLint is the only formatter for non-Elm files (no Prettier): double quotes, semicolons, 2-space indent. Type assertions (`as`) are banned.

Node is pinned by the `volta` field in `apps/client/package.json`; CI reads the same pin. npm deps are saved exact (`apps/client/.npmrc`).

## Agent skills layout

Agent skills are vendored from `mattpocock/skills`:

- `.agents/skills/<name>/` holds the actual skill files (`SKILL.md` plus supporting docs; `agents/openai.yaml` is for non-Claude agents).
- `.claude/skills/<name>` is a **symlink** to `../../.agents/skills/<name>`. Edit the files under `.agents/skills/`, never the symlinks, and add a matching symlink when you add a skill.
- `skills-lock.json` pins each skill's upstream source path and content hash. Editing a vendored skill locally makes its hash stale, so change skills deliberately.

Several engineering skills (`triage`, `to-tickets`, `to-spec`, `domain-modeling`, …) expect per-repo config (issue tracker, triage labels, `GLOSSARY.md` / `docs/adr/` layout) under `docs/agents/`, summarised in the `## Agent skills` section below. Edit those files directly; re-run `setup-matt-pocock-skills` only to switch issue trackers or start over.

## Agent skills

### Issue tracker

Issues live in GitHub Issues on `TheTaverners/cantrip`, managed with the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

Default vocabulary: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: one root `GLOSSARY.md` plus `docs/adr/`, both created when first needed. See `docs/agents/domain.md`.
