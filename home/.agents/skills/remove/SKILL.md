---
name: remove
description: "Use when asked to remove, delete, drop, or strip something from code, docs, configuration, or any file. Remove it fully and leave no residue at the site."
---

# Clean removal

If the caller asks to remove something, remove it. Do not leave a trace at the removal site.

Follow these rules:

- Delete the item outright. Do not replace it with a shorter version. Do not add a note that says it was removed. Do not add a sentence that records the caller's suggestion.
- Do not add comments, doc lines, or log entries in the same location to explain the change.
- Do not keep a pointer to the removed item at its old location. If the information belongs somewhere else, put it in that place as normal content, not as a tombstone.
- If a reference elsewhere becomes false, update or delete that reference there. Do not add a note at the removal site about it.
- In the final answer to the caller, report what you removed. Do not report it in the file.

Apply these rules to code, comments, commands, documentation, configuration entries, and generated files.
