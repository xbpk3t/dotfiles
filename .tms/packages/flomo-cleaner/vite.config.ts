import { defineConfig } from "vite";
import monkey from "vite-plugin-monkey";

export default defineConfig({
  plugins: [
    monkey({
      entry: "src/main.ts",
      userscript: {
        name: "Flomo Cleaner",
        namespace: "https://github.com/luck/dotfiles",
        version: "0.1.0",
        description: "Tampermonkey migration of flomo-cleaner.",
        match: ["https://v.flomoapp.com/mine*"],
        "run-at": "document-end",
        grant: ["GM_registerMenuCommand", "unsafeWindow"],
      },
      build: {
        fileName: "flomo-cleaner.user.js",
      },
    }),
  ],
});
