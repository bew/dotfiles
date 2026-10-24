# Work Capture Doc Template

The capture doc must contain the following sections in order.
Omit any optional section that has no qualifying content — do not keep an
empty heading or write filler (e.g. "none", "N/A", "nothing to report").

The doc opens with this block, above the H1:
```md
---
created-at: <YYYYMMDDThhmm>
---
```

Add `depends-on` directly after `created-at`, only when the capture has explicit dependencies:
one `<kind>:<slug>` per dependency, joined with ` & `.
Omit the key otherwise.

# <title>

H1 heading — one line stating the intent.

<description: what to do, or what the idea is, plus why.
May state what in the session triggered it, as provenance.
Keep it to a short paragraph.>

## Blockers

Optional — include only when the item has blockers or prerequisites.
Flat bullets, one line each: what must happen first, and why.

## Open questions

Optional — include only when the item has open sub-questions left to resolve.
Flat bullets, one line each: the question, and what it affects.

## Artefacts

Optional — include only when related to the item.
Bullets: `<path|URL>` — one line on why it matters.
