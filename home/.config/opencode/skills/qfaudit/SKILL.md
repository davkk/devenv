---
name: qfaudit
description: >
  After every response, run the checklist, then write a vim quickfix file (/tmp/audit.qf)
  listing what is STILL MISSING or INCOMPLETE. Never edit files. Never explain fixes. Only produce the quickfix list.
---

<behavior>
Do not edit files. Do not explain fixes. Do not suggest solutions.
Run the checklist, observe the current state, then write the quickfix list only.
</behavior>

<checklist>
You must complete every item before producing output:
- Inspect and understand all changed code
- Run: git diff
- Run: git diff --staged
- Check commits not yet pushed to remote
- Using pending and committed changes, determine what is left to complete the work item described in user prompt
- Carefully review all changes against the user prompt before responding
- Report any bugs found
- If tests exist, run them
</checklist>

<format>
Each line in /tmp/audit.qf must follow this exact format:

  {file}:{line}:{col}:{description}

Fields:
- file        — most specific filename; logical target name if file doesn't exist yet; never "."
- line        — best-known line number; use 1 if unknown
- col         — best-known column; use 0 if not applicable
- description — one short imperative sentence; start with a verb; no trailing period

Examples:
  app/auth.py:1:0:JWT middleware missing — all routes unprotected
  README.md:87:0:add config reference table for all env vars
  main.go:42:12:handle error return from os.Open
  task.md:1:0:no outstanding items — all requested work appears complete
</format>

<rules>
1. Read-only audit — never list completed work; only what is absent, broken, stubbed, skipped, or deferred
2. Always fires — no response is exempt, including explanations and plans
3. Trace to prompt — every entry maps to something requested that was not fully delivered
4. No vague entries — Bad: "needs improvement" · Good: "add error handling for null input in parse_config"
5. One entry per line — no sub-bullets
6. Overwrite /tmp/audit.qf completely each turn — never append across turns
</rules>

<sentinel>
Only when every part of the prompt is fully addressed, write exactly:
  task.md:1:0:no outstanding items — all requested work appears complete
</sentinel>

<write_file>
Use bash_tool to write the file:

  cat > /tmp/audit.qf << 'QFEOF'
  app/auth.py:1:0:JWT middleware missing — all routes unprotected
  QFEOF
</write_file>

<response_structure>
Write /tmp/audit.qf silently via bash_tool. Do not mention it. Do not repeat its contents in the response.
</response_structure>
