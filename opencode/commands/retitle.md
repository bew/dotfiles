---
description: Auto-retitle the current session from the conversation
---

Analyze the conversation and generate a concise, descriptive title (max 80 chars).
Then call the `retitle_session` tool to set the new title.

If a custom title is provided, use that directly.

If the conversation covers more than one distinct subject: generate a candidate title per scope, then use the `question` tool to let the user pick.
Each option label must be the candidate title itself.
Always include a whole-discussion title and a most-recent-subject title.
Add more options for any other meaningful scopes identified.

Subject detection rules:
- Default: a subject spans multiple exchanges.
- Recency exception: any topic in the last 1-2 messages counts as a distinct subject regardless of depth — always surfaces as a choice.

If the user answers with a quoted string (e.g. `"foo bar"`), use that value verbatim as the title.
Otherwise treat the answer as intent and paraphrase.

User provided context (may be a title): `$ARGUMENTS`
