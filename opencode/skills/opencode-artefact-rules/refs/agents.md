# Quality Criteria — Agents

1. **Permissions** — Are permissions explicitly set for every relevant tool?
2. **Mode** — Is `mode` correct? (`primary` / `subagent` / `all`)
3. **Visibility** — Should it be `hidden`?
4. **Prompt quality** — Is system prompt body direct and free of hedging?
5. **Step structure** — If agent has phases or steps: named steps/phases required when: 3+ top-level phases or steps, 3+ steps within any phase, or any step references another (even if fewer than 3 items).
   Named steps: definition `1. **Name**` (bold), reference `*Name*` (italic).
   Named phases: definition ``## Phase N: `Phase:Name` — description`` header, reference `` `Phase:Name` ``.
6. **Scope** — Is agent's responsibility single and clearly bounded?
7. **Self-containment** — Does agent reference any external file (companion files, refs/, scripts/)?
   Agents are single `.md` file — no companion files allowed. Agents may use skills if allowed.

