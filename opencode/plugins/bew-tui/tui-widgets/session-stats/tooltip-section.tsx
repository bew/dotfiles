/** @jsxImportSource @opentui/solid */
// Tooltip body views for the session-stats component: a titled group of rows,
// and one label/value row.

import { usePlugin } from "@opencode/plugin/tui";
import type { Context } from "@opencode/plugin/tui/context";
import { TextAttributes } from "@opentui/core";
import { For, Show } from "solid-js";
import type { InsightRow, InsightSection, InsightSegment, InsightToneName } from "./insights";
import { dimColor } from "./colors";

// Column width of a row's label, in cells, so values line up between rows.
export const LABEL_WIDTH = 9;

// Cells between a row's label column and its value.
export const LABEL_GAP = 1;

// Cells a detail row spends on its prefix, in place of the label column: the
// bar or corner alone, with the row's gap supplying the space after it.
export const DETAIL_INDENT = 1;

// Prefix of a detail row that has further detail rows under it.
const DETAIL_BAR = "│";

// Prefix of the last detail row of a run, closing the bar above it.
const DETAIL_CORNER = "└";

// Fallback blue for a subagent name, used when the theme has no blue palette.
const AGENT_FALLBACK_COLOR = "#5f87ff";

// Fallback yellow for a count, used when the theme has no yellow palette.
const COUNT_FALLBACK_COLOR = "#e5c07b";

// Fallback orange for a duration, used when the theme has no orange palette.
const TIME_FALLBACK_COLOR = "#d19a66";

// Share of the count yellow kept on a per-tool count, so the number recedes
// behind the tool name it belongs to.
const DETAIL_TOKEN_DIM = 0.4;

// One tooltip section: its heading and its rows.
export function InsightSectionView(props: {
  readonly section: InsightSection;
}) {
  const context = usePlugin();

  return (
    <box flexDirection="column">
      <Show when={props.section.heading.length > 0}>
        <text
          fg={context.theme.hue.accent[400]}
          attributes={TextAttributes.BOLD}
          wrapMode="none"
        >
          {props.section.heading.toUpperCase()}
        </text>
      </Show>
      <For each={props.section.rows}>
        {(row, index) => (
          <InsightRowView
            row={row}
            isLastDetail={endsDetailRun(props.section.rows, index())}
          />
        )}
      </For>
    </box>
  );
}

// One tooltip row: a muted label in a fixed column, then the value.
//
// A row with no label is a detail line for the row above, so a bar opens it in
// place of the label column; the last detail row of a run closes with a corner.
export function InsightRowView(props: {
  readonly row: InsightRow;
  readonly isLastDetail: boolean;
}) {
  const context = usePlugin();
  const labelWidth = isDetailRow(props.row) ? DETAIL_INDENT : LABEL_WIDTH;

  return (
    <box flexDirection="row" gap={LABEL_GAP}>
      <text
        fg={context.theme.text.muted}
        width={labelWidth}
        wrapMode="none"
      >
        {rowPrefix(props.row, props.isLastDetail)}
      </text>
      <box flexDirection="row">
        <For each={props.row.segments}>
          {(segment) => (
            <text
              fg={segmentColor(context, segment.tone)}
              attributes={
                segment.bold === true ? TextAttributes.BOLD : undefined
              }
              wrapMode="none"
            >
              {segment.text}
            </text>
          )}
        </For>
      </box>
    </box>
  );
}

// Whether a row is a detail line for the row above it, rather than a labelled
// row of its own.
function isDetailRow(row: InsightRow): boolean {
  return row.label === undefined;
}

// Text opening a row: a labelled row shows its label, a detail row shows a bar,
// and the last detail row of a run closes the bar with a corner.
function rowPrefix(row: InsightRow, isLastDetail: boolean): string {
  const label = row.label;
  if (label !== undefined) {
    return label;
  }
  return isLastDetail ? DETAIL_CORNER : DETAIL_BAR;
}

// Colour a segment's tone reads in, with `muted` dimming whatever base tone it
// accompanies: a count in the theme's yellow, a duration in its orange, a cost
// or a failure count in its error red, a subagent name in its blue, a
// description muted, and anything else in the value colour.
function segmentColor(
  context: Context,
  tone: InsightSegment["tone"],
): string {
  const tones = typeof tone === "string" ? [tone] : tone;
  const base = tones.find((candidate) => candidate !== "muted") ?? "muted";
  const color = baseToneColor(context, base);
  const isMuted = tones.includes("muted");
  if (base === "muted" || !isMuted) {
    return color;
  }
  return dimColor(color, DETAIL_TOKEN_DIM);
}

// Colour of a base tone, before any `muted` modifier.
function baseToneColor(context: Context, tone: InsightToneName): string {
  if (tone === "count") {
    return context.theme.hue.yellow?.[400] ?? COUNT_FALLBACK_COLOR;
  }
  if (tone === "cost" || tone === "error") {
    return context.theme.text.feedback.error.base;
  }
  if (tone === "time") {
    return context.theme.hue.orange?.[400] ?? TIME_FALLBACK_COLOR;
  }
  if (tone === "agent") {
    return context.theme.hue.blue?.[400] ?? AGENT_FALLBACK_COLOR;
  }
  if (tone === "muted") {
    return context.theme.text.muted;
  }
  return context.theme.text.base;
}

// Whether the row at `index` ends a run of detail rows, so its prefix closes
// the bar that the rows above it drew.
function endsDetailRun(rows: readonly InsightRow[], index: number): boolean {
  const row = rows[index];
  if (row === undefined || !isDetailRow(row)) {
    return false;
  }
  const next = rows[index + 1];
  return next === undefined || !isDetailRow(next);
}
