# tooltip

## Purpose
The reusable overlay panel that places a themed tooltip beside an anchor.
It knows nothing about its content: a widget hands it a builder that packs rows for the cells the panel can offer.
Only the session-stats widget uses it today.

## Responsibilities
- The panel component: caps, an optional title band with an optional close control, and a scrolling body.
- Placement: the maths that decides where the panel goes and keeps it on screen.
- Anchoring: reading the anchored element's box through a ref the caller owns, so the panel stays beside it.
- The body contract: handing the caller the cells its rows get, and drawing what comes back.
- Visibility: hiding on request without discarding the caller's state.

## Architecture
Placement draws the panel on the side of its anchor the caller asks for, and on the side the anchor leaves the room for when the caller states none: `onTop` when the anchor sits in the lower half of the area, `onBottom` otherwise.
The side values name the edge of the anchor the panel is placed at, so placing a panel at the anchor's left or right edge later needs no renaming.
It is centred on the anchor, held inside a left and a right margin, and kept inside the area the overlay may occupy.

The caller passes a `body` builder rather than rows, because only the caller can re-pack its content: the panel calls it with the cells the body may take and receives back a title, a row count, a requested width, and the content itself.
The builder runs again whenever the offered width changes, so a narrowing terminal repacks the rows instead of leaving them wider than the panel.
A builder that returns nothing gets the placeholder body: a centred `no data` note between blank rows.

The panel adds its own cap and header rows to the body's row count, caps the total at the rows the panel's side of the anchor leaves, and scrolls the remainder with a scrollbar.
A side that leaves less room than the body needs does not send the panel to the other side of its anchor: the body is cut to that room and scrolls, so an open panel stays where its caller put it.
The frame keeps a minimum body regardless, so a side with almost no room overlaps the anchor rather than drawing an unreadable panel.

The area is the host's main area, not the whole terminal: the host draws its own bottom bars inside the terminal, and the dimensions a panel can read do not know about them.
The slot publishes no geometry, so the panel measures the area through a zero-width box it stretches between the area's top and bottom edges, and reads that box from the renderer's frames the way it reads the anchor.
Until that box has been laid out once, the whole terminal stands in for the area.
`when` hides the panel without unmounting it: while hidden it measures nothing, builds no body, and drops its placement, so showing it again measures the anchor afresh rather than flashing at the old spot.

The header band carries the title, centred in an inverted stripe, and the close glyph when an `onClose` handler is given; without one the panel shows no close control and cannot be dismissed from itself.
The caller passes a ref that yields the anchored element's box, and it is read from the renderer's frame events, so a resize keeps the panel beside the element it belongs to.
A ref that yields no box, because the element is not laid out yet or the host destroyed it, leaves the panel undrawn.
A renderable reports the terminal origin until the frame that mounts or moves it has been laid out, so the panel waits for the first frame after it mounts before placing itself.
Moving the panel means rebuilding it, since the runtime applies a node's props when it creates that node, so consecutive moves are rate limited to one rebuild per interval; a delayed move is measured again when it runs, which places the panel exactly once the anchor settles.
The panel's width is the body's requested width plus its own padding, held inside the caller's preferred body width and then inside the terminal margins, so a narrow terminal shrinks it instead of letting its rows wrap.
The requested width may only narrow the panel, never widen it past what the caller asked for.
A terminal resize places the panel again before the frame that lays the new size out, clamped into the shrunken terminal, so it is never painted against the screen it used to fit.
The body rows keep the width they were built for, so a row too wide for the shrunken panel is truncated at the panel edge rather than running past it.
The placement maths itself stays renderer-free, so it can be tested without a terminal.

## Failure behaviour
- Out-of-range coordinates are clamped back into the area, and no placement error is thrown at the caller.
- A side with less room than the panel needs cuts the panel to that room and scrolls; a panel that still cannot fit, which only happens when the room is smaller than its frame rows, is pulled inside the area and overlaps its anchor.
- An area that has not been measured yet leaves the whole terminal as the room a placement is made against.
- A builder that returns nothing shows the placeholder body instead of an empty panel.
- An anchor that is not laid out yet, or that the host destroyed, leaves the panel undrawn until it has a box again.

## Trade-offs
- Moving the panel rebuilds it, because the runtime applies a node's props when it creates it, so a move costs the panel's subtree and is rate limited.
- The caller owns the width, including the cell arithmetic for its own columns; the panel only caps what it is offered.
- The panel draws a zero-width box of its own to measure the area it overlays; it spans no cells, so it paints nothing and takes no click, but it is one more renderable per tooltip.
- The vertical room is measured against the host's main area, while the horizontal margins are still kept inside the terminal width, which the area spans.
- Widths count code units, so a row with wide glyphs or emoji is measured as if every cell were single-width.
- The body is sampled when the panel is built, so content that changes under an open panel shows up on the next rebuild.
