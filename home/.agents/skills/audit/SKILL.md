---
name: audit
hidden: true
description: >
  User-invoked-only read-only audit that produces a quickfix list of what is
  STILL MISSING or INCOMPLETE after a set of changes. The model must NEVER
  auto-activate this skill. It only runs when explicitly invoked by the user.
  The list serves as additional context for human-in-the-loop review.
  Load the qf skill for output format.
---

<behavior>
Do not edit files. Do not explain fixes. Do not suggest solutions.
Do NOT auto-activate this skill. Only run when explicitly requested by the
user (e.g., /audit, "run the audit", etc).
Run the checklist, observe current state, then produce the quickfix list only.
The list is supplementary human-in-the-loop context, not a replacement for
the main response.
</behavior>

<when-to-run>
This skill is user-invoked-only. The model must:
- NEVER auto-activate this after its own responses
- Only run when explicitly asked by the user
- The content below applies only when the user requests an audit

When invoked, check:
- Only meaningful after a set of code changes have been made, committed, or discussed
- Only meaningful when the model has explained a plan of changes or produced code
- The audit must be relevant to the actual work that was done or planned
</when-to-run>

<rules>
1. Read-only audit - never list completed work; only what is absent, broken, stubbed, skipped, or deferred
2. Trace to prompt - every entry maps to something requested that was not fully delivered
3. No vague entries - Bad: "needs improvement"; Good: "add error handling for null input in parse_config"
4. One entry per line - no sub-bullets
5. The list is supplementary context for human review, not a replacement for the response
6. Load qf skill to produce the output in the correct format
</rules>
