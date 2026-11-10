// Session stats counting helpers for the session-stats component.
//
// Counts conversation messages and tool usage for a whole session and for the
// part still in model context, given the message and tool ids DCP
// has compressed away.
// Kept free of OpenCode and OpenTUI types, so it stays unit-testable.

import type { CompressedIds } from "./dcp-state";

// A session message, narrowed to the fields the counters read.
// The host's SessionMessageInfo satisfies this shape structurally.
export type CountableMessage = {
  readonly id: string;
  readonly type: string;
  readonly content?: readonly CountablePart[];
  // Plain text of a user, synthetic, shell, or skill message.
  readonly text?: string;
  // Name of the skill a `skill` message loaded.
  readonly name?: string;
  // Wall-clock marks of an assistant step, used for the working-time split.
  readonly time?: {
    readonly created: number;
    readonly streamed?: number;
    readonly completed?: number;
  };
  // Token counts of an assistant step, when the provider reported them.
  readonly tokens?: CountableTokens;
  // Cost of an assistant step, in US dollars.
  readonly cost?: number;
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

// Token counts as a message reports them, with the cache split into directions.
export type CountableTokens = {
  readonly input: number;
  readonly output: number;
  readonly reasoning: number;
  readonly cache: {
    readonly read: number;
    readonly write: number;
  };
};

// One part of an assistant message, narrowed to the fields the counters read.
export type CountablePart = {
  // Tool call id; text and reasoning parts carry none.
  readonly id?: string;
  readonly type: string;
  // Tool name.
  readonly name?: string;
  // Text of a text or reasoning part.
  readonly text?: string;
  // Tool call state; its status, input, and output are read.
  readonly state?: {
    readonly status?: string;
    readonly input?: unknown;
    readonly content?: readonly CountableTextPart[];
  };
  // Wall-clock marks of a tool call, used to keep a user wait out of tool time.
  readonly time?: {
    readonly created?: number;
    readonly ran?: number;
    readonly completed?: number;
  };
};

// Text of one part of a tool result.
export type CountableTextPart = {
  readonly type: string;
  readonly text?: string;
};

// Counts for one scope: the whole session, or the part still in model context.
export type StatsGroup = {
  // User turns.
  readonly userMessages: number;
  // Assistant turns.
  readonly assistantMessages: number;
  // Tool usage, one per assistant tool part, shell command, or loaded skill.
  readonly toolCalls: number;
  // Tool usage per tool name.
  readonly toolUsage: ReadonlyMap<string, number>;
  // Tool calls that ended in an error.
  readonly failures: number;
  // Skill loads, counted per `skill` tool call.
  readonly skills: number;
  // Loads per skill name, taken from the load call's input.
  readonly skillUsage: ReadonlyMap<string, number>;
  // `read` calls.
  readonly reads: number;
  // Distinct files read, counted by the read tool's `path` input.
  readonly uniqueReads: number;
};

// Working time the session spent, split by what it was doing.
export type SessionTiming = {
  // Time the model spent streaming its steps, in milliseconds.
  readonly generatingMs: number;
  // Time the steps spent waiting for their tools, in milliseconds.
  readonly toolsMs: number;
};

// A kind of content still in the model's context.
export type ContentKind =
  | "user"
  | "assistant"
  | "tools"
  | "system"
  | "switches"
  | "idle";

// One kind's share of the active context, measured from the transcript.
export type ContentBucket = {
  // What the bucket holds.
  readonly kind: ContentKind;
  // Messages for conversation buckets, tool calls for `tools`.
  readonly entries: number;
  // Whitespace-separated words in the bucket's text.
  readonly words: number;
  // Characters in the bucket's text, used to apportion token counts.
  readonly characters: number;
};

// Content buckets of the active context, in report order.
export type ContentFacts = readonly ContentBucket[];

// Size of the agent's system prompt, which the host does
// not store as a message.
export type PromptFacts = {
  // Whitespace-separated words in the prompt.
  readonly words: number;
  // Characters in the prompt, used to apportion its token count.
  readonly characters: number;
};

// Running totals while a content bucket is counted.
type ContentTally = {
  entries: number;
  words: number;
  characters: number;
};

// What the last user turn did, taken from the steps still in context.
export type LastTurn = {
  // Wall-clock span from the user message to the last completed step.
  readonly durationMs?: number;
  // Creation time of the user message, used to place the turn's subagents.
  readonly startedAt?: number;
  // Assistant steps the turn ran.
  readonly steps: number;
  // Cost of the turn's steps, in US dollars.
  readonly costUsd: number;
  // Completion tokens the steps produced.
  readonly outputTokens: number;
  // Reasoning tokens the steps produced.
  readonly reasoningTokens: number;
  // Time the steps spent streaming, in milliseconds.
  readonly generatingMs: number;
};

// Counts for the whole session and for its active context.
export type SessionStats = {
  // Counts for the whole session.
  readonly session: StatsGroup;
  // Counts for the part still visible to the model.
  readonly context: StatsGroup;
  // Working time for the whole session.
  readonly timing: SessionTiming;
  // Content still in the model's context.
  readonly content: ContentFacts;
  // The agent's system prompt, when it is known.
  readonly systemPrompt: PromptFacts | undefined;
  // The latest user turn, when it has run at least one step.
  readonly lastTurn: LastTurn | undefined;
};

// Tool ids nothing is filtered out by, used for the whole-session counts.
const NO_SKIPPED_TOOL_IDS: ReadonlySet<string> = new Set();

// The tool name recorded for a loaded skill in the usage table.
const SKILL_TOOL_NAME = "skill";

// The tool name recorded for a shell command in the usage table.
const SHELL_TOOL_NAME = "shell";

// The tool name whose input paths are counted as unique reads.
const READ_TOOL_NAME = "read";

// Tool whose running time is the user's answer wait, not tool work.
const QUESTION_TOOL_NAME = "question";

// Count conversation turns and tool usage for a session and
// for its active context.
//
// User and assistant turns are counted separately; bookkeeping entries (agent
// switches, synthetic text, idle markers) are ignored.
// A tool counts once per assistant tool part and once per shell or skill
// message, which are command usage rather than conversation turns.
// `compressed` holds the ids DCP currently hides from the model: messages it
// drops from the context count entirely, tool ids it drops from tool totals.
export function countInsights(
  messages: readonly CountableMessage[],
  compressed: CompressedIds,
  systemPrompt?: string,
): SessionStats {
  const contextMessages = messages.filter(
    (message) => !compressed.messageIds.has(message.id),
  );

  return {
    session: countGroup(messages, NO_SKIPPED_TOOL_IDS),
    context: countGroup(contextMessages, compressed.toolIds),
    timing: countTiming(messages),
    content: countContent(contextMessages, compressed.toolIds),
    systemPrompt: promptFacts(systemPrompt),
    lastTurn: countLastTurn(contextMessages),
  };
}

// Split the session's working time into streaming and tool waits.
//
// A step streams from `created` until `streamed`, then waits for its tools
// until `completed`, so the two halves do not overlap and
// together cover the step.
// Steps still running, and messages without timings, contribute nothing.
function countTiming(messages: readonly CountableMessage[]): SessionTiming {
  let generatingMs = 0;
  let toolsMs = 0;
  for (const message of messages) {
    const time = message.time;
    if (time === undefined || time.completed === undefined) {
      continue;
    }
    const streamed = time.streamed ?? time.completed;
    generatingMs += Math.max(0, streamed - time.created);
    const toolMs = Math.max(0, time.completed - streamed);
    toolsMs += Math.max(0, toolMs - questionWaitMs(message));
  }
  return { generatingMs, toolsMs };
}

// Time a step spent waiting for the user's answer to a question tool.
//
// The question tool runs from its `ran` mark until the answer arrives, which is
// user time rather than tool time.
// A call without a `ran` mark contributes nothing, so its time
// stays in the tool phase.
function questionWaitMs(message: CountableMessage): number {
  return (message.content ?? []).reduce((total, part) => {
    if (part.type !== "tool" || part.name !== QUESTION_TOOL_NAME) {
      return total;
    }
    const started = part.time?.ran;
    const completed = part.time?.completed;
    if (started === undefined || completed === undefined) {
      return total;
    }
    return total + Math.max(0, completed - started);
  }, 0);
}

// Kinds of content the tooltip reports, in display order.
const CONTENT_KINDS: readonly ContentKind[] = [
  "user",
  "assistant",
  "tools",
  "system",
  "switches",
  "idle",
];

// Count the content still in the model's context by kind.
//
// Text is measured from message text, assistant text and reasoning, and tool
// inputs and results; the system prompt and tool schemas never appear in the
// transcript, so they are not measured.
function countContent(
  messages: readonly CountableMessage[],
  skippedToolIds: ReadonlySet<string>,
): ContentFacts {
  const tallies = new Map<ContentKind, ContentTally>();

  // The tally for one kind, created on first use.
  const tallyOf = (kind: ContentKind): ContentTally => {
    const existing = tallies.get(kind);
    if (existing !== undefined) {
      return existing;
    }
    const tally: ContentTally = { entries: 0, words: 0, characters: 0 };
    tallies.set(kind, tally);
    return tally;
  };

  // Add text to a bucket without counting another entry.
  const addText = (kind: ContentKind, text: string): void => {
    const tally = tallyOf(kind);
    tally.words += countWords(text);
    tally.characters += text.length;
  };

  // Count one message, tool call, or bookkeeping entry and its text.
  const addEntry = (kind: ContentKind, text: string): void => {
    const tally = tallyOf(kind);
    tally.entries += 1;
    tally.words += countWords(text);
    tally.characters += text.length;
  };

  for (const message of messages) {
    if (message.type === "user") {
      addEntry("user", message.text ?? "");
      continue;
    }
    if (message.type === "synthetic" || message.type === "system") {
      addEntry("system", message.text ?? "");
      continue;
    }
    if (message.type === "agent-switched") {
      addEntry("switches", "");
      continue;
    }
    if (message.type === "idle") {
      addEntry("idle", "");
      continue;
    }
    if (message.type === "shell" || message.type === "skill") {
      addEntry("tools", message.text ?? "");
      continue;
    }
    if (message.type !== "assistant") {
      continue;
    }

    // A step still streaming has no provider report yet, so its text would grow
    // the denominator under the token counts while those stay at the last
    // completed step, shrinking every other bucket's share as it streams.
    // Leave it out until the step settles: the whole section
    // then updates at once.
    if (message.time !== undefined && message.time.completed === undefined) {
      continue;
    }

    // One assistant message is one step; its text and reasoning are content,
    // while its tool parts belong to the tools bucket.
    addEntry("assistant", "");
    for (const part of message.content ?? []) {
      if (part.type === "text" || part.type === "reasoning") {
        addText("assistant", part.text ?? "");
        continue;
      }
      if (part.type !== "tool") {
        continue;
      }
      if (part.id !== undefined && skippedToolIds.has(part.id)) {
        continue;
      }
      addEntry("tools", toolContentText(part));
    }
  }

  // OpenCode assembles the agent's system prompt per request and never stores
  // it as a message; count it as the implicit first system entry so its size is
  // visible instead of leaving the bucket empty.
  return CONTENT_KINDS.flatMap((kind) => {
    const tally = tallies.get(kind);
    return tally === undefined || tally.entries === 0
      ? []
      : [{ kind, ...tally }];
  });
}

// Text a tool call contributes to the context: its input and its result.
function toolContentText(part: CountablePart): string {
  const input = part.state?.input;
  const serializedInput =
    input === undefined ? "" : (JSON.stringify(input) ?? "");
  const resultText = (part.state?.content ?? [])
    .map((content) => content.text ?? "")
    .join("");
  return [serializedInput, resultText]
    .filter((text) => text.length > 0)
    .join(" ");
}

// Size of the agent's system prompt, or undefined when no prompt is known.
function promptFacts(systemPrompt: string | undefined): PromptFacts | undefined {
  if (systemPrompt === undefined || systemPrompt.length === 0) {
    return undefined;
  }
  return {
    words: countWords(systemPrompt),
    characters: systemPrompt.length,
  };
}

// Words in a piece of text, or none when it has no non-whitespace run.
function countWords(text: string): number {
  const words = text.match(/\S+/gu);
  return words === null ? 0 : words.length;
}

// What the latest user turn did, or undefined when no user turn has run.
//
// The turn starts at the last user message still in context; its duration runs
// to the last completed assistant step, and its token counts come from the
// steps' provider reports.
function countLastTurn(
  messages: readonly CountableMessage[],
): LastTurn | undefined {
  let userIndex = -1;
  for (let index = messages.length - 1; index >= 0; index -= 1) {
    if (messages[index]?.type === "user") {
      userIndex = index;
      break;
    }
  }
  if (userIndex === -1) {
    return undefined;
  }

  const user = messages[userIndex];
  const turn = messages.slice(userIndex);
  let steps = 0;
  let costUsd = 0;
  let outputTokens = 0;
  let reasoningTokens = 0;
  let generatingMs = 0;
  let lastCompleted: number | undefined;

  for (const message of turn) {
    if (message.type !== "assistant") {
      continue;
    }
    steps += 1;
    costUsd += message.cost ?? 0;
    const time = message.time;
    if (time?.completed !== undefined) {
      lastCompleted = Math.max(lastCompleted ?? 0, time.completed);
      const streamed = time.streamed ?? time.completed;
      generatingMs += Math.max(0, streamed - time.created);
    }
    const tokens = message.tokens;
    if (tokens !== undefined) {
      outputTokens += tokens.output;
      reasoningTokens += tokens.reasoning;
    }
  }

  if (steps === 0) {
    return undefined;
  }

  const started = user?.time?.created;
  const durationMs =
    started === undefined || lastCompleted === undefined
      ? undefined
      : Math.max(0, lastCompleted - started);
  return {
    durationMs,
    startedAt: started,
    steps,
    costUsd,
    outputTokens,
    reasoningTokens,
    generatingMs,
  };
}

// Count turns and tool usage in one set of messages.
// Tool parts whose id is in `skippedToolIds` are left out.
function countGroup(
  messages: readonly CountableMessage[],
  skippedToolIds: ReadonlySet<string>,
): StatsGroup {
  const toolUsage = new Map<string, number>();
  const skillUsage = new Map<string, number>();
  const readPaths = new Set<string>();
  let userMessages = 0;
  let assistantMessages = 0;
  let toolCalls = 0;
  let failures = 0;
  let skills = 0;
  let reads = 0;

  // Tool usage is tallied as it is found, so the group needs one pass.
  const recordTool = (name: string): void => {
    toolCalls += 1;
    toolUsage.set(name, (toolUsage.get(name) ?? 0) + 1);
  };

  // A skill load named by its call; loads without a name only raise the total.
  const recordSkill = (name: string | undefined): void => {
    if (name === undefined) {
      return;
    }
    skillUsage.set(name, (skillUsage.get(name) ?? 0) + 1);
  };

  for (const message of messages) {
    if (message.type === "user") {
      userMessages += 1;
      continue;
    }
    if (message.type === "assistant") {
      assistantMessages += 1;
    }
    if (message.type === "skill") {
      skills += 1;
      recordTool(SKILL_TOOL_NAME);
      recordSkill(message.name);
      continue;
    }
    if (message.type === "shell") {
      recordTool(SHELL_TOOL_NAME);
      continue;
    }

    for (const part of message.content ?? []) {
      if (part.type !== "tool") {
        continue;
      }
      if (part.id !== undefined && skippedToolIds.has(part.id)) {
        continue;
      }
      const toolName = part.name ?? "unknown";
      recordTool(toolName);
      if (toolName === SKILL_TOOL_NAME) {
        skills += 1;
        recordSkill(skillNameOf(part));
      }
      if (part.state?.status === "error") {
        failures += 1;
      }
      if (toolName === READ_TOOL_NAME) {
        reads += 1;
        const readPath = readPathOf(part);
        if (readPath !== undefined) {
          readPaths.add(readPath);
        }
      }
    }
  }

  return {
    userMessages,
    assistantMessages,
    toolCalls,
    toolUsage,
    failures,
    skills,
    skillUsage,
    reads,
    uniqueReads: readPaths.size,
  };
}

// The `path` input of a read tool call, when the call recorded one.
function readPathOf(part: CountablePart): string | undefined {
  const input = part.state?.input;
  if (typeof input !== "object" || input === null) {
    return undefined;
  }
  const path = (input as { readonly path?: unknown }).path;
  return typeof path === "string" ? path : undefined;
}

// The `id` input of a skill load call, which names the skill.
function skillNameOf(part: CountablePart): string | undefined {
  const input = part.state?.input;
  if (typeof input !== "object" || input === null) {
    return undefined;
  }
  const id = (input as { readonly id?: unknown }).id;
  return typeof id === "string" ? id : undefined;
}
