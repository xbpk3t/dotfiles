import { describe, expect, it } from "vitest";
import { buildInjectedCleanerSource, isFlomoMineUrl } from "./flomo";

describe("isFlomoMineUrl", () => {
  it("accepts flomo mine urls", () => {
    expect(isFlomoMineUrl("https://v.flomoapp.com/mine")).toBe(true);
    expect(isFlomoMineUrl("https://v.flomoapp.com/mine?foo=1")).toBe(true);
  });

  it("rejects non-mine urls", () => {
    expect(isFlomoMineUrl("https://v.flomoapp.com/notes")).toBe(false);
    expect(isFlomoMineUrl("https://example.com/mine")).toBe(false);
  });
});

describe("buildInjectedCleanerSource", () => {
  it("builds a self-contained page-context script with probe and run modes", () => {
    const probeSource = buildInjectedCleanerSource("probe");
    const runSource = buildInjectedCleanerSource("run");

    expect(probeSource).toContain("flomo 清空脚本");
    expect(probeSource).toContain('"probe"');
    expect(runSource).toContain('"run"');
    expect(probeSource).toContain("data-flomo-cleaner-root");
    expect(probeSource).toContain("data-flomo-cleaner-state");
    expect(probeSource).toContain("openSelectMode");
    expect(probeSource).toContain("selectAllNotes");
    expect(probeSource).toContain("clickDelete");
  });
});
