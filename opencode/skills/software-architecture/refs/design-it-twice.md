# design it twice

Use when a fork is worth arguing about: a `contract` shape, a data shape, a module split.
Not for a choice with one workable answer.

## Steps

1. **Frame the constraints**
   State what the design must hold, what is allowed to change, and which dependency category the
   volatile part falls into — <./patterns/side-effects-at-the-edge.md> names them.
2. **Sketch the obvious answer**
   Keep the sketch to a few lines, so the alternatives have something to beat.
3. **Produce candidates**, each optimised under a different constraint:
   - minimise the `contract` — fewest things a caller must know
   - maximise flexibility for one named future change
   - optimise the most common caller — its code becomes the shortest
   - isolate the volatile dependency behind a `seam`
4. **Compare on depth**: for the same behaviour, which candidate demands least from its callers, and
   which needs fewer modules?
   Name where each puts its seam, and what each makes awkward.
5. **Recommend one**, and state what it gives up.

## Rules

- One constraint per candidate, or the comparison has nothing to compare.
- For the same behaviour, prefer the candidate with the smaller `contract` and fewer modules.
  Every module is a place a reader must look, and one more edge the next change crosses.
- The recommendation is opinionated; a list of trade-offs with no pick is not an answer.
- The cost of the recommendation is stated in the same breath as the recommendation.
- No fixed number of candidates, and no requirement to spawn subagents.
  Write the alternatives yourself when nothing can be spawned; split them across subagents when
  something can.

## Output

The comparison stays in conversation.
Write it to a file only when the user agrees and names the location.
A design expected to outlive the session belongs in `write-spec` instead.
