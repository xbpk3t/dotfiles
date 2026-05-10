import { chromium, type BrowserContext, type Page } from "@playwright/test";
import { spawnSync } from "node:child_process";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { persistentChromeOptions } from "./helpers/chrome";

const profileDir = path.resolve(".e2e/chrome-profile");
const userscriptPath = path.resolve(
  "packages/flomo-cleaner/dist/flomo-cleaner.user.js",
);
const tampermonkeyExtensionId = "dhdgffkkebhmkfjojejmpbldmpobfkfo";
const userscriptInstallUrl = "http://127.0.0.1:8899/flomo-cleaner.user.js";

type InstallResult = {
  lastError?: string | null;
  response?: {
    success?: boolean;
    items?: unknown;
    error?: unknown;
  };
};

type ScriptItem = {
  uuid?: string;
  name?: string;
  enabled?: boolean;
  matches?: string[];
};

type MessageResult = {
  lastError?: string | null;
  response?: {
    success?: boolean;
    installed?: boolean;
    items?: unknown;
    error?: unknown;
  };
};

function buildUserscript(): void {
  const result = spawnSync(
    "pnpm",
    ["--dir", "packages/flomo-cleaner", "build"],
    {
      stdio: "inherit",
      env: { ...process.env, PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD: "1" },
    },
  );

  if (result.status !== 0) {
    throw new Error("Failed to build flomo-cleaner userscript");
  }
}

function findInstalledScript(value: unknown): ScriptItem | null {
  if (Array.isArray(value)) {
    for (const item of value) {
      const found = findInstalledScript(item);
      if (found) {
        return found;
      }
    }
    return null;
  }

  if (!value || typeof value !== "object") {
    return null;
  }

  const record = value as Record<string, unknown>;
  if (record.name === "Flomo Cleaner") {
    return {
      uuid: typeof record.uuid === "string" ? record.uuid : undefined,
      name: typeof record.name === "string" ? record.name : undefined,
      enabled: typeof record.enabled === "boolean" ? record.enabled : undefined,
      matches: Array.isArray(record.matches)
        ? record.matches.filter(
            (item): item is string => typeof item === "string",
          )
        : undefined,
    };
  }

  for (const child of Object.values(record)) {
    const found = findInstalledScript(child);
    if (found) {
      return found;
    }
  }

  return null;
}

async function sendTampermonkeyMessage<T>(
  page: Page,
  message: unknown,
): Promise<MessageResult> {
  return await page.evaluate<MessageResult, unknown>(async (message) => {
    const runtime = (
      globalThis as unknown as {
        chrome?: {
          runtime?: {
            lastError?: { message?: string };
            sendMessage: (
              message: unknown,
              callback: (response: unknown) => void,
            ) => void;
          };
        };
      }
    ).chrome?.runtime;

    if (!runtime) {
      return {
        lastError:
          "chrome.runtime is unavailable on the Tampermonkey options page",
      };
    }

    return await new Promise<MessageResult>((resolve) => {
      const timer = setTimeout(
        () =>
          resolve({ lastError: "Timed out waiting for Tampermonkey response" }),
        15_000,
      );
      runtime.sendMessage(message, (response: unknown) => {
        clearTimeout(timer);
        resolve({
          response: response as T,
          lastError: runtime.lastError?.message ?? null,
        });
      });
    });
  }, message);
}

async function installUserscript(context: BrowserContext): Promise<void> {
  const source = await readFile(userscriptPath, "utf8");
  const page = await context.newPage();

  await page.goto(
    `chrome-extension://${tampermonkeyExtensionId}/options.html`,
    { waitUntil: "domcontentloaded" },
  );
  await page.waitForTimeout(2_000);

  const mode = await sendTampermonkeyMessage(page, {
    method: "setOption",
    name: "runtime_content_mode",
    value: "userscripts-dynamic",
  });
  if (mode.lastError) {
    throw new Error(
      `Tampermonkey runtime_content_mode setup failed: ${mode.lastError}`,
    );
  }

  const tree = await sendTampermonkeyMessage(page, {
    method: "loadTree",
    referrer: "options.scripts",
  });
  if (tree.lastError) {
    throw new Error(`Tampermonkey loadTree failed: ${tree.lastError}`);
  }

  const current = findInstalledScript(tree.response?.items);
  const result = current?.uuid
    ? await sendTampermonkeyMessage<InstallResult["response"]>(page, {
        method: "saveScript",
        uuid: current.uuid,
        name: "Flomo Cleaner",
        code: source,
        force_url: userscriptInstallUrl,
        reload: true,
      })
    : await sendTampermonkeyMessage<InstallResult["response"]>(page, {
        method: "buttonPress",
        name: "installFromUrl",
        data: { url: userscriptInstallUrl, source },
      });

  await page.close();

  if (result.lastError) {
    throw new Error(`Tampermonkey install failed: ${result.lastError}`);
  }

  if (!result.response?.success && !result.response?.installed) {
    throw new Error(
      `Tampermonkey install failed: ${JSON.stringify(result.response ?? {})}`,
    );
  }

  const installed = findInstalledScript(result.response.items);
  if (
    !installed?.enabled ||
    !installed.matches?.includes("https://v.flomoapp.com/mine*")
  ) {
    throw new Error(
      `Tampermonkey install did not return an enabled Flomo Cleaner script: ${JSON.stringify(installed)}`,
    );
  }

  console.log(
    `Installed userscript in Tampermonkey: ${installed.name} (${installed.matches.join(", ")})`,
  );
}

async function tryLogin(page: Page): Promise<boolean> {
  const email = process.env.FLOMO_EMAIL;
  const password = process.env.FLOMO_PASSWORD;

  const emailInput = page
    .locator(
      'input[type="email"], input[type="text"], input[name="email"], input[placeholder*="手机号"], input[placeholder*="邮箱"], input[placeholder*="Email"], input[placeholder*="email"]',
    )
    .first();
  const passwordInput = page
    .locator(
      'input[type="password"], input[name="password"], input[placeholder*="密码"], input[placeholder*="Password"], input[placeholder*="password"]',
    )
    .first();

  const loginFormVisible = await passwordInput
    .isVisible({ timeout: 10_000 })
    .catch(() => false);
  if (!loginFormVisible) {
    console.log(
      "Login form not detected; assuming the profile is already logged into flomo.",
    );
    return true;
  }

  if (!email || !password) {
    console.log(
      "FLOMO_EMAIL/FLOMO_PASSWORD not set; complete login manually in the opened browser.",
    );
    return false;
  }

  await emailInput.waitFor({ state: "visible", timeout: 10_000 });
  await emailInput.fill(email);
  await passwordInput.fill(password);

  const submit = page
    .getByRole("button", { name: /登录|登陆|login|sign in/i })
    .first();
  if (await submit.isVisible({ timeout: 3_000 }).catch(() => false)) {
    await submit.click();
  } else {
    await passwordInput.press("Enter");
  }

  await page.waitForLoadState("networkidle").catch(() => undefined);
  return true;
}

async function main(): Promise<void> {
  buildUserscript();

  const context = await chromium.launchPersistentContext(
    profileDir,
    persistentChromeOptions,
  );
  try {
    await installUserscript(context);

    const flomoPage = await context.newPage();
    await flomoPage.goto("https://v.flomoapp.com/mine", {
      waitUntil: "domcontentloaded",
    });
    await flomoPage.waitForLoadState("networkidle").catch(() => undefined);
    const ready = await tryLogin(flomoPage);

    if (!ready) {
      console.log(
        "Complete first-time flomo login in the opened Chrome profile, then close the browser window.",
      );
      await new Promise<void>((resolve) => context.once("close", resolve));
      return;
    }

    await context.close();
  } catch (error) {
    await context.close().catch(() => undefined);
    throw error;
  }
}

void main();
