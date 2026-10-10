import { expect, test } from "@playwright/test";

test("home page greets the table", async ({ page }) => {
  await page.goto("/");

  await expect(page).toHaveTitle("Cantrip");
  await expect(page.getByText("Hello, World")).toBeVisible();
});
