# Server plugins

The non-terminal side of plugins.
This build only needed a no-op server entry, so this page is pointers rather than notes.

- The server entry imports `Plugin` from `@opencode/plugin` and default-exports `Plugin.define({ id, setup })`; discovery pairs it with a sibling `tui.tsx`.
- The no-op entry exists only so directory discovery finds the plugin beside its TUI entry, e.g. `../plugins/ui-tester/index.ts`.
- Server plugins cover hooks, tool transforms, and server-side context.
  The full surface is the V2 guide at `https://opencode.ai/v2/docs/build/plugins`.
- A local example of a server plugin with a tool transform is `../plugins/git-track-new-file/`, which registers the `git_track_new_file` tool through a tool transform.
- For custom methods and events shared with other plugins or clients, see `https://opencode.ai/v2/docs/build/plugins/rpc`.
