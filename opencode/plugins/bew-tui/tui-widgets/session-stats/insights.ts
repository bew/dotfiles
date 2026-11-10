// Tooltip content for the session-stats component.
//
// Turns the counters, the session totals, and DCP's compression
// summary into labelled rows.
// Pure formatting, so the wording and the number shapes are
// unit-testable without a terminal.

import type { DcpBlock, DcpSummary } from "./dcp-state";
import type {
  ContentBucket,
  ContentFacts,
  ContentKind,
  LastTurn,
  PromptFacts,
  SessionStats,
  SessionTiming,
  StatsGroup,
  TokenTraffic,
} from "./counts";

export type { TokenTraffic } from "./counts";

// A base colour a run can take.
export type InsightToneName =
  | "default"
  | "muted"
  | "agent"
  | "count"
  | "cost"
  | "error"
  | "time";

// A run's colour: one base tone, or a base tone plus `muted` to make it recede.
// `muted` on its own is the muted text colour rather than a dimmed base.
export type InsightTone = InsightToneName | readonly InsightToneName[];

// A coloured run of a row; plain text needs only its `text`.
export type InsightSegment = {
  // Text of the run.
  readonly text: string;
  // Which part of the row the run is, so the view can pick its colour; omitted
  // for the default tone.
  readonly tone?: InsightTone;
  // Draw the run in bold, for a unit that should stand out from its number.
  readonly bold?: boolean;
};

// One row of a tooltip, labelled or a detail line for the row above.
export type InsightRow = {
  // Left-hand label; omitted on a detail line.
  readonly label?: string;
  // Coloured runs of the row, read left to right.
  readonly segments: readonly InsightSegment[];
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
  // The subagent session's own token total: prompt, completion, and
  // both cache directions.
  // Reasoning is left out, matching the session's token detail line, so the two
  // figures stay comparable.
  readonly tokenTotal: number;
  // The subagent session's own cost in US dollars.
  readonly costUsd: number;
  // Creation time in milliseconds since the epoch, when the host reported it.
  readonly createdAt?: number;
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
  // The agent's system prompt, when the host exposes its text.
  readonly systemPrompt?: PromptFacts;
  // Whether the host has an agent whose prompt it could expose.
  readonly systemPromptExposed?: boolean;
  // Skills the agent can load, when the location lists them.
  readonly availableSkills?: number;
  // Agents the session can switch to, when the location lists them.
  readonly availableAgents?: number;
  // MCP servers whose tools the agent can call, when the location lists them.
  readonly mcpServers?: number;
};

// Tokens in the model's window, and the window's size when it is known.
export type ContextWindowUsage = {
  // Prompt, completion, reasoning, and cache tokens of the step in context.
  readonly traffic: TokenTraffic;
  // The model's window size, missing until the model catalogue is synced.
  readonly limit?: number;
  // Streaming time of that step, missing until the provider stamps its end.
  readonly streamingMs?: number;
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

// Spaces between the columns of a subagent line: agent, tokens,
// description, and cost.
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
          heading: "general",
          rows: [
            costRow(input.session),
            ...tokenRows(input.session, input.contextWindow),
            {
              label: "wall time",
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
        ...windowSections(
          input.contextWindow,
          input.session,
          input.stats.lastTurn,
        ),
        ...contentSections(
          input.stats.content,
          input.contextWindow,
          input.session,
        ),
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
// A panel is sized from this so it hugs its content instead of reserving
// columns its rows never reach.
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

// Plain text of a row, as its coloured runs read left to right.
function rowText(row: InsightRow): string {
  return segmentsText(row.segments);
}

// Cells one rendered row needs, its label cell included.
function rowWidthOf(row: InsightRow, layout: InsightLayout): number {
  const labelCell =
    row.label === undefined ? layout.detailIndent : layout.labelWidth;
  return labelCell + layout.labelGap + rowText(row).length;
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

// Durations in the largest unit that keeps them short: seconds,
// minutes, hours, or days.
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

// Costs in US dollars, at most two decimals.
// A non-zero amount that rounds to nothing shows as
// `~$0`, so a sub-cent figure is not read as exact.
export function formatCost(usd: number): string {
  const rounded = Math.round(usd * 100) / 100;
  if (rounded === 0) {
    return usd === 0 ? "$0.00" : "~$0";
  }
  return `$${rounded.toFixed(2)}`;
}

// Tool rows: the total, then the usage entries packed onto lines of `width`
// cells, under an empty label.
function toolRows(
  label: string,
  group: StatsGroup,
  width: number,
): readonly InsightRow[] {
  if (group.toolCalls === 0) {
    return [{ label, segments: [{ text: "none" }] }];
  }

  const entries: readonly (readonly InsightSegment[])[] = sortedUsage(
    group.toolUsage,
  ).map(([name, count]) => [
    { text: name },
    { text: ` ${count}`, tone: ["count", "muted"] },
  ]);

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
  const entries: readonly (readonly InsightSegment[])[] = sortedUsage(
    group.skillUsage,
  ).map(([name]) => [{ text: name }]);
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
  entries: readonly (readonly InsightSegment[])[],
  width: number,
  note?: { readonly count: number; readonly label: string },
): readonly InsightRow[] {
  const total = formatCount(count);
  const totalSegments: readonly InsightSegment[] = [
    { text: total, tone: "count" },
  ];
  const firstRow: InsightRow =
    note === undefined
      ? { label, segments: totalSegments }
      : rowWithNote({
          label,
          body: totalSegments,
          note: [
            { text: formatCount(note.count), tone: "count" },
            { text: ` ${note.label}`, tone: "muted" },
          ],
        });
  return [
    firstRow,
    ...packEntries(entries, width).map(
      (entry): InsightRow => ({ segments: entry }),
    ),
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
  entries: readonly (readonly InsightSegment[])[],
  width: number,
): readonly (readonly InsightSegment[])[] {
  const lines: (readonly (readonly InsightSegment[])[])[] = [];
  let line: (readonly InsightSegment[])[] = [];
  let lineWidth = 0;
  for (const entry of entries) {
    const addition =
      (line.length === 0 ? 0 : ENTRY_SEPARATOR.length) +
      segmentsText(entry).length;
    // Start a new line when this entry would overrun the current one.
    if (line.length > 0 && lineWidth + addition > width) {
      lines.push(line);
      line = [entry];
      lineWidth = segmentsText(entry).length;
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

// Join entries onto one run list, dimming the separators between them.
function joinEntries(
  entries: readonly (readonly InsightSegment[])[],
): readonly InsightSegment[] {
  return entries.flatMap(
    (entry, index): readonly InsightSegment[] =>
      index === 0
        ? entry
        : [{ text: ENTRY_SEPARATOR, tone: "muted" }, ...entry],
  );
}

// The plain text of a run list.
function segmentsText(segments: readonly InsightSegment[]): string {
  return segments.map((segment) => segment.text).join("");
}

// A detail row built from entries, keeping their runs and dimming the
// separators between them.
function detailRow(entries: readonly (readonly InsightSegment[])[]): InsightRow {
  return { segments: joinEntries(entries) };
}

// A row whose body is followed by a parenthesized note; a row without a
// label is a detail line.
function rowWithNote(noteRow: {
  readonly label?: string;
  readonly body: readonly InsightSegment[];
  readonly note: readonly InsightSegment[];
}): InsightRow {
  const segments = [...noteRow.body, ...parenthesized(noteRow.note)];
  return noteRow.label === undefined
    ? { segments }
    : { label: noteRow.label, segments };
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

// A row of token counts as a detail line:
// `label count`, joined by the separator.
function packedTokenRow(
  entries: readonly (readonly [string, number])[],
): InsightRow {
  return detailRow(
    entries.map(([label, count]) => [
      { text: `${label} ` },
      ...tokenSegments(count),
    ]),
  );
}

// Cache-hit detail: the share of the prompt tokens served from the cache.
//
// Prompt tokens are the uncached input plus both cache directions, and a cache
// read counts as a hit.
// Omitted when the prompt carried no tokens, so an empty or untokenized scope
// does not report a meaningless rate.
function cacheHitRows(
  traffic: TokenTraffic,
  label: "avg cache hit" | "cache hit",
): readonly InsightRow[] {
  const promptTokens = traffic.input + traffic.cacheRead + traffic.cacheWrite;
  if (promptTokens === 0) {
    return [];
  }
  const percent = Math.round((traffic.cacheRead / promptTokens) * 100);
  return [
    rowWithNote({
      body: [
        { text: `${label} ` },
        { text: String(percent), tone: "count" },
        { text: "%", tone: "count", bold: true },
      ],
      note: [
        ...tokenSegments(traffic.cacheRead),
        { text: " of ", tone: "muted" },
        ...tokenSegments(promptTokens),
        { text: " tokens", tone: "muted" },
      ],
    }),
  ];
}

// Detail rows for the session totals: the lifetime prompt, completion, and
// cache traffic, then the session's thinking and its average cache-hit share.
//
// The context group reports its own step instead; see `lastStepRows`.
function tokenDetailRows(
  facts: SessionFacts,
  traffic: TokenTraffic,
): readonly InsightRow[] {
  return [
    packedTokenRow([
      ["input", traffic.input],
      ["output", traffic.output],
      ["cache", traffic.cacheRead + traffic.cacheWrite],
    ]),
    ...thinkingRows(facts),
    ...cacheHitRows(traffic, "avg cache hit"),
  ];
}

// Token rows: the size of the model's window now, then the token
// details both groups share.
//
// The window size is left blank while no assistant step carries token data; the
// details stay, since they are read from the session totals rather than a step.
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
  return [
    tokenRow(usedTokens),
    ...tokenDetailRows(facts, traffic),
  ];
}

// Token row: the used size, and the model's limit beside it when known.
//
// Blank while no assistant step carries token data.
function tokenRow(usedTokens: number | undefined, limit?: number): InsightRow {
  if (usedTokens === undefined) {
    return { label: "tokens", segments: [] };
  }
  const usedSegments = tokenSegments(usedTokens);
  if (limit === undefined) {
    return { label: "tokens", segments: usedSegments };
  }
  return rowWithNote({
    label: "tokens",
    body: usedSegments,
    note: [
      { text: "model limit: ", tone: "muted" },
      ...tokenSegments(limit),
    ],
  });
}

// Thinking detail, reporting the reasoning the session generated and how much
// of it is still in the active context.
//
// Omitted for a session that never reported reasoning.
function thinkingRows(facts: SessionFacts): readonly InsightRow[] {
  if (facts.reasoningTokens === 0) {
    return [];
  }
  return [
    rowWithNote({
      body: [
        { text: "thinking " },
        ...tokenSegments(facts.reasoningTokens),
      ],
      note: [
        ...tokenSegments(facts.activeReasoningTokens),
        { text: " active", tone: "muted" },
      ],
    }),
  ];
}

// Cost row, showing this session and the whole family once they differ.
function costRow(facts: SessionFacts): InsightRow {
  const sessionCost = formatCost(facts.costUsd);
  const sessionSegments: readonly InsightSegment[] = [
    { text: sessionCost, tone: "cost" },
  ];
  if (facts.familyCostUsd <= facts.costUsd) {
    return { label: "cost", segments: sessionSegments };
  }
  return rowWithNote({
    label: "cost",
    body: sessionSegments,
    note: [
      { text: formatCost(facts.familyCostUsd), tone: "cost" },
      { text: " incl. subagents", tone: "muted" },
    ],
  });
}

// The subagents section: the total, then one line per subagent.
//
// A list longer than the limit is trimmed to its dearest few and its most
// recent few, each group under a label row of its own, so the total still
// accounts for what the rows leave out.
// The subagents arrive in creation order.
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
  return {
    label: "count",
    segments: [{ text: formatCount(count), tone: "count" }],
  };
}

// Label row opening one group of a trimmed subagent list, naming the group and
// how many lines follow it.
function subagentGroupRow(name: string, count: number): InsightRow {
  return { label: `${name} ${formatCount(count)}`, segments: [] };
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
    { text: " " },
    ...paddingSegments(token.length, columns.token),
    ...tokenSegments(subagent.tokenTotal),
    { text: " " },
    ...descriptionSegments,
    ...paddingSegments(description.length, columns.description),
    { text: " " },
    { text: formatCost(subagent.costUsd).padStart(columns.cost), tone: "cost" },
  ];
  return { segments };
}

// Spaces that widen a column's content to its shared width, so the columns to
// its right start at the same place on every row.
function paddingSegments(
  length: number,
  width: number,
): readonly InsightSegment[] {
  return length >= width
    ? []
    : [{ text: " ".repeat(width - length) }];
}

// Longest length in a list of strings, 0 when it is empty.
function longestOf(values: readonly string[]): number {
  return values.reduce((longest, value) => Math.max(longest, value.length), 0);
}

// Working-time rows: the share of the span spent working, then the split
// between streaming, waiting for tools, and idling.
//
// Idle covers everything else in the span, including time waiting for the
// user's answer to a question tool.
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
  const idle = formatDuration(idleMs);
  const share =
    spanMs > 0
      ? `${Math.min(100, Math.round((busyMs / spanMs) * 100))}%`
      : undefined;
  const details: readonly (readonly [string, string])[] = [
    [formatDuration(timing.generatingMs), "generating"],
    [formatDuration(timing.toolsMs), "tools"],
  ];
  const busySegments: readonly InsightSegment[] = [
    { text: busy, tone: "time" },
    { text: " busy" },
    ...(share === undefined
      ? []
      : parenthesized([{ text: share, tone: "muted" }])),
    { text: ENTRY_SEPARATOR, tone: "muted" },
    { text: idle, tone: "time" },
    { text: " idle" },
  ];
  return [
    { label: "timings", segments: busySegments },
    detailRow(
      details.map(([duration, unit]) => [
        { text: duration, tone: "time" },
        { text: ` ${unit}` },
      ]),
    ),
  ];
}

// One count as coloured runs: the number as a count, then its unit in bold so a
// shortened figure still reads as a quantity.
function tokenSegments(
  count: number,
  tone: InsightTone = "count",
): readonly InsightSegment[] {
  return countSegments(formatCount(count), tone);
}

// A difference as coloured runs, rounded to a whole unit: a saving is not known
// to the token, so a decimal would read as precision it does not have.
function roundedTokenSegments(
  count: number,
  tone: InsightTone = "count",
): readonly InsightSegment[] {
  return countSegments(formatRoundedTokens(count), tone);
}

// Splits a formatted count into its number run and a bold unit run.
function countSegments(
  text: string,
  tone: InsightTone,
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

// Content section: what fills the active context, by kind.
//
// Token figures are apportioned from each bucket's share of the
// transcript's characters.
// The system prompt and tool schemas are not in the transcript, so the split is
// an approximation; the word count is measured exactly.
function contentSections(
  content: ContentFacts,
  usage: ContextWindowUsage | undefined,
  session: SessionFacts,
): readonly InsightSection[] {
  const rows = contentRows(content, usage, session);
  if (rows.length === 0) {
    return [];
  }
  return [{ heading: "content", rows }];
}

// The agent prompt first, then one row per content bucket, then the remaining
// system records, bookkeeping, and the prompt overhead the location reports.
function contentRows(
  content: ContentFacts,
  usage: ContextWindowUsage | undefined,
  session: SessionFacts,
): readonly InsightRow[] {
  const prompt = session.systemPrompt;
  const totalCharacters =
    (prompt?.characters ?? 0) +
    content.reduce((total, bucket) => total + bucket.characters, 0);
  const usedTokens = usage === undefined ? undefined : tokenTotal(usage.traffic);

  const rows: InsightRow[] = [];
  if (prompt !== undefined) {
    rows.push(systemPromptRow(prompt, totalCharacters, usedTokens));
  } else if (session.systemPromptExposed === true) {
    // The built-in agents keep their prompt out of the SDK, so the row can
    // report that the prompt exists without inventing a size for it.
    rows.push({
      label: "system",
      segments: [{ text: "prompt not exposed", tone: "muted" }],
    });
  }

  // Prompt overhead the location reports sits directly below the
  // prompt it loads alongside.
  const available = availableSegments(session);
  if (available.length > 0) {
    rows.push({ segments: [{ text: "available: " }, ...available] });
  }

  // Conversation buckets are reported one per row; switches, idle markers, and
  // persisted system notices are protocol records rather than conversation.
  for (const bucket of content) {
    if (
      bucket.kind === "switches" ||
      bucket.kind === "idle" ||
      bucket.kind === "system"
    ) {
      continue;
    }
    rows.push(contentRow(bucket, totalCharacters, usedTokens));
  }

  const system = content.find((bucket) => bucket.kind === "system");
  const switches = contentEntries(content, "switches");
  const idle = contentEntries(content, "idle");
  const otherTotal = (system?.entries ?? 0) + switches + idle;
  if (otherTotal > 0) {
    rows.push(
      contentRow(
        {
          kind: "system",
          entries: otherTotal,
          words: system?.words ?? 0,
          characters: system?.characters ?? 0,
        },
        totalCharacters,
        usedTokens,
        "other",
      ),
    );
    const breakdown = otherBreakdownSegments(
      system?.entries ?? 0,
      switches,
      idle,
    );
    if (breakdown.length > 0) {
      rows.push({ segments: breakdown });
    }
  }

  return rows;
}

// The agent's system prompt as the first system row.
// It is one prompt, so no message count is shown.
function systemPromptRow(
  prompt: PromptFacts,
  totalCharacters: number,
  usedTokens: number | undefined,
): InsightRow {
  const body = contentTokenSegments(
    prompt.characters,
    totalCharacters,
    usedTokens,
  );
  const note: readonly InsightSegment[] =
    prompt.words === 0
      ? []
      : [
          { text: formatCount(prompt.words), tone: "count" },
          { text: " words", tone: "muted" },
        ];
  return rowWithNote({ label: "system", body, note });
}

// One content bucket as a labelled row, with its estimated token share
// and exact word count.
function contentRow(
  bucket: ContentBucket,
  totalCharacters: number,
  usedTokens: number | undefined,
  label: string = contentLabel(bucket.kind),
): InsightRow {
  const unit = bucket.kind === "tools" ? "calls" : "msg";
  const estimatedTokens = contentTokenSegments(
    bucket.characters,
    totalCharacters,
    usedTokens,
  );
  const body: InsightSegment[] = [
    { text: formatCount(bucket.entries), tone: "count" },
    { text: ` ${unit}` },
    ...(estimatedTokens.length === 0
      ? []
      : [
          { text: ENTRY_SEPARATOR, tone: "muted" as const },
          ...estimatedTokens,
        ]),
  ];
  const note: readonly InsightSegment[] =
    bucket.words === 0
      ? []
      : [
          { text: formatCount(bucket.words), tone: "count" },
          { text: " words", tone: "muted" },
        ];
  return rowWithNote({ label, body, note });
}

// Estimated tokens of a piece of content, marked `~`, with its share of the
// window; empty when the window size is unknown.
function contentTokenSegments(
  characters: number,
  totalCharacters: number,
  usedTokens: number | undefined,
): readonly InsightSegment[] {
  const share =
    totalCharacters === 0 ? undefined : characters / totalCharacters;
  if (usedTokens === undefined || share === undefined || share <= 0) {
    return [];
  }
  const tokens = Math.round(usedTokens * share);
  const percent = Math.round(share * 100);
  return [
    { text: "~", tone: "muted" },
    ...tokenSegments(tokens),
    { text: " (", tone: "muted" },
    { text: String(percent), tone: "count" },
    { text: "% ctx)", tone: "muted" },
  ];
}

// Entries recorded for one content kind, or zero when it is absent.
function contentEntries(content: ContentFacts, kind: ContentKind): number {
  return content.find((bucket) => bucket.kind === kind)?.entries ?? 0;
}

// The other entries broken down under their total: persisted system notices,
// agent switches, and idle markers.
function otherBreakdownSegments(
  system: number,
  switches: number,
  idle: number,
): readonly InsightSegment[] {
  const entries: (readonly InsightSegment[])[] = [];
  if (system > 0) {
    entries.push([
      { text: formatCount(system), tone: "count" },
      { text: " system" },
    ]);
  }
  if (switches > 0) {
    entries.push([
      { text: formatCount(switches), tone: "count" },
      { text: " switches" },
    ]);
  }
  if (idle > 0) {
    entries.push([
      { text: formatCount(idle), tone: "count" },
      { text: " idle" },
    ]);
  }
  return entries.length === 0 ? [] : joinEntries(entries);
}

// Prompt overhead the location reports: available skills,
// agents, and MCP servers.
function availableSegments(session: SessionFacts): readonly InsightSegment[] {
  const entries: (readonly InsightSegment[])[] = [];
  const skills = session.availableSkills ?? 0;
  if (skills > 0) {
    entries.push([
      { text: formatCount(skills), tone: "count" },
      { text: " skills" },
    ]);
  }
  const agents = session.availableAgents ?? 0;
  if (agents > 0) {
    entries.push([
      { text: formatCount(agents), tone: "count" },
      { text: " agents" },
    ]);
  }
  const servers = session.mcpServers ?? 0;
  if (servers > 0) {
    entries.push([
      { text: formatCount(servers), tone: "count" },
      { text: " mcp servers" },
    ]);
  }
  return joinEntries(entries);
}

// Label of a content bucket.
function contentLabel(kind: ContentKind): string {
  switch (kind) {
    case "user":
      return "user";
    case "assistant":
      return "assistant";
    case "tools":
      return "tools";
    case "system":
      return "system";
    case "switches":
      return "switches";
    case "idle":
      return "idle";
  }
}

// Last-turn rows, shown under the context group's general section: how long the
// turn took, what it cost, and what it produced.
function lastTurnRows(
  turn: LastTurn | undefined,
  subagents: readonly SubagentFacts[],
): readonly InsightRow[] {
  if (turn === undefined) {
    return [];
  }
  const note: InsightSegment[] =
    turn.durationMs === undefined
      ? []
      : [{ text: formatDuration(turn.durationMs), tone: "time" }];
  const rows: InsightRow[] = [
    rowWithNote({
      label: "last turn",
      body: [
        { text: formatCount(turn.steps), tone: "count" },
        { text: " steps" },
      ],
      note,
    }),
    lastTurnCostRow(turn.costUsd, lastTurnSubagentCost(turn, subagents)),
    packedTokenRow([
      ["output", turn.outputTokens],
      ["thinking", turn.reasoningTokens],
    ]),
  ];
  return rows;
}

// The step whose report fills the window, under the last-turn rows: how long it
// streamed and how fast, then the prompt it sent uncached and cached, the
// completion it returned, and its cache-hit share.
//
// `input` counts only the prompt tokens the provider billed as uncached, so the
// cache figure carries the bulk of a long prompt; together they are the window
// total the row above reports.
//
// Both figures need the provider's streaming marks, so a step still in flight
// reports its tokens under the last turn's rows without a `last step` label.
function lastStepRows(usage: ContextWindowUsage): readonly InsightRow[] {
  const rows: InsightRow[] = [];
  const pace = stepPaceSegments(usage);
  if (pace.length > 0) {
    rows.push({ label: "last step", segments: pace });
  }
  rows.push(
    packedTokenRow([
      ["input", usage.traffic.input],
      ["output", usage.traffic.output],
      ["cache", usage.traffic.cacheRead + usage.traffic.cacheWrite],
    ]),
    ...cacheHitRows(usage.traffic, "cache hit"),
  );
  return rows;
}

// How long the step streamed and how fast it did, as `22s · ~50 tok/s`.
function stepPaceSegments(usage: ContextWindowUsage): readonly InsightSegment[] {
  const segments: InsightSegment[] = [];
  if (usage.streamingMs !== undefined) {
    segments.push({ text: formatDuration(usage.streamingMs), tone: "time" });
  }
  const rate = tokensPerSecond(
    usage.traffic.output + usage.traffic.reasoning,
    usage.streamingMs,
  );
  if (rate === undefined) {
    return segments;
  }
  if (segments.length > 0) {
    segments.push({ text: ENTRY_SEPARATOR, tone: "muted" });
  }
  segments.push(
    { text: "~", tone: "muted" },
    { text: String(rate), tone: "count" },
    { text: " tok/s" },
  );
  return segments;
}

// Cost of the last turn, with the subagent total when any ran during it.
function lastTurnCostRow(costUsd: number, subagentCostUsd: number): InsightRow {
  const body: readonly InsightSegment[] = [
    { text: "cost " },
    { text: formatCost(costUsd), tone: "cost" },
  ];
  if (subagentCostUsd <= 0) {
    return { segments: body };
  }
  return rowWithNote({
    body,
    note: [
      { text: formatCost(costUsd + subagentCostUsd), tone: "cost" },
      { text: " incl. subagents", tone: "muted" },
    ],
  });
}

// Cost of the subagents created during the turn, skipping any without a
// creation time, which cannot be placed in time.
function lastTurnSubagentCost(
  turn: LastTurn,
  subagents: readonly SubagentFacts[],
): number {
  const startedAt = turn.startedAt;
  if (startedAt === undefined) {
    return 0;
  }
  return subagents.reduce(
    (total, subagent) =>
      subagent.createdAt !== undefined && subagent.createdAt >= startedAt
        ? total + subagent.costUsd
        : total,
    0,
  );
}

// Tokens the model produced per second of streaming time.
function tokensPerSecond(
  generatedTokens: number,
  generatingMs: number | undefined,
): number | undefined {
  if (generatingMs === undefined || generatingMs <= 0) {
    return undefined;
  }
  return Math.round((generatedTokens / generatingMs) * 1000);
}

// Window section: the used and total window with the session's thinking, then
// the last turn, then the step whose report fills the window.
//
// The window rows need the model's limit, which stays unknown until the model
// catalogue is synced; the last-turn and the last-step rows are
// reported without it.
function windowSections(
  usage: ContextWindowUsage | undefined,
  facts: SessionFacts,
  lastTurn: LastTurn | undefined,
): readonly InsightSection[] {
  const limit = usage?.limit;
  const windowRows: readonly InsightRow[] =
    usage === undefined || limit === undefined
      ? []
      : [tokenRow(tokenTotal(usage.traffic), limit), ...thinkingRows(facts)];
  // The last turn is reported as soon as its first step starts, before the
  // provider has returned the token counts the window row needs.
  const turnRows = lastTurnRows(lastTurn, facts.subagents);
  const stepRows = usage === undefined ? [] : lastStepRows(usage);
  if (windowRows.length === 0 && turnRows.length === 0) {
    return [];
  }
  return [
    {
      heading: "general",
      rows: [...windowRows, ...turnRows, ...stepRows],
    },
  ];
}

// Reads row: total reads with the distinct-file count beside them.
function readRows(group: StatsGroup): readonly InsightRow[] {
  if (group.reads === 0) {
    return [];
  }
  return [
    rowWithNote({
      label: "reads",
      body: [{ text: formatCount(group.reads), tone: "count" }],
      note: [
        { text: formatCount(group.uniqueReads), tone: "count" },
        { text: " unique", tone: "muted" },
      ],
    }),
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
      segments: [{ text: formatCount(group.failures), tone: "error" }],
    },
  ];
}

// Compression section: one row per active block, showing its topic and what it
// replaced with its summary plus the saving, and the running total at the top,
// with the context size before and after the pruning when the usage is known.
//
// `width` is the value column, so a topic too long for the room left is cut.
function compressionSection(
  dcp: DcpSummary,
  heading: string,
  windowUsage: ContextWindowUsage | undefined,
  width: number,
): InsightSection {
  if (dcp.blocks.length === 0) {
    return { heading, rows: [{ label: "none", segments: [] }] };
  }

  // Context size had nothing been pruned: what the model holds now plus every
  // token DCP has pruned over the session.
  const usedTokens =
    windowUsage === undefined ? undefined : tokenTotal(windowUsage.traffic);
  const unprunedTokens =
    usedTokens === undefined ? undefined : usedTokens + dcp.totalPruneTokens;
  const rangeSegments =
    usedTokens === undefined || unprunedTokens === undefined
      ? []
      : parenthesized([
          ...tokenSegments(unprunedTokens),
          { text: " → ", tone: "muted" },
          ...tokenSegments(usedTokens),
        ]);

  const blockWord = dcp.blocks.length === 1 ? "block" : "blocks";
  return {
    heading,
    rows: [
      {
        label: "pruned",
        segments: [
          ...tokenSegments(dcp.totalPruneTokens),
          ...rangeSegments,
        ],
      },
      {
        label: "blocks",
        segments: [
          { text: formatCount(dcp.blocks.length), tone: "count" },
          { text: ` ${blockWord}` },
        ],
      },
      ...dcp.blocks.map((block): InsightRow => {
        const id = `#${block.id}`;
        const saving = block.compressedTokens - block.summaryTokens;
        const savingText = saving > 0 ? ` (−${formatRoundedTokens(saving)})` : "";
        const blockSize = formatBlockSize(block);
        // Cut the topic to the cells the figures after it leave, so an
        // overflowing description ends in an ellipsis rather
        // than a clipped word.
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
          segments: [
            { text: `${id} `, tone: "muted" },
            { text: topic },
            { text: ENTRY_SEPARATOR, tone: "muted" },
            ...tokenSegments(block.compressedTokens),
            { text: " → ", tone: "muted" },
            ...tokenSegments(block.summaryTokens),
            ...(saving > 0 ? parenthesized(savingSegments(saving)) : []),
          ],
        };
      }),
    ],
  };
}

// A run of segments wrapped in a plain pair of parentheses, its runs muted so
// the note recedes behind the body it qualifies.
function parenthesized(
  inner: readonly InsightSegment[],
): readonly InsightSegment[] {
  if (inner.length === 0) {
    return [];
  }
  return [
    { text: " (", tone: "muted" },
    ...inner.map((segment) => ({
      ...segment,
      tone: withMutedTone(segment.tone),
    })),
    { text: ")", tone: "muted" },
  ];
}

// A tone with `muted` added, unless it is already there; omitted tones start
// from the default tone.
function withMutedTone(tone: InsightTone = "default"): InsightTone {
  const tones = typeof tone === "string" ? [tone] : tone;
  return tones.includes("muted") ? tone : [...tones, "muted"];
}

// A saving shown as a dimmed negative figure: the tokens a compression freed.
function savingSegments(saving: number): readonly InsightSegment[] {
  const [head, ...tail] = roundedTokenSegments(saving);
  if (head === undefined) {
    return [];
  }
  return [{ ...head, text: `−${head.text}` }, ...tail];
}

// Label for a compression block: its topic, or its number when
// DCP recorded no topic.
// Cutting it to the room left is the section's job.
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
