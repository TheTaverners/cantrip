#!/usr/bin/env bash
# Tests the versioned git hooks (.githooks/) end to end, by committing in a
# throwaway copy of this repository. Needs the client's npm dependencies
# (`make setup`). Run it with `make test-hooks`.

set -uo pipefail

ROOT=$(git rev-parse --show-toplevel)
CLIENT_MODULES="$ROOT/apps/client/node_modules"

if [[ ! -d $CLIENT_MODULES ]]; then
    echo "error: $CLIENT_MODULES is missing. Run 'make setup' first." >&2
    exit 1
fi

SANDBOX=$(mktemp -d)
trap 'rm -rf "$SANDBOX"' EXIT

FAILURES=0
pass() { echo "ok   - $1"; }
fail() {
    echo "FAIL - $1"
    FAILURES=$((FAILURES + 1))
}

# Copy the repository's current files (committed or not, minus ignored ones)
# into a fresh repository with a single commit.
REPO="$SANDBOX/repo"
mkdir "$REPO"
(cd "$ROOT" && git ls-files -co --exclude-standard -z) |
    (cd "$ROOT" && tar --null -T - -cf -) | tar -xf - -C "$REPO"
cd "$REPO" || exit 1
git init -q -b main
git config user.name "Hook Test"
git config user.email "hook-test@example.invalid"
git config commit.gpgsign false
ln -s "$CLIENT_MODULES" apps/client/node_modules
echo "apps/client/node_modules" >>.git/info/exclude
git add -A
git commit -q --no-verify -m "chore: initial"

# Runs `git commit "$@"`, keeping its output in $OUTPUT and returning its status.
try_commit() {
    OUTPUT=$(git commit "$@" 2>&1)
}

# A fingerprint of the working tree and the index, to prove a hook left them alone.
snapshot() {
    {
        git status --porcelain=v1 --untracked-files=all
        git diff --cached --binary
        git diff --binary
        git ls-files -o --exclude-standard -z | xargs -0 shasum
    } | shasum
}

# Puts back the state of the last commit, dropping any test file.
reset_sandbox() {
    git reset -q --hard
    git clean -q -fd
}

# --- make setup: hooks are activated -----------------------------------------

make -s setup-hooks >/dev/null
if [[ $(git config core.hooksPath) == ".githooks" ]]; then
    pass "make setup-hooks sets core.hooksPath to .githooks"
else
    fail "make setup-hooks sets core.hooksPath to .githooks (got '$(git config core.hooksPath)')"
fi

# --- commit-msg ---------------------------------------------------------------

if try_commit --allow-empty -m "update stuff"; then
    fail "subject 'update stuff' is rejected"
elif [[ $OUTPUT == *"Conventional Commits"* ]]; then
    pass "subject 'update stuff' is rejected"
else
    fail "subject 'update stuff' is rejected with an explanation (got: $OUTPUT)"
fi

if try_commit --allow-empty -m "feat(client): add route"; then
    pass "subject 'feat(client): add route' is accepted"
else
    fail "subject 'feat(client): add route' is accepted (got: $OUTPUT)"
fi

if try_commit --allow-empty -m "feat!: drop the old API"; then
    pass "breaking-change subject 'feat!: ...' is accepted"
else
    fail "breaking-change subject 'feat!: ...' is accepted (got: $OUTPUT)"
fi

if try_commit --allow-empty --fixup HEAD; then
    pass "fixup commit is accepted"
else
    fail "fixup commit is accepted (got: $OUTPUT)"
fi

git switch -q -c topic
git commit -q --allow-empty -m "docs: topic work"
git switch -q main
git commit -q --allow-empty -m "docs: main work"
if OUTPUT=$(git merge --no-ff --no-edit topic 2>&1); then
    pass "merge commit is accepted"
else
    fail "merge commit is accepted (got: $OUTPUT)"
fi

# --- pre-commit ---------------------------------------------------------------

echo "Some notes." >>README.md
git add README.md
if try_commit -m "docs: no client files staged"; then
    pass "commit without client files passes"
else
    fail "commit without client files passes (got: $OUTPUT)"
fi

# Unformatted Elm (a misplaced, over-indented definition).
printf 'module Ugly exposing (x)\nx   =   1\n' >apps/client/src/Ugly.elm
git add apps/client/src/Ugly.elm
before=$(snapshot)
if try_commit -m "feat(client): add ugly module"; then
    fail "staged unformatted Elm file blocks the commit"
elif [[ $OUTPUT == *"make fmt"* ]]; then
    pass "staged unformatted Elm file blocks the commit and points to 'make fmt'"
else
    fail "staged unformatted Elm file points to 'make fmt' (got: $OUTPUT)"
fi
if [[ $(snapshot) == "$before" ]]; then
    pass "blocked Elm commit leaves the working tree and index untouched"
else
    fail "blocked Elm commit leaves the working tree and index untouched"
fi
reset_sandbox

# TS with an ESLint (lint, not formatting) error.
printf 'export const value: any = 1;\n' >apps/client/src/bad.ts
git add apps/client/src/bad.ts
before=$(snapshot)
if try_commit -m "feat(client): add bad module"; then
    fail "staged TS file with an ESLint error blocks the commit"
elif [[ $OUTPUT == *"no-explicit-any"* && $OUTPUT == *"make fmt"* ]]; then
    pass "staged TS file with an ESLint error blocks the commit"
else
    fail "staged TS file with an ESLint error reports the error (got: $OUTPUT)"
fi
if [[ $(snapshot) == "$before" ]]; then
    pass "blocked TS commit leaves the working tree and index untouched"
else
    fail "blocked TS commit leaves the working tree and index untouched"
fi
reset_sandbox

# Unformatted TS (fixable by ESLint): blocked, but not fixed by the hook.
printf "export const greeting = 'hi'\n" >apps/client/src/quotes.ts
git add apps/client/src/quotes.ts
before=$(snapshot)
if try_commit -m "feat(client): add greeting"; then
    fail "staged unformatted TS file blocks the commit"
elif [[ $OUTPUT == *"@stylistic/quotes"* && $OUTPUT == *"make fmt"* ]]; then
    pass "staged unformatted TS file blocks the commit and points to 'make fmt'"
else
    fail "staged unformatted TS file reports the formatting error (got: $OUTPUT)"
fi
if [[ $(snapshot) == "$before" ]]; then
    pass "blocked TS formatting commit leaves the working tree and index untouched"
else
    fail "blocked TS formatting commit leaves the working tree and index untouched"
fi
reset_sandbox

# Problems in files that aren't staged don't block a commit of clean files.
printf 'module Ugly exposing (x)\nx   =   1\n' >apps/client/src/Ugly.elm
printf 'export const value: any = 1;\n' >apps/client/src/bad.ts
echo "x   =   2" >>apps/client/src/Page/NotFound.elm
printf 'module Clean exposing (x)\n\n\nx : Int\nx =\n    1\n' >apps/client/src/Clean.elm
printf 'export const clean = 1;\n' >apps/client/src/clean.ts
git add apps/client/src/Clean.elm apps/client/src/clean.ts
if try_commit -m "feat(client): add clean modules"; then
    pass "unstaged problems in other files don't block the commit"
else
    fail "unstaged problems in other files don't block the commit (got: $OUTPUT)"
fi
expected_status=$' M apps/client/src/Page/NotFound.elm\n?? apps/client/src/Ugly.elm\n?? apps/client/src/bad.ts'
if [[ $(git status --porcelain=v1 --untracked-files=all) == "$expected_status" ]]; then
    pass "passing commit leaves unstaged changes alone"
else
    fail "passing commit leaves unstaged changes alone (got: $(git status --porcelain=v1 --untracked-files=all))"
fi
reset_sandbox

# Partially staged files: the hook checks the staged content, not the
# working-tree copy.
CLEAN_ELM=$'module Partial exposing (x)\n\n\nx : Int\nx =\n    1\n'
UGLY_ELM=$'module Partial exposing (x)\nx   =   1\n'
CLEAN_TS=$'export const partial = 1;\n'
UGLY_TS=$'export const partial: any = 1\n'

printf '%s' "$CLEAN_ELM" >apps/client/src/Partial.elm
printf '%s' "$CLEAN_TS" >apps/client/src/partial.ts
git add apps/client/src/Partial.elm apps/client/src/partial.ts
printf '%s' "$UGLY_ELM" >apps/client/src/Partial.elm
printf '%s' "$UGLY_TS" >apps/client/src/partial.ts
before_tree=$(git diff --binary)
if try_commit -m "feat(client): add partial module"; then
    pass "clean staged content with dirty unstaged changes passes"
else
    fail "clean staged content with dirty unstaged changes passes (got: $OUTPUT)"
fi
if [[ $(git diff --binary) == "$before_tree" ]]; then
    pass "passing partial commit leaves the unstaged changes alone"
else
    fail "passing partial commit leaves the unstaged changes alone"
fi
reset_sandbox

printf '%s' "$UGLY_ELM" >apps/client/src/Partial.elm
git add apps/client/src/Partial.elm
printf '%s' "$CLEAN_ELM" >apps/client/src/Partial.elm
before=$(snapshot)
if try_commit -m "feat(client): add partial module"; then
    fail "unformatted staged Elm with a clean working copy blocks the commit"
elif [[ $OUTPUT == *"apps/client/src/Partial.elm"* && $OUTPUT == *"make fmt"* ]]; then
    pass "unformatted staged Elm with a clean working copy blocks the commit"
else
    fail "unformatted staged Elm with a clean working copy names the file (got: $OUTPUT)"
fi
if [[ $(snapshot) == "$before" ]]; then
    pass "blocked partial Elm commit leaves the working tree and index untouched"
else
    fail "blocked partial Elm commit leaves the working tree and index untouched"
fi
reset_sandbox

printf '%s' "$UGLY_TS" >apps/client/src/partial.ts
git add apps/client/src/partial.ts
printf '%s' "$CLEAN_TS" >apps/client/src/partial.ts
before=$(snapshot)
if try_commit -m "feat(client): add partial module"; then
    fail "staged TS with ESLint errors and a clean working copy blocks the commit"
elif [[ $OUTPUT == *"no-explicit-any"* && $OUTPUT == *"@stylistic/semi"* && $OUTPUT == *"make fmt"* ]]; then
    pass "staged TS with ESLint errors and a clean working copy blocks the commit"
else
    fail "staged TS with ESLint errors and a clean working copy reports them (got: $OUTPUT)"
fi
if [[ $(snapshot) == "$before" ]]; then
    pass "blocked partial TS commit leaves the working tree and index untouched"
else
    fail "blocked partial TS commit leaves the working tree and index untouched"
fi
reset_sandbox

echo
if ((FAILURES > 0)); then
    echo "$FAILURES hook test(s) failed."
    exit 1
fi
echo "All hook tests passed."
