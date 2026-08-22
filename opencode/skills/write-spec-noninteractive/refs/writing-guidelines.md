# Writing guidelines

## Prose style

- One sentence per line.
  Long sentences may wrap, but next sentence always starts on a new line.
- Introduction: full prose, no compression.
- Terminology section (if present): full prose, no compression.
- Other sections: terse, imperative, concrete.
- Use `NOTE:` / `FIXME:` / `WARNING:` for callouts.

Bad:
```md
This is a sentence. This is another sentence
that wraps and continues here.
```

Good:
```md
This is a sentence.
This is another sentence that wraps and continues here.
```

## API sections

- Show most complete realistic example, not a toy.
- Preserve honest comments (`-- FIXME`, `-- NOTE`) — they are design signals.
- If API has multiple forms (named / anonymous, shorthand / full), show all.

## Naming discipline

- Define canonical name for each concept.
  If Terminology section exists, define names there.
- Use that exact name everywhere — in prose, code comments, section headings.
- Never use synonyms: pick one word and hold it.
