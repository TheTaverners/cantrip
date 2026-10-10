import css from "@eslint/css";
import js from "@eslint/js";
import json from "@eslint/json";
import markdown from "@eslint/markdown";
import { defineConfig, globalIgnores } from "eslint/config";
import tseslint from "typescript-eslint";
import { formatting, ignores } from "./eslint.format.config";

// ESLint is the only formatter and linter for the client's non-Elm files.
// TypeScript is linted and formatted; JSON, CSS and Markdown are linted only
// (their whitespace formatting is not enforced).
export default defineConfig(
  globalIgnores(ignores),
  {
    files: ["**/*.ts"],
    extends: [
      js.configs.recommended,
      tseslint.configs.strictTypeChecked,
      tseslint.configs.stylisticTypeChecked,
    ],
    languageOptions: {
      parserOptions: {
        projectService: true,
        tsconfigRootDir: import.meta.dirname,
      },
    },
    rules: {
      // Type assertions silence the checker: type the value instead.
      "@typescript-eslint/consistent-type-assertions": ["error", { assertionStyle: "never" }],
    },
  },
  formatting,
  {
    files: ["**/*.json"],
    ignores: ["tsconfig.json"],
    language: "json/json",
    extends: [json.configs.recommended],
  },
  {
    // tsconfig.json allows comments and trailing commas.
    files: ["tsconfig.json"],
    language: "json/jsonc",
    extends: [json.configs.recommended],
  },
  {
    files: ["**/*.css"],
    language: "css/css",
    extends: [css.configs.recommended],
  },
  {
    files: ["**/*.md"],
    language: "markdown/gfm",
    extends: [markdown.configs.recommended],
  },
);
