# [MAYBE-READY] Smear-Cursor Kitty Graphics Backend

## Introduction

`smear-cursor.nvim` animates the Neovim cursor with a spring-damped smear trail, inspired by Neovide's animated cursor.
Its current renderer (`draw.lua`) fakes sub-cell, pixel-ish visuals by spawning many small floating windows filled with Unicode block-element glyphs, one glyph cell approximating a fragment of the smear shape.
This works in every terminal, since it only depends on Neovim's window and highlight APIs, but it has two structural costs.

First, the visual resolution is capped at the glyph grid: even with block-element sub-cell glyphs, the smear silhouette is quantized to a coarse lattice, producing visibly blocky edges instead of a smooth antialiased shape.
Second, the floating-window approach is a genuine hack: every animation tick may create, resize, or destroy several floating windows, each with its own highlight namespace, and Neovim's compositor is not designed to layer many transient overlapping windows cheaply.
This shows up as two known issues in the upstream plugin: text shadowing (Neovim cannot render superimposed characters cleanly) and incompatibility with other plugins that also manipulate the cursor or floating windows.

This spec proposes an alternative renderer backend that draws the smear using the Kitty terminal graphics protocol instead of floating windows.
Under this backend, the smear shape is rasterized to an RGBA bitmap and displayed via the graphics protocol's placement mechanism, using pixel-precise sub-cell offsets.
This removes the glyph-grid resolution ceiling (real alpha-blended pixels instead of block glyphs) and removes the floating-window machinery entirely (cheap per-cell placement calls per frame instead of N floating windows).

The existing physics core — spring-mass-damping interpolation in `animation.lua`, event wiring in `events.lua`, and buffer/screen coordinate tracking in `screen.lua` — is unaffected and reused as-is.
This is purely a renderer swap: `draw.lua`'s responsibility (turn interpolated smear geometry into terminal-visible pixels) is being replaced for terminals that support the graphics protocol, with the current floating-window renderer preserved as the fallback for terminals that do not.

Prior art informing this design: `3rd/image.nvim` (full Kitty-protocol Lua backend for Neovim, including window-overlap clearing and multiplexer passthrough), `folke/snacks.nvim`'s `image` module (another maintained Lua transport implementation), `edluffy/hologram.nvim` (minimal wire-protocol reference), and Neovim core's emerging `vim.ui.img` module (native PNG-via-Kitty-protocol display API).
The Kitty graphics protocol specification itself (`sw.kovidgoyal.net/kitty/graphics-protocol`) is the normative reference for wire format, placement semantics, source-rectangle selection, and cursor-movement policy.

This work is being developed as a personal fork first, not an immediate upstream PR.
It may be proposed back to `sphamba/smear-cursor.nvim` once the approach is proven working in daily use.

## Terminology

- **Smear** (well-known, plugin-specific): the interpolated trail shape drawn between the cursor's previous and current position, computed each animation frame.
- **Renderer backend** (new!): the pluggable component responsible for turning a computed smear shape into visible terminal output.
  Two backends are defined by this spec: **Window Backend** (existing, floating-window/glyph-based) and **Kitty Backend** (new, graphics-protocol/pixel-based).
- **Window Backend** (new! — name for existing code): the current `draw.lua` renderer using floating windows and Unicode block glyphs. Kept as the universal-compatibility fallback.
- **Kitty Backend** (new!): the proposed renderer using the Kitty graphics protocol to display a rasterized smear via image placements.
- **Cell size** (well-known): the terminal's per-character-cell pixel dimensions, queried at startup (e.g. via `<ESC>[16t` or `TIOCGWINSZ`) and re-queried on resize, required to convert smear geometry (in cells/rows/cols) into pixel offsets for placement.
- **Placement** (well-known, protocol term): a Kitty graphics protocol instruction to display a previously transmitted image at a specific location, with policies like cursor-movement behavior, z-index, and an optional source rectangle within the image.
- **Backend detection** (new!): the startup routine that probes terminal capability (Kitty graphics protocol support) and dependency availability (`image.nvim` / `magick.nvim` presence), selecting Window Backend or Kitty Backend accordingly.
- **Image number** (well-known, protocol term, `I` key): a client-chosen, non-unique request value the terminal uses to allocate a real, collision-free image id (`i`), returned in the terminal's response. This is the protocol's documented mechanism for programs that share a terminal/session with other graphics-protocol clients.
- **Atlas** (new!): a single transmitted image containing a fixed set of pre-rendered smear-fragment shapes (quantized fill-angle/fill-fraction combinations), looked up per cell per frame via source-rectangle selection rather than re-rasterized and re-transmitted every frame.

## Naming & IDs

The Kitty Backend requests an image id via the protocol's **image number** mechanism (`I=<locally-random number>`) rather than a fixed constant `i` value.
The terminal allocates and returns a genuinely unique `i` in its response, which the plugin then uses for all subsequent placement/deletion commands for that session.
This satisfies the requirement that two Neovim instances running side-by-side (e.g. in separate tmux panes sharing one terminal's graphics-protocol namespace) do not collide: each instance independently requests its own number and receives its own real id from the terminal, with no coordination needed between instances.

## API

The public plugin API (`require("smear_cursor").setup({...})`) is unchanged in shape.
A new config field selects or auto-detects the backend:

```lua
require("smear_cursor").setup({
  -- existing options unchanged
  stiffness = 0.6,
  trailing_stiffness = 0.3,
  -- ...

  -- new: renderer backend selection
  renderer = "auto", -- "auto" | "window" | "kitty"
  -- "auto" (default): probe terminal capability + image.nvim availability at startup.
  --          Kitty Backend is only selected if BOTH the terminal supports the graphics
  --          protocol AND image.nvim is installed (see Transport Implementation Approach).
  --          Falls back to "window" otherwise, silently (expected common case today).
  -- "window": force the existing floating-window/glyph renderer.
  -- "kitty": force the graphics-protocol renderer. If the terminal does not support it,
  --          OR image.nvim is not installed, setup() emits one warning and falls back
  --          to "window" rather than silently failing to draw.

  kitty_renderer_opts = {
    -- only consulted when the kitty backend is active
    atlas_angle_steps = 32,   -- quantization of fill-angle for atlas (see Rasterization section)
    atlas_fraction_steps = 16, -- quantization of fill-fraction for atlas
  },
})
```

Internally, `draw.lua` becomes a thin dispatch layer:

```lua
-- draw.lua (post-refactor sketch)
local M = {}
local backend -- set at setup() time, one of require("smear_cursor.draw_window") / require("smear_cursor.draw_kitty")

function M.init(config)
  backend = select_backend(config.renderer) -- runs Backend Detection
  backend.init(config)
end

function M.draw_frame(smear_shape)
  -- smear_shape: geometry already computed by animation.lua / screen.lua, backend-agnostic
  backend.draw_frame(smear_shape)
end

function M.clear()
  backend.clear()
end

return M
```

`animation.lua`, `events.lua`, and `screen.lua` call only `draw.draw_frame(shape)` and `draw.clear()` — they must not know which backend is active.
This keeps the physics core's existing behavior and test coverage untouched.

## Rasterization Strategy: Atlas

Per-frame rasterization does not need to generate and transmit a fresh image every animation tick.
The smear shape, at any instant, is already discretized per cell by the Window Backend today: it picks a Unicode block/octant glyph approximating the local fill-fraction and fill-angle of the smear within that cell.
The Kitty Backend can reuse this exact discretization, but replace "look up a Unicode glyph" with "look up a source rectangle inside a pre-rendered atlas image."

**Atlas construction (once, at startup or lazily on first activation; re-run whenever the detected cell-size changes):**

1. Enumerate the discrete set of fragment shapes the animation can produce, quantized along two axes: fill-angle (`atlas_angle_steps`, default 32) and fill-fraction/coverage (`atlas_fraction_steps`, default 16).
   These defaults are accepted starting points, tunable if quality/size tradeoffs need adjusting later.
2. Rasterize each combination once, with proper antialiasing, into a fixed-size cell-sized tile (see the shape-drawing approach described under the POC path — the same drawing primitives apply here, at atlas-build time rather than per animation frame).
3. Pack all tiles into a single RGBA atlas image (a simple grid layout: `atlas_angle_steps * atlas_fraction_steps` tiles).
4. Transmit the atlas once via `a=T` (or `a=t` then a placement), storing its allocated image id (see Naming & IDs).

**Per animation frame:**

1. For each affected cell, compute fill-angle and fill-fraction exactly as the Window Backend does today for glyph selection — this logic is reused, not rewritten.
2. Quantize to the nearest atlas tile and compute that tile's `(x, y, w, h)` source rectangle within the atlas.
3. Issue a placement (`a=p`) referencing the atlas image id, with the computed source rectangle and the target cell's pixel destination (`X`, `Y` sub-cell offsets), `C=1` to avoid moving the real cursor.
4. Re-use one placement id per active cell slot across frames (update via same `i`+`p` pair) so placements move/change without needing deletion, per the protocol's replace-on-same-id-pair behavior.

The only per-frame cost is cheap placement commands (small control-data escape sequences, no base64 payload, no re-transmission) — a significant efficiency win over naive "rasterize and transmit a full custom image every frame."

**What this trades away:** shape fidelity is bounded by the atlas's quantization steps, not fully continuous.
With the defaults above (512 tiles total), quantization error should be visually imperceptible — finer than the existing block-glyph alphabet — but this is a tunable tradeoff between atlas size/transmit cost and shape smoothness, not a hard limit removed entirely.

**Color/gradient handling: solid tint for v1.**
The existing plugin supports gradient coloring across the smear (via `color.lua`).
A monochrome/alpha-only atlas (tiles store coverage, not final color) does not directly support arbitrary gradient color: storing pre-tinted color variants in the atlas is not viable for continuous gradients (combinatorial explosion of atlas tiles).
The Kitty Backend ships with a single solid tint applied uniformly to the whole smear, accepting reduced color fidelity versus the Window Backend's gradient support.

### Open Questions

1. How should gradient/per-cell color eventually be restored on top of alpha-mask atlas tiles?
   **Non-blocking.** V1 ships with solid tint by deliberate decision; gradient restoration is a real follow-up, but the right approach (background-color compositing, per-segment re-tint, multi-layer placements, or something else) is not yet known, and timing for exploring it is undecided.

## Backend Detection & Fallback

At `setup()` time, when `renderer = "auto"` (default):

1. Query terminal capability using the protocol's documented detection technique (query action `a=q` plus a request for primary device attributes; if a graphics-protocol response arrives before/alongside the device-attributes response, the terminal supports it).
2. Check whether `image.nvim` (and its `magick.nvim` dependency) is installed and loadable (`pcall(require, "image")`), since the implementation path depends on it (see Transport Implementation Approach).
3. If both checks pass, activate Kitty Backend.
4. If either check fails, activate Window Backend, with no user-visible error (expected common case today, since `image.nvim` is an optional dependency, not a hard one).

When `renderer = "kitty"` is forced and either check fails, `setup()` emits one warning (not a repeated per-frame warning) and falls back to Window Backend, so users forcing an unsupported backend still get a working smear rather than a silently broken one.

Detection runs **synchronously** at startup.
NOTE: synchronous detection risks adding startup latency on slow terminal/pty round trips (e.g. over SSH).
This is an accepted tradeoff for now.

## Placement / Scope

Backend selection is global per Neovim instance (set once in `setup()`), not per-window or per-buffer.
This matches the Window Backend's current scope: the smear is a single global cursor-follow effect, not a per-buffer feature.
The Kitty Backend's atlas image id and cell-size cache are similarly global singletons, re-initialized only on `setup()` re-invocation or on a detected terminal resize.

On resize, the cached cell-size is invalidated and re-queried before the next frame is drawn, preventing stale-scale placements.
Because the Atlas tiles are cell-sized and Kitty placements do not scale, a detected cell-size change also triggers Atlas re-rasterization and re-transmission at the new cell size; the stale image is replaced via a fresh transmit.

## Smear Frame as Graphics Placement

The core conceptual mapping this spec introduces: what the Window Backend represents as *N floating windows with glyph content*, the Kitty Backend represents as *N placements referencing shared atlas tiles*.
Concretely:

| Window Backend concept | Kitty Backend equivalent |
|---|---|
| Floating window per smear fragment | Placement per smear fragment, same atlas image id |
| Block-element glyph choice (resolution unit) | Atlas tile lookup via quantized fill-angle/fraction (resolution unit) |
| Highlight namespace per window (color) | Solid tint for v1; gradient restoration unresolved (see Rasterization Open Questions) |
| Window `close()` per stale fragment | Placement update under same `(image id, placement id)` pair (implicit replace, no delete needed) |
| Window z-order via `zindex` option | Placement z-index parameter |

This table is the concrete "familiar concept maps to new primitive" translation.
The physics core needs zero changes; only the fragment-to-pixel lookup changes from "glyph choice" to "atlas tile choice."

## Transport Implementation Approach

**Decision: depend on `image.nvim`'s Kitty backend (and its `magick.nvim`/ImageMagick dependency) for the shipped implementation.**
Kitty Backend is only available when `image.nvim` is installed and loadable — this is an accepted, explicit tradeoff (see Backend Detection: `renderer = "auto"` requires it; `renderer = "kitty"` warns and falls back without it).
No attempt is made to vendor or bundle image.nvim's transport code; it is treated as a genuine optional runtime dependency.

In parallel, a hand-rolled minimal transport is built independently as a personal protocol-learning exercise — not a shipping dependency of the plugin, and does not block or delay the `image.nvim`-based path.
A future move to Neovim core's `vim.ui.img` module is deferred until that module is confirmed stable, since it would otherwise raise the plugin's minimum supported Neovim version ahead of that module's own stabilization.

No whole-spec "Alternatives & Tradeoffs" section is included: no competing overall design (e.g. "don't build a Kitty Backend at all, do X instead") is under consideration, so that canonical section is omitted rather than left hollow.

**The three transport paths considered:**

- **Hand-rolled minimal transport** (learning track, parallel, not shipped): implement transmission/chunking/placement/query directly from the protocol spec.
  Advantage: deepest protocol understanding, zero dependency.
  Cost: duplicates work already done well elsewhere; not worth shipping when a maintained alternative exists.
- **`image.nvim`'s Kitty backend** (selected, shipped path): reuse its existing transport, window-overlap clearing, multiplexer-passthrough handling, and its `magick.nvim` (ImageMagick FFI) dependency for drawing/rasterization primitives.
  Advantage: no transport or rasterization code to maintain for the shipped path.
  Cost: Kitty Backend is gated behind these optional dependencies being present.
- **Neovim core's `vim.ui.img`** (deferred): would remove the dependency entirely once stable.
  Advantage: zero dependency, core-aligned.
  Cost: version floor and API stability not yet acceptable.

**Decision criteria:** use `image.nvim`'s Kitty backend whenever it is loadable (the shipped path); use the hand-rolled transport only as a protocol-learning exercise, never in shipped code; revisit `vim.ui.img` once it is stable and no longer raises the plugin's Neovim version floor.

## Related files

- `lua/smear_cursor/draw.lua` — becomes the backend-dispatch shim described in API section; currently holds the Window Backend implementation directly.
- `lua/smear_cursor/draw_window.lua` (new, extracted) — Window Backend implementation, moved out of `draw.lua` unchanged.
- `lua/smear_cursor/draw_kitty.lua` (new) — Kitty Backend implementation per Rasterization Strategy and Implementation Milestones sections; depends on `image.nvim`/`magick.nvim` at runtime.
- `lua/smear_cursor/atlas.lua` (new) — atlas construction and fill-angle/fraction lookup logic, shared conceptually with (but not code-shared with) the Window Backend's existing glyph-selection logic.
- `experimental/kitty_transport_learning.lua` (new, out-of-tree or clearly marked experimental) — hand-rolled protocol transport, personal learning track; explicitly not wired into the shipped backend.
- `lua/smear_cursor/animation.lua`, `lua/smear_cursor/events.lua`, `lua/smear_cursor/screen.lua` — unchanged; consumed by both backends via the `draw.lua` dispatch interface.

## Implementation Milestones & POC Path

Start small and prove the riskiest, least-familiar piece — raw graphics-protocol wiring — completely independently of smear-cursor's animation machinery, before touching the real plugin at all.

1. **Standalone protocol POC (no Neovim plugin, no smear logic).**
   A minimal script (can run inside a scratch Neovim buffer or a bare Lua/PTY test harness) that: queries graphics-protocol support (`a=q`), requests an image number (`I=`) and records the terminal-assigned `i`, transmits one static solid-color image, places it at a fixed screen cell with `C=1`, and clears it.
   Goal: prove the wire mechanics (query, id allocation, transmit, place, clear) work end-to-end, with nothing else in the way.

2. **Cursor-follow POC, still no animation.**
   Extend step 1: on every `CursorMoved` autocmd, move the same placement to the cursor's *current* cell (snap, no interpolation, no trail).
   Goal: prove cell-size querying, coordinate conversion, and placement-move-without-delete work reliably as the cursor actually moves around a real buffer.

3. **Two-point shape POC, still no spring animation.**
   On each `CursorMoved`, draw a simple shape (e.g. a filled rectangle or capsule) directly between the previous and current cursor position, recomputed instantly — no easing, no timer-driven frames, no trailing decay.
   Rasterization for this shape does not need hand-written line/polygon-fill code: use `magick.nvim` (the ImageMagick FFI bindings `image.nvim` already depends on) and call its `MagickWand` drawing primitives directly — `DrawRectangle`, `DrawLine`, or `DrawPolygon` with `DrawSetStrokeAntialias` enabled — to get an antialiased RGBA buffer for the shape in a couple of Lua calls.
   This is the same dependency already committed to in Transport Implementation Approach, so it adds no new dependency, and it is the same drawing mechanism reused at atlas-build time in step 4/6 below.
   Goal: prove basic non-trivial geometry-to-pixel rasterization and placement, using an existing drawing library rather than implementing rasterization algorithms.

4. **Minimal atlas POC.**
   Replace step 3's per-frame draw call with a tiny atlas (a handful of tile shapes, not the full 512-tile grid), built once using the same `magick.nvim` drawing primitives, with source-rectangle lookups replacing the per-frame draw.
   Goal: prove the atlas-lookup mechanic itself (transmit once, look up source rect per frame) before investing in full quantization granularity.

5. **Wire into real smear-cursor as an opt-in backend.**
   Behind `renderer = "kitty"`, feed real `animation.lua` spring output into the POC's placement logic (still using the minimal atlas from step 4).
   Goal: first visually-animated integration test, validating the `draw.lua` dispatch shim and backend-swap wiring described in the API section.

6. **Scale up the atlas to full quantization defaults.**
   Move to `atlas_angle_steps = 32` / `atlas_fraction_steps = 16`, measure visual quality against the Window Backend and measure per-frame cost improvement versus the step-3/4 per-call drawing approach.

7. **Solid-tint color support.**
   Wire the v1 solid-tint decision through config and rendering; gradient restoration stays out of scope for this milestone.

8. **Backend detection, fallback, and multi-instance correctness.**
   Wire the full `auto`/`window`/`kitty` detection logic (including `image.nvim` availability check), resize-invalidation, and verify no collisions across two Neovim instances in separate tmux panes (validating the `I=` image-number allocation approach under real multi-client conditions).

9. **Polish and decide on upstreaming.**
   Documentation, edge-case hardening (fast cursor jumps, window close during animation, etc.), and a decision on whether to propose this back to `sphamba/smear-cursor.nvim` per the Introduction's stated plan.

Steps 1–4 deliberately have nothing to do with smear-cursor's actual codebase — they are the "prove it works at all, KISS" phase, and are the recommended starting point before any of the spec's other sections need to be touched in real code.
