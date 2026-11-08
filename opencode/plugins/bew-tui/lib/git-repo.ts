// Git-repository location helpers for the directory path label.
//
// Parses `git rev-parse --show-toplevel --show-prefix` into the repository root
// and the directory's path within it.
// Kept free of OpenCode and OpenTUI types, so it stays unit-testable.

// A directory resolved to its repository: the absolute repository root, and the
// directory's path within it (empty at the root, no leading or trailing slash).
export type RepoLocation = {
  readonly root: string;
  readonly suffix: string;
};

// Parse the two-line output of `git rev-parse --show-toplevel --show-prefix`.
// Empty output (outside a repository) yields no location.
export function parseRepoLocation(output: string): RepoLocation | undefined {
  const lines = output.split("\n");
  const root = (lines[0] ?? "").trim();
  if (root === "") {
    return undefined;
  }

  // `--show-prefix` prints a trailing slash, and a bare newline at the root.
  const prefix = (lines[1] ?? "").trim();
  const suffix = prefix.endsWith("/") ? prefix.slice(0, -1) : prefix;

  return { root, suffix };
}
