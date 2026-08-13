# Quality Criteria — Commands

1. **Arguments** — Are all arguments documented (`$1`, `$ARGUMENTS`)?
   Is there semantic mentioned in command description if important/required?
2. **Shell injection** — Is shell injection used correctly?
3. **Context isolation** — Should `subtask: true` isolate context? (losing any prior discussion)
4. **Error handling** — Is there guidance on what to do when command fails or produces unexpected output?
5. **Skill trigger** — If command's sole purpose is to trigger a skill:
   - Is it a thin launcher? (surfaces `$ARGUMENTS` raw, then loads skill — nothing else)
   - Is there any extraction or interpretation of `$ARGUMENTS` in the command body? If yes, flag it — extraction belongs in the skill.
