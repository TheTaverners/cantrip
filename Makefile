# Cantrip task interface.
#
# A thin, language-agnostic layer: each target delegates to the components
# under apps/. Keep it compatible with GNU Make 3.81 (the macOS default).

CLIENT_DIR := apps/client

.DEFAULT_GOAL := help

.PHONY: help setup dev fmt fmt-check lint build lint-workflows check

help: ## List the available targets
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*## "}; {printf "  %-16s %s\n", $$1, $$2}'

setup: ## Install machine tools (Homebrew bundle) and project dependencies
	@command -v brew >/dev/null 2>&1 || { \
		echo "error: Homebrew is required. Install it from https://brew.sh and re-run 'make setup'." >&2; \
		exit 1; }
	brew bundle --file=Brewfile
	@command -v npm >/dev/null 2>&1 || { \
		echo "error: npm is not on your PATH. Run 'volta setup', restart your shell and re-run 'make setup'." >&2; \
		exit 1; }
	cd $(CLIENT_DIR) && npm ci

dev: ## Start the client dev server
	cd $(CLIENT_DIR) && npm run dev

fmt: ## Format all code
	cd $(CLIENT_DIR) && npm run fmt

fmt-check: ## Fail if any file is not formatted
	cd $(CLIENT_DIR) && npm run fmt-check

lint: ## Run static analysis (elm-review)
	cd $(CLIENT_DIR) && npm run lint

build: ## Build the optimised production client bundle
	cd $(CLIENT_DIR) && npm run build

lint-workflows: ## Lint the GitHub Actions workflows with actionlint
	@command -v actionlint >/dev/null 2>&1 || { \
		echo "error: actionlint is not installed. Run 'make setup' (or 'brew install actionlint')." >&2; \
		exit 1; }
	actionlint

check: fmt-check lint build lint-workflows ## Run every check CI runs (except e2e)
