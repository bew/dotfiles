# spinners

## Purpose
The shared spinner views a widget draws when it has taken over a region the host used to fill.
Two widgets use them today: the running indicator and the branch label.

## Responsibilities
- The knight-rider sweep, with the frame and per-cell colour maths that drives it.
- The braille loader, a fixed frame set with an interval of its own.
- A single re-export surface, so a widget imports both views from one place.

## Architecture
The knight-rider view builds its frames and a per-cell colour generator from the scanner maths, then hands both to the host's globally registered spinner element, which owns the clock.
Its defaults match the host footer's sweep, because the maths is a port of that footer; keep it a faithful port, including the colour generator's argument order.
The braille view draws a small fixed frame set through the same element with a single colour.

## Conventions
- Import the views from `components.tsx`, which stays re-export only, so widgets have one import site.
- The scanner maths stays internal to the views, and every view requires a colour.
