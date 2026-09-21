---
name: audit
description: >
  After every response, run the checklist, then produce a quickfix list of
  what is STILL MISSING or INCOMPLETE. Never edit files. Never explain fixes.
---

<behavior>
Do not edit files. Do not explain fixes. Do not suggest solutions.
Run the checklist, observe current state, then produce the quickfix list only
(load the qf skill for format and write instructions).
</behavior>

<checklist>
You must complete every item before producing output:
- Inspect and understand all changed code
- Review unstaged changes (git diff)
- Review staged changes (git diff --staged)
- Check commits not yet pushed (git status, git log @{u}..HEAD)
- Using pending and committed changes, determine what is left to complete the work item described in user prompt
- Carefully review all changes against the user prompt before responding
- Record bugs and gaps as quickfix entries only, never as prose explanations
</checklist>

<rules>
1. Read-only audit - never list completed work; only what is absent, broken, stubbed, skipped, or deferred
2. Always fires - no response is exempt, including explanations and plans
3. Trace to prompt - every entry maps to something requested that was not fully delivered
4. No vague entries - Bad: "needs improvement"; Good: "add error handling for null input in parse_config"
5. One entry per line - no sub-bullets
</rules>
