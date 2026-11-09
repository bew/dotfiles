// DCP state helpers for the session-stats component.
//
// Resolves and parses the per-session state file that DCP
// (opencode-dynamic-context-pruning) writes, extracting the message and tool
// ids it currently holds compressed — the ids the model no longer sees as
// original content — plus the compression blocks those ids belong to.
// Kept free of OpenCode and OpenTUI types, so it stays unit-testable.

import { readFileSync, statSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

// Message and tool ids DCP currently hides from the model's context.
export type CompressedIds = {
  readonly messageIds: ReadonlySet<string>;
  readonly toolIds: ReadonlySet<string>;
};

// One active DCP compression block.
export type DcpBlock = {
  // Block number DCP assigned.
  readonly id: number;
  // Topic DCP recorded for the block, empty when it recorded none.
  readonly topic: string;
  // Tokens the block replaced with its summary.
  readonly compressedTokens: number;
  // Tokens the block's summary costs.
  readonly summaryTokens: number;
  // Messages the block currently covers.
  readonly messageCount: number;
  // Creation time in milliseconds since the epoch, zero when missing.
  readonly createdAt: number;
};

// Everything the component reads out of DCP's state file.
export type DcpSummary = {
  // Ids the active blocks hide from the model.
  readonly compressed: CompressedIds;
  // Active blocks, oldest first.
  readonly blocks: readonly DcpBlock[];
  // Tokens DCP has pruned over the whole session.
  readonly totalPruneTokens: number;
};

// No compression at all, used before a session has one and when DCP's state
// file is missing or unreadable.
export const NO_DCP_SUMMARY: DcpSummary = {
  compressed: { messageIds: new Set(), toolIds: new Set() },
  blocks: [],
  totalPruneTokens: 0,
};

// Wire shape of one DCP compression block, limited to the fields read here.
type DcpCompressionBlock = {
  readonly active?: boolean;
  readonly topic?: string;
  readonly compressedTokens?: number;
  readonly summaryTokens?: number;
  readonly createdAt?: number;
  readonly effectiveMessageIds?: readonly string[];
  readonly effectiveToolIds?: readonly string[];
};

// Wire shape of the DCP state file, limited to the fields read here.
type DcpStateFile = {
  readonly prune?: {
    readonly messages?: {
      readonly activeBlockIds?: readonly number[];
      readonly blocksById?: Readonly<Record<string, DcpCompressionBlock>>;
    };
  };
  readonly stats?: {
    readonly totalPruneTokens?: number;
  };
};

// A parsed state file and the modification time it was parsed at.
type CacheEntry = {
  readonly mtimeMs: number;
  readonly summary: DcpSummary;
};

// Parsed state per session, keyed by the file's modification time so an
// unchanged file is never parsed twice.
const cache = new Map<string, CacheEntry>();

// Absolute path of DCP's state directory, resolved under OpenCode's data root.
export function getDcpStateDirectory(): string {
  const dataRoot =
    process.env.XDG_DATA_HOME ?? join(homedir(), ".local", "share");
  return join(dataRoot, "opencode", "storage", "plugin", "dcp");
}

// Read a session's compression summary from DCP's state file.
// A missing or unreadable file yields no compression.
export function readDcpSummary(sessionID: string): DcpSummary {
  const statePath = join(getDcpStateDirectory(), `${sessionID}.json`);

  let mtimeMs: number;
  try {
    mtimeMs = statSync(statePath).mtimeMs;
  } catch {
    cache.delete(sessionID);
    return NO_DCP_SUMMARY;
  }

  const cached = cache.get(sessionID);
  if (cached !== undefined && cached.mtimeMs === mtimeMs) {
    return cached.summary;
  }

  let text: string;
  try {
    text = readFileSync(statePath, "utf8");
  } catch {
    return NO_DCP_SUMMARY;
  }

  const summary = parseDcpState(text) ?? NO_DCP_SUMMARY;
  cache.set(sessionID, { mtimeMs, summary });
  return summary;
}

// Parse a DCP state file into the compression it currently applies.
// Returns undefined when the text is not a DCP state object; a state object
// without compression fields yields no compression.
export function parseDcpState(text: string): DcpSummary | undefined {
  let parsed: unknown;
  try {
    parsed = JSON.parse(text);
  } catch {
    return undefined;
  }

  if (typeof parsed !== "object" || parsed === null) {
    return undefined;
  }

  const state = parsed as DcpStateFile;
  const pruneMessages = state.prune?.messages;
  if (pruneMessages === undefined) {
    return NO_DCP_SUMMARY;
  }

  const blocksById = pruneMessages.blocksById ?? {};
  const messageIds = new Set<string>();
  const toolIds = new Set<string>();
  const blocks: DcpBlock[] = [];

  // Only active blocks count: they are the ones hiding content from the model.
  for (const blockId of pruneMessages.activeBlockIds ?? []) {
    const block = blocksById[String(blockId)];
    if (block === undefined || block.active === false) {
      continue;
    }
    for (const id of block.effectiveMessageIds ?? []) {
      messageIds.add(id);
    }
    for (const id of block.effectiveToolIds ?? []) {
      toolIds.add(id);
    }
    blocks.push({
      id: blockId,
      topic: block.topic ?? "",
      compressedTokens: block.compressedTokens ?? 0,
      summaryTokens: block.summaryTokens ?? 0,
      messageCount: block.effectiveMessageIds?.length ?? 0,
      createdAt: block.createdAt ?? 0,
    });
  }

  blocks.sort((left, right) => left.createdAt - right.createdAt);

  return {
    compressed: { messageIds, toolIds },
    blocks,
    totalPruneTokens: state.stats?.totalPruneTokens ?? 0,
  };
}
