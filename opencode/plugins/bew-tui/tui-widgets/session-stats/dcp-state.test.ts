// Tests for the DCP state helpers.

import { describe, expect, test } from "bun:test";
import { getDcpStateDirectory, parseDcpState } from "./dcp-state";

// A state file with one active and one inactive block.
const STATE_WITH_BLOCKS = JSON.stringify({
  prune: {
    messages: {
      activeBlockIds: [1, 2],
      blocksById: {
        "1": {
          active: true,
          topic: "first block",
          compressedTokens: 12000,
          summaryTokens: 1500,
          createdAt: 200,
          effectiveMessageIds: ["msg_a", "msg_b"],
          effectiveToolIds: ["call_a"],
        },
        "2": {
          active: false,
          effectiveMessageIds: ["msg_c"],
          effectiveToolIds: ["call_b"],
        },
      },
    },
  },
  stats: { totalPruneTokens: 18000 },
});

describe("parseDcpState", () => {
  test("collects the ids of active blocks only", () => {
    const summary = parseDcpState(STATE_WITH_BLOCKS);

    expect(summary).toBeDefined();
    expect([...(summary?.compressed.messageIds ?? [])]).toEqual([
      "msg_a",
      "msg_b",
    ]);
    expect([...(summary?.compressed.toolIds ?? [])]).toEqual(["call_a"]);
  });

  test("reports each active block with its size and topic", () => {
    const summary = parseDcpState(STATE_WITH_BLOCKS);

    expect(summary?.blocks).toEqual([
      {
        id: 1,
        topic: "first block",
        compressedTokens: 12000,
        summaryTokens: 1500,
        messageCount: 2,
        createdAt: 200,
      },
    ]);
  });

  test("reports the session-wide pruned total", () => {
    const summary = parseDcpState(STATE_WITH_BLOCKS);

    expect(summary?.totalPruneTokens).toBe(18000);
  });

  test("orders blocks oldest first", () => {
    const text = JSON.stringify({
      prune: {
        messages: {
          activeBlockIds: [1, 2],
          blocksById: {
            "1": { active: true, createdAt: 500, effectiveMessageIds: ["a"] },
            "2": { active: true, createdAt: 100, effectiveMessageIds: ["b"] },
          },
        },
      },
    });

    const summary = parseDcpState(text);

    expect(summary?.blocks.map((block) => block.id)).toEqual([2, 1]);
  });

  test("yields no compression when the state carries no prune block", () => {
    const summary = parseDcpState(JSON.stringify({ manualMode: false }));

    expect(summary?.compressed.messageIds.size).toBe(0);
    expect(summary?.compressed.toolIds.size).toBe(0);
    expect(summary?.blocks).toEqual([]);
  });

  test("returns undefined for malformed JSON", () => {
    expect(parseDcpState("{not json")).toBeUndefined();
  });

  test("returns undefined for a non-object document", () => {
    expect(parseDcpState("null")).toBeUndefined();
    expect(parseDcpState("42")).toBeUndefined();
  });

  test("ignores an active block id with no block entry", () => {
    const text = JSON.stringify({
      prune: { messages: { activeBlockIds: [7], blocksById: {} } },
    });

    const summary = parseDcpState(text);

    expect(summary?.compressed.messageIds.size).toBe(0);
    expect(summary?.compressed.toolIds.size).toBe(0);
    expect(summary?.blocks).toEqual([]);
  });
});

describe("getDcpStateDirectory", () => {
  test("resolves under the XDG data root", () => {
    const previous = process.env.XDG_DATA_HOME;
    process.env.XDG_DATA_HOME = "/tmp/data";
    try {
      expect(getDcpStateDirectory()).toBe(
        "/tmp/data/opencode/storage/plugin/dcp",
      );
    } finally {
      if (previous === undefined) {
        delete process.env.XDG_DATA_HOME;
      } else {
        process.env.XDG_DATA_HOME = previous;
      }
    }
  });
});
