/** @jsxImportSource @opentui/solid */
// Session stats header component: message and tool counts.
//
// Draws one line above the prompt composer: how many conversation messages and
// tool calls the session holds, and how many of them remain in the model's
// active context after DCP compression.
// Session counts come from the host's reactive message store; the compressed
// ids come from DCP's per-session state file, watched so the line follows a
// compression.

import { usePlugin } from "@opencode/plugin/tui";
import type { Context } from "@opencode/plugin/tui/context";
import { watch } from "node:fs";
import { For, Show, createEffect, createMemo, createSignal, on } from "solid-js";
import type { Accessor, JSX } from "solid-js";
import { BODY_PADDING_X, Tooltip } from "../../tui-toolkit/tooltip/component";
import { anchorBoxFromEvent, anchorFromEvent } from "../../tui-toolkit/tooltip/anchor";
import type { AnchorBox } from "../../tui-toolkit/tooltip/anchor";
import type { Rect } from "../../tui-toolkit/tooltip/layout";
import { countInsights } from "./counts";
import type { CountableMessage, StatsGroup } from "./counts";
import { brightenColor } from "./colors";
import type {
  ContextWindowUsage,
  InsightGroup,
  InsightLayout,
  InsightSection,
  SessionFacts,
  SubagentFacts,
} from "./insights";
import { buildInsights, countInsightLines, measureInsightWidth } from "./insights";
import {
  DETAIL_INDENT,
  InsightSectionView,
  LABEL_GAP,
  LABEL_WIDTH,
} from "./tooltip-section";
import { getDcpStateDirectory, readDcpSummary } from "./dcp-state";
import type { DcpSummary } from "./dcp-state";

// Milliseconds to wait after a state-file event before re-reading, so a burst
// of writes settles first.
const WATCH_DEBOUNCE_MS = 50;

// Nerd Font glyph that labels a user-message count.
const USER_GLYPH = "󰍩";

// Nerd Font glyph that labels an assistant-message count.
const ASSISTANT_GLYPH = "󱜾";

// Nerd Font glyph that labels a tool count.
const TOOL_GLYPH = "󰒔";

// Widest the tooltip may draw, in terminal cells, padding included.
const TOOLTIP_MAX_WIDTH = 64;

// Narrowest the tooltip may draw, so a short readout still reads as a panel.
const TOOLTIP_MIN_WIDTH = 30;

// Cells the tooltip's value column offers at its widest: the panel width less
// its body padding, the label column, and the gap after the label. Long rows
// wrap to it.
const TOOLTIP_VALUE_WIDTH =
  TOOLTIP_MAX_WIDTH - 2 * BODY_PADDING_X - LABEL_WIDTH - LABEL_GAP;

// Row layout the widest line is measured against, so the panel can hug it.
const TOOLTIP_LAYOUT: InsightLayout = {
  labelWidth: LABEL_WIDTH,
  detailIndent: DETAIL_INDENT,
  labelGap: LABEL_GAP,
};

// How far an open group's colour is brightened toward white, 0 to 1.
const OPEN_BRIGHTEN_AMOUNT = 0.35;

// The row drawn between two tooltip sections, leaving a line of panel colour.
const SECTION_GAP_ROW = " ";

// Warning shown when the host's message store has no paging API, so the counts
// can only cover the newest window.
const MISSING_PAGING_WARNING =
  "the message store has no paging API, so the counts cover only the newest window";

// Warning shown when paging the whole transcript failed.
const FAILED_PAGING_WARNING =
  "loading the whole transcript failed, so the counts may cover only the newest window";

// Warning shown when paging reported success but older pages remained.
const INCOMPLETE_PAGING_WARNING =
  "loading the whole transcript did not finish, so the counts may cover only the newest window";

// Which count group the click landed on.
type StatsGroupKind = "session" | "context";

// An open count group, with the box it occupies and the session it belongs to,
// so the tooltip can be placed and filled.
type OpenStatsGroup = {
  readonly kind: StatsGroupKind;
  readonly anchor: Rect;
  // The clicked element itself, kept so the anchor can be re-read after a
  // terminal resize moves it.
  readonly source?: AnchorBox;
  readonly sessionID: string;
};

// Session totals used when the host has not published session info yet.
const EMPTY_SESSION_FACTS: SessionFacts = {
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
};

// The insights line, ready to plug into the composer header slot.
export type SessionStatsLine = {
  // Render the counts for a session.
  readonly render: (sessionID: string) => JSX.Element;
  // Stop watching DCP's state directory and release the tooltip slot.
  readonly dispose: () => void;
};

// Build the insights line and start watching DCP for compressions.
//
// The watch and the tooltip overlay are owned by the plugin rather than a
// rendered component, so they are started once and survive slot re-renders.
export function createSessionStats(context: Context): SessionStatsLine {
  // Bumped whenever DCP rewrites a state file, so the counts re-read it.
  const [revision, setRevision] = createSignal(0);
  const stopWatching = watchDcpState(() => setRevision((value) => value + 1));

  // The count group whose tooltip is open, or nothing when it is closed.
  const [open, setOpen] = createSignal<OpenStatsGroup | undefined>(undefined);

  // Clicking a group opens its tooltip, clicking it again closes it, and
  // clicking the other group replaces it.
  function toggleGroup(target: OpenStatsGroup): void {
    setOpen((current) =>
      current?.kind === target.kind && current.sessionID === target.sessionID
        ? undefined
        : target,
    );
  }

  // The tooltip lives in the app slot, whose box is the whole main area, so an
  // absolutely positioned child can sit above the composer.
  const disposeTooltip = context.ui.slot({
    append: "app",
    render: () => (
      <Show when={open()}>
        {(target) => (
          <StatsTooltip
            target={target()}
            revision={revision}
            onClose={() => setOpen(undefined)}
          />
        )}
      </Show>
    ),
  });

  return {
    render: (sessionID) => (
      <SessionStats
        sessionID={sessionID}
        revision={revision()}
        open={open}
        onToggle={toggleGroup}
        onClose={() => setOpen(undefined)}
      />
    ),
    dispose: () => {
      stopWatching();
      disposeTooltip();
    },
  };
}

// Watch DCP's state directory for compressions, reporting to `onChange` once a
// burst of writes settles. Returns a disposer that closes the watch.
function watchDcpState(onChange: () => void): () => void {
  let debounceTimer: ReturnType<typeof setTimeout> | undefined;
  function scheduleChange(): void {
    if (debounceTimer !== undefined) {
      clearTimeout(debounceTimer);
    }
    debounceTimer = setTimeout(onChange, WATCH_DEBOUNCE_MS);
  }

  // Watch the directory, not the session file: DCP rewrites state in place,
  // which can replace the watched inode.
  let watcher: ReturnType<typeof watch> | undefined;
  try {
    watcher = watch(getDcpStateDirectory(), (_event, filename) => {
      if (filename === null || String(filename).endsWith(".json")) {
        scheduleChange();
      }
    });
  } catch {
    // DCP may not have created its state directory yet; the counts still
    // resolve on the next session change or restart.
  }

  return () => {
    if (debounceTimer !== undefined) {
      clearTimeout(debounceTimer);
    }
    watcher?.close();
  };
}

// Load a session's whole transcript into the host's message store.
//
// The store holds only the newest window by default and pages older messages in
// on demand, so the counts would otherwise cover just that window. Reading the
// store here keeps the caller's effect subscribed, so the load repeats whenever
// the host truncates the window again.
function loadTranscript(context: Context, sessionID: string): void {
  if (context.data.session.message.list(sessionID).length === 0) {
    void syncTranscript(context, sessionID);
    return;
  }

  void extendTranscript(context, sessionID).catch(() => {
    // The paging methods are undocumented; a throw from the shape check itself
    // must not break the render.
  });
}

// Load the newest window of a session whose store is empty, then the rest of its
// transcript. A failure leaves the counts on whatever was loaded.
async function syncTranscript(
  context: Context,
  sessionID: string,
): Promise<void> {
  try {
    await context.data.session.message.sync(sessionID);
  } catch {
    // A session can be deleted while it loads; the counts stay empty until the
    // store has messages.
    return;
  }

  await extendTranscript(context, sessionID);
}

// Page the messages older than the loaded window into the store.
//
// The paging methods are undocumented host surface, so a missing, failing, or
// unfinished load is reported: the counts would otherwise silently cover only
// the newest window.
async function extendTranscript(
  context: Context,
  sessionID: string,
): Promise<void> {
  const history = context.data.session.message as MessageHistoryStore;
  if (history.more === undefined || history.loadMore === undefined) {
    reportPagingProblem(context, sessionID, "missing", MISSING_PAGING_WARNING);
    return;
  }

  if (history.more(sessionID) !== true) {
    return;
  }

  try {
    await history.loadMore(sessionID, { all: true });
  } catch {
    reportPagingProblem(context, sessionID, "failed", FAILED_PAGING_WARNING);
    return;
  }

  if (history.more(sessionID) === true) {
    reportPagingProblem(
      context,
      sessionID,
      "incomplete",
      INCOMPLETE_PAGING_WARNING,
    );
  }
}

// Problems already reported, keyed by session and reason, so a repeated failure
// does not notify again.
const reportedPagingProblems = new Set<string>();

// Tell the user about a paging problem, once per session and reason.
//
// These failures are invisible in the counts, so the toast (and the desktop
// notification while the TUI is unfocused) is the only sign that the paging
// surface has changed under the widget.
function reportPagingProblem(
  context: Context,
  sessionID: string,
  reason: string,
  message: string,
): void {
  const key = `${sessionID}:${reason}`;
  if (reportedPagingProblems.has(key)) {
    return;
  }
  reportedPagingProblems.add(key);

  context.ui.toast.show({
    title: "session stats",
    message,
    variant: "warning",
  });
  void context.attention
    .notify({
      title: "session stats",
      message,
      notification: { when: "blurred" },
      sound: { when: "blurred" },
    })
    .catch(() => undefined);
}

// The message-store methods the host exposes at runtime but omits from the
// plugin's declared data surface: they page in the transcript older than the
// initial window, which is what the host itself does when the user scrolls up.
type MessageHistoryStore = {
  readonly more?: (sessionID: string) => boolean;
  readonly loadMore?: (
    sessionID: string,
    options: { readonly all?: boolean },
  ) => Promise<void>;
};

// The insights line for one session.
function SessionStats(props: {
  readonly sessionID: string;
  readonly revision: number;
  readonly open: Accessor<OpenStatsGroup | undefined>;
  readonly onToggle: (target: OpenStatsGroup) => void;
  readonly onClose: () => void;
}) {
  const context = usePlugin();
  const [dcp, setDcp] = createSignal<DcpSummary>(
    readDcpSummary(props.sessionID),
  );

  // A session opens with only a short window of messages loaded, so ask the
  // store for the rest; the counts then cover the whole transcript.
  createEffect(() => {
    loadTranscript(context, props.sessionID);
  });

  // Re-read DCP's summary when the session changes or DCP rewrites state.
  createEffect(
    on(
      () => [props.sessionID, props.revision] as const,
      ([sessionID]) => {
        setDcp(readDcpSummary(sessionID));
      },
    ),
  );

  // Close an open tooltip when the viewed session changes, so it never
  // describes the session that was open before.
  createEffect(
    on(
      () => props.sessionID,
      () => props.onClose(),
      { defer: true },
    ),
  );

  const insights = createMemo(() =>
    countInsights(
      context.data.session.message.list(props.sessionID),
      dcp().compressed,
    ),
  );

  // Whether the session has a conversation turn to report.
  const hasTurns = () => {
    const session = insights().session;
    return session.userMessages + session.assistantMessages > 0;
  };

  // Whether compression has removed anything, so the context counts need their
  // own group.
  const contextDiffers = () => {
    const { session, context: active } = insights();
    return (
      active.userMessages !== session.userMessages ||
      active.assistantMessages !== session.assistantMessages ||
      active.toolCalls !== session.toolCalls
    );
  };

  // Muted theme colour, shared by the session group and the separator.
  const mutedColor = context.theme.text.muted;

  // Colour for a group: its base colour, or a brighter shade of the same hue
  // while its tooltip is open.
  const groupColor = (kind: StatsGroupKind, base: string) =>
    props.open()?.kind === kind
      ? brightenColor(base, OPEN_BRIGHTEN_AMOUNT)
      : base;

  return (
    <Show when={hasTurns()}>
      <box flexDirection="row" gap={1} flexShrink={0}>
        <Show
          when={contextDiffers()}
          fallback={
            <CountGroup
              label="Sess/Ctx"
              kind="session"
              sessionID={props.sessionID}
              group={insights().session}
              fg={groupColor("session", mutedColor)}
              onToggle={props.onToggle}
            />
          }
        >
          <CountGroup
            label="Sess"
            kind="session"
            sessionID={props.sessionID}
            group={insights().session}
            fg={groupColor("session", mutedColor)}
            onToggle={props.onToggle}
          />
          <text fg={mutedColor} selectable={false} wrapMode="none">
            ·
          </text>
          <CountGroup
            label="Ctx"
            kind="context"
            sessionID={props.sessionID}
            group={insights().context}
            fg={groupColor("context", context.theme.hue.accent[400])}
            onToggle={props.onToggle}
          />
        </Show>
      </box>
    </Show>
  );
}

// One count group: a label followed by the user, assistant, and tool counts, for
// example `Sess: 󰍩 12 󱜾 30 󰒔 118`.
//
// `label` names the group, `kind` says which tooltip it explains, `sessionID` is
// the session it counts, `group` holds the counts it shows, and `fg` is the
// terminal colour token applied to the whole group. `onToggle` reports a click
// released over the group.
function CountGroup(props: {
  readonly label: string;
  readonly kind: StatsGroupKind;
  readonly sessionID: string;
  readonly group: StatsGroup;
  readonly fg: string;
  readonly onToggle: (target: OpenStatsGroup) => void;
}) {
  return (
    // Keyed on the colour: the host applies `fg` when the text is created, so a
    // changed colour needs a fresh renderable.
    <Show keyed when={props.fg}>
      {(fg) => (
        <text
          fg={fg}
          selectable={false}
          wrapMode="none"
          truncate
          onMouseUp={(event) => {
            if (event.button !== 0) {
              return;
            }
            props.onToggle({
              kind: props.kind,
              anchor: anchorFromEvent(event),
              source: anchorBoxFromEvent(event),
              sessionID: props.sessionID,
            });
          }}
        >
          {`${props.label}: ${USER_GLYPH} ${props.group.userMessages} ${ASSISTANT_GLYPH} ${props.group.assistantMessages} ${TOOL_GLYPH} ${props.group.toolCalls}`}
        </text>
      )}
    </Show>
  );
}

// The tooltip for the open count group.
//
// Reads the session's counters, totals, and DCP compression summary, so the
// tooltip follows both the session and the compression state while it is open.
function StatsTooltip(props: {
  readonly target: OpenStatsGroup;
  readonly revision: Accessor<number>;
  readonly onClose: () => void;
}) {
  const context = usePlugin();

  // The tooltip's rows and the body-row count they need. Reading the revision
  // here subscribes the memo to DCP's state-file watcher.
  const view = createMemo(() => {
    void props.revision();
    return buildTooltipView(context, props.target);
  });

  return (
    <Tooltip
      anchor={props.target.anchor}
      anchorSource={props.target.source}
      width={view().width}
      bodyRows={view().bodyRows}
      title={view().title}
      onClose={props.onClose}
    >
      <For each={view().sections}>
        {(section, index) => (
          <>
            <Show when={index() > 0}>
              <text selectable={false}>{SECTION_GAP_ROW}</text>
            </Show>
            <InsightSectionView section={section} />
          </>
        )}
      </For>
    </Tooltip>
  );
}

// The tooltip's title, rows, and the body rows they need for an open group.
//
// Always returns a value. A failure while reading the host's stores becomes a
// titled `error` section: the panel is a readout, so a visible reason beats a
// tooltip that would blank out.
function buildTooltipView(
  context: Context,
  target: OpenStatsGroup,
): {
  readonly title: string;
  readonly sections: readonly InsightSection[];
  readonly bodyRows: number;
  readonly width: number;
} {
  try {
    const group = buildTooltipGroup(context, target);
    return {
      title: group.title,
      sections: group.sections,
      bodyRows: countInsightLines(group.sections),
      width: panelWidth(group.sections),
    };
  } catch (error) {
    const detail = error instanceof Error ? error.message : String(error);
    const sections: readonly InsightSection[] = [
      {
        heading: "error",
        rows: [{ label: "reason", value: detail.slice(0, 120) }],
      },
    ];
    return {
      title: "session stats",
      sections,
      bodyRows: countInsightLines(sections),
      width: panelWidth(sections),
    };
  }
}

// Cells the panel needs for the sections, kept inside the tooltip's width range:
// wide enough for the widest rendered line, and no wider.
function panelWidth(sections: readonly InsightSection[]): number {
  const content = measureInsightWidth(sections, TOOLTIP_LAYOUT);
  return Math.min(
    TOOLTIP_MAX_WIDTH,
    Math.max(TOOLTIP_MIN_WIDTH, content + 2 * BODY_PADDING_X),
  );
}

// The tooltip group for an open kind: the counters, the session's totals, the
// window usage, and DCP's compression state.
function buildTooltipGroup(
  context: Context,
  target: OpenStatsGroup,
): InsightGroup {
  const sessionID = target.sessionID;
  const messages = context.data.session.message.list(sessionID) ?? [];
  const dcp = readDcpSummary(sessionID);
  const info = context.data.session.get(sessionID);
  const stats = countInsights(messages, dcp.compressed);

  return buildInsights({
    stats,
    session:
      info === undefined
        ? EMPTY_SESSION_FACTS
        : {
            costUsd: info.cost,
            familyCostUsd: context.data.session.cost(sessionID),
            subagents: collectSubagents(context, sessionID),
            inputTokens: info.tokens.input,
            outputTokens: info.tokens.output,
            reasoningTokens: info.tokens.reasoning,
            activeReasoningTokens: activeReasoningTokens(messages, dcp),
            cacheReadTokens: info.tokens.cache.read,
            cacheWriteTokens: info.tokens.cache.write,
            createdAt: info.time.created,
            updatedAt: info.time.updated,
          },
    contextWindow: contextWindowOf(
      messages,
      dcp,
      info?.model,
      listModels(context),
    ),
    dcp,
    valueWidth: TOOLTIP_VALUE_WIDTH,
  })[target.kind];
}

// The models the host knows, or undefined when the data layer has not synced
// them yet.
//
// Read through a narrow type: the collection hangs off the data layer's
// location group, well away from anything the tooltip otherwise touches.
function listModels(context: Context): readonly ModelInfoShape[] | undefined {
  const location = (
    context.data as { readonly location?: ModelLocationGroup }
  ).location;
  return location?.model?.list?.();
}

// The data layer's location group, narrowed to the model collection.
type ModelLocationGroup = {
  readonly model?: {
    readonly list?: () => readonly ModelInfoShape[] | undefined;
  };
};

// The session fields the subagent walk needs.
type SessionTreeEntry = {
  readonly id: string;
  readonly parentID?: string;
  readonly agent?: string;
  readonly title?: string;
  readonly cost: number;
  readonly tokens: {
    readonly input: number;
    readonly output: number;
    readonly cache: {
      readonly read: number;
      readonly write: number;
    };
  };
  readonly time: { readonly created: number };
};

// Sessions spawned under `sessionID`, at any depth, in the order they were
// created.
//
// The host's family list is keyed by root, so it cannot answer this for a
// nested session; walking the parent links stays right at either level.
function collectSubagents(
  context: Context,
  sessionID: string,
): readonly SubagentFacts[] {
  const sessions = context.data.session.list();
  const childIds = childSessions(sessions);
  const sessionsByID = new Map<string, SessionTreeEntry>(
    sessions.map((session) => [session.id, session]),
  );
  const seen = new Set<string>();
  const pending = [...(childIds.get(sessionID) ?? [])];
  while (pending.length > 0) {
    const nextID = pending.pop();
    if (nextID === undefined || seen.has(nextID)) {
      continue;
    }
    seen.add(nextID);
    pending.push(...(childIds.get(nextID) ?? []));
  }
  return [...seen]
    .map((id) => sessionsByID.get(id))
    .filter((session): session is SessionTreeEntry => session !== undefined)
    .sort((left, right) => left.time.created - right.time.created)
    .map((session) => ({
      agent: session.agent ?? "agent",
      title: session.title ?? "",
      // Prompt, completion, and both cache directions, matching the session's
      // token traffic line; reasoning is reported separately as thinking.
      tokenTotal:
        session.tokens.input +
        session.tokens.output +
        session.tokens.cache.read +
        session.tokens.cache.write,
      costUsd: session.cost,
    }));
}

// Child session ids, grouped by their parent.
function childSessions(
  sessions: readonly SessionTreeEntry[],
): ReadonlyMap<string, readonly string[]> {
  const childIds = new Map<string, string[]>();
  for (const session of sessions) {
    if (session.parentID === undefined) {
      continue;
    }
    const siblings = childIds.get(session.parentID) ?? [];
    siblings.push(session.id);
    childIds.set(session.parentID, siblings);
  }
  return childIds;
}

// Tokens in the model's window, from the newest assistant step still in context,
// and the window of the model the session runs.
//
// The token split matches the host's own context-usage figure: prompt, completion,
// reasoning, and both cache directions of that step.
// The usage is returned without a limit when the model's catalogue entry is
// unknown, so the window figures still reach the tooltip; it is undefined only
// when no assistant step carries token data.
function contextWindowOf(
  messages: readonly WindowMessage[],
  dcp: DcpSummary,
  model: { readonly providerID: string; readonly id: string } | undefined,
  models: readonly ModelInfoShape[] | undefined,
): ContextWindowUsage | undefined {
  const lastAssistant = lastAssistantInContext(messages, dcp);
  if (lastAssistant?.tokens === undefined) {
    return undefined;
  }

  const tokens = lastAssistant.tokens;
  return {
    traffic: {
      input: tokens.input,
      output: tokens.output,
      reasoning: tokens.reasoning,
      cacheRead: tokens.cache.read,
      cacheWrite: tokens.cache.write,
    },
    limit: modelLimitOf(model, models),
  };
}

// Reasoning tokens the assistant steps still in context carry.
//
// A step DCP compresses leaves the model's context, so its thinking no longer
// counts as active.
function activeReasoningTokens(
  messages: readonly WindowMessage[],
  dcp: DcpSummary,
): number {
  return messages.reduce((total, message) => {
    if (
      message.type !== "assistant" ||
      dcp.compressed.messageIds.has(message.id)
    ) {
      return total;
    }
    return total + (message.tokens?.reasoning ?? 0);
  }, 0);
}

// The model's window size, or undefined until the model list is synced or when
// it has no entry for the model.
function modelLimitOf(
  model: { readonly providerID: string; readonly id: string } | undefined,
  models: readonly ModelInfoShape[] | undefined,
): number | undefined {
  if (model === undefined || models === undefined) {
    return undefined;
  }
  return models.find(
    (candidate) =>
      candidate.providerID === model.providerID &&
      (candidate.modelID === model.id || candidate.id === model.id),
  )?.limit.context;
}

// The newest assistant step still in context: its tokens are the ones filling
// the window now.
function lastAssistantInContext(
  messages: readonly WindowMessage[],
  dcp: DcpSummary,
): WindowMessage | undefined {
  for (let index = messages.length - 1; index >= 0; index -= 1) {
    const message = messages[index];
    if (message === undefined || message.type !== "assistant") {
      continue;
    }
    if (dcp.compressed.messageIds.has(message.id)) {
      continue;
    }
    if (message.tokens !== undefined) {
      return message;
    }
  }
  return undefined;
}

// The message fields the window line reads, on top of the counted ones.
type WindowMessage = CountableMessage & {
  readonly tokens?: {
    readonly input: number;
    readonly output: number;
    readonly reasoning: number;
    readonly cache: {
      readonly read: number;
      readonly write: number;
    };
  };
};

// The model fields the window line reads, matching the host's model info.
type ModelInfoShape = {
  readonly id: string;
  readonly modelID: string;
  readonly providerID: string;
  readonly limit: {
    readonly context: number;
  };
};
