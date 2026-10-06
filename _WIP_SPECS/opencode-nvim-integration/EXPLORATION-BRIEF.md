# OpenCode.nvim integration — exploration brief

## Motivation

Idea: a thin Neovim↔OpenCode bridge — inject editor context into prompts, run
prompts/OpenCode commands, and support edit review, driven from keymaps.
Work in this space exists upstream (e.g. `nickjvandyke/opencode.nvim`,
`sudo-tee/opencode.nvim`); treat them as prior art, not as the subject.

Problem: the interaction model of these bridges is weak — every plugin API call pushes a
separate message into the OpenCode session (so many comments can't be batched into one long
message), and the ask prompt is single-line (so long or multiline/structured messages aren't
really writable).

Scope: explore the interaction-model gaps and evaluate building or forking a bridge to close
them — upstream is actively moving (OC v2 support landed recently), and Neovim 0.13
`vim.async` support is expected to land.

Out of scope: the broader "nvim + opencode review/annotation plugin" idea — that prior-art
record lives in `EXPLORATION-nvim-opencode-review-plugin.md`; link, don't duplicate.

## Topics

- (active) `opencode-nvim-integration` — the bridge idea: interaction-model gaps + fork candidacy
- (active) `nvim-opencode-review-plugin` — prior art for the review/annotation plugin idea
