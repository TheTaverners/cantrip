import stylistic from "@stylistic/eslint-plugin";
import { defineConfig, globalIgnores } from "eslint/config";
import tseslint from "typescript-eslint";

// Formatting rules only. `npm run fmt-check` runs this config on its own, so
// that a formatting check never fails on a lint error. eslint.config.ts
// includes it too, so `npm run fmt` (eslint --fix) applies both.
export const ignores = ["dist/", "**/elm-stuff/", "package-lock.json"];

export const formatting = defineConfig({
  files: ["**/*.ts"],
  languageOptions: { parser: tseslint.parser },
  extends: [stylistic.configs.customize({ quotes: "double", semi: true })],
});

export default defineConfig(globalIgnores(ignores), formatting);
