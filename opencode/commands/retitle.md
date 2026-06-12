---
description: Auto-retitle the current session from the conversation
---

Analyze conversation and generate concise, descriptive title (max 80 chars).
Then call `retitle_session` tool to set new title.

If custom title is provided, use it directly.

If conversation covers more than one distinct subject: generate candidate title per scope, then use `question` tool to let user pick.
Each option label must be candidate title itself.
Always include a whole-discussion title and a most-recent-subject title.
Add more options for any other meaningful scopes identified.

Subject detection rules:
- Default: subject spans multiple exchanges.
- Recency exception: any topic in last 1-2 messages counts as distinct subject regardless of depth — always surfaces as choice.

If user answers with quoted string (e.g. `"foo bar"`), use that value verbatim as title.
Otherwise treat answer as intent and paraphrase.

User provided context (may be a title): `$ARGUMENTS`
