---
name: audit
description: Use to perform an audit that produces a quickfix list of what is STILL MISSING or INCOMPLETE after a set of changes.
---

Run the checklist. Observe the current state. Produce the quickfix list only.
The list gives extra context to the human. It does not replace the main response.

Do not edit files. Do not explain fixes. Do not suggest solutions.

The audit must cover the work that the caller did or planned.

Before you produce the output, load the `qf` skill. Use its format.

Follow these rules:

1. Audit in read-only mode. List each item that is absent, broken, stubbed, skipped, or deferred.
2. Trace each entry to the prompt. Map each entry to a requested item that was not fully delivered.
3. Reject vague entries. Bad: "needs improvement". Good: "add error handling for null input in parse_config".
4. Point to the exact location in the codebase. Do not use general file pointers or entries.
