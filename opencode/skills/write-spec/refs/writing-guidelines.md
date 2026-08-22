# Writing guidelines

## Prose style

- One sentence per line.
  Long sentences may wrap, but next sentence always starts on a new line.
- Keep sentences direct and relatively short — prefer clarity over verbosity.
- Introduction: full prose, no compression.
- Terminology & Key Concepts (if present): follows general prose rules above.
  Should read well — bullets and concise phrasing are allowed but not the default.
- Other sections: terse, imperative, concrete.
- Use `NOTE:` / `FIXME:` / `WARNING:` for callouts.

Bad:
```text
This is a sentence. This is another sentence
that wraps and continues here.
```

Good:
```text
This is a sentence.
This is another sentence that wraps and continues here.
```

## Naming discipline

- Define canonical name for each concept.
  If Terminology & Key Concepts section exists, define names there.
- Use that exact name everywhere — in prose, code comments, section headings.
- If concept has short internal form (e.g. `P` for provider inside impl), define at first use.
- Never use synonyms: pick one word and hold it.

## API sections

- Show most complete realistic example, not a toy.
- Preserve honest comments (`-- FIXME`, `-- NOTE`) — they are design signals, not noise.
- If API has multiple forms (named / anonymous, shorthand / full), show all.
- If a field has a type annotation, show both simple and more-defined type variants if relevant.