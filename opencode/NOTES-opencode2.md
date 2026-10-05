# Feedbacks / frictions (+ some ideas/wishes) on opencode v2

<!-- NOTE: posted on https://gist.github.com/bew/fad7939851511010ddf9d2de7f6c2a94, to share on OC Discord -->

BUG: When I have 2 opencode instances opened in same dir, with tabs scoped to the directory, when I close a session in one instance it also closes the tab for it in the other instance, even if it's the current session the other instance was on,  where an LLM was outputting stuff:
RESULT: the other instance still has the session open but no tab for it anymore ^^
And closing all tabs in the first instance makes the other instance not have a tab bar anymore even if there is a visible session active (I can interact with it no problem)..
EXPECTED: → Honestly I'd expect session tabs closes to be per instance. When I open an instance I get all the active sessions but I can close the ones I don't need in this instance.
IDEA: Maybe there needs to be a concept of a 'DONE' session, so that it doesn't pop up when I open an instance (but I can still access it in the session list) :thinking:

BAD++: When I load opencode2 with a cli.jsonc it works (and its options are correctly respected)
UNTIL I attempt to save the cli.jsonc again while the opencode2 instance is running, at which
point the entire content is replaced with the default config.. (loosing all my personal config 😱)
OPENED: https://github.com/anomalyco/opencode/pull/53031
TODO: follow-up PR for timing issue (editor writes may not be atomic)

BAD: shell command output is 'muted'
AND there is no way to override that color in e.g. a custom colorscheme
👉 I want a dedicated theme color so I can color it as I want 🤔 (make it more visible!)
BAD: long shell command run for a block is truncated..

BAD: When a subagent timeouts / gets interrupted I have no way to see that subagent's session without asking the agent to restart it.. Clicking on it allows to show why it stopped but that's not
enough..

BAD: Cannot open subagent's session timeline when watching a subagent's timeline
(opening the command-palette doesn't work at all..)

BAD: Can't have an AGENTS.md in my opencode config dir to hint the agent how to work in this directory tree, since I already have an AGENTS.md for the system prompt 👀😅
→ idea: enforce use of SYSTEM.md for the system prompt? (with auto-migration if it doesn't exist already)
(in the meantime, I made a DIR_AGENTS.md & a note at root of my dotfiles repo, but it won't take effect if agent uses the `~/.config/opencode/` path I think 🤔)

BAD: FS watcher fails to watch my ~/.config/opencode because it's a symlink (to my dotfiles repo), not a directory.
TODO: I have a PR coming for that

BAD: in `question` tool, question titles are less visible
- ~no separations
- no visual (reverse) highlight about which question is the CURRENT one like on v1
- hover highlight be very subtle and only covers the text, no padding like on v1
- when terminal width too small, it only mentions e.g. `Field 4 of 6   3/6 completed`: Doesn't mention the _current_ question title.. 😬

BAD: Typing `@` gives autocompletion for ALL skills+subagents+files, not ONLY the subagents+files..
.. This is very annoying when typing `@hand` when I want the HANDOFF-* files, not the skills starting with `handoff` 😬

BAD: `read` tool call display doesn't show offset/limit params, so a model reading multiple
segments of the same file looks like it's reading the same whole file over and over again..

BAD: `messages_toggle_conceal` keybind has no replacement in v2??

BAD: opencode2 doesn't auto install local plugins' dependencies (v1 did!)
→ Should ask user! "Install X/Y deps for plugin Z ?"
(might be gated by having a package.json in the config dir or in each plugins dir 🤔)

BAD: `question` tool blocks `ctrl+z` to suspend the TUI and get back to my shell!
(note: this was already an issue with v1)

BAD: slash-commands scoring isn't great, for `/dco` it shows `/dcp` before `/dcp-compress` because it's first in the list and it has a `o` in its cmd description 😬

BAD/MEH: The `opencode server` caches bun resolution failures, so when I installed deps for my local plugin later on, the plugin was still failing and an agent had to work to understand the reason.
Solved it by restarting the server & confirming my plugin loaded with `opencode2 plugin list`.

BAD/GRR: it's hard to know which keybind action to use in my `cli.json` for an action (docs are not great to explain this, and the JSON schema doesn't have a lot of explanation either..)
e.g. I want to bind a custom key (replace the Enter default) for submitting a custom answer in `question` :thinking:

GRR: `question` tool doesn't clearly show which questions I answered already, v1 did that with a different fg color.
(the `2/5 completed` only shows up when terminal width is too narrow, but doesn't show which questions was answered)
ALSO: the tick mark (`✓`) on the answered question is quite subtle, easy to miss 😬

GRR: I can easily loose valuable content when writing a custom answer for a question and pressing Escape, which cancels the whole custom answer instead of just exiting custom answer editor (keeping content) without selecting that answer.. 😬
(v1 did the same? don't remember)

GRR: `question` tool doesn't keep showing the answer description after I confirmed the answers and the LLM continues to process them.
→ I ~regularly would like to re-read the answer description that I just accepted, currently I can't..
(note: this was already an issue with v1)

GRR: I can't see the cost / session size of a subagent's session like in v1 😬

GRR: When moving a session from dir A to dir B, the moved session doesn't appear session listing of B (nor in an already running opencode in B).
I understand why it doesn't disappear in the opencode open in A, but I'd like to close that session in OC-in-A and keep working on it in OC-in-B 🤔

GRR: new tab is auto-closed if I switch to another tab, even if I started to write something in the prompt.. Would prefer to _not_ close the new tabs in this case!

GRR: thinking output doesn't show code blocks/inlines like `foo` in different colors like v1

MEH: 

MEH: The status indicators in tab bar are quite subtle, easy to miss! 😬
Would be nice to have a kind of intermitent tab flash, or breathing tab/indicator color with brighter color 🤔

MEH: Using `/new` from a session keeps the current agent instead of re-applying the configured `default_agent` in config. (v1 has same behavior tho..)

MEH: codemode tools include browser-related tools, even though they don't work because no browser is configured..
→ don't list tools that are not actually available…
(maybe codemode tools can have a kind of `is_available` function that defaults to true?)

WANT: clicking on `grep` (with matches) doesn't show me the actual matches 😬

WANT: ability to map `ctrl+d` to close session if prompt is empty (like in a shell) 🤔

WANT: middle-click on session tab should close it

WANT: ability to add a custom additional prompt from the `question` tool.
Questions that the model ask regularly makes me think of something else I'd like the model to know..
Currently I have to either:
- highjack the custom answer of another question (saying e.g. `3; also I'd like …`)
- submit the answers and cancel the model with a few Escape key presses, and add my additional context and submit the prompt.

WANT: warnings for config issues, like:
- binding a key to two actions at the same layer

WANT: support for multiple <leader> (like <leader>/<localleader> in neovim)
I'd like this to have `ctrl+space` as global leader (session/tabs/ui management, ..) & `alt+space` as in-session content leader (toggle thinking mode, switch model, list skills, ..)

WANT: actions (+ key action, none by default) to move current tab left/right
(currently I can only do that with mouse click & drag in tab bar)

WISH: Custom tool renderer for any tool (or at least for _my_ tool), to re-style how the UI shows the tool execution.
I'd want to use this to show custom status message to the user (not useful for the LLM).
WISH(related): Ability to inject a custom UI element in the chat scrollback, to display information to the user (but not the LLM).

WISH: allow to switch agent from `question` tool (e.g. at `confirm` step).
I usually annoyed when I'm in plan mode (I have it enabled by default) and a question tool asks something I know I have to switch to BUILD mode for.
Currently in this case I have to either:
- If I already answered 1+ questions: I usually confirm, abort the model right after, switch to BUILD and say `resume`
- or just Escape out of the tool, switch to BUILD and say something like `resume` or `re-ask`
(and hope the model understands that I want to resume/re-ask questions now that I'm in BUILD mode)

WISH: support assigning a key to a plugin action

WISH: arbitrary key chords, like `<leader>` then `s` then `n` to trigger an action. (like neovim)

IDEA: I'd like `/new` in a session to open a new tab on the right of current session, so I don't have to move it there manually once first prompt submitted..
Ideally there would be a config option for where new tab should open (`right`/`last`/`first`) 🤔

IDEA: Now that config / skills / tools / ... are live reloaded, would be nice to have a subtle notification in the TUI when it _is_ reloaded!

IDEA: Diff viewer mode to view diffs since a specific message (previous/first) 🤔

IDEA: would be nice to be able to right click an 'edit' diff and revert a specific change 🤔

IDEA: when OPENCODE_CONFIG_DIR is set, should reflect that path when OpenCode skill is loaded


## Specifc for DCP plugin

BAD: `compress` tool (from DCP plugin) doesn't give any insight about how much was compressed like in v1 😬 (what was kept as-is, what was removed/sumarized)
