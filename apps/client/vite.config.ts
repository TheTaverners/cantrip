import { defineConfig } from "vite";
import elmPlugin from "vite-plugin-elm";

export default defineConfig(({ command }) => {
  const isBuild = command === "build";

  return {
    plugins: [
      // Production builds compile Elm with --optimize; the dev server keeps
      // the Elm time-travelling debugger instead.
      elmPlugin({ debug: !isBuild, optimize: isBuild }),
    ],
  };
});
