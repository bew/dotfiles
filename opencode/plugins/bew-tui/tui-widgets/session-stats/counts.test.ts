// Tests for the session-stats counting helpers.

import { describe, expect, test } from "bun:test";
import { countInsights } from "./counts";
import type { CountableMessage } from "./counts";
import type { CompressedIds } from "./dcp-state";
import { NO_DCP_SUMMARY } from "./dcp-state";

// Build a message with the default id and type, overridden per case.
function makeMessage(
  overrides: Partial<CountableMessage> & { readonly type: string },
): CountableMessage {
  return { id: "msg_default", ...overrides };
}

// Build a compressed-id set from message and tool ids.
function makeCompressed(
  messageIds: readonly string[],
  toolIds: readonly string[],
): CompressedIds {
  return { messageIds: new Set(messageIds), toolIds: new Set(toolIds) };
}

describe("countInsights", () => {
  test("splits each step's working time into streaming and tool waits", () => {
    const messages: CountableMessage[] = [
      makeMessage({
        id: "a1",
        type: "assistant",
        time: { created: 1_000, streamed: 4_000, completed: 6_000 },
      }),
      makeMessage({
        id: "a2",
        type: "assistant",
        time: { created: 10_000, streamed: 10_500, completed: 11_000 },
      }),
    ];

    expect(countInsights(messages, NO_DCP_SUMMARY.compressed).timing).toEqual({
      generatingMs: 3_500,
      toolsMs: 2_500,
    });
  });

  test("keeps the wait for a question answer out of tool time", () => {
    const messages: CountableMessage[] = [
      makeMessage({
        id: "a1",
        type: "assistant",
        time: { created: 1_000, streamed: 2_000, completed: 12_000 },
        content: [
          {
            id: "call_1",
            type: "tool",
            name: "question",
            time: { ran: 2_500, completed: 11_000 },
          },
        ],
      }),
    ];

    expect(countInsights(messages, NO_DCP_SUMMARY.compressed).timing).toEqual({
      generatingMs: 1_000,
      toolsMs: 1_500,
    });
  });

  test("leaves a step that has not finished out of the working time", () => {
    const messages: CountableMessage[] = [
      makeMessage({ id: "a1", type: "assistant", time: { created: 1_000 } }),
    ];

    expect(countInsights(messages, NO_DCP_SUMMARY.compressed).timing).toEqual({
      generatingMs: 0,
      toolsMs: 0,
    });
  });

  test("counts only user and assistant turns as messages", () => {
    const messages: CountableMessage[] = [
      makeMessage({ id: "u1", type: "user" }),
      makeMessage({ id: "a1", type: "assistant" }),
      makeMessage({ id: "s1", type: "system" }),
      makeMessage({ id: "syn1", type: "synthetic" }),
      makeMessage({ id: "sw1", type: "agent-switched" }),
      makeMessage({ id: "idle1", type: "idle" }),
    ];

    const insights = countInsights(messages, NO_DCP_SUMMARY.compressed);

    expect(insights.session.userMessages).toBe(1);
    expect(insights.session.assistantMessages).toBe(1);
    expect(insights.context.userMessages).toBe(1);
    expect(insights.context.assistantMessages).toBe(1);
  });

  test("counts assistant tool parts as tools", () => {
    const messages: CountableMessage[] = [
      makeMessage({
        id: "a1",
        type: "assistant",
        content: [
          { id: "call_1", type: "text" },
          { id: "call_2", type: "tool", name: "read" },
          { id: "call_3", type: "tool", name: "edit" },
        ],
      }),
    ];

    const insights = countInsights(messages, NO_DCP_SUMMARY.compressed);

    expect(insights.session.assistantMessages).toBe(1);
    expect(insights.session.toolCalls).toBe(2);
  });

  test("tallies tool usage per tool name", () => {
    const messages: CountableMessage[] = [
      makeMessage({
        id: "a1",
        type: "assistant",
        content: [
          { id: "call_1", type: "tool", name: "read" },
          { id: "call_2", type: "tool", name: "read" },
          { id: "call_3", type: "tool", name: "bash" },
        ],
      }),
    ];

    const insights = countInsights(messages, NO_DCP_SUMMARY.compressed);

    expect(insights.session.toolUsage.get("read")).toBe(2);
    expect(insights.session.toolUsage.get("bash")).toBe(1);
  });

  test("counts shell and skill messages as tools, not messages", () => {
    const messages: CountableMessage[] = [
      makeMessage({ id: "sh1", type: "shell" }),
      makeMessage({ id: "sk1", type: "skill", name: "coder-ts" }),
    ];

    const insights = countInsights(messages, NO_DCP_SUMMARY.compressed);

    expect(insights.session.userMessages).toBe(0);
    expect(insights.session.assistantMessages).toBe(0);
    expect(insights.session.toolCalls).toBe(2);
    expect(insights.session.skills).toBe(1);
    expect(insights.session.toolUsage.get("shell")).toBe(1);
    expect(insights.session.toolUsage.get("skill")).toBe(1);
    expect(insights.session.skillUsage.get("coder-ts")).toBe(1);
  });

  test("counts skill tool parts as skill loads", () => {
    const messages: CountableMessage[] = [
      makeMessage({
        id: "a1",
        type: "assistant",
        content: [
          {
            id: "call_1",
            type: "tool",
            name: "skill",
            state: { status: "completed", input: { id: "coder-ts" } },
          },
          {
            id: "call_2",
            type: "tool",
            name: "skill",
            state: { status: "completed", input: { id: "coder-ts" } },
          },
          {
            id: "call_3",
            type: "tool",
            name: "skill",
            state: { status: "completed", input: { id: "coder-lua" } },
          },
          { id: "call_4", type: "tool", name: "read" },
        ],
      }),
    ];

    const insights = countInsights(messages, NO_DCP_SUMMARY.compressed);

    expect(insights.session.skills).toBe(3);
    expect(insights.session.toolUsage.get("skill")).toBe(3);
    expect(insights.session.skillUsage.get("coder-ts")).toBe(2);
    expect(insights.session.skillUsage.get("coder-lua")).toBe(1);
  });

  test("counts a named skill load once per distinct name", () => {
    const messages: CountableMessage[] = [
      makeMessage({
        id: "a1",
        type: "assistant",
        content: [
          {
            id: "call_1",
            type: "tool",
            name: "skill",
            state: { status: "completed", input: { id: "opencode" } },
          },
          {
            id: "call_2",
            type: "tool",
            name: "skill",
            state: { status: "completed", input: {} },
          },
        ],
      }),
    ];

    const insights = countInsights(messages, NO_DCP_SUMMARY.compressed);

    expect(insights.session.skills).toBe(2);
    expect([...insights.session.skillUsage.keys()]).toEqual(["opencode"]);
  });

  test("drops compressed skill tool parts from the context count", () => {
    const messages: CountableMessage[] = [
      makeMessage({
        id: "a1",
        type: "assistant",
        content: [{ id: "call_1", type: "tool", name: "skill" }],
      }),
    ];

    const insights = countInsights(messages, makeCompressed([], ["call_1"]));

    expect(insights.session.skills).toBe(1);
    expect(insights.context.skills).toBe(0);
  });

  test("counts failed tool calls", () => {
    const messages: CountableMessage[] = [
      makeMessage({
        id: "a1",
        type: "assistant",
        content: [
          { id: "call_1", type: "tool", name: "read", state: { status: "error" } },
          {
            id: "call_2",
            type: "tool",
            name: "read",
            state: { status: "completed" },
          },
        ],
      }),
    ];

    const insights = countInsights(messages, NO_DCP_SUMMARY.compressed);

    expect(insights.session.failures).toBe(1);
  });

  test("counts reads and distinct read paths", () => {
    const messages: CountableMessage[] = [
      makeMessage({
        id: "a1",
        type: "assistant",
        content: [
          {
            id: "call_1",
            type: "tool",
            name: "read",
            state: { status: "completed", input: { path: "/a.ts" } },
          },
          {
            id: "call_2",
            type: "tool",
            name: "read",
            state: { status: "completed", input: { path: "/a.ts" } },
          },
          {
            id: "call_3",
            type: "tool",
            name: "read",
            state: { status: "completed", input: { path: "/b.ts" } },
          },
          {
            id: "call_4",
            type: "tool",
            name: "edit",
            state: { status: "completed", input: { path: "/c.ts" } },
          },
        ],
      }),
    ];

    const insights = countInsights(messages, NO_DCP_SUMMARY.compressed);

    expect(insights.session.reads).toBe(3);
    expect(insights.session.uniqueReads).toBe(2);
  });

  test("drops compressed messages from the context count only", () => {
    const messages: CountableMessage[] = [
      makeMessage({ id: "u1", type: "user" }),
      makeMessage({ id: "a1", type: "assistant" }),
    ];

    const insights = countInsights(messages, makeCompressed(["u1"], []));

    expect(insights.session.userMessages).toBe(1);
    expect(insights.session.assistantMessages).toBe(1);
    expect(insights.context.userMessages).toBe(0);
    expect(insights.context.assistantMessages).toBe(1);
  });

  test("drops compressed tool parts from the context count only", () => {
    const messages: CountableMessage[] = [
      makeMessage({
        id: "a1",
        type: "assistant",
        content: [
          { id: "call_1", type: "tool", name: "read" },
          { id: "call_2", type: "tool", name: "read" },
        ],
      }),
    ];

    const insights = countInsights(messages, makeCompressed([], ["call_1"]));

    expect(insights.session.toolCalls).toBe(2);
    expect(insights.context.toolCalls).toBe(1);
    expect(insights.session.toolUsage.get("read")).toBe(2);
    expect(insights.context.toolUsage.get("read")).toBe(1);
  });

  test("counts a compressed shell message out of the context tools", () => {
    const messages: CountableMessage[] = [
      makeMessage({ id: "sh1", type: "shell" }),
    ];

    const insights = countInsights(messages, makeCompressed(["sh1"], []));

    expect(insights.session.toolCalls).toBe(1);
    expect(insights.context.toolCalls).toBe(0);
  });

  test("equals the session counts when nothing is compressed", () => {
    const messages: CountableMessage[] = [
      makeMessage({ id: "u1", type: "user" }),
      makeMessage({
        id: "a1",
        type: "assistant",
        content: [{ id: "call_1", type: "tool", name: "read" }],
      }),
    ];

    const insights = countInsights(messages, NO_DCP_SUMMARY.compressed);

    expect(insights.context.userMessages).toBe(
      insights.session.userMessages,
    );
    expect(insights.context.assistantMessages).toBe(
      insights.session.assistantMessages,
    );
    expect(insights.context.toolCalls).toBe(insights.session.toolCalls);
  });
});
