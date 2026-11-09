// Tests for the tooltip content builder.

import { describe, expect, test } from "bun:test";
import {
  buildInsights,
  countInsightLines,
  formatCost,
  formatDuration,
  formatTokens,
  measureInsightWidth,
} from "./insights";
import type {
  InsightGroup,
  InsightInput,
  InsightLayout,
  InsightRow,
  InsightSection,
} from "./insights";
import { NO_DCP_SUMMARY } from "./dcp-state";
import type { StatsGroup } from "./counts";

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

// Tooltip input with neutral defaults, overridden per case.
function makeInput(overrides: Partial<InsightInput> = {}): InsightInput {
  return {
    stats: { session: makeGroup(), context: makeGroup(), timing: { generatingMs: 0, toolsMs: 0 } },
    session: {
      costUsd: 0,
      familyCostUsd: 0,
      subagents: [],
      inputTokens: 0,
      outputTokens: 0,
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

// The value of the row with `label`, or undefined when it is absent.
function valueOf(
  sections: readonly InsightSection[],
  label: string,
): string | undefined {
  return rowsOf(sections).find((row) => row.label === label)?.value;
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

// Rows reduced to label and plain value, so colour runs do not affect a
// structural comparison.
function labelledRows(rows: readonly InsightRow[]) {
  return rows.map((row) => ({ label: row.label, value: row.value }));
}

describe("formatTokens", () => {
  test("keeps counts below a thousand as-is", () => {
    expect(formatTokens(0)).toBe("0");
    expect(formatTokens(999)).toBe("999");
  });

  test("shortens thousands to one decimal", () => {
    expect(formatTokens(1234)).toBe("1.2k");
    expect(formatTokens(12000)).toBe("12k");
  });

  test("rounds larger thousands to whole numbers", () => {
    expect(formatTokens(215784)).toBe("216k");
    expect(formatTokens(999_999)).toBe("1000k");
  });

  test("shortens millions", () => {
    expect(formatTokens(1_250_000)).toBe("1.25M");
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
        },
      }),
    );

    expect(labelledRows(sectionRows(insights.session, "activity"))).toEqual([
      { label: "tools", value: "6" },
      { label: "", value: "read 3 · edit 2 · bash 1" },
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
        },
      }),
    );

    expect(labelledRows(sectionRows(insights.session, "activity")).slice(0, 3)).toEqual([
      { label: "tools", value: "6" },
      { label: "", value: "read 3 · edit 2" },
      { label: "", value: "bash 1" },
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
        },
      }),
    );

    expect(labelledRows(sectionRows(insights.session, "activity"))).toEqual([
      { label: "tools", value: "none" },
      { label: "skills", value: "4" },
      { label: "", value: "coder-ts · opencode · text-replace" },
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
        },
      }),
    );

    expect(labelledRows(sectionRows(insights.session, "activity"))).toEqual([
      { label: "tools", value: "none" },
      { label: "skills", value: "4" },
      { label: "", value: "coder-ts · opencode" },
      { label: "", value: "text-replace" },
    ]);
  });

  test("says how many skill loads compression removed", () => {
    const insights = buildInsights(
      makeInput({
        stats: {
          session: makeGroup({ skills: 5 }),
          context: makeGroup({ skills: 0 }),
          timing: { generatingMs: 0, toolsMs: 0 },
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

  test("groups the session rows into totals, subagents, and activity", () => {
    const insights = buildInsights(makeInput());

    expect(insights.session.sections.map((section) => section.heading)).toEqual([
      "totals",
      "subagents",
      "activity",
    ]);
  });

  test("groups the context rows into activity and compression", () => {
    const insights = buildInsights(makeInput());

    expect(insights.context.sections.map((section) => section.heading)).toEqual([
      "activity",
      "compression",
    ]);
  });

  test("reports session totals and span", () => {
    const insights = buildInsights(
      makeInput({
        session: {
          costUsd: 2.5,
          familyCostUsd: 2.5,
          subagents: [],
          inputTokens: 1_200_000,
          outputTokens: 40_000,
          cacheReadTokens: 500_000,
          cacheWriteTokens: 20_000,
          createdAt: 1_000_000,
          updatedAt: 1_000_000 + 8_100_000,
        },
      }),
    );

    expect(valueOf(insights.session.sections, "cost")).toBe("$2.50");
    expect(valueOf(insights.session.sections, "tokens")).toBe(
      "in 1.2M · out 40k · cache 520k",
    );
    expect(valueOf(insights.session.sections, "span")).toBe("2h 15m");
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

    expect(rows.map((row) => row.value)).toEqual([
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
      { text: " ", tone: "value" },
      { text: "12.4", tone: "count" },
      { text: "k", tone: "count", bold: true },
      { text: " ", tone: "value" },
      { text: "Verify examples", tone: "muted" },
      { text: " ".repeat(15), tone: "value" },
      { text: " ", tone: "value" },
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

    expect(rows.map((row) => row.value)).toEqual([
      `a${" ".repeat(7)}1.5k ${"one".padEnd(31)} $1.20`,
      `explore 800k ${"two".padEnd(31)}   ~$0`,
    ]);
    expect(rows.map((row) => row.value.length)).toEqual([50, 50]);
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

    expect(sectionRows(insights.session, "subagents")[1]?.value).toBe(
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

    expect(rows.map((row) => row.label)).toEqual([
      "count",
      "top 3",
      "",
      "",
      "",
      "latest 4",
      "",
      "",
      "",
      "",
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

    expect(rows.map((row) => row.label)).toEqual([
      "count",
      "top 3",
      "",
      "",
      "",
      "latest 4",
      "",
      "",
      "",
      "",
    ]);
    expect(
      rows
        .filter((row) => row.label === "")
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
      sectionRows(insights.session, "subagents").map((row) => row.label),
    ).toEqual(["count", "", "", "", "", "", "", ""]);
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
      sectionRows(family.session, "totals").find((row) => row.label === "cost")
        ?.segments,
    ).toEqual([
      { text: "$1.21", tone: "cost" },
      { text: " (", tone: "muted" },
      { text: "$1.41", tone: "costDim" },
      { text: " incl. subagents)", tone: "muted" },
    ]);
  });

  test("shows the working time under the span", () => {
    const insights = buildInsights(
      makeInput({
        stats: {
          session: makeGroup(),
          context: makeGroup(),
          timing: { generatingMs: 3_600_000, toolsMs: 900_000 },
        },
      }),
    );

    const working = rowsOf(insights.session.sections).find((row) =>
      row.value.includes("generating"),
    );
    expect(working?.label).toBe("");
    expect(working?.value).toBe("1h generating · 15m tools");
  });

  test("hides the working time while nothing has run", () => {
    const insights = buildInsights(makeInput());

    expect(
      rowsOf(insights.session.sections).some((row) =>
        row.value.includes("generating"),
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
        },
      }),
    );

    const rows = sectionRows(insights.session, "activity");
    expect(rows[0]?.segments).toEqual([{ text: "6", tone: "count" }]);
    expect(rows[1]?.segments).toEqual([
      { text: "read", tone: "value" },
      { text: " 3", tone: "countDim" },
      { text: " · ", tone: "muted" },
      { text: "edit", tone: "value" },
      { text: " 2", tone: "countDim" },
    ]);
  });

  test("draws a shortened token count as a count with a bold unit", () => {
    const insights = buildInsights(
      makeInput({
        session: {
          ...makeInput().session,
          inputTokens: 123_456,
          outputTokens: 4_000_000,
        },
      }),
    );

    const tokens = sectionRows(insights.session, "totals").find(
      (row) => row.label === "tokens",
    );
    expect(tokens?.segments).toEqual([
      { text: "in ", tone: "value" },
      { text: "123", tone: "count" },
      { text: "k", tone: "count", bold: true },
      { text: " · ", tone: "muted" },
      { text: "out ", tone: "value" },
      { text: "4", tone: "count" },
      { text: "M", tone: "count", bold: true },
      { text: " · ", tone: "muted" },
      { text: "cache ", tone: "value" },
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
        },
      }),
    );

    expect(valueOf(insights.session.sections, "reads")).toBe("41 (23 unique)");
  });

  test("reports the window only when the model limit is known", () => {
    const without = buildInsights(makeInput());
    const withUsage = buildInsights(
      makeInput({ contextWindow: { used: 62_300, limit: 200_000 } }),
    );

    expect(valueOf(without.context.sections, "window")).toBeUndefined();
    expect(valueOf(withUsage.context.sections, "window")).toBe(
      "62.3k (model limit: 200k)",
    );
    expect(
      rowsOf(withUsage.context.sections, "window")[0]?.segments,
    ).toContainEqual({ text: "k", tone: "countDim", bold: true });
    expect(
      withUsage.context.sections.map((section) => section.heading),
    ).toEqual(["window", "activity", "compression"]);
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

    expect(valueOf(insights.context.sections, "pruned")).toBe("1 blocks · 216k");
    const compression = sectionRows(insights.context, "compression");
    expect(compression.map((row) => row.label)).toEqual([
      "pruned",
      "blocks",
      "",
    ]);
    expect(compression.at(-1)?.value).toBe(
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

    expect(sectionRows(insights.context, "compression").at(-1)?.value).toBe(
      "#3 a very… · 12k → 1.5k (−11k)",
    );
  });

  test("puts the context size before and after the pruning beside the total", () => {
    const insights = buildInsights(
      makeInput({
        contextWindow: { used: 62_300, limit: 200_000 },
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
      "1 blocks · 216k (278k → 62.3k)",
    );
    expect(
      sectionRows(insights.context, "compression")[0]?.segments,
    ).toContainEqual({ text: "62.3", tone: "countDim" });
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
    expect(last?.rows).toEqual([{ label: "none", value: "" }]);
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
      { heading: "only", rows: [{ label: "a", value: "1" }] },
    ];

    expect(countInsightLines(singleSection)).toBe(2);
  });
});

describe("measureInsightWidth", () => {
  // Layout the widget renders with: a label column, a detail indent, and the gap
  // between a label cell and its value.
  const layout: InsightLayout = { labelWidth: 9, detailIndent: 1, labelGap: 1 };

  test("measures a labelled row by its label column, gap, and value", () => {
    const sections: readonly InsightSection[] = [
      { heading: "ab", rows: [{ label: "cost", value: "$1.24" }] },
    ];

    expect(measureInsightWidth(sections, layout)).toBe(9 + 1 + 5);
  });

  test("measures a detail row by the indent instead of the label column", () => {
    const sections: readonly InsightSection[] = [
      { heading: "ab", rows: [{ label: "", value: "read 3 · edit 2" }] },
    ];

    expect(measureInsightWidth(sections, layout)).toBe(1 + 1 + "read 3 · edit 2".length);
  });

  test("takes the widest row across every section", () => {
    const sections: readonly InsightSection[] = [
      { heading: "one", rows: [{ label: "a", value: "12" }] },
      { heading: "two", rows: [{ label: "", value: "read 3 · edit 2" }] },
    ];

    expect(measureInsightWidth(sections, layout)).toBe(1 + 1 + "read 3 · edit 2".length);
  });

  test("measures a heading that outruns its rows", () => {
    const sections: readonly InsightSection[] = [
      { heading: "compression", rows: [{ label: "a", value: "1" }] },
    ];

    expect(measureInsightWidth(sections, layout)).toBe(11);
  });

  test("measures nothing when there are no sections", () => {
    expect(measureInsightWidth([], layout)).toBe(0);
  });
});
