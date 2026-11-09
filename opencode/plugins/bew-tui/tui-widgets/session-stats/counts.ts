// Session stats counting helpers for the session-stats component.
//
// Counts conversation messages and tool usage for a whole session and for the
// part still in model context, given the message and tool ids DCP has
// compressed away.
// Kept free of OpenCode and OpenTUI types, so it stays unit-testable.

import type { CompressedIds } from "./dcp-state";

// A session message, narrowed to the fields the counters read.
// The host's SessionMessageInfo satisfies this shape structurally.
export type CountableMessage = {
  readonly id: string;
  readonly type: string;
  readonly content?: readonly CountablePart[];
  // Name of the skill a `skill` message loaded.
  readonly name?: string;
  // Wall-clock marks of an assistant step, used for the working-time split.
  readonly time?: {
    readonly created: number;
    readonly streamed?: number;
    readonly completed?: number;
  };
};

// One part of an assistant message, narrowed to the fields the counters read.
export type CountablePart = {
  readonly id: string;
  readonly type: string;
  // Tool name.
  readonly name?: string;
  // Tool call state; only its status and input are read.
  readonly state?: {
    readonly status?: string;
    readonly input?: unknown;
  };
  // Wall-clock marks of a tool call, used to keep a user wait out of tool time.
  readonly time?: {
    readonly created?: number;
    readonly ran?: number;
    readonly completed?: number;
  };
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

// Counts for the whole session and for its active context.
export type SessionStats = {
  // Counts for the whole session.
  readonly session: StatsGroup;
  // Counts for the part still visible to the model.
  readonly context: StatsGroup;
  // Working time for the whole session.
  readonly timing: SessionTiming;
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

// Count conversation turns and tool usage for a session and for its active
// context.
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
): SessionStats {
  const contextMessages = messages.filter(
    (message) => !compressed.messageIds.has(message.id),
  );

  return {
    session: countGroup(messages, NO_SKIPPED_TOOL_IDS),
    context: countGroup(contextMessages, compressed.toolIds),
    timing: countTiming(messages),
  };
}

// Split the session's working time into streaming and tool waits.
//
// A step streams from `created` until `streamed`, then waits for its tools until
// `completed`, so the two halves do not overlap and together cover the step.
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
// user time rather than tool time. A call without a `ran` mark contributes
// nothing, so its time stays in the tool phase.
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
      if (part.type !== "tool" || skippedToolIds.has(part.id)) {
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
