// Hand-written types for the Elm entry point compiled by vite-plugin-elm.
// Main takes no flags and declares no ports yet: widen these types when it
// does (elm-ts-interop is tracked in #3).
declare module "*.elm" {
  interface ElmApp {
    readonly ports: Readonly<Record<string, never>>;
  }

  interface InitOptions {
    readonly node: HTMLElement;
  }

  export const Elm: {
    readonly Main: {
      readonly init: (options: InitOptions) => ElmApp;
    };
  };
}
