# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project state

`cantrip` has no application code, build system, or tests yet. The only commit is an empty initial commit. Don't invent build/lint/test commands. When a toolchain is added, update this file with the real commands, including how to run a single test.

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
