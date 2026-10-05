# MY_AI_STUFF

Catalogue of every OpenCode skill, agent, command, and plugin in my config, grouped by topic then the rest 🚀

> [!NOTE]
> The catalogue of skills, agents, commands, and plugins follows the graph below.

## Dependency graph

Not a full view of the catalogue — only the complex skills and their direct dependencies are shown.

```mermaid
flowchart LR
  subgraph craft[Crafting OC artefacts]
    sk_crafter["opencode-crafter"]
    ag_reviewer["opencode-reviewer"]
    ag_script_crafter["opencode-skill-script-crafter"]
    sk_artefact_rules["opencode-artefact-rules"]
    sk_test_runner["opencode-test-runner"]
    ag_sim_test_runner["opencode-simulated-test-runner"]
    sk_crafter -->|delegates| ag_reviewer
    sk_crafter -->|delegates| ag_script_crafter
    ag_reviewer -->|needs| sk_artefact_rules
    ag_reviewer -->|invokes| ag_sim_test_runner
    ag_sim_test_runner -->|uses| sk_test_runner
    ag_reviewer -. fallback .-> sk_test_runner
  end

  subgraph code[Coding]
    sk_coder_generic["coder-generic"]
    sk_coder_bash["coder-bash"]
    sk_coder_bats["coder-bats"]
    sk_coder_python["coder-python"]
    sk_coder_pytest["coder-pytest"]
    sk_coder_lua["coder-lua"]
    sk_coder_nix["coder-nix"]
    sk_coder_nushell["coder-nushell"]
    sk_coder_rust["coder-rust"]
    sk_coder_meta["coder-meta"]
    sk_coder_bash -->|needs| sk_coder_generic
    sk_coder_bash -->|uses| sk_coder_bats
    sk_coder_bats -->|needs| sk_coder_generic
    sk_coder_python -->|needs| sk_coder_generic
    sk_coder_python -->|uses| sk_coder_pytest
    sk_coder_pytest -->|needs| sk_coder_generic
    sk_coder_pytest -->|needs| sk_coder_python
    sk_coder_lua -->|needs| sk_coder_generic
    sk_coder_nix -->|needs| sk_coder_generic
    sk_coder_nushell -->|needs| sk_coder_generic
    sk_coder_rust -->|needs| sk_coder_generic
    sk_coder_meta -->|needs| sk_coder_generic
    sk_crafter -->|uses| sk_coder_generic
    ag_script_crafter -->|uses| sk_coder_generic
  end

  subgraph spec[Spec and planning]
    sk_write_spec["write-spec<br/>(Has variants)"]
    sk_design_explore["design-exploration"]
    sk_plan_milestones["plan-milestones"]
    sk_write_spec -->|delegates| sk_design_explore
  end

  subgraph commit[Commits]
    sk_committer["committer"]
    sk_diff2commits["diff-to-commits"]
    ag_explore_diff["explore-diff"]
    sk_check_width["check-line-width"]
    sk_committer -->|uses| ag_explore_diff
    sk_committer -->|uses| sk_check_width
    sk_diff2commits -->|uses| ag_explore_diff
    sk_diff2commits -->|uses| sk_committer
  end

  subgraph trig[Trigger commands]
    cmd_commit["/commit"]
    cmd_add_commit["/add-finished-and-commit"]
    cmd_diff2commits["/diff-to-commits"]
    cmd_handoff["/handoff"]
    cmd_friction["/reflect-friction"]
    cmd_commit -->|triggers| sk_committer
    cmd_add_commit -->|triggers| sk_committer
    cmd_bew_commit -->|triggers| sk_committer
    cmd_diff2commits -->|triggers| sk_diff2commits
    cmd_handoff -->|triggers| sk_handoff
    cmd_friction -->|triggers| sk_reflect_frict
  end

  subgraph misc[Misc]
    sk_handoff["handoff<br/>(Has variants)"]
    sk_git_track_skill["git-track-new-file skill"]
    plug_git_track["git-track-new-file plugin"]
    sk_github_issue["write-github-issue"]
    sk_draft_gh["draft-github-issue-pr"]
    sk_bew_comm_style["bew-communication-style"]
    sk_cav["caveman"]
    sk_reflect_frict["opencode-reflect-friction"]
    sk_git_track_skill -->|uses| plug_git_track
    sk_github_issue -->|needs| sk_bew_comm_style
    sk_draft_gh -->|needs| sk_bew_comm_style
    sk_draft_gh -->|uses| ag_explore_diff
    sk_draft_gh -. supersedes .-> sk_github_issue
    ag_explore_diff -. loads .-> sk_cav
  end

  %% Invisible layout spine: force the section order as written
  %% (craft → code → spec → commit → trig → misc).
  sk_coder_generic ~~~ sk_write_spec
  sk_write_spec ~~~ sk_committer
  sk_committer ~~~ cmd_commit
  cmd_commit ~~~ sk_handoff

  %% Invisible links pinning `misc`'s root nodes after a late-ranked group.
  sk_test_runner ~~~ sk_git_track_skill
  sk_test_runner ~~~ sk_draft_gh
```

## Crafting OC artefacts

- Skill `opencode-crafter` (multi-phased, has script) — Creates, updates, and refactors any OC artefact: skills, agents, commands, oc-tools, oc-plugins.

  - Full lifecycle: Classify → Discover → Draft → (Scripts) → Review → Ship, then (PropagateChange) when variants exist.
  - Delegates review to `opencode-reviewer` and script drafting to `opencode-skill-script-crafter`.
  - Pulls in `coder-generic` + a matching `coder-*` skill for script writing as needed.
  - Can derives a standalone (single-file, tool-less) skill variant on request.
  - Can take inspiration from an existing skill (e.g. from a Github URL).

- Agent `opencode-reviewer` — Refines a draft OC artefact through focused user feedback; applies trivial edits directly and iterates with you on the rest.

  Invoked by `opencode-crafter` at `Phase:Review` to find gaps and iterate with the user.

- Skill `opencode-artefact-rules` — Quality criteria and review checklist for OC artefacts, one reference per type.

  Used for `opencode-reviewer`'s `Phase:Review` — the reviewer loads it to check every criterion for the artefact type.

- Agent `opencode-simulated-test-runner` — Runs an isolated simulated test on a draft artefact.

  Invoked by `opencode-reviewer` at `Phase:Testing` (structural changes only), with no prior review context.

- Skill `opencode-test-runner` — Dry-run testing instructions: generate test cases, narrate them, iterate with reviewer on failures.

  Used for `opencode-simulated-test-runner`'s test pass (entered from `opencode-reviewer`'s `Phase:Testing`) — runs isolated simulated tests on a draft.

- Agent `opencode-skill-script-crafter` — Drafts, tests, and iterates on a skill's scripts.

  Invoked by `opencode-crafter` at `Phase:Scripts` (when needed) to POC and harden scripts in isolation.

- Plugin `opencode-snippets` — Hashtag-based snippet expansion (`#snippet`), with shell substitution, includes, forms, and skill rendering.

## Coding

- Skill `coder-generic` — General code rules for any language: structure, naming, types, comments, error handling.

  - Splits into `module-rules.md` (imported code) and `script-rules.md` (standalone executables).
  - Loaded before any language skill; every `coder-<lang>` requires it.

- Skills by language/tech: `coder-bash`, `coder-bats`, `coder-python`, `coder-pytest`, `coder-lua`, `coder-nix`, `coder-nushell`, `coder-rust`.

- Skill `coder-meta` — Rules for writing new `coder-<lang>` skills.

## Specs & planning

- Skill `write-spec` (multi-phased, has script) — Interactive methodology for drafting and refining specs, design docs, architecture notes, RFCs.

  - Phases: Discover → Explore (optional) → Draft → Review.
  - Delegates deep, pre-spec design maturation to `design-exploration`.

  Variants:
  * `write-spec-noninteractive` — non-interactive pass for tool-less chat contexts; no phase gates, questions batched at the end.
  * `write-spec-noninteractive-standalone` — self-contained (inlined) variant of the non-interactive one.

- Skill `design-exploration` (multi-phased) — Methodology for maturing a design before a spec exists.

  - Phases: Setup → Explore → Wrap.
  - Runs in single-topic or multi-topic mode.

  Used for `write-spec`'s optional `Phase:Explore` when the design is genuinely uncertain.

- Skill `plan-milestones` (multi-phased) — Plans, creates, and refines project milestones (`MILESTONES.md`).

  - Phases: Discover → Draft → Discuss → Finalize.

## Commits

- Skill `committer` (multi-phased) — Drafts a commit message from a diff, only when explicitly asked.

  - Phases: Setup → Analyse → Style → Draft → Commit.
  - Routes diff analysis through `explore-diff`; wraps with `check-line-width`.
  - Iterates the message with you, offering subject/body refinement suggestions.

- Skill `diff-to-commits` (multi-phased) — Interactive process to splits a diff (default to unstaged changes) into logical commits and drafts each message with user, one group at a time.

  - Phases: Explore → Group → Draft → Summary.
  - Uses `explore-diff` for analysis, then the `committer` skill for each message.

- Skill `check-line-width` (has script) — Checks line length / column overflow from a file or stdin; the only authority on wrapping.

  Used explicitly by `committer` to validate message wrapping, and relied on implicitly by `opencode-crafter` / `opencode-reviewer` when writing or reviewing artefacts (via `coder-generic`'s line-width rule).

- Agent `explore-diff` — Generic diff/patch explorer; defaults to a summary of concerns, but can be driven to return any structure the caller asks for.

  Used explicitly by `committer` (`Phase:Analyse`) and `diff-to-commits` (`Phase:Explore`) to analyse a diff without polluting shared context.

- Command `/commit` — **triggers `committer`**.
- Command `/bew-commit` — (alias of `/commit`, useful when `/commit` is hijacked by a repo).
- Command `/add-finished-and-commit` — **triggers `committer`**: draft a commit for the task just finished, scoped to its files.
- Command `/diff-to-commits` — **triggers `diff-to-commits`**.

## Handoff & session

- Skill `handoff` — Produces a structured handoff document from the session so another agent or human can continue in a fresh session.

  Variants:
  * `handoff-standalone` — self-contained, tool-less variant; skill refs become plain recommendations.

- Command `/handoff` — **triggers `handoff`**.

- Skill `opencode-reflect-friction` — Reviews session friction (main conversation + subagents) and suggests artefact improvements; only on explicit request.

- Command `/reflect-friction` — **triggers `opencode-reflect-friction`**.

## Writing & issues

- Skill `bew-communication-style` — Style reference for writing prose in bew's voice (PRs, issues, posts, emails, chat).
- Skill `bew-inline-callout-style` — Convention for inline callout markers in prose and artefact files; reference-only.
- Skill `draft-github-issue-pr` (multi-phased) — Drafts GitHub issues and PRs, conforming to the target repo's templates and guidelines in bew's voice.

  - Phases: Classify → ContribGuidelines → PreDraft → Draft → VerifyClaims → (IssueFirst) → Submit.
  - Layers the repo's required template/guideline items over the personal shapes (`for-pr` / `for-issue-feature` / `for-issue-bug`).
  - PR-centric: drafts an issue just-in-time only when the repo requires one before a PR.
  - Uses `bew-communication-style` for voice; delegates diff analysis to `explore-diff`.

- Skill `write-github-issue` — Legacy issue-only drafter, kept for comparison; superseded by `draft-github-issue-pr`.

  Uses `bew-communication-style` for voice and tone. Auto-trigger removed from its description.

- Skill `caveman` — Compressed communication mode; ~75% fewer tokens, full technical accuracy.

## Other Skills

- `agent-blocker` — Load on environment/runtime hard errors (missing command, version mismatch, permission/auth failure, unreachable network, independently broken tests, failed tool/subagent launch).
- `agent-stuck` — Load when a human decision or strategy change is needed; track consecutive identical failures, load at the third.
- `gh-read-file` — Read one explicitly referenced file from GitHub via the authenticated `gh` CLI.
- `git-track-new-file` — Load right after creating a file/dir so the `git_track_new_file` tool git-tracks it; companion to the local `git-track-new-file` plugin.
- `incremental-write` — Write structured files incrementally: skeleton first, then targeted edits per section.
- `karpathy-guidelines` — Behavioral guidelines to avoid overcomplication, keep changes surgical, surface assumptions.
- `read-man-page` (has script) — Token-efficient incremental man page reading via its `manq` script.
- `text-replace` — Bulk/mechanical search & replace and renames across files using `sd`; supports literal or regex.

## Other Commands

- `/why-you` — Reflect on the root cause of a decision, without acting.
- `/retitle` — Auto-retitle the current session from the conversation.
- `/dcp-compress-aggressive` — Aggressively shrink context by collapsing blocks into one lean summary.
- `/smarter-take-over-for-better-suggestions` — A smarter model takes over after a weaker model's suggestions.

## Other Plugins

- `git-track-new-file` (local) — Registers the `git_track_new_file` tool, which runs `git add -N` on new files/dirs, skipping gitignored paths, secrets, and `/tmp`.

  Companion skill `git-track-new-file` tells the agent when to call it.

## Important third-party plugins

- `@tarquinen/opencode-dcp` (package) — Dynamic Context Pruning: manages context to optimize tokens for long sessions.
- `opencode-snippets` (package) — Hashtag-based snippet expansion (`#snippet`); used heavily.

## Dotfiles-specific skills

Skills scoped to this dotfiles repo (under `<repo>/.agents/skills/`), not the global config:

- Skill `coder-lua-for-nvim` — Neovim Lua conventions for this repo's `nvim/lua/**`; requires `coder-generic` + `coder-lua`.
- Skill `nvim-plugin-dev` (has script) — Neovim plugin authoring under `nvim-myplugins/`; requires `coder-generic`, `coder-lua`, `coder-lua-for-nvim`.
- Skill `read-nvim-help` (has script) — Token-efficient incremental Neovim/Vim help reading via its `nvimq` script.

No dotfiles-specific agents or commands exist yet.
