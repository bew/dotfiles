// Tests for the git-status poller's scheduling math.

import { describe, expect, test } from "bun:test";
import {
  GIT_POLL_MAX_MS,
  GIT_POLL_MIN_MS,
  nextPollInterval,
} from "./git-watcher";

describe("nextPollInterval", () => {
  test("stays at the floor while active", () => {
    expect(nextPollInterval(GIT_POLL_MAX_MS, false, true)).toBe(
      GIT_POLL_MIN_MS,
    );
  });

  test("resets to the floor after a change", () => {
    expect(nextPollInterval(GIT_POLL_MAX_MS, true, false)).toBe(
      GIT_POLL_MIN_MS,
    );
  });

  test("doubles when quiet and unchanged", () => {
    expect(nextPollInterval(GIT_POLL_MIN_MS, false, false)).toBe(
      GIT_POLL_MIN_MS * 2,
    );
  });

  test("caps at the ceiling", () => {
    expect(nextPollInterval(GIT_POLL_MAX_MS, false, false)).toBe(
      GIT_POLL_MAX_MS,
    );
  });
});
