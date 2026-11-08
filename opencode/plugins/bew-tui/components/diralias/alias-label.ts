// Alias-to-label helpers for the diralias footer component.
//
// Parses the output of diralias's `get` and holds the directory-label glyphs.
// Kept free of OpenCode and OpenTUI types, so it stays unit-testable.

import { homedir } from "node:os";
import { join } from "node:path";

// Folder glyph for a directory outside a repository; Nerd Font `nf-md-folder_open`.
export const FOLDER_GLYPH = "\u{f0645}";
// Repository glyph for a directory inside a repository; Nerd Font `nf-dev-git`.
export const REPO_GLYPH = "\u{e702}";

// A directory resolved to a diralias alias: the alias name, plus the path
// remainder relative to the alias target for a prefix match.
export type AliasMatch = {
  readonly alias: string;
  readonly remainder?: string;
};

// Absolute path of diralias's state directory, resolved the way diralias does.
export function getDiraliasStateDirectory(): string {
  const stateRoot =
    process.env.XDG_STATE_HOME ?? join(homedir(), ".local", "state");
  return join(stateRoot, "diralias");
}

// Parse the output of `diralias get` into a match.
// An exact match prints only the alias name; a prefix match prints the alias and
// the remainder separated by a space; empty output yields no match.
export function parseAliasGet(output: string): AliasMatch | undefined {
  const line = output.trim();
  if (line === "") {
    return undefined;
  }

  const separatorIndex = line.indexOf(" ");
  if (separatorIndex === -1) {
    return { alias: line };
  }

  return {
    alias: line.slice(0, separatorIndex),
    remainder: line.slice(separatorIndex + 1),
  };
}

// Render a match as a tilde path: `~alias`, or `~alias/remainder` when the
// directory sits under the alias target.
export function formatAliasPath(match: AliasMatch): string {
  const hasRemainder = match.remainder !== undefined && match.remainder !== "";
  return hasRemainder ? `~${match.alias}/${match.remainder}` : `~${match.alias}`;
}
