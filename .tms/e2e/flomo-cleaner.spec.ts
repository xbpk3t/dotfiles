import { chromium, expect, test } from "@playwright/test";

declare global {
  interface Window {
    __flomoCleaner?: {
      probe: () => Promise<{ ok: boolean; mode: "probe"; message: string }>;
      run: () => Promise<{ ok: boolean; message: string }>;
    };
  }
}
import path from "node:path";
import { persistentChromeOptions } from "./helpers/chrome";

const profileDir = path.resolve(".e2e/chrome-profile");

async function openLoggedInFlomoPage() {
  const context = await chromium.launchPersistentContext(
    profileDir,
    persistentChromeOptions,
  );
  const page = await context.newPage();
  const logs: string[] = [];
  page.on("console", (msg) => logs.push(`[${msg.type()}] ${msg.text()}`));

  await page.goto("https://v.flomoapp.com/mine", {
    waitUntil: "domcontentloaded",
  });
  await page.waitForLoadState("networkidle");

  const loginFormVisible = await page
    .locator('input[type="password"]')
    .first()
    .isVisible({ timeout: 2_000 })
    .catch(() => false);

  return { context, page, logs, loginFormVisible };
}

async function publishMemo(
  page: Awaited<ReturnType<typeof openLoggedInFlomoPage>>["page"],
  content: string,
): Promise<void> {
  const editor = page.locator(".tiptap.ProseMirror").first();
  await expect(editor).toBeVisible();
  await editor.click();
  await page.keyboard.insertText(content);
  await page.keyboard.press("Meta+Enter");

  if (
    !(await page
      .getByText(content, { exact: false })
      .first()
      .isVisible({ timeout: 5_000 })
      .catch(() => false))
  ) {
    await page.keyboard.press("Control+Enter");
  }

  await expect(page.getByText(content, { exact: false }).first()).toBeVisible({
    timeout: 15_000,
  });
}

test("flomo-cleaner exposes the Tampermonkey menu automation hook", async () => {
  const { context, page, logs, loginFormVisible } =
    await openLoggedInFlomoPage();
  test.skip(
    loginFormVisible,
    "Run `task setup:flomo-profile` first so the persistent profile is logged into flomo.",
  );

  const probeResult = await page.evaluate(async () => {
    const cleaner = window.__flomoCleaner;
    if (!cleaner) {
      throw new Error("userscript hook missing: window.__flomoCleaner");
    }

    return await cleaner.probe();
  });

  expect(probeResult).toMatchObject({
    ok: true,
    mode: "probe",
    message: "probe-ready",
  });
  expect(logs.some((line) => line.includes("[flomo-cleaner]"))).toBeTruthy();

  await context.close();
});

test("destructive: flomo-cleaner publishes a memo and clears the current list", async () => {
  test.skip(
    process.env.FLOMO_CLEANER_ALLOW_DESTRUCTIVE !== "1",
    "Set FLOMO_CLEANER_ALLOW_DESTRUCTIVE=1 to run the destructive cleaner flow.",
  );

  const { context, page, loginFormVisible } = await openLoggedInFlomoPage();
  test.skip(
    loginFormVisible,
    "Run `task setup:flomo-profile` first so the persistent profile is logged into flomo.",
  );

  const testMemo = `flomo-cleaner-e2e-${Date.now()}`;
  await publishMemo(page, testMemo);

  page.on("dialog", (dialog) => dialog.accept());

  const result = await page.evaluate(async () => {
    const cleaner = window.__flomoCleaner;
    if (!cleaner) {
      throw new Error("userscript hook missing: window.__flomoCleaner");
    }

    return await cleaner.run();
  });

  expect(result.ok).toBe(true);

  await page.reload({ waitUntil: "domcontentloaded" });
  await page.waitForLoadState("networkidle");
  await expect(page.getByText(testMemo, { exact: false })).toHaveCount(0, {
    timeout: 30_000,
  });
  await expect(page.locator(".memo")).toHaveCount(0, { timeout: 30_000 });

  await context.close();
});
