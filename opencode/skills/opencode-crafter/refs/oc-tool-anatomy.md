# oc-tool Anatomy

A TypeScript function the LLM can call during a conversation.

In OpenCode a tool is registered by an **oc-plugin** under `plugins/<name>/`.
The install layout, entry rule, required `README.md`, dependency guidance, and shared conventions
all live in <./oc-plugin-anatomy.md> — read it before drafting a tool.

Official documentation:
- https://opencode.ai/v2/docs/build/plugins — tool registration

## What is oc-tool-specific

- Register with `ctx.tool.transform`, using a synchronous callback that calls `editor.add`.
- Set `options.codemode: true` by default, so the tool appears in the Code Mode catalog.
- `name` is the effective tool name the LLM sees.
- The executor receives the tool input and a context object, and returns content to the model.

## Tool vs oc-plugin

Both are implemented as an oc-plugin directory under `plugins/`; the difference is classification
and scope, not location.
Choose the `oc-tool` type when the plugin's only job is to expose one function the LLM calls.
Choose `oc-plugin` when it hooks events, or does more than register a tool.
When in doubt, see <./classify-new.md>.
