import { expect, test } from "@playwright/test";

test("home page lists the Games", async ({ page }) => {
  await page.goto("/");

  await expect(page).toHaveTitle("Cantrip");
  await expect(page.getByRole("listitem").getByRole("link")).toHaveText([
    "The Sunken Crypt",
    "Market Day in Brindle",
  ]);
});
