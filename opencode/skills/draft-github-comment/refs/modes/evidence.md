# Mode: evidence

Adds repro, version, logs, or a second data point to someone else's report.

## Shape

1. One line: you hit the same thing, on what (version, platform, client).
2. Minimal repro — numbered steps, nothing extraneous.
3. Shortest diagnostic showing the failure: the error line, log excerpt, or trace.
4. What you ruled out, if anything.

## Rules

- Version and platform on the first line.
- Never invent a version, platform, log line, error text, or the user's own steps and workarounds.
  Ask the user for what is missing.
- Numbered steps only where order matters.
- Trim logs to the failing lines. Never paste a whole session.
- Mark each diagnostic as observed or inferred.
- No repro, no diagnosis: report what happened, not what it must be.
