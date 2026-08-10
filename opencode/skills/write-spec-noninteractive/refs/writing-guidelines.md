# Writing guidelines

## Prose style

- One sentence per line.
  Long sentences may wrap, but next sentence always starts on a new line.
- Introduction and Terminology: full prose, no compression.
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

## Terminology entries

- `**Some New Thing** (new!): The definition…`
- `**Some Updated Thing** (updated!):` The revised definition — state what changed, or mark `(replaced!)` if fully superseded.
- Well-known terms: no need to re-define; one-line note or omit entirely.

A term may define a short name (e.g. `ExtPoint` for `Extension Point`).
Short names reduce token count and avoid horizontal overflow.
If a short name is defined, use it consistently throughout — never alternate with the full name.

## API sections

- Show most complete realistic example, not a toy.
- Preserve honest comments (`-- FIXME`, `-- NOTE`) — they are design signals.
- If API has multiple forms (named / anonymous, shorthand / full), show all.

## Naming discipline

- Define canonical name for each concept in Terminology.
- Use that exact name everywhere — in prose, code comments, section headings.
- Never use synonyms: pick one word and hold it.
