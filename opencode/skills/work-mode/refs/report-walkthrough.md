# Walkthrough report

Written at the stop of a walkthrough slice, or when showing a slice plan.

Short sentences, one idea each.
Use bullets for anything enumerable.

```md
Slice: **<Slice name>**

<2-4 short sentences, or a short bullet list, explaining that part>

_Connections_:
- <what it takes from another seam, or hands to one>

_Sharp edges_:
- <edge>

Next slice: **<slice>** — <what it covers>.
Say `next` to continue.
```

## Rules

These govern the explanation.
The opening and closing lines follow the template.

- Open with the slice name as a bold line. No preamble, no "now let's look at".
- Explain in short sentences, one fact each. Split rather than chain.
- Use bullets whenever the slice has parts, steps, conditions, or branches.
  One item per bullet.
  Never pack a list into a sentence.
- Name concrete things: files, functions, flags, config keys.
- Explain the content, not the structure.
  Never define a field, a type, a function, or a convention the reader already knows.
  Assume the reader knows the language, the framework, and the surrounding code.
- Stop at what the reader needs for this slice.
  Do not recap the previous one, and do not re-explain the architecture unless explicitly requested.
  Naming another seam as a link is not a recap.
- _Connections_ and _Sharp edges_ are the only extra sections, and each appears only when it
  carries something. One bullet per link or edge.
- The closing line names the next slice and what it covers, in the template's shape.
  On the last slice, it says what the walkthrough did not cover, and drops the continue invitation.
- A slice that yields before it is explained closes by naming the same slice and what is left of
  it, never the following slice.

## Slice plan

Show it before any slice, always.

```md
**Walkthrough slices**
- <seam> — <what it covers>
- <seam> — <what it covers>

Say `next` to start with <first slice>.
```

Rules:
- One line per seam, all of them, in walk order.
- Name the seam, then what the reader gets from it.
- Explain nothing. No sharp edges. The plan is the whole response.

## Connections

Include the section when the link between this seam and another is not obvious from its name:
- it consumes what another seam produces
- it produces what another seam consumes
- it must run before or after another seam

One bullet per link, naming the seam and the direction.

## Sharp edges

Include the section when the slice carries any of these:
- an unverified claim, or behaviour nobody has checked
- something that surprises a reader who knows the surrounding code
- a trap: a fix, ordering, or coupling the reader must respect
- undocumented coupling between this part and another

## Example

Subject: a pull request that adds a `--verbose` flag.
Slices: arg parsing / reporter level threading / tests.
The agent does the first slice.

```md
Slice: **Arg parsing**

`--verbose` is a new boolean in the flag table in `src/args.ts`.

- `parseArgs` maps it to `level: 2`.
- The default stays `level: 0`.
- The same table drives parsing and `--help`, so both stay in step.

_Connections_:
- `level` is only read by the reporter, so the flag shows nothing until threading lands.

_Sharp edges_:
- Levels above 2 are accepted, but the reporter only distinguishes 0 to 2.
- The help text does not mention that limit.

Next slice: **Reporter level threading** — how `level` reaches the reporter, where the number starts changing output.
Say `next` to continue.
```
