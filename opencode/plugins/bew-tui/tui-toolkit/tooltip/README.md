# tooltip

## Purpose
The reusable overlay panel that places a themed tooltip beside an anchor.
It knows nothing about its content: a widget passes the rows it wants drawn and gets them back on a panel.
Only the session-stats widget uses it today.

## Responsibilities
- The panel component: caps, an optional title band with an optional close control, and a scrolling body.
- Placement: the maths that decides where the panel goes and keeps it on screen.
- Anchoring: deriving the anchor rectangle from a mouse event, either once at click time or from a live element.

## Architecture
Placement puts the panel above its anchor when it fits, otherwise below, centred on the anchor, held inside a left and a right margin, and lifted back inside the terminal when it would run past an edge.
The caller supplies the number of body rows; the panel adds its own cap and header rows, caps the total at the terminal height, and scrolls the remainder with a scrollbar.

The header band carries the title, centred in an inverted stripe, and the close glyph when an `onClose` handler is given; without one the panel shows no close control and cannot be dismissed from itself.
An anchor is either a fixed rectangle or a live box, and a live one is re-read on every layout pass, so a resize keeps the panel beside the element it belongs to.
Passing a live box is what makes that behave; the placement maths itself stays renderer-free, so it can be tested without a terminal.

## Failure behaviour
- Out-of-range coordinates are clamped back into the terminal, and no placement error is thrown at the caller.
