// Tooltip content for the session-stats component.
//
// Turns the counters, the session totals, and DCP's compression summary into
// labelled rows. Pure formatting, so the wording and the number shapes are
// unit-testable without a terminal.

import type { DcpBlock, DcpSummary } from "./dcp-state";
import type { SessionStats, SessionTiming, StatsGroup } from "./counts";

// A coloured run of a row's value.
export type InsightSegment = {
  // Text of the run.
  readonly text: string;
  // Which part of the row the run is, so the view can pick its colour.
  readonly tone:
    | "value"
    | "muted"
    | "agent"
    | "count"
    | "countDim"
    | "cost"
    | "costDim"
    | "error"
    | "time";
  // Draw the run in bold, for a unit that should stand out from its number.
  readonly bold?: boolean;
};

// One labelled row of a tooltip.
export type InsightRow = {
  // Left-hand label.
  readonly label: string;
  // Right-hand value, as one plain run unless `segments` splits it.
  readonly value: string;
  // Coloured runs of the value, for rows whose parts read better apart.
  readonly segments?: readonly InsightSegment[];
};

// One titled group of rows.
export type InsightSection = {
  // Section title.
  readonly heading: string;
  // Rows under the title.
  readonly rows: readonly InsightRow[];
};

// Tooltip content for one count group: its name and the sections below it.
export type InsightGroup = {
  // Group name, drawn in the tooltip's title row.
  readonly title: string;
  // Sections under the title.
  readonly sections: readonly InsightSection[];
};

// A session spawned under the session the tooltip describes.
export type SubagentFacts = {
  // Agent the subagent session ran.
  readonly agent: string;
  // What the subagent was asked to do.
  readonly title: string;
  // The subagent session's own token total: prompt, completion, and both cache
  // directions. Reasoning is left out, matching the session's token detail line,
  // so the two figures stay comparable.
  readonly tokenTotal: number;
  // The subagent session's own cost in US dollars.
  readonly costUsd: number;
};

// Session totals the tooltip reports, reduced from the host's session info.
export type SessionFacts = {
  // This session's own cost in US dollars.
  readonly costUsd: number;
  // Cost of the session together with its subagent sessions.
  readonly familyCostUsd: number;
  // Sessions spawned under this one, at any depth.
  readonly subagents: readonly SubagentFacts[];
  // Prompt tokens the session sent.
  readonly inputTokens: number;
  // Completion tokens the session produced.
  readonly outputTokens: number;
  // Reasoning tokens the session generated.
  readonly reasoningTokens: number;
  // Reasoning tokens still in the model's active context.
  readonly activeReasoningTokens: number;
  // Tokens served from the provider's prompt cache.
  readonly cacheReadTokens: number;
  // Tokens written to the provider's prompt cache.
  readonly cacheWriteTokens: number;
  // Session creation time in milliseconds since the epoch.
  readonly createdAt: number;
  // Session last-update time in milliseconds since the epoch.
  readonly updatedAt: number;
};

// Token counts of one assistant step, split the way the provider reports them.
export type TokenTraffic = {
  // Prompt tokens the provider had to process.
  readonly input: number;
  // Completion tokens the step produced.
  readonly output: number;
  // Reasoning tokens the step produced.
  readonly reasoning: number;
  // Prompt tokens served from the provider's cache.
  readonly cacheRead: number;
  // Prompt tokens written to the provider's cache.
  readonly cacheWrite: number;
};

// Tokens in the model's window, and the window's size when it is known.
export type ContextWindowUsage = {
  // Prompt, completion, reasoning, and cache tokens of the step in context.
  readonly traffic: TokenTraffic;
  // The model's window size, missing until the model catalogue is synced.
  readonly limit?: number;
};

// Everything the tooltip content is built from.
export type InsightInput = {
  // Conversation and tool counters, with the session's working time.
  readonly stats: SessionStats;
  // Session totals.
  readonly session: SessionFacts;
  // Window usage, when an assistant step carries token data.
  readonly contextWindow: ContextWindowUsage | undefined;
  // DCP's compression summary.
  readonly dcp: DcpSummary;
  // Cells the value column offers, so long rows wrap onto several lines.
  readonly valueWidth: number;
};

// Tooltip content for both count groups.
export type Insights = {
  readonly session: InsightGroup;
  readonly context: InsightGroup;
};

// Separator between two entries packed onto one line.
const ENTRY_SEPARATOR = " · ";

// Name of the group that counts the whole conversation.
const SESSION_GROUP_TITLE = "whole session";

// Name of the group that counts what is still in the model's context.
const CONTEXT_GROUP_TITLE = "active context";

// Subagents listed individually before the list is trimmed into groups.
const SUBAGENT_LIST_LIMIT = 7;

// Dearest subagents kept when the list is trimmed.
const SUBAGENT_TOP_LIMIT = 3;

// Most recently created subagents kept when the list is trimmed.
const SUBAGENT_LATEST_LIMIT = 4;

// Spaces between the columns of a subagent line: agent, tokens, description,
// and cost.
const SUBAGENT_COLUMN_GAPS = 3;

// Cells the subagent name column may take before its description is squeezed.
const SUBAGENT_AGENT_MAX_WIDTH = 12;

// Build the tooltip content for the session and context groups.
export function buildInsights(input: InsightInput): Insights {
  const spanMs = input.session.updatedAt - input.session.createdAt;
  const span = formatDuration(spanMs);
  return {
    session: {
      title: SESSION_GROUP_TITLE,
      sections: [
        {
          heading: "totals",
          rows: [
            costRow(input.session),
            ...tokenRows(input.session, input.contextWindow),
            {
              label: "span",
              value: span,
              segments: [{ text: span, tone: "time" }],
            },
            ...workingRows(input.stats.timing, spanMs),
          ],
        },
        {
          heading: "activity",
          rows: [
            ...toolRows("tools", input.stats.session, input.valueWidth),
            ...skillRows(input.stats.session, input.valueWidth, 0),
            ...readRows(input.stats.session),
            ...failureRows(input.stats.session),
          ],
        },
        subagentSection(input.session.subagents, input.valueWidth),
      ],
    },
    context: {
      title: CONTEXT_GROUP_TITLE,
      sections: [
        ...windowSections(input.contextWindow),
        {
          heading: "activity",
          rows: [
            ...toolRows("tools", input.stats.context, input.valueWidth),
            ...skillRows(
              input.stats.context,
              input.valueWidth,
              input.stats.session.skills - input.stats.context.skills,
            ),
            ...readRows(input.stats.context),
          ],
        },
        compressionSection(
          input.dcp,
          "compression",
          input.contextWindow,
          input.valueWidth,
        ),
      ],
    },
  };
}

// Number of terminal lines the sections occupy: a heading and its rows, plus a
// blank line between neighbouring sections.
export function countInsightLines(sections: readonly InsightSection[]): number {
  const content = sections.reduce(
    (total, section) => total + 1 + section.rows.length,
    0,
  );
  const gaps = Math.max(0, sections.length - 1);
  return content + gaps;
}

// Layout the insight rows are measured against.
export type InsightLayout = {
  // Cells the label column takes on a row that carries a label.
  readonly labelWidth: number;
  // Cells a detail row takes in place of the label column.
  readonly detailIndent: number;
  // Cells between the label cell and the value.
  readonly labelGap: number;
};

// Cells the widest line of the sections needs, headings included.
//
// A panel is sized from this so it hugs its content instead of reserving columns
// its rows never reach.
export function measureInsightWidth(
  sections: readonly InsightSection[],
  layout: InsightLayout,
): number {
  const headingWidth = sections.reduce(
    (widest, section) => Math.max(widest, section.heading.length),
    0,
  );
  const rowWidth = sections.reduce(
    (widest, section) =>
      section.rows.reduce(
        (widestRow, row) => Math.max(widestRow, rowWidthOf(row, layout)),
        widest,
      ),
    0,
  );
  return Math.max(headingWidth, rowWidth);
}

// Cells one rendered row needs, its label cell included.
function rowWidthOf(row: InsightRow, layout: InsightLayout): number {
  const labelCell =
    row.label.length === 0 ? layout.detailIndent : layout.labelWidth;
  return labelCell + layout.labelGap + row.value.length;
}

// Counts <1k as-is, then <1M with `k`, then >=1M with `M`, each with at most
// one decimal, so a breakdown stays readable in a narrow tooltip.
export function formatCount(count: number): string {
  if (count < 1000) {
    return String(count);
  }
  if (count < 1_000_000) {
    return `${trimDecimals(count / 1000, 1)}k`;
  }
  return `${trimDecimals(count / 1_000_000, 1)}M`;
}

// Durations in the largest unit that keeps them short: seconds, minutes, hours,
// or days.
export function formatDuration(milliseconds: number): string {
  const totalSeconds = Math.max(0, Math.round(milliseconds / 1000));
  if (totalSeconds < 60) {
    return `${totalSeconds}s`;
  }
  const totalMinutes = Math.floor(totalSeconds / 60);
  if (totalMinutes < 60) {
    return `${totalMinutes}m`;
  }
  const hours = Math.floor(totalMinutes / 60);
  const minutes = totalMinutes % 60;
  if (hours < 24) {
    return minutes === 0 ? `${hours}h` : `${hours}h ${minutes}m`;
  }
  const days = Math.floor(hours / 24);
  const rest = hours % 24;
  return rest === 0 ? `${days}d` : `${days}d ${rest}h`;
}

// Costs in US dollars, at most two decimals. A non-zero amount that rounds to
// nothing shows as `~$0`, so a sub-cent figure is not read as exact.
export function formatCost(usd: number): string {
  const rounded = Math.round(usd * 100) / 100;
  if (rounded === 0) {
    return usd === 0 ? "$0.00" : "~$0";
  }
  return `$${rounded.toFixed(2)}`;
}

// One entry of a packed usage list: its plain text for measuring, and the runs
// it is drawn as.
type UsageEntry = {
  // The whole entry, as the packer measures it.
  readonly text: string;
  // Coloured runs the entry renders as.
  readonly segments: readonly InsightSegment[];
};

// Tool rows: the total, then the usage entries packed onto lines of `width`
// cells, under an empty label.
function toolRows(
  label: string,
  group: StatsGroup,
  width: number,
): readonly InsightRow[] {
  if (group.toolCalls === 0) {
    return [{ label, value: "none" }];
  }

  const entries: readonly UsageEntry[] = sortedUsage(group.toolUsage).map(
    ([name, count]) => ({
      text: `${name} ${count}`,
      segments: [
        { text: name, tone: "value" },
        { text: ` ${count}`, tone: "countDim" },
      ],
    }),
  );

  return countThenRows(label, group.toolCalls, entries, width);
}

// Skill rows: the total, then the names packed onto as few lines as fit.
//
// `compressed` counts the loads compression removed, so the context group can
// say why a low number is not a missing one.
function skillRows(
  group: StatsGroup,
  width: number,
  compressed: number,
): readonly InsightRow[] {
  const entries: readonly UsageEntry[] = sortedUsage(group.skillUsage).map(
    ([name]) => ({
      text: name,
      segments: [{ text: name, tone: "value" }],
    }),
  );
  const note =
    compressed > 0
      ? { count: compressed, label: "compressed" }
      : undefined;
  return countThenRows("skills", group.skills, entries, width, note);
}

// A count row, then entries packed onto as few lines as the width allows.
//
// A note qualifies the count in parentheses, its own figure drawn as a dimmed
// count so it stays readable as the same kind of token.
function countThenRows(
  label: string,
  count: number,
  entries: readonly UsageEntry[],
  width: number,
  note?: { readonly count: number; readonly label: string },
): readonly InsightRow[] {
  const total = formatCount(count);
  const noteCount = note === undefined ? "" : formatCount(note.count);
  return [
    {
      label,
      value:
        note === undefined ? total : `${total} (${noteCount} ${note.label})`,
      segments:
        note === undefined
          ? [{ text: total, tone: "count" }]
          : [
              { text: total, tone: "count" },
              { text: " (", tone: "muted" },
              { text: noteCount, tone: "countDim" },
              { text: ` ${note.label})`, tone: "muted" },
            ],
    },
    ...packEntries(entries, width).map((entry) => ({
      label: "",
      value: entry.text,
      segments: entry.segments,
    })),
  ];
}

// Usage entries, most-used first, with ties broken by name.
function sortedUsage(
  usage: ReadonlyMap<string, number>,
): readonly (readonly [string, number])[] {
  return [...usage.entries()].sort(
    (left, right) => right[1] - left[1] || left[0].localeCompare(right[0]),
  );
}

// Pack entries onto lines of at most `width` cells.
//
// An entry longer than the width keeps a line to itself rather than being cut
// here: the renderer is left to decide what to do with an over-long row.
function packEntries(
  entries: readonly UsageEntry[],
  width: number,
): readonly UsageEntry[] {
  const lines: UsageEntry[][] = [];
  let line: UsageEntry[] = [];
  let lineWidth = 0;
  for (const entry of entries) {
    const addition =
      (line.length === 0 ? 0 : ENTRY_SEPARATOR.length) + entry.text.length;
    // Start a new line when this entry would overrun the current one.
    if (line.length > 0 && lineWidth + addition > width) {
      lines.push(line);
      line = [entry];
      lineWidth = entry.text.length;
      continue;
    }
    line.push(entry);
    lineWidth += addition;
  }
  if (line.length > 0) {
    lines.push(line);
  }
  return lines.map(joinEntries);
}

// Join entries onto one row, keeping their own runs and dimming the separators.
function joinEntries(entries: readonly UsageEntry[]): UsageEntry {
  const segments = entries.flatMap(
    (entry, index): readonly InsightSegment[] =>
      index === 0
        ? entry.segments
        : [{ text: ENTRY_SEPARATOR, tone: "muted" }, ...entry.segments],
  );
  return {
    text: entries.map((entry) => entry.text).join(ENTRY_SEPARATOR),
    segments,
  };
}

// Sum of a step's token counts, matching the host's context-usage figure.
//
// Prompt tokens are counted both uncached and cached, plus the completion and
// reasoning the step produced.
function tokenTotal(traffic: TokenTraffic): number {
  return (
    traffic.input +
    traffic.output +
    traffic.reasoning +
    traffic.cacheRead +
    traffic.cacheWrite
  );
}

// One detail row packing token entries as `label count`, joined by the
// separator.
function packedTokenRow(
  entries: readonly (readonly [string, number])[],
): InsightRow {
  return {
    label: "",
    value: entries
      .map(([label, count]) => `${label} ${formatCount(count)}`)
      .join(ENTRY_SEPARATOR),
    segments: entries.flatMap(([label, count], index) => {
      const segments: InsightSegment[] = [
        ...(index === 0
          ? []
          : [{ text: ENTRY_SEPARATOR, tone: "muted" as const }]),
        { text: `${label} `, tone: "value" },
        ...tokenSegments(count),
      ];
      return segments;
    }),
  };
}

// Cache-hit detail: the share of the prompt tokens the provider served from its
// cache.
//
// Prompt tokens are the uncached input plus both cache directions, and a cache
// read counts as a hit. Omitted when the prompt carried no tokens, so an empty
// or untokenized scope does not report a meaningless rate.
function cacheHitRows(traffic: TokenTraffic): readonly InsightRow[] {
  const promptTokens = traffic.input + traffic.cacheRead + traffic.cacheWrite;
  if (promptTokens === 0) {
    return [];
  }
  const percent = Math.round((traffic.cacheRead / promptTokens) * 100);
  const cacheRead = formatCount(traffic.cacheRead);
  const prompt = formatCount(promptTokens);
  return [
    {
      label: "",
      value: `last cache hit ${percent}% (${cacheRead} of ${prompt} prompt)`,
      segments: [
        { text: `last cache hit `, tone: "value" },
        { text: String(percent), tone: "count" },
        { text: "%", tone: "count", bold: true },
        { text: " (", tone: "muted" },
        ...tokenSegments(traffic.cacheRead, "countDim"),
        { text: " of ", tone: "muted" },
        ...tokenSegments(promptTokens, "countDim"),
        { text: " prompt)", tone: "muted" },
      ],
    },
  ];
}

// Token rows: the size of the model's window now, then the session's prompt,
// completion, and cache traffic as its detail line, its cache-hit share, and its
// thinking when it reasoned.
//
// The window size is left blank while no assistant step carries token data; the
// traffic stays, since it is read from the session totals rather than a step.
function tokenRows(
  facts: SessionFacts,
  usage: ContextWindowUsage | undefined,
): readonly InsightRow[] {
  const traffic: TokenTraffic = {
    input: facts.inputTokens,
    output: facts.outputTokens,
    reasoning: facts.reasoningTokens,
    cacheRead: facts.cacheReadTokens,
    cacheWrite: facts.cacheWriteTokens,
  };
  const usedTokens = usage === undefined ? undefined : tokenTotal(usage.traffic);
  const usageRow: InsightRow =
    usedTokens === undefined
      ? { label: "tokens", value: "" }
      : {
          label: "tokens",
          value: formatCount(usedTokens),
          segments: tokenSegments(usedTokens),
        };
  return [
    usageRow,
    packedTokenRow([
      ["input", traffic.input],
      ["output", traffic.output],
      ["cache", traffic.cacheRead + traffic.cacheWrite],
    ]),
    ...cacheHitRows(traffic),
    ...thinkingRows(facts),
  ];
}

// Thinking detail, reporting the reasoning the session generated and how much of
// it is still in the active context.
//
// Omitted for a session that never reported reasoning.
function thinkingRows(facts: SessionFacts): readonly InsightRow[] {
  if (facts.reasoningTokens === 0) {
    return [];
  }
  const total = formatCount(facts.reasoningTokens);
  const active = formatCount(facts.activeReasoningTokens);
  return [
    {
      label: "",
      value: `thinking ${total} (${active} active)`,
      segments: [
        { text: "thinking ", tone: "value" },
        ...tokenSegments(facts.reasoningTokens),
        { text: " (", tone: "muted" },
        ...tokenSegments(facts.activeReasoningTokens, "countDim"),
        { text: " active)", tone: "muted" },
      ],
    },
  ];
}

// Cost row, showing this session and the whole family once they differ.
function costRow(facts: SessionFacts): InsightRow {
  const sessionCost = formatCost(facts.costUsd);
  if (facts.familyCostUsd <= facts.costUsd) {
    return {
      label: "cost",
      value: sessionCost,
      segments: [{ text: sessionCost, tone: "cost" }],
    };
  }
  const familyCost = formatCost(facts.familyCostUsd);
  return {
    label: "cost",
    value: `${sessionCost} (${familyCost} incl. subagents)`,
    segments: [
      { text: sessionCost, tone: "cost" },
      { text: " (", tone: "muted" },
      { text: familyCost, tone: "costDim" },
      { text: " incl. subagents)", tone: "muted" },
    ],
  };
}

// The subagents section: the total, then one line per subagent.
//
// A list longer than the limit is trimmed to its dearest few and its most recent
// few, each group under a label row of its own, so the total still accounts for
// what the rows leave out. The subagents arrive in creation order.
function subagentSection(
  subagents: readonly SubagentFacts[],
  width: number,
): InsightSection {
  const columns = subagentColumns(subagents, width);
  const countRow = subagentCountRow(subagents.length);
  if (subagents.length <= SUBAGENT_LIST_LIMIT) {
    return {
      heading: "subagents",
      rows: [countRow, ...subagentRows(subagents, columns)],
    };
  }

  // The dearest group keeps its rows out of the recent group, which then takes
  // the latest of what is left, so no subagent is listed twice and the label
  // still counts the rows beneath it.
  const dearest = dearestIndexes(subagents).slice(0, SUBAGENT_TOP_LIMIT);
  const recent = subagents
    .map((_subagent, index) => index)
    .filter((index) => !dearest.includes(index))
    .slice(-SUBAGENT_LATEST_LIMIT);
  return {
    heading: "subagents",
    rows: [
      countRow,
      subagentGroupRow("top", dearest.length),
      ...subagentRows(atIndexes(subagents, dearest), columns),
      subagentGroupRow("latest", recent.length),
      ...subagentRows(atIndexes(subagents, recent), columns),
    ],
  };
}

// The count row that opens the subagents section.
function subagentCountRow(count: number): InsightRow {
  const text = formatCount(count);
  return { label: "count", value: text, segments: [{ text, tone: "count" }] };
}

// Label row opening one group of a trimmed subagent list, naming the group and
// how many lines follow it.
function subagentGroupRow(name: string, count: number): InsightRow {
  return { label: `${name} ${formatCount(count)}`, value: "" };
}

// Subagent indexes, dearest first, ties left in creation order.
function dearestIndexes(subagents: readonly SubagentFacts[]): readonly number[] {
  return subagents
    .map((_subagent, index) => index)
    .sort(
      (left, right) =>
        (subagents[right]?.costUsd ?? 0) - (subagents[left]?.costUsd ?? 0),
    );
}

// The subagents at the given indexes, in the order the indexes carry.
function atIndexes(
  subagents: readonly SubagentFacts[],
  indexes: readonly number[],
): readonly SubagentFacts[] {
  return indexes.flatMap((index) => {
    const subagent = subagents[index];
    return subagent === undefined ? [] : [subagent];
  });
}

// Column widths every subagent line is laid out against, taken over the whole
// list so the columns line up across the groups of a trimmed one.
function subagentColumns(
  subagents: readonly SubagentFacts[],
  width: number,
): SubagentColumns {
  const agentWidth = Math.min(
    longestOf(subagents.map((subagent) => subagent.agent)),
    SUBAGENT_AGENT_MAX_WIDTH,
  );
  const tokenWidth = longestOf(
    subagents.map((subagent) => formatCount(subagent.tokenTotal)),
  );
  const costWidth = longestOf(
    subagents.map((subagent) => formatCost(subagent.costUsd)),
  );
  return {
    agent: agentWidth,
    token: tokenWidth,
    description: Math.max(
      0,
      width - agentWidth - tokenWidth - costWidth - SUBAGENT_COLUMN_GAPS,
    ),
    cost: costWidth,
  };
}

// One line per subagent, in the order given.
function subagentRows(
  subagents: readonly SubagentFacts[],
  columns: SubagentColumns,
): readonly InsightRow[] {
  return subagents.map((subagent) => subagentRow(subagent, columns));
}

// Shared column widths one subagent line is laid out against, so the columns
// line up across the list.
type SubagentColumns = {
  readonly agent: number;
  readonly token: number;
  readonly description: number;
  readonly cost: number;
};

// One subagent line: the agent, its token total, what it worked on, and its
// cost, each in a colour of its own.
//
// The token column is right-aligned and the cost column right-aligned in their
// shared widths, while the purpose is padded into the description column so the
// costs stay in one column down the list; a purpose too long for the column is
// cut with an ellipsis.
function subagentRow(
  subagent: SubagentFacts,
  columns: SubagentColumns,
): InsightRow {
  const token = formatCount(subagent.tokenTotal);
  const agent = truncateText(subagent.agent, columns.agent);
  const description = truncateText(subagent.title, columns.description);
  const descriptionSegments: readonly InsightSegment[] =
    description.length === 0
      ? []
      : [{ text: description, tone: "muted" }];
  const segments: readonly InsightSegment[] = [
    { text: agent, tone: "agent" },
    ...paddingSegments(agent.length, columns.agent),
    { text: " ", tone: "value" },
    ...paddingSegments(token.length, columns.token),
    ...tokenSegments(subagent.tokenTotal),
    { text: " ", tone: "value" },
    ...descriptionSegments,
    ...paddingSegments(description.length, columns.description),
    { text: " ", tone: "value" },
    { text: formatCost(subagent.costUsd).padStart(columns.cost), tone: "cost" },
  ];
  return {
    label: "",
    value: segments.map((segment) => segment.text).join(""),
    segments,
  };
}

// Spaces that widen a column's content to its shared width, so the columns to
// its right start at the same place on every row.
function paddingSegments(
  length: number,
  width: number,
): readonly InsightSegment[] {
  return length >= width
    ? []
    : [{ text: " ".repeat(width - length), tone: "value" }];
}

// Longest length in a list of strings, 0 when it is empty.
function longestOf(values: readonly string[]): number {
  return values.reduce((longest, value) => Math.max(longest, value.length), 0);
}

// Working-time rows: the share of the span spent working, then the split
// between streaming, waiting for tools, and idling.
//
// Idle covers everything else in the span, including time waiting for the user's
// answer to a question tool.
function workingRows(
  timing: SessionTiming,
  spanMs: number,
): readonly InsightRow[] {
  const busyMs = timing.generatingMs + timing.toolsMs;
  if (busyMs === 0) {
    return [];
  }
  const idleMs = Math.max(0, spanMs - busyMs);
  const busy = formatDuration(busyMs);
  const share =
    spanMs > 0
      ? `${Math.min(100, Math.round((busyMs / spanMs) * 100))}%`
      : undefined;
  const details: readonly (readonly [string, string])[] = [
    [formatDuration(timing.generatingMs), "generating"],
    [formatDuration(timing.toolsMs), "tools"],
    ...(idleMs > 0 ? [[formatDuration(idleMs), "idle"] as const] : []),
  ];
  return [
    {
      label: "busy",
      value: share === undefined ? busy : `${busy} (${share})`,
      segments: [
        { text: busy, tone: "time" },
        ...(share === undefined
          ? []
          : [{ text: ` (${share})`, tone: "muted" as const }]),
      ],
    },
    {
      label: "",
      value: details
        .map(([duration, unit]) => `${duration} ${unit}`)
        .join(ENTRY_SEPARATOR),
      segments: details.flatMap(([duration, unit], index) => [
        ...(index === 0 ? [] : [{ text: ENTRY_SEPARATOR, tone: "muted" as const }]),
        { text: duration, tone: "time" as const },
        { text: ` ${unit}`, tone: "value" as const },
      ]),
    },
  ];
}

// One count as coloured runs: the number as a count, then its unit in bold so a
// shortened figure still reads as a quantity.
//
// Pass `countDim` for a figure that sits in parentheses, so it keeps its own
// colour while receding behind the value it qualifies.
function tokenSegments(
  count: number,
  tone: "count" | "countDim" = "count",
): readonly InsightSegment[] {
  return countSegments(formatCount(count), tone);
}

// A difference as coloured runs, rounded to a whole unit: a saving is not known
// to the token, so a decimal would read as precision it does not have.
function roundedTokenSegments(
  count: number,
  tone: "count" | "countDim" = "count",
): readonly InsightSegment[] {
  return countSegments(formatRoundedTokens(count), tone);
}

// Splits a formatted count into its number run and a bold unit run.
function countSegments(
  text: string,
  tone: "count" | "countDim",
): readonly InsightSegment[] {
  const unit = text.at(-1);
  if (unit === "k" || unit === "M") {
    return [
      { text: text.slice(0, -1), tone },
      { text: unit, tone, bold: true },
    ];
  }
  return [{ text, tone }];
}

// Token count rounded to whole thousands or millions, never carrying a decimal.
function formatRoundedTokens(count: number): string {
  if (count < 1000) {
    return String(count);
  }
  if (count < 1_000_000) {
    return `${Math.round(count / 1000)}k`;
  }
  return `${Math.round(count / 1_000_000)}M`;
}

// Shortens `text` to `width` cells, marking any cut with an ellipsis.
function truncateText(text: string, width: number): string {
  if (width <= 0) {
    return "";
  }
  if (text.length <= width) {
    return text;
  }
  if (width === 1) {
    return "…";
  }
  return `${text.slice(0, width - 1)}…`;
}

// Window section: the used and total window, the step's token composition, and
// its cache-hit share.
//
// No section at all when the model's limit is unknown.
function windowSections(
  usage: ContextWindowUsage | undefined,
): readonly InsightSection[] {
  const limit = usage?.limit;
  if (usage === undefined || limit === undefined) {
    return [];
  }
  const traffic = usage.traffic;
  const composition: readonly (readonly [string, number])[] = [
    ["input", traffic.input],
    ["output", traffic.output],
    ["cache", traffic.cacheRead + traffic.cacheWrite],
    ...(traffic.reasoning > 0
      ? [["thinking", traffic.reasoning] as const]
      : []),
  ];
  return [
    {
      heading: "window",
      rows: [
        windowRow(tokenTotal(traffic), limit),
        packedTokenRow(composition),
        ...cacheHitRows(traffic),
      ],
    },
  ];
}

// Window usage row, for a window whose limit is known.
function windowRow(used: number, limit: number): InsightRow {
  return {
    label: "window",
    value: `${formatCount(used)} (model limit: ${formatCount(limit)})`,
    segments: [
      ...tokenSegments(used),
      { text: " (model limit: ", tone: "muted" },
      ...tokenSegments(limit, "countDim"),
      { text: ")", tone: "muted" },
    ],
  };
}

// Reads row: total reads with the distinct-file count beside them.
function readRows(group: StatsGroup): readonly InsightRow[] {
  if (group.reads === 0) {
    return [];
  }
  return [
    {
      label: "reads",
      value: `${group.reads} (${group.uniqueReads} unique)`,
      segments: [
        { text: formatCount(group.reads), tone: "count" },
        { text: " (", tone: "muted" },
        { text: formatCount(group.uniqueReads), tone: "countDim" },
        { text: " unique)", tone: "muted" },
      ],
    },
  ];
}

// Failures row, shown only when something failed.
function failureRows(group: StatsGroup): readonly InsightRow[] {
  if (group.failures === 0) {
    return [];
  }
  return [
    {
      label: "failures",
      value: formatCount(group.failures),
      segments: [{ text: formatCount(group.failures), tone: "error" }],
    },
  ];
}

// Compression section: one row per active block, showing its topic and what it
// replaced with its summary plus the saving, and the running total at the top,
// with the context size before and after the pruning when the usage is known.
//
// `width` is the value column, so a topic too long for the room left is cut to
// it.
function compressionSection(
  dcp: DcpSummary,
  heading: string,
  windowUsage: ContextWindowUsage | undefined,
  width: number,
): InsightSection {
  if (dcp.blocks.length === 0) {
    return { heading, rows: [{ label: "none", value: "" }] };
  }

  // Context size had nothing been pruned: what the model holds now plus every
  // token DCP has pruned over the session.
  const usedTokens =
    windowUsage === undefined ? undefined : tokenTotal(windowUsage.traffic);
  const unprunedTokens =
    usedTokens === undefined ? undefined : usedTokens + dcp.totalPruneTokens;
  const rangeText =
    usedTokens === undefined || unprunedTokens === undefined
      ? ""
      : ` (${formatCount(unprunedTokens)} → ${formatCount(usedTokens)})`;
  const rangeSegments =
    usedTokens === undefined || unprunedTokens === undefined
      ? []
      : parenthetical([
          ...tokenSegments(unprunedTokens, "countDim"),
          { text: " → ", tone: "muted" },
          ...tokenSegments(usedTokens, "countDim"),
        ]);

  const blockWord = dcp.blocks.length === 1 ? "block" : "blocks";
  return {
    heading,
    rows: [
      {
        label: "pruned",
        value: `${formatCount(dcp.totalPruneTokens)}${rangeText}`,
        segments: [
          ...tokenSegments(dcp.totalPruneTokens),
          ...rangeSegments,
        ],
      },
      {
        label: "blocks",
        value: `${formatCount(dcp.blocks.length)} ${blockWord}`,
        segments: [
          { text: formatCount(dcp.blocks.length), tone: "count" },
          { text: ` ${blockWord}`, tone: "value" },
        ],
      },
      ...dcp.blocks.map((block) => {
        const id = `#${block.id}`;
        const saving = block.compressedTokens - block.summaryTokens;
        const savingText = saving > 0 ? ` (−${formatRoundedTokens(saving)})` : "";
        const blockSize = formatBlockSize(block);
        // Cut the topic to the cells the figures after it leave, so an
        // overflowing description ends in an ellipsis rather than a clipped word.
        const topic = truncateText(
          formatTopic(block),
          width -
            id.length -
            1 -
            ENTRY_SEPARATOR.length -
            blockSize.length -
            savingText.length,
        );
        return {
          label: "",
          value: `${id} ${topic}${ENTRY_SEPARATOR}${blockSize}${savingText}`,
          segments: [
            { text: `${id} `, tone: "muted" },
            { text: topic, tone: "value" },
            { text: ENTRY_SEPARATOR, tone: "muted" },
            ...tokenSegments(block.compressedTokens),
            { text: " → ", tone: "muted" },
            ...tokenSegments(block.summaryTokens),
            ...(saving > 0 ? parenthetical(savingSegments(saving)) : []),
          ],
        };
      }),
    ],
  };
}

// A run of segments wrapped in a plain pair of parentheses.
function parenthetical(inner: readonly InsightSegment[]): readonly InsightSegment[] {
  return [
    { text: " (", tone: "muted" },
    ...inner,
    { text: ")", tone: "muted" },
  ];
}

// A saving as a dimmed figure with a minus sign: the tokens a compression freed.
function savingSegments(saving: number): readonly InsightSegment[] {
  const [head, ...tail] = roundedTokenSegments(saving, "countDim");
  if (head === undefined) {
    return [];
  }
  return [{ ...head, text: `−${head.text}` }, ...tail];
}

// Label for a compression block: its topic, or its number when DCP recorded no
// topic. Cutting it to the room left is the section's job.
function formatTopic(block: DcpBlock): string {
  const topic = block.topic.trim();
  return topic.length === 0 ? `block ${block.id}` : topic;
}

// Size a compression block replaced against the size of its summary.
function formatBlockSize(block: DcpBlock): string {
  return `${formatCount(block.compressedTokens)} → ${formatCount(block.summaryTokens)}`;
}

// Drop trailing zeros so `12.0k` reads as `12k` and `1.30M` as `1.3M`.
function trimDecimals(value: number, digits: number): string {
  return value
    .toFixed(digits)
    .replace(/(\.\d*?)0+$/, "$1")
    .replace(/\.$/, "");
}
