import { defineConfig, devices } from "@playwright/test";

// Browser tests run against the production bundle served by `vite preview`,
// never the dev server. WebKit stands in for Safari on the table's iPad.
const port = 4173;
const baseURL = `http://localhost:${String(port)}`;
const isCi = process.env["CI"] !== undefined;

export default defineConfig({
  testDir: "./e2e",
  forbidOnly: isCi,
  retries: isCi ? 2 : 0,
  reporter: [["html", { open: "never" }], isCi ? ["github"] : ["list"]],
  use: { baseURL, trace: "on-first-retry" },
  projects: [
    { name: "chromium", use: { ...devices["Desktop Chrome"] } },
    { name: "webkit", use: { ...devices["Desktop Safari"] } },
  ],
  webServer: {
    command: `npm run build && npm run preview -- --port ${String(port)} --strictPort`,
    url: baseURL,
    // Always build and serve afresh, so a stray dev server is never tested.
    reuseExistingServer: false,
  },
});
