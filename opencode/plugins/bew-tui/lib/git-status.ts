// Git-status parsing and branch-label formatting for the git-branch label.
//
// Turns the porcelain v2 output of `git status --branch` into the signals the
// footer reflects, and lays out the branch glyph, name, and divergence.
// Kept free of OpenCode and OpenTUI types, so it stays unit-testable.

// Git-branch glyph; Nerd Font `nf-oct-git_branch`.
const BRANCH_GLYPH = "\u{f418}";
// Commit-ahead marker, prefixed to the ahead count.
const AHEAD_GLYPH = "\u{2191}";
// Commit-behind marker, prefixed to the behind count.
const BEHIND_GLYPH = "\u{2193}";

// Porcelain v2 header line carrying the ahead/behind counts, e.g. `# branch.ab +1 -2`.
const BRANCH_AB_PREFIX = "# branch.ab ";
// Prefix of every porcelain v2 header line; any other non-empty line is a
// changed path.
const HEADER_PREFIX = "#";

// Git status of the labelled repository, as the footer reflects it.
export type GitStatus = {
  // Whether the index or working tree has changes, including untracked files.
  readonly dirty: boolean;
  // Commits the branch is ahead of its upstream.
  readonly ahead: number;
  // Commits the branch is behind its upstream.
  readonly behind: number;
};

// The branch label split into the parts the footer colours separately.
export type BranchParts = {
  // The branch glyph.
  readonly glyph: string;
  // The branch name.
  readonly name: string;
  // The ahead marker and count, e.g. `↑1`, or empty when in sync or unknown.
  readonly ahead: string;
  // The behind marker and count, e.g. `↓2`, or empty when in sync or unknown.
  readonly behind: string;
};

// Parse the porcelain v2 output of `git status --branch` into a status.
// A missing upstream leaves both counts at zero; a detached or unborn branch
// still reports working-tree dirtiness.
export function parseGitStatus(output: string): GitStatus {
  let dirty = false;
  let ahead = 0;
  let behind = 0;

  for (const line of output.split("\n")) {
    if (line.startsWith(BRANCH_AB_PREFIX)) {
      // `+<ahead> -<behind>`, each count carrying a leading sign.
      const [aheadToken, behindToken] = line
        .slice(BRANCH_AB_PREFIX.length)
        .split(" ");
      if (aheadToken !== undefined && behindToken !== undefined) {
        ahead = Number(aheadToken.slice(1));
        behind = Number(behindToken.slice(1));
      }
      continue;
    }
    if (line !== "" && !line.startsWith(HEADER_PREFIX)) {
      dirty = true;
    }
  }

  return { dirty, ahead, behind };
}

// Split the branch display into parts the footer colours separately.
// A missing status leaves both divergence parts empty, so a caller renders the
// label alone.
// The parts carry no separator; the footer row gap spaces them.
export function formatBranchParts(
  name: string,
  status: GitStatus | undefined,
): BranchParts {
  const ahead =
    status !== undefined && status.ahead > 0
      ? `${AHEAD_GLYPH}${status.ahead}`
      : "";
  const behind =
    status !== undefined && status.behind > 0
      ? `${BEHIND_GLYPH}${status.behind}`
      : "";
  return { glyph: BRANCH_GLYPH, name, ahead, behind };
}
