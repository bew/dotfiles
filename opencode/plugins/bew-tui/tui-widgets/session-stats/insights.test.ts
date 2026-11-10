// Tests for the tooltip content builder.

import { describe, expect, test } from "bun:test";
import {
  buildInsights,
  countInsightLines,
  formatCost,
  formatDuration,
  formatCount,
  measureInsightWidth,
} from "./insights";
import type {
  InsightGroup,
  InsightInput,
  InsightLayout,
  InsightRow,
  InsightSection,
  TokenTraffic,
} from "./insights";
import { NO_DCP_SUMMARY } from "./dcp-state";
import { DETAIL_INDENT, LABEL_GAP, LABEL_WIDTH } from "./tooltip-width";
import type { StatsGroup } from "./counts";

// Sentinel for a detail row, which carries no label.
const NO_LABEL = Symbol("no label");

// A stats group with everything at zero, overridden per case.
function makeGroup(overrides: Partial<StatsGroup> = {}): StatsGroup {
  return {
    userMessages: 0,
    assistantMessages: 0,
    toolCalls: 0,
    toolUsage: new Map<string, number>(),
    failures: 0,
    skills: 0,
    skillUsage: new Map<string, number>(),
    reads: 0,
    uniqueReads: 0,
    ...overrides,
  };
}

// A token breakdown with everything at zero, overridden per case.
function makeTraffic(overrides: Partial<TokenTraffic> = {}): TokenTraffic {
  return {
    input: 0,
    output: 0,
    reasoning: 0,
    cacheRead: 0,
    cacheWrite: 0,
    ...overrides,
  };
}

// Tooltip input with neutral defaults, overridden per case.
function makeInput(overrides: Partial<InsightInput> = {}): InsightInput {
  return {
    stats: {
      session: makeGroup(),
      context: makeGroup(),
      timing: { generatingMs: 0, toolsMs: 0 },
      content: [],
      systemPrompt: undefined,
      lastTurn: undefined,
    },
    session: {
      costUsd: 0,
      familyCostUsd: 0,
      subagents: [],
      inputTokens: 0,
      outputTokens: 0,
      reasoningTokens: 0,
      activeReasoningTokens: 0,
      cacheReadTokens: 0,
      cacheWriteTokens: 0,
      createdAt: 0,
      updatedAt: 0,
    },
    contextWindow: undefined,
    dcp: NO_DCP_SUMMARY,
    valueWidth: 50,
    ...overrides,
  };
}

// All rows of every section, flattened for lookup by label.
function rowsOf(sections: readonly InsightSection[]) {
  return sections.flatMap((section) => section.rows);
}

// Plain text of a row, as its coloured runs read.
function textOf(row: InsightRow): string {
  return row.segments.map((segment) => segment.text).join("");
}

// The value of the row with `label`, or undefined when it is absent.
function valueOf(
  sections: readonly InsightSection[],
  label: string,
): string | undefined {
  const row = rowsOf(sections).find((candidate) => candidate.label === label);
  return row === undefined ? undefined : textOf(row);
}

// The rows of the section with `heading`, or none when the section is absent.
function sectionRows(
  group: InsightGroup,
  heading: string,
): readonly InsightRow[] {
  return (
    group.sections.find((section) => section.heading === heading)?.rows ?? []
  );
}

// The row's label, or the detail-row sentinel.
function labelOf(row: InsightRow): string | typeof NO_LABEL {
  return row.label ?? NO_LABEL;
}

// Rows reduced to label and plain text, so colour runs do not affect a
// structural comparison.
function labelledRows(rows: readonly InsightRow[]) {
  return rows.map((row) => ({ label: labelOf(row), value: textOf(row) }));
}

describe("formatCount", () => {
  test("keeps counts below a thousand as-is", () => {
    expect(formatCount(0)).toBe("0");
    expect(formatCount(999)).toBe("999");
  });

  test("shortens thousands to one decimal", () => {
    expect(formatCount(1234)).toBe("1.2k");
    expect(formatCount(12000)).toBe("12k");
  });

  test("keeps one decimal for larger thousands", () => {
    expect(formatCount(215784)).toBe("215.8k");
    expect(formatCount(999_999)).toBe("1000k");
  });

  test("shortens millions", () => {
    expect(formatCount(1_250_000)).toBe("1.3M");
  });
});

describe("formatDuration", () => {
  test("reports seconds", () => {
    expect(formatDuration(45_000)).toBe("45s");
  });

  test("reports minutes", () => {
    expect(formatDuration(119_000)).toBe("1m");
  });

  test("reports hours, with minutes when they matter", () => {
    expect(formatDuration(3_600_000)).toBe("1h");
    expect(formatDuration(8_100_000)).toBe("2h 15m");
  });

  test("reports days", () => {
    expect(formatDuration(90_000_000)).toBe("1d 1h");
  });
});

describe("formatCost", () => {
  test("reports dollars with two decimals", () => {
    expect(formatCost(1.239)).toBe("$1.24");
  });

  test("clamps a sub-cent amount to a rounded figure", () => {
    expect(formatCost(0.005)).toBe("$0.01");
    expect(formatCost(0.004)).toBe("~$0");
  });

  test("reports zero as a plain amount", () => {
    expect(formatCost(0)).toBe("$0.00");
  });
});

describe("tool rows", () => {
  test("reports nothing used as none, with no detail lines", () => {
    const insights = buildInsights(makeInput());

    expect(labelledRows(sectionRows(insights.session, "activity"))).toEqual([
      { label: "tools", value: "none" },
      { label: "skills", value: "0" },
    ]);
  });

  test("reports the total, then the entries, most-used first", () => {
    const insights = buildInsights(
      makeInput({
        stats: {
          session: makeGroup({
            toolCalls: 6,
            toolUsage: new Map([
              ["bash", 1],
              ["read", 3],
              ["edit", 2],
            ]),
          }),
          context: makeGroup(),
          timing: { generatingMs: 0, toolsMs: 0 },
          content: [],
          lastTurn: undefined,
        },
      }),
    );

    expect(labelledRows(sectionRows(insights.session, "activity"))).toEqual([
      { label: "tools", value: "6" },
      { label: NO_LABEL, value: "read 3 · edit 2 · bash 1" },
      { label: "skills", value: "0" },
    ]);
  });

  test("wraps the entries onto further lines at the value width", () => {
    const insights = buildInsights(
      makeInput({
        valueWidth: 20,
        stats: {
          session: makeGroup({
            toolCalls: 6,
            toolUsage: new Map([
              ["bash", 1],
              ["read", 3],
              ["edit", 2],
            ]),
          }),
          context: makeGroup(),
          timing: { generatingMs: 0, toolsMs: 0 },
          content: [],
          lastTurn: undefined,
        },
      }),
    );

    expect(labelledRows(sectionRows(insights.session, "activity")).slice(0, 3)).toEqual([
      { label: "tools", value: "6" },
      { label: NO_LABEL, value: "read 3 · edit 2" },
      { label: NO_LABEL, value: "bash 1" },
    ]);
  });
});

describe("skill rows", () => {
  test("lists the names under the count, most-loaded first", () => {
    const insights = buildInsights(
      makeInput({
        stats: {
          session: makeGroup({
            skills: 4,
            skillUsage: new Map([
              ["coder-ts", 2],
              ["opencode", 1],
              ["text-replace", 1],
            ]),
          }),
          context: makeGroup(),
          timing: { generatingMs: 0, toolsMs: 0 },
          content: [],
          lastTurn: undefined,
        },
      }),
    );

    expect(labelledRows(sectionRows(insights.session, "activity"))).toEqual([
      { label: "tools", value: "none" },
      { label: "skills", value: "4" },
      { label: NO_LABEL, value: "coder-ts · opencode · text-replace" },
    ]);
  });

  test("packs the names onto further lines at the value width", () => {
    const insights = buildInsights(
      makeInput({
        valueWidth: 30,
        stats: {
          session: makeGroup({
            skills: 4,
            skillUsage: new Map([
              ["coder-ts", 2],
              ["opencode", 1],
              ["text-replace", 1],
            ]),
          }),
          context: makeGroup(),
          timing: { generatingMs: 0, toolsMs: 0 },
          content: [],
          lastTurn: undefined,
        },
      }),
    );

    expect(labelledRows(sectionRows(insights.session, "activity"))).toEqual([
      { label: "tools", value: "none" },
      { label: "skills", value: "4" },
      { label: NO_LABEL, value: "coder-ts · opencode" },
      { label: NO_LABEL, value: "text-replace" },
    ]);
  });

  test("says how many skill loads compression removed", () => {
    const insights = buildInsights(
      makeInput({
        stats: {
          session: makeGroup({ skills: 5 }),
          context: makeGroup({ skills: 0 }),
          timing: { generatingMs: 0, toolsMs: 0 },
          content: [],
          lastTurn: undefined,
        },
      }),
    );

    expect(valueOf(insights.context.sections, "skills")).toBe(
      "0 (5 compressed)",
    );
    expect(valueOf(insights.session.sections, "skills")).toBe("5");
  });
});

describe("buildInsights", () => {
  test("names the session and context groups", () => {
    const insights = buildInsights(makeInput());

    expect(insights.session.title).toBe("whole session");
    expect(insights.context.title).toBe("active context");
  });

  test("groups the session rows into general, activity, and subagents", () => {
    const insights = buildInsights(makeInput());

    expect(insights.session.sections.map((section) => section.heading)).toEqual([
      "general",
      "activity",
      "subagents",
    ]);
  });

  test("keeps the context activity and compression when no content is known", () => {
    const insights = buildInsights(makeInput());

    expect(insights.context.sections.map((section) => section.heading)).toEqual([
      "activity",
      "compression",
    ]);
  });

  test("reports the window size, the token traffic, and the wall time", () => {
    const insights = buildInsights(
      makeInput({
        contextWindow: {
          traffic: makeTraffic({
            input: 30_000,
            output: 1_000,
            reasoning: 300,
            cacheRead: 30_000,
            cacheWrite: 1_000,
          }),
          limit: 200_000,
        },
        session: {
          costUsd: 2.5,
          familyCostUsd: 2.5,
          subagents: [],
          inputTokens: 1_200_000,
          outputTokens: 40_000,
          reasoningTokens: 0,
          activeReasoningTokens: 0,
          cacheReadTokens: 500_000,
          cacheWriteTokens: 20_000,
          createdAt: 1_000_000,
          updatedAt: 1_000_000 + 8_100_000,
        },
      }),
    );

    expect(labelledRows(sectionRows(insights.session, "general")).slice(0, 4)).toEqual([
      { label: "cost", value: "$2.50" },
      { label: "tokens", value: "62.3k" },
      { label: NO_LABEL, value: "input 1.2M · output 40k · cache 520k" },
      { label: NO_LABEL, value: "avg cache hit 29% (500k of 1.7M tokens)" },
    ]);
    expect(valueOf(insights.session.sections, "wall time")).toBe("2h 15m");
  });

  test("keeps the token traffic when the window usage is unknown", () => {
    const insights = buildInsights(makeInput());

    expect(labelledRows(sectionRows(insights.session, "general")).slice(0, 3)).toEqual([
      { label: "cost", value: "$0.00" },
      { label: "tokens", value: "" },
      { label: NO_LABEL, value: "input 0 · output 0 · cache 0" },
    ]);
  });

  test("reports thinking and the part still in the active context", () => {
    const insights = buildInsights(
      makeInput({
        session: {
          ...makeInput().session,
          reasoningTokens: 21_662,
          activeReasoningTokens: 6_463,
        },
      }),
    );

    const totals = sectionRows(insights.session, "general");

    expect(labelledRows(totals).slice(2, 4)).toEqual([
      { label: NO_LABEL, value: "input 0 · output 0 · cache 0" },
      { label: NO_LABEL, value: "thinking 21.7k (6.5k active)" },
    ]);
    expect(totals[3]?.segments).toContainEqual({
      text: "6.5",
      tone: ["count", "muted"],
    });
  });

  test("hides the thinking line while the session reported no reasoning", () => {
    const insights = buildInsights(makeInput());

    expect(
      rowsOf(insights.session.sections).some((row) =>
        textOf(row).startsWith("thinking "),
      ),
    ).toBe(false);
  });

  test("lists each subagent with its tokens, purpose, and cost", () => {
    const insights = buildInsights(
      makeInput({
        session: {
          ...makeInput().session,
          subagents: [
            {
              agent: "explore",
              title: "Verify examples",
              tokenTotal: 12_400,
              costUsd: 0.0097,
            },
            { agent: "general", title: "", tokenTotal: 800, costUsd: 0.004 },
          ],
        },
      }),
    );

    const rows = sectionRows(insights.session, "subagents");

    expect(rows.map((row) => textOf(row))).toEqual([
      "2",
      `explore 12.4k ${"Verify examples".padEnd(30)} $0.01`,
      `general   800 ${" ".repeat(30)}   ~$0`,
    ]);
  });

  test("splits a subagent line into an agent, tokens, purpose, and cost", () => {
    const insights = buildInsights(
      makeInput({
        session: {
          ...makeInput().session,
          subagents: [
            {
              agent: "explore",
              title: "Verify examples",
              tokenTotal: 12_400,
              costUsd: 0.0097,
            },
          ],
        },
      }),
    );

    expect(sectionRows(insights.session, "subagents")[1]?.segments).toEqual([
      { text: "explore", tone: "agent" },
      { text: " " },
      { text: "12.4", tone: "count" },
      { text: "k", tone: "count", bold: true },
      { text: " " },
      { text: "Verify examples", tone: "muted" },
      { text: " ".repeat(15) },
      { text: " " },
      { text: "$0.01", tone: "cost" },
    ]);
  });

  test("lines the subagent columns up into shared widths", () => {
    const insights = buildInsights(
      makeInput({
        session: {
          ...makeInput().session,
          subagents: [
            { agent: "a", title: "one", tokenTotal: 1_500, costUsd: 1.2 },
            {
              agent: "explore",
              title: "two",
              tokenTotal: 800_000,
              costUsd: 0.004,
            },
          ],
        },
      }),
    );

    const rows = sectionRows(insights.session, "subagents").slice(1);

    expect(rows.map((row) => textOf(row))).toEqual([
      `a${" ".repeat(7)}1.5k ${"one".padEnd(31)} $1.20`,
      `explore 800k ${"two".padEnd(31)}   ~$0`,
    ]);
    expect(rows.map((row) => textOf(row).length)).toEqual([50, 50]);
  });

  test("cuts a long agent name to its column", () => {
    const insights = buildInsights(
      makeInput({
        session: {
          ...makeInput().session,
          subagents: [
            {
              agent: "a-very-long-agent-name",
              title: "work",
              tokenTotal: 1_000,
              costUsd: 0,
            },
          ],
        },
      }),
    );

    const row = sectionRows(insights.session, "subagents")[1];
    expect(row?.segments?.[0]).toEqual({
      text: "a-very-long…",
      tone: "agent",
    });
    expect(row === undefined ? undefined : textOf(row).length).toBe(50);
  });

  test("cuts a long purpose to the description column", () => {
    const insights = buildInsights(
      makeInput({
        valueWidth: 30,
        session: {
          ...makeInput().session,
          subagents: [
            {
              agent: "explore",
              title: "Verify examples",
              tokenTotal: 12_400,
              costUsd: 0.0097,
            },
          ],
        },
      }),
    );

    expect(
      sectionRows(insights.session, "subagents")[1] === undefined
        ? undefined
        : textOf(sectionRows(insights.session, "subagents")[1]),
    ).toBe(
      "explore 12.4k Verify ex… $0.01",
    );
  });

  test("draws a subagent token total as a count with a bold unit", () => {
    const insights = buildInsights(
      makeInput({
        session: {
          ...makeInput().session,
          subagents: [
            {
              agent: "explore",
              title: "",
              tokenTotal: 123_456,
              costUsd: 0,
            },
          ],
        },
      }),
    );

    expect(
      sectionRows(insights.session, "subagents")[1]?.segments,
    ).toContainEqual({ text: "k", tone: "count", bold: true });
  });

  test("trims a long subagent list into a dearest group and a recent group", () => {
    const subagents = Array.from({ length: 8 }, (_unused, index) => ({
      agent: `s${index}`,
      title: "",
      tokenTotal: 0,
      costUsd: (8 - index) / 100,
    }));
    const insights = buildInsights(
      makeInput({ session: { ...makeInput().session, subagents } }),
    );

    const rows = sectionRows(insights.session, "subagents");

    expect(rows.map((row) => labelOf(row))).toEqual([
      "count",
      "top 3",
      NO_LABEL,
      NO_LABEL,
      NO_LABEL,
      "latest 4",
      NO_LABEL,
      NO_LABEL,
      NO_LABEL,
      NO_LABEL,
    ]);
    expect(labelledRows(rows).slice(0, 2)).toEqual([
      { label: "count", value: "8" },
      { label: "top 3", value: "" },
    ]);
  });

  test("keeps a subagent out of the recent group once it is already listed", () => {
    const costs = [0.01, 0.01, 0.01, 0.01, 0.01, 0.1, 0.2, 0.3];
    const subagents = costs.map((costUsd, index) => ({
      agent: `s${index}`,
      title: "",
      tokenTotal: 0,
      costUsd,
    }));
    const insights = buildInsights(
      makeInput({ session: { ...makeInput().session, subagents } }),
    );

    const rows = sectionRows(insights.session, "subagents");

    expect(rows.map((row) => labelOf(row))).toEqual([
      "count",
      "top 3",
      NO_LABEL,
      NO_LABEL,
      NO_LABEL,
      "latest 4",
      NO_LABEL,
      NO_LABEL,
      NO_LABEL,
      NO_LABEL,
    ]);
    expect(
      rows
        .filter((row) => labelOf(row) === NO_LABEL)
        .map((row) => row.segments?.[0]?.text),
    ).toEqual(["s7", "s6", "s5", "s1", "s2", "s3", "s4"]);
  });

  test("lists every subagent up to the trim limit", () => {
    const subagents = Array.from({ length: 7 }, (_unused, index) => ({
      agent: `s${index}`,
      title: "",
      tokenTotal: 0,
      costUsd: 0.01,
    }));
    const insights = buildInsights(
      makeInput({ session: { ...makeInput().session, subagents } }),
    );

    expect(
      sectionRows(insights.session, "subagents").map((row) => labelOf(row)),
    ).toEqual([
      "count",
      NO_LABEL,
      NO_LABEL,
      NO_LABEL,
      NO_LABEL,
      NO_LABEL,
      NO_LABEL,
      NO_LABEL,
    ]);
  });

  test("shows the session and family cost together once they differ", () => {
    const facts = makeInput().session;
    const alone = buildInsights(makeInput({ session: facts }));
    const family = buildInsights(
      makeInput({
        session: {
          ...facts,
          costUsd: 1.21,
          familyCostUsd: 1.41,
          subagents: [
            {
              agent: "explore",
              title: "Audit",
              tokenTotal: 1_000,
              costUsd: 0.2,
            },
          ],
        },
      }),
    );

    expect(valueOf(alone.session.sections, "cost")).toBe("$0.00");
    expect(valueOf(family.session.sections, "cost")).toBe(
      "$1.21 ($1.41 incl. subagents)",
    );
    expect(
      sectionRows(family.session, "general").find((row) => row.label === "cost")
        ?.segments,
    ).toEqual([
      { text: "$1.21", tone: "cost" },
      { text: " (", tone: "muted" },
      { text: "$1.41", tone: ["cost", "muted"] },
      { text: " incl. subagents", tone: "muted" },
      { text: ")", tone: "muted" },
    ]);
  });

  test("shows busy time with its share and the idle part of the wall time", () => {
    const insights = buildInsights(
      makeInput({
        session: {
          ...makeInput().session,
          createdAt: 1_000,
          updatedAt: 1_000 + 5_400_000,
        },
        stats: {
          session: makeGroup(),
          context: makeGroup(),
          timing: { generatingMs: 3_600_000, toolsMs: 900_000 },
          content: [],
          lastTurn: undefined,
        },
      }),
    );

    const totals = sectionRows(insights.session, "general");
    expect(valueOf(insights.session.sections, "timings")).toBe(
      "1h 15m busy (83%) · 15m idle",
    );
    expect(labelledRows(totals)).toContainEqual({
      label: NO_LABEL,
      value: "1h generating · 15m tools",
    });
  });

  test("hides the working time while nothing has run", () => {
    const insights = buildInsights(makeInput());

    expect(
      rowsOf(insights.session.sections).some((row) =>
        textOf(row).includes("generating"),
      ),
    ).toBe(false);
  });

  test("tones counts, separators, and values apart", () => {
    const insights = buildInsights(
      makeInput({
        stats: {
          session: makeGroup({
            toolCalls: 6,
            toolUsage: new Map([
              ["read", 3],
              ["edit", 2],
            ]),
          }),
          context: makeGroup(),
          timing: { generatingMs: 0, toolsMs: 0 },
          content: [],
          lastTurn: undefined,
        },
      }),
    );

    const rows = sectionRows(insights.session, "activity");
    expect(rows[0]?.segments).toEqual([{ text: "6", tone: "count" }]);
    expect(rows[1]?.segments).toEqual([
      { text: "read" },
      { text: " 3", tone: ["count", "muted"] },
      { text: " · ", tone: "muted" },
      { text: "edit" },
      { text: " 2", tone: ["count", "muted"] },
    ]);
  });

  test("draws shortened token traffic as counts with bold units", () => {
    const insights = buildInsights(
      makeInput({
        session: {
          ...makeInput().session,
          inputTokens: 123_456,
          outputTokens: 4_000_000,
        },
      }),
    );

    const traffic = rowsOf(insights.session.sections).find((row) =>
      textOf(row).startsWith("input "),
    );
    expect(traffic?.segments).toEqual([
      { text: "input " },
      { text: "123.5", tone: "count" },
      { text: "k", tone: "count", bold: true },
      { text: " · ", tone: "muted" },
      { text: "output " },
      { text: "4", tone: "count" },
      { text: "M", tone: "count", bold: true },
      { text: " · ", tone: "muted" },
      { text: "cache " },
      { text: "0", tone: "count" },
    ]);
  });

  test("hides the read and failure rows while nothing used or failed", () => {
    const insights = buildInsights(makeInput());

    expect(valueOf(insights.session.sections, "reads")).toBeUndefined();
    expect(valueOf(insights.session.sections, "failures")).toBeUndefined();
  });

  test("reports reads with their distinct count", () => {
    const insights = buildInsights(
      makeInput({
        stats: {
          session: makeGroup({ reads: 41, uniqueReads: 23 }),
          context: makeGroup(),
          timing: { generatingMs: 0, toolsMs: 0 },
          content: [],
          lastTurn: undefined,
        },
      }),
    );

    expect(valueOf(insights.session.sections, "reads")).toBe("41 (23 unique)");
  });

  test("reports the failure count in the error tone", () => {
    const insights = buildInsights(
      makeInput({
        stats: {
          session: makeGroup({ failures: 2 }),
          context: makeGroup(),
          timing: { generatingMs: 0, toolsMs: 0 },
          content: [],
          lastTurn: undefined,
        },
      }),
    );

    const failures = rowsOf(insights.session.sections).find(
      (row) => row.label === "failures",
    );

    expect(failures?.segments).toEqual([{ text: "2", tone: "error" }]);
  });

  test("reports the window only when the model limit is known", () => {
    const without = buildInsights(makeInput());
    const withoutLimit = buildInsights(
      makeInput({
        contextWindow: {
          traffic: makeTraffic({
            input: 30_000,
            output: 1_000,
            reasoning: 300,
            cacheRead: 30_000,
            cacheWrite: 1_000,
          }),
        },
      }),
    );
    const withUsage = buildInsights(
      makeInput({
        session: {
          ...makeInput().session,
          reasoningTokens: 2_500,
          activeReasoningTokens: 1_000,
        },
        contextWindow: {
          traffic: makeTraffic({
            input: 30_000,
            output: 1_000,
            reasoning: 300,
            cacheRead: 30_000,
            cacheWrite: 1_000,
          }),
          limit: 200_000,
          streamingMs: 26_000,
        },
      }),
    );

    expect(valueOf(without.context.sections, "tokens")).toBeUndefined();
    expect(valueOf(withoutLimit.context.sections, "tokens")).toBeUndefined();
    expect(valueOf(withoutLimit.context.sections, "last step")).toBeUndefined();
    expect(valueOf(withoutLimit.session.sections, "tokens")).toBe("62.3k");
    expect(valueOf(withUsage.context.sections, "tokens")).toBe(
      "62.3k (model limit: 200k)",
    );
    expect(labelledRows(sectionRows(withUsage.context, "general"))).toEqual([
      { label: "tokens", value: "62.3k (model limit: 200k)" },
      { label: NO_LABEL, value: "thinking 2.5k (1k active)" },
      { label: "last step", value: "26s · ~50 tok/s" },
      { label: NO_LABEL, value: "input 30k · output 1k · cache 31k" },
      { label: NO_LABEL, value: "cache hit 49% (30k of 61k tokens)" },
    ]);
    expect(
      sectionRows(withUsage.context, "general")[0]?.segments,
    ).toContainEqual({ text: "k", tone: ["count", "muted"], bold: true });
    expect(
      withUsage.context.sections.map((section) => section.heading),
    ).toEqual(["general", "activity", "compression"]);
  });

  test("apportions the context across content kinds and reports words", () => {
    const insights = buildInsights(
      makeInput({
        contextWindow: {
          traffic: makeTraffic({
            input: 30_000,
            output: 1_000,
            reasoning: 300,
            cacheRead: 30_000,
            cacheWrite: 1_000,
          }),
          limit: 200_000,
        },
        stats: {
          ...makeInput().stats,
          content: [
            { kind: "user", entries: 2, words: 10, characters: 100 },
            { kind: "assistant", entries: 3, words: 20, characters: 200 },
            { kind: "tools", entries: 4, words: 5, characters: 100 },
          ],
        },
      }),
    );

    expect(labelledRows(sectionRows(insights.context, "content"))).toEqual([
      { label: "user", value: "2 msg · ~15.6k (25% ctx) (10 words)" },
      { label: "assistant", value: "3 msg · ~31.1k (50% ctx) (20 words)" },
      { label: "tools", value: "4 calls · ~15.6k (25% ctx) (5 words)" },
    ]);
  });

  test("folds bookkeeping and prompt overhead under the system row", () => {
    const insights = buildInsights(
      makeInput({
        contextWindow: {
          traffic: makeTraffic({
            input: 30_000,
            output: 1_000,
            reasoning: 300,
            cacheRead: 30_000,
            cacheWrite: 1_000,
          }),
          limit: 200_000,
        },
        session: {
          ...makeInput().session,
          systemPrompt: { words: 10, characters: 100 },
          availableSkills: 12,
          availableAgents: 5,
          mcpServers: 2,
        },
        stats: {
          ...makeInput().stats,
          content: [
            { kind: "user", entries: 2, words: 10, characters: 100 },
            { kind: "assistant", entries: 3, words: 20, characters: 200 },
            { kind: "tools", entries: 4, words: 5, characters: 100 },
            { kind: "system", entries: 4, words: 6, characters: 100 },
            { kind: "switches", entries: 3, words: 0, characters: 0 },
            { kind: "idle", entries: 20, words: 0, characters: 0 },
          ],
        },
      }),
    );

    expect(labelledRows(sectionRows(insights.context, "content"))).toEqual([
      { label: "system", value: "~10.4k (17% ctx) (10 words)" },
      {
        label: NO_LABEL,
        value: "available: 12 skills · 5 agents · 2 mcp servers",
      },
      { label: "user", value: "2 msg · ~10.4k (17% ctx) (10 words)" },
      { label: "assistant", value: "3 msg · ~20.8k (33% ctx) (20 words)" },
      { label: "tools", value: "4 calls · ~10.4k (17% ctx) (5 words)" },
      { label: "other", value: "27 msg · ~10.4k (17% ctx) (6 words)" },
      { label: NO_LABEL, value: "4 system · 3 switches · 20 idle" },
    ]);
  });

  test("reports the last turn's steps, cost, output, and the last step's pace and cache hit", () => {
    const insights = buildInsights(
      makeInput({
        contextWindow: {
          traffic: makeTraffic({
            input: 30_000,
            output: 1_000,
            reasoning: 300,
            cacheRead: 30_000,
            cacheWrite: 1_000,
          }),
          limit: 200_000,
          streamingMs: 26_000,
        },
        session: {
          ...makeInput().session,
          subagents: [
            {
              agent: "explore",
              title: "Check the turn",
              tokenTotal: 2_000,
              costUsd: 0.08,
              createdAt: 2_000,
            },
          ],
        },
        stats: {
          ...makeInput().stats,
          lastTurn: {
            durationMs: 80_000,
            startedAt: 1_000,
            steps: 4,
            costUsd: 0.12,
            outputTokens: 1_200,
            reasoningTokens: 300,
            generatingMs: 30_000,
          },
        },
      }),
    );

    const rows = labelledRows(sectionRows(insights.context, "general"));
    expect(rows).toContainEqual({
      label: "last turn",
      value: "4 steps (1m)",
    });
    expect(rows).toContainEqual({
      label: NO_LABEL,
      value: "cost $0.12 ($0.20 incl. subagents)",
    });
    expect(rows).toContainEqual({
      label: NO_LABEL,
      value: "output 1.2k · thinking 300",
    });
    expect(rows).toContainEqual({
      label: "last step",
      value: "26s · ~50 tok/s",
    });
    expect(rows).toContainEqual({
      label: NO_LABEL,
      value: "input 30k · output 1k · cache 31k",
    });
    expect(rows).toContainEqual({
      label: NO_LABEL,
      value: "cache hit 49% (30k of 61k tokens)",
    });
    expect(
      insights.context.sections.map((section) => section.heading),
    ).toEqual(["general", "activity", "compression"]);
  });

  test("keeps the last turn visible before the provider reports tokens", () => {
    const insights = buildInsights(
      makeInput({
        stats: {
          ...makeInput().stats,
          lastTurn: {
            steps: 1,
            costUsd: 0,
            outputTokens: 0,
            reasoningTokens: 0,
            generatingMs: 0,
          },
        },
      }),
    );

    expect(labelledRows(sectionRows(insights.context, "general"))).toEqual([
      { label: "last turn", value: "1 steps" },
      { label: NO_LABEL, value: "cost $0.00" },
      { label: NO_LABEL, value: "output 0 · thinking 0" },
    ]);
  });

  test("reports a system row when the prompt text is unavailable", () => {
    const insights = buildInsights(
      makeInput({
        session: {
          ...makeInput().session,
          systemPromptExposed: true,
        },
        stats: {
          ...makeInput().stats,
          content: [
            { kind: "user", entries: 2, words: 10, characters: 100 },
          ],
        },
      }),
    );

    expect(labelledRows(sectionRows(insights.context, "content"))).toEqual([
      { label: "system", value: "prompt not exposed" },
      { label: "user", value: "2 msg (10 words)" },
    ]);
  });

  test("lists each compression block with its size in the context group", () => {
    const insights = buildInsights(
      makeInput({
        dcp: {
          compressed: NO_DCP_SUMMARY.compressed,
          totalPruneTokens: 215_784,
          blocks: [
            {
              id: 1,
              topic: "session stats",
              compressedTokens: 12_000,
              summaryTokens: 1_500,
              messageCount: 40,
              createdAt: 10,
            },
          ],
        },
      }),
    );

    expect(valueOf(insights.context.sections, "pruned")).toBe("215.8k");
    const compression = sectionRows(insights.context, "compression");
    expect(compression.map((row) => labelOf(row))).toEqual([
      "pruned",
      "blocks",
      NO_LABEL,
    ]);
    const block = compression[1];
    const last = compression.at(-1);
    expect(block === undefined ? undefined : textOf(block)).toBe("1 block");
    expect(last === undefined ? undefined : textOf(last)).toBe(
      "#1 session stats · 12k → 1.5k (−11k)",
    );
  });

  test("cuts a long compression topic to the room the figures leave", () => {
    const insights = buildInsights(
      makeInput({
        valueWidth: 30,
        dcp: {
          compressed: NO_DCP_SUMMARY.compressed,
          totalPruneTokens: 215_784,
          blocks: [
            {
              id: 3,
              topic: "a very long compression topic indeed",
              compressedTokens: 12_000,
              summaryTokens: 1_500,
              messageCount: 40,
              createdAt: 10,
            },
          ],
        },
      }),
    );

    const last = sectionRows(insights.context, "compression").at(-1);

    expect(last === undefined ? undefined : textOf(last)).toBe(
      "#3 a very… · 12k → 1.5k (−11k)",
    );
  });

  test("puts the context size before and after the pruning beside the total", () => {
    const insights = buildInsights(
      makeInput({
        contextWindow: {
          traffic: makeTraffic({
            input: 30_000,
            output: 1_000,
            reasoning: 300,
            cacheRead: 30_000,
            cacheWrite: 1_000,
          }),
          limit: 200_000,
        },
        dcp: {
          compressed: NO_DCP_SUMMARY.compressed,
          totalPruneTokens: 215_784,
          blocks: [
            {
              id: 1,
              topic: "session stats",
              compressedTokens: 12_000,
              summaryTokens: 1_500,
              messageCount: 40,
              createdAt: 10,
            },
          ],
        },
      }),
    );

    expect(valueOf(insights.context.sections, "pruned")).toBe(
      "215.8k (278.1k → 62.3k)",
    );
    expect(
      sectionRows(insights.context, "compression")[0]?.segments,
    ).toContainEqual({ text: "62.3", tone: ["count", "muted"] });
  });

  test("keeps the compression list out of the session group", () => {
    const insights = buildInsights(
      makeInput({
        dcp: {
          compressed: NO_DCP_SUMMARY.compressed,
          totalPruneTokens: 215_784,
          blocks: [
            {
              id: 1,
              topic: "session stats",
              compressedTokens: 12_000,
              summaryTokens: 1_500,
              messageCount: 40,
              createdAt: 10,
            },
          ],
        },
      }),
    );

    expect(valueOf(insights.session.sections, "pruned")).toBeUndefined();
  });

  test("reports no compression as an empty context section", () => {
    const insights = buildInsights(makeInput());

    const last = insights.context.sections.at(-1);

    expect(last?.heading).toBe("compression");
    expect(last?.rows).toEqual([{ label: "none", segments: [] }]);
  });
});

describe("countInsightLines", () => {
  test("counts a heading per section plus one line per row", () => {
    const insights = buildInsights(
      makeInput({
        stats: {
          session: makeGroup({
            toolUsage: new Map([["read", 2]]),
            reads: 2,
            uniqueReads: 1,
            failures: 1,
            skills: 1,
          }),
          context: makeGroup(),
          timing: { generatingMs: 0, toolsMs: 0 },
          content: [],
          lastTurn: undefined,
        },
      }),
    );

    const sections = insights.context.sections;
    const lines = countInsightLines(sections);
    const rows = rowsOf(sections).length;
    const gaps = sections.length - 1;

    expect(lines).toBe(sections.length + rows + gaps);
  });

  test("counts no separator when a group has a single section", () => {
    const singleSection: readonly InsightSection[] = [
      { heading: "only", rows: [{ label: "a", segments: [{ text: "1", tone: "count" }] }] },
    ];

    expect(countInsightLines(singleSection)).toBe(2);
  });
});

describe("measureInsightWidth", () => {
  // Layout the widget renders with: a label column, a detail indent, and the gap
  // between a label cell and its value.
  const layout: InsightLayout = {
    labelWidth: LABEL_WIDTH,
    detailIndent: DETAIL_INDENT,
    labelGap: LABEL_GAP,
  };

  test("measures a labelled row by its label column, gap, and value", () => {
    const sections: readonly InsightSection[] = [
      {
        heading: "ab",
        rows: [{ label: "cost", segments: [{ text: "$1.24", tone: "cost" }] }],
      },
    ];

    expect(measureInsightWidth(sections, layout)).toBe(
      layout.labelWidth + layout.labelGap + 5,
    );
  });

  test("measures a detail row by the indent instead of the label column", () => {
    const sections: readonly InsightSection[] = [
      {
        heading: "ab",
        rows: [
          {
            segments: [{ text: "read 3 · edit 2" }],
          },
        ],
      },
    ];

    expect(measureInsightWidth(sections, layout)).toBe(
      layout.detailIndent + layout.labelGap + "read 3 · edit 2".length,
    );
  });

  test("takes the widest row across every section", () => {
    const sections: readonly InsightSection[] = [
      {
        heading: "one",
        rows: [{ label: "a", segments: [{ text: "12", tone: "count" }] }],
      },
      {
        heading: "two",
        rows: [
          {
            segments: [{ text: "read 3 · edit 2" }],
          },
        ],
      },
    ];

    expect(measureInsightWidth(sections, layout)).toBe(
      layout.detailIndent + layout.labelGap + "read 3 · edit 2".length,
    );
  });

  test("measures a heading that outruns its rows", () => {
    const sections: readonly InsightSection[] = [
      {
        heading: "compression",
        rows: [{ label: "a", segments: [{ text: "1", tone: "count" }] }],
      },
    ];

    expect(measureInsightWidth(sections, layout)).toBe(11);
  });

  test("measures nothing when there are no sections", () => {
    expect(measureInsightWidth([], layout)).toBe(0);
  });
});
