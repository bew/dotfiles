# [DRAFT] WM Profiles

> IMPORTANT: Before any drafting/planning/editing of this spec,
> agents MUST load one of the spec-writing skill first.

## Introduction

The spec covers two cooperating subsystems:

**Window tagging** — a lightweight per-window label store that persists across app restarts within a session.
Tags are user-assigned strings that associate a window with a specific slot in a layout profile.
Untagged windows trigger "needs tag" violations, which the system resolves interactively via a chooser UI.

**Window positioning** — a profile-driven system that detects the current set of attached screens and ensures every tagged window sits in its expected location: correct screen, correct workspace (e.g. macOS Space or a virtual desktop on another WM), and correct pixel rectangle.

When a macOS user switches between physical display setups, windows that were on an external monitor may end up on the built-in display, or vice versa.
Manually repositioning windows after every desk change is tedious and error-prone.

WM Profiles define named configurations (profiles) of window layouts, each keyed to a specific set of attached screens.
When the screen configuration is detected as matching a known profile, the system checks whether every tagged window is in its expected slot.
If any window deviates — wrong workspace, wrong position, or still waiting for a tag assignment — the system reports a violation and offers to repair it.

Each profile is a pure specification: it does not contain imperative repair logic.
The spec declares where each tagged window should be (screen alias, workspace index, unit rectangle) and what the screen set must look like (a mapping of alias → display name pattern).
The machinery that detects violations, collects untagged windows, and applies repairs operates on top of these profiles generically.

## Terminology & Key Concepts

Terms are listed in dependency order within each group.

### Core entities

**Window** — a standard application window identified by a stable numeric window ID, a title string, and its owning application's bundle ID.

### Tagging subsystem

**Tag** — a user-assigned label attached to a window.
Format: `prefix[:suffix]` where the suffix is optional.
Both parts are restricted to `[a-z0-9_-]+`.
A bare `prefix` tag (e.g. `web`) is valid; adding `:suffix` (e.g. `web:work-main`) refines the exact target when multiple windows of the same app need distinct slots.
The prefix maps to an application bundle ID via the bundle ID mapping.

**Bundle ID mapping** — a static table mapping application bundle IDs to tag prefixes.
Example: `org.mozilla.firefox → web`, `com.microsoft.teams2 → teams`.
When checking a layout slot, the system resolves the slot's tag prefix to find which application owns the window.

**Tag store** — an in-memory key/value store mapping window IDs to tag strings.
Lives for the session lifetime.
Stale entries (windows that no longer exist) are pruned periodically.

**Valid tags** — the set of tags that appear in the currently active profile's layout.
A stored tag not present in this set is treated as untagged (stale from a previous profile version).

### Positioning subsystem

**Profile** — a named window layout configuration.
Contains a name, a screen alias map, and a layout.

**Layout** — a collection of layout slots that collectively define where every tagged window should reside when a profile is active.
Supports two equivalent forms: a flat ordered list (`layout`) or a map keyed by screen alias (`layout-by-screen`).
Order matters: within a given screen, workspace targets are visited in slot order, determining workspace creation order if the WM backend creates workspaces on demand.

**Layout Slot** — a single placement expectation within a profile.
Declares a tag, a screen alias, a workspace index, and a target frame.
One tag maps to exactly one slot within a profile.

### Spatial concepts

**Workspace** — an indexed virtual desktop within a screen.
Workspaces are identified by an opaque ID and indexed 1-based per screen.
Slot targets reference workspaces by index, which is resolved to an opaque ID at check time by the WM backend.

**Screen matcher** — the per-profile mapping of screen aliases to match criteria.
By default an alias value is an exact display name string; it may also be a matcher object with richer predicates (e.g. aspect ratio, width > N pt). The matcher syntax is not defined here.
Layout slots reference screens by alias, not by matcher directly.

**Frame** — a named rectangle expressed as fractions of the target screen dimensions.
Can be specified inline as `{x, y, w, h}` with each value in `[0, 1]`, or as a frame alias (see below).
Allows the same layout spec to work across different screen resolutions.

**Frame alias** — a predefined named frame.
Built-in alias:
- `full` → `{x: 0, y: 0, w: 1, h: 1}`

Aliases expand to a unit rect at check time.

### Correctness

**Drift threshold** — a tolerance percentage of screen dimension used when comparing a window's current frame to its target frame.
A window is considered correctly placed if each coordinate difference is ≤ threshold % of the corresponding screen dimension.

**Violation** — a single detected deviation from the profile.
Types:
- `needs-tag`: the slot requires a tag but no window has it.
- `wrong-workspace`: the window is on the wrong workspace.
- `wrong-frame`: the window is at the wrong position or size.
- `is-fullscreen`: the window is in native fullscreen mode (must exit before framing).

### Open Questions

1. Should workspace index be relative to the screen (1-based) or use the opaque workspace ID directly?
   Non-blocking. Index-based is more portable across WM backends; ID-based survives workspace reordering but couples to a specific backend.

## Profile & Layout Definition

A profile declares which screens must be present and where each tagged window should be placed.
It has four fields:

- `name` — a human-readable identifier (e.g. `"home"`, `"work"`).
- `screens` — a map of alias → screen matcher (see Terminology).
- `config` — optional map of profile-specific key/value settings (all keys in kebab-case). See "Profile config" section.
- `layout` or `layout-by-screen` — one must be present, not both.
  `layout` is a flat ordered list of slots; `layout-by-screen` is a map of alias → slot list.
  Both are functionally equivalent — the system normalizes `layout-by-screen` into a flat list internally.

### Screen matching

The system compares the current set of attached screens against each profile in definition order.

For each profile:

1. Resolve every alias declared in `screens` against the attached screens using their screen matchers.
2. If **all** aliases resolve to distinct screens, the profile matches.
   If any alias fails to match a screen, the profile is rejected — partial matches are not accepted.
3. When the same physical screen could match multiple aliases (e.g. two regexes match the same display name), the first alias in definition order claims it.
   Remaining aliases are resolved against the still-available screens.
4. The first profile where all aliases resolve is the active profile.
   Subsequent profiles are not evaluated.

If no profile matches, the system is inactive — no violations to report, no repair actions available.

Examples:

A profile with two aliases (`benq` and `builtin`) only matches when both the BenQ monitor and the built-in display are attached.
If only one is present, the profile does not match.
A profile with a single alias matches whenever that screen is present, regardless of other attached screens.
To match a specific screen count (e.g. "exactly one external monitor"), declare exactly that many aliases — the number of aliases implies the expected screen count.

### Layout forms

Two equivalent forms. Slots in both forms have the same fields:

- `tag` — the tag a window must carry to fill this slot.
  Prefix maps to the target application via the bundle ID mapping.
- `screen` — a screen alias declared in the profile's `screens` map.
- `workspace` — 1-based workspace index within the target screen.
  Resolved to an opaque workspace ID by the WM backend at check time.
- `frame` — target position.
  Either the frame alias `full` or an inline map with named fields `x`, `y`, `w`, `h`, each in `[0, 1]`, relative to the target screen's frame.

Multiple slots may target the same screen and workspace (e.g. two windows side by side).
Overlapping frames are valid — the system places each window independently.

Slot order determines the order in which workspace targets are visited during repair.
For WM backends that create workspaces on demand, this defines workspace creation order within a screen.

#### Flat layout

```
profile "home":
  screens:
    benq:    "BenQ PD2705U"
    builtin: "Built%-in"
  layout:
    - tag: "teams:chat"
      screen: benq
      workspace: 1
      frame: { x: 0, y: 0, w: 0.5, h: 1 }
    - tag: "web:work-main"
      screen: benq
      workspace: 1
      frame: { x: 0.3, y: 0, w: 0.7, h: 1 }
    - tag: "term:main"
      screen: benq
      workspace: 2
      frame: full
    - tag: "web:misc"
      screen: builtin
      workspace: 1
      frame: full
    - tag: "web:work-secondary"
      screen: builtin
      workspace: 2
      frame: full
    - tag: "mails:main"
      screen: builtin
      workspace: 3
      frame: full
```

#### Grouped by screen

```
profile "home":
  screens:
    benq:    "BenQ PD2705U"
    builtin: "Built%-in"
  layout-by-screen:
    benq:
      - tag: "teams:chat"
        workspace: 1
        frame: { x: 0, y: 0, w: 0.5, h: 1 }
      - tag: "web:work-main"
        workspace: 1
        frame: { x: 0.3, y: 0, w: 0.7, h: 1 }
      - tag: "term:main"
        workspace: 2
        frame: full
    builtin:
      - tag: "web:misc"
        workspace: 1
        frame: full
      - tag: "web:work-secondary"
        workspace: 2
        frame: full
      - tag: "mails:main"
        workspace: 3
        frame: full
```

### Profile config

Each profile has an optional `config` map of key/value settings.
All keys use kebab-case.
Known keys:

| Key | Type | Default | Description |
|---|---|---|---|
| `poll-interval-sec` | number | `5` | Seconds between periodic layout checks for this profile. `0` disables polling. |
| `drift-threshold` | number | `0.1` | Tolerance as fraction of screen dimension for frame comparisons. `0.1` = 10%. |
| `auto-repair` | boolean | `false` | If `true`, violations are repaired immediately after detection. If `false`, system reports violations but the user must invoke repair manually. |
| `repair-prompts` | list of violation types | none | When `auto-repair` is `true`, violation types listed here still require user confirmation before repairing. Violations not in this list are repaired silently. |

When `auto-repair` is `false`, all violations must be repaired manually regardless of `repair-prompts`.

## Violation Detection

A layout check runs against the currently active profile.
For each slot in the profile's layout, the system resolves the target app, screen, and workspace, then compares the actual state of tagged windows against the expected state.

If no profile matches (no active profile), the check produces zero violations.

### Check flow per slot

When a check runs, the system iterates over every slot in the active profile's layout (in order) and applies the following steps.

**1. Resolve the application from the tag**

The slot's tag (e.g. `"web:work-main"`) has a prefix `web`.
The system does a reverse lookup in the bundle ID mapping: which bundle IDs have tag prefix `web`?
Zero match → warning, skip the slot.
Multiple matches → all bundle IDs are considered; the app search in step 5 covers all of them.
The bundle ID mapping is expected to be 1:1 in practice, but duplicates are not an error.

**2. Resolve the workspace**

The slot's `workspace` is a 1-based index into the target screen's workspace list.
The system asks the WM backend for the ordered workspace list on that screen and takes the Nth entry.
If the index is out of bounds (the workspace doesn't exist yet):
- During check → skip the slot.
- During repair → attempt to create the workspace first (see Auto-Repair).

**3. Compute the target frame**

If the slot's `frame` is the alias `full`, expand to `{x: 0, y: 0, w: 1, h: 1}`.
Otherwise it's an inline map `{x, y, w, h}` with values in `[0, 1]`.
Convert the unit rect to absolute pixels using the target screen's dimensions:

```
pixels_x = screen.x + unit.x * screen.w
pixels_y = screen.y + unit.y * screen.h
pixels_w = unit.w * screen.w
pixels_h = unit.h * screen.h
```

**4. Find the matching window**

Collect all standard windows of the resolved application(s).
For each window, look up its stored tag.
Tags not present in the active profile's valid-tag set are treated as untagged (stale from a previous profile).
Pick the window whose effective tag exactly matches the slot's tag.

Three possible outcomes:

| Match result | Violation |
|---|---|
| Found, but on wrong workspace | `wrong-workspace` |
| Found on correct workspace, but frame deviates | `wrong-frame` |
| Found on correct workspace, frame within tolerance | *none* |
| Found, but in native fullscreen | `is-fullscreen` (+ `wrong-frame` implied) |
| Not found, but untagged windows of the app exist | `needs-tag` |
| Not found, and no untagged windows of the app exist | *skip* (no candidate) |

A single window may produce multiple violation types simultaneously (e.g. `wrong-workspace` + `is-fullscreen`).

### Frame drift tolerance

Frame comparison uses the profile's `drift-threshold` config (default 0.1 = 10% of screen dimension).
For each of `x`, `y`, `w`, `h`:

```
|actual - expected| / screen_dimension ≤ threshold  →  OK
```

If all four coordinates pass with the window on the correct workspace, the slot is clean.
Frame drift is only measured when the window is on the correct workspace — comparisons across workspaces are meaningless.

`is-fullscreen` always implies `wrong-frame`: the window must exit native fullscreen before the system can set its frame, regardless of what the targeted frame is.

### Open Questions

1. Should `needs-tag` violations fire when only one untagged window exists for the app (auto-assign), or always require user confirmation?
   Non-blocking. Auto-assign is faster but risks wrong assignment if the app has multiple windows.

## Auto-Detect & Auto-Repair

This section defines when checks run (triggers), how repair is gated (per-profile policy), and what actions each violation type triggers during repair.

### Triggers

The system fires a layout check on three kinds of event:

1. **Screen layout change** — any change to the set of attached screens (monitor plugged/unplugged, resolution change, screen position change).
2. **Wake / unlock** — the system wakes from sleep or the user unlocks the session. Screens may have been reconfigured while the machine was asleep.
3. **Periodic polling** — a configurable timer that fires even when no system events are received. Acts as a backstop for mid-session drift (e.g. accidental window moves).

Polling interval is controlled by the profile's `poll-interval-sec` config key.

### Debounce

Multiple triggers can fire in rapid succession (e.g. screen change → wake → poll).
The system debounces checks: if a check is already running or a new trigger fires within a small window (e.g. 1 second) since the last check completed, the new trigger is suppressed.
When suppressed, the system schedules one pending check to run after the debounce window expires, using the latest screen configuration.

### Repair policy

Repair behavior is controlled by the profile's `auto-repair` and `repair-prompts` config keys (see Profile config).

A manual repair is a user-initiated action (keybinding, menu item) that runs repair on the active profile's current violations.

### Repair actions per violation type

Repair processes violations in layout order. For each violation:

**`needs-tag`** — the slot has no matching window, but untagged windows of the target app exist.

1. Collect the untagged windows of the resolved app(s).
2. If `needs-tag` is in the profile's `repair-prompts` (or `auto-repair` is off): present a chooser UI listing the untagged windows by title. User selects one to assign the tag. Cancel leaves the window untagged.
3. If `auto-repair` is on and `needs-tag` is not prompted: auto-tag the first untagged window.
4. After tagging, re-check the slot. If the newly tagged window is not on the correct workspace/frame, the check produces `wrong-workspace`/`wrong-frame` violations, which are repaired next.

**`wrong-workspace`** — the window is on the wrong screen or workspace.

If the workspace index is out of bounds (doesn't exist yet), create it first.
Then move the window to the correct screen's correct workspace.
If the workspace index is out of bounds and WM backend does not support creating workspaces on demand → skip with a warning.

**`wrong-frame`** — the window is on the correct workspace but its frame deviates beyond the drift threshold.

Set the window's frame to the absolute pixel rect computed in step 3 of the check flow.
The system first ensures the window is on the correct workspace (equivalent to a `wrong-workspace` repair), then sets the frame.

**`is-fullscreen`** — the window is in native fullscreen.

Exit native fullscreen first. This returns the window to a standard state. Then apply `wrong-workspace` and `wrong-frame` repairs as needed.

### Persistent violations

After repair, the system re-checks each repaired slot.
If a violation persists (e.g. the WM backend rejected the frame change), the system logs a warning and skips further repair attempts for that slot in the current check cycle.
The slot will be re-checked on the next trigger.