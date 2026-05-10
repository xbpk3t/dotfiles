import { buildInjectedCleanerSource, isFlomoMineUrl } from "./flomo";

type CleanerMode = "probe" | "run";
type CleanerResult = {
  ok: boolean;
  mode?: CleanerMode;
  state: string;
  message: string;
  remainingDomMemos: number;
};

type FlomoCleanerApi = {
  probe: () => Promise<CleanerResult>;
  run: () => Promise<CleanerResult>;
};

declare global {
  interface Window {
    __flomoCleaner?: FlomoCleanerApi;
  }

  const GM_registerMenuCommand:
    | undefined
    | ((
        name: string,
        callback: () => void,
        options?: { accessKey?: string; autoClose?: boolean; title?: string },
      ) => void);

  const unsafeWindow: Window | undefined;
}

const finalStates = new Set([
  "probe-ready",
  "done",
  "idle",
  "cancelled",
  "error",
]);

function injectPageScript(source: string): void {
  const script = document.createElement("script");
  script.textContent = source;
  document.documentElement.append(script);
  script.remove();
}

function readResult(state: string): CleanerResult {
  const root = document.querySelector<HTMLElement>("[data-flomo-cleaner-root]");
  const message = root?.dataset.flomoCleanerMessage ?? state;

  return {
    ok: state !== "error" && state !== "cancelled",
    mode: state === "probe-ready" ? "probe" : undefined,
    state,
    message,
    remainingDomMemos: document.querySelectorAll(".memo").length,
  };
}

async function waitForFinalState(timeoutMs = 120_000): Promise<CleanerResult> {
  const startedAt = Date.now();

  while (Date.now() - startedAt < timeoutMs) {
    const root = document.querySelector<HTMLElement>(
      "[data-flomo-cleaner-root]",
    );
    const state = root?.dataset.flomoCleanerState;

    if (state && finalStates.has(state)) {
      const result = readResult(state);
      if (state === "error") {
        throw new Error(result.message);
      }
      return result;
    }

    await new Promise((resolve) => setTimeout(resolve, 250));
  }

  throw new Error("flomo-cleaner timed out waiting for final state");
}

async function invokeMode(mode: CleanerMode): Promise<CleanerResult> {
  if (!isFlomoMineUrl(location.href)) {
    throw new Error(`当前页面不是 flomo mine: ${location.href}`);
  }

  injectPageScript(buildInjectedCleanerSource(mode));
  const result = await waitForFinalState();
  return mode === "probe" ? { ...result, mode: "probe" } : result;
}

const api: FlomoCleanerApi = {
  probe: () => invokeMode("probe"),
  run: () => invokeMode("run"),
};

window.__flomoCleaner = api;
if (typeof unsafeWindow !== "undefined") {
  unsafeWindow.__flomoCleaner = api;
}

if (typeof GM_registerMenuCommand === "function") {
  GM_registerMenuCommand(
    "清空当前 flomo 笔记",
    () => {
      void api.run().catch((error: unknown) => {
        const message = error instanceof Error ? error.message : String(error);
        console.error("[flomo-cleaner]", error);
        window.alert(`flomo 清空失败：${message}`);
      });
    },
    {
      accessKey: "c",
      autoClose: true,
      title: "删除当前 flomo 列表中的全部笔记并移入回收站",
    },
  );
}
