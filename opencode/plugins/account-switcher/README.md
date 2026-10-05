# account-switcher plugin

Global OpenCode V2 TUI plugin: show the selected account of the current provider and switch it.
The accounts of the provider selected in the prompt box are shown, the active one highlighted.
Clicking an account activates it.

## Behaviour

- The line reads `Selected account: perso pro`, each account on a dark-gray chip, the active one highlighted.
- Only the accounts of the currently selected provider are shown.
- The line renders only when that provider has 2+ accounts.
- Clicking an account calls `credential.activate` and refreshes the line.
- The line refreshes on `credential.updated`, `credential.switched`, and `integration.updated`.

## Slots

- `session.composer.top` — the line shown while composing, above the input.
- `home.footer.status` — the same line on the home screen.

## Notes

- Account names come from the local credential label (`CredentialEntry.label`).
  The Console org name/email is a different identity and is not shown.
- Credentials may all carry the label `default`, so entries can look identical until they are labelled.
- The credential secret (`CredentialEntry.value`) is never read.
- The `sidebar.content` and `sidebar.footer` slots are not used: `cli.json` hides the sidebar.
- Layout: discovered automatically from the global plugins root (`~/.config/opencode/plugins/`).
  `index.ts` is the server entry (no behavior); `tui.tsx` is the TUI entry.
