// Adaptive git-status poller for the git-branch label.
//
// Owns the timer that re-runs the label's `git status`, its backoff policy, and
// the activity signals that hold the interval at the floor while the app is
// busy.
// Free of OpenCode, OpenTUI, and Solid types: the caller injects the activity
// stream, the running-session predicate, and the clock, and the scheduling math
// stays unit-testable.

// Poll floor: the interval while a session runs or recent activity is seen.
export const GIT_POLL_MIN_MS = 3000;
// Poll ceiling: the interval once nothing has changed for a while.
export const GIT_POLL_MAX_MS = 180_000;
// How long one activity event keeps the poll at the floor.
export const GIT_ACTIVITY_WINDOW_MS = 15_000;

// Setup for a watcher: how it asks for a re-run, observes activity, and sees
// whether a session in the directory is running.
export type GitWatcherOptions = {
  // Request a re-run of the label's git status.
  readonly onTick: () => void;
  // Subscribe to a stream of activity events; returns the unsubscribe.
  readonly subscribeActivity: (onActivity: () => void) => () => void;
  // Whether any session in `directory` is running.
  readonly hasRunningSession: (directory: string) => boolean;
  // Current time in milliseconds; injectable for tests.
  readonly now?: () => number;
};

// The running poller.
export type GitWatcher = {
  // Point the poller at the labelled directory; resets the backoff.
  readonly setDirectory: (directory: string | undefined) => void;
  // Report the signature of the status a re-run for `directory` resolved.
  readonly reportStatus: (directory: string, signature: string) => void;
  readonly dispose: () => void;
};

// Next interval after a re-run: the floor while active, the floor again after a
// change, otherwise double up to the ceiling.
export function nextPollInterval(
  previous: number,
  changed: boolean,
  active: boolean,
): number {
  if (active || changed) {
    return GIT_POLL_MIN_MS;
  }
  return Math.min(previous * 2, GIT_POLL_MAX_MS);
}

// Build the poller. It re-runs only while a directory is set.
export function createGitWatcher(options: GitWatcherOptions): GitWatcher {
  const now = options.now ?? Date.now;
  let directory: string | undefined;
  let interval = GIT_POLL_MIN_MS;
  let lastSignature: string | undefined;
  let lastActivityAt = 0;
  let timer: ReturnType<typeof setTimeout> | undefined;
  let pendingDelay = 0;

  // Active when a session in the directory runs, or an event arrived inside the
  // activity window.
  const isActive = (): boolean =>
    now() - lastActivityAt < GIT_ACTIVITY_WINDOW_MS ||
    (directory !== undefined && options.hasRunningSession(directory));

  function schedule(): void {
    if (timer !== undefined) {
      clearTimeout(timer);
      timer = undefined;
    }
    if (directory === undefined) {
      pendingDelay = 0;
      return;
    }
    const active = isActive();
    if (active) {
      interval = GIT_POLL_MIN_MS;
    }
    pendingDelay = active ? GIT_POLL_MIN_MS : interval;
    timer = setTimeout(() => {
      timer = undefined;
      pendingDelay = 0;
      options.onTick();
      schedule();
    }, pendingDelay);
  }

  const stopActivity = options.subscribeActivity(() => {
    lastActivityAt = now();
    // Pull the timer in only when it is currently slower than the floor, so a
    // steady event stream cannot starve the poll.
    if (timer !== undefined && pendingDelay > GIT_POLL_MIN_MS) {
      schedule();
    }
  });

  return {
    setDirectory(next) {
      if (next === directory) {
        return;
      }
      directory = next;
      lastSignature = undefined;
      interval = GIT_POLL_MIN_MS;
      schedule();
    },
    reportStatus(reportedDirectory, signature) {
      if (reportedDirectory !== directory) {
        return;
      }
      const changed = signature !== lastSignature;
      lastSignature = signature;
      interval = nextPollInterval(interval, changed, isActive());
      schedule();
    },
    dispose() {
      if (timer !== undefined) {
        clearTimeout(timer);
        timer = undefined;
      }
      stopActivity();
    },
  };
}
