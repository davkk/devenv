---
name: audit
disable-model-invocation: true
description: Use to perform an audit that produces a quickfix list of what is STILL MISSING or INCOMPLETE after a set of changes.
---

Run the checklist, observe current state, then produce the quickfix list only.
The list is supplementary human-in-the-loop context, not a replacement for
the main response.

Do not edit files. Do not explain fixes. Do not suggest solutions.

The audit must be relevant to the actual work that was done or planned

Always load qf skill to produce the output in the correct format.

1. Read-only audit - list what is absent, broken, stubbed, skipped, or deferred
2. Trace to prompt - every entry maps to something requested that was not fully delivered
3. No vague entries - Bad: "needs improvement"; Good: "add error handling for null input in parse_config"
4. Point to the exact location in the codebase - no general file pointers/entries.
