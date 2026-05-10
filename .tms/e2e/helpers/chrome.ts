import type { LaunchPersistentContextOptions } from "@playwright/test";

export const persistentChromeOptions = {
  channel: "chrome",
  headless: false,
  viewport: { width: 1440, height: 1000 },
  ignoreDefaultArgs: ["--disable-extensions"],
} satisfies LaunchPersistentContextOptions;
