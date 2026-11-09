# running indicator

## Purpose
The running sweep the footer draws while a session works.
The widget is a plain component rather than a factory, and claims no slot itself.

## Responsibilities
- Own the running-session condition: show the sweep only while the session's status is running.
- Draw the sweep through the shared spinner views.

## Architecture
The sweep is the shared knight-rider view, coloured with the theme's accent and rendered through the host's globally registered spinner element.
`tui.tsx` replaces the host's footer status region, which suppresses the host's own indicator, so the plugin draws one back.
The session id is optional: the home composer has none, and shows nothing.
