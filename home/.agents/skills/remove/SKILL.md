---
name: remove
description: "Use when asked to remove, delete, drop, or strip something from code, docs, config, or any file. Remove it fully and leave no residue at the site."
---

# Clean removal

When the caller asks to remove something, remove it. Do not leave a trace at the removal site.

- Delete the item outright. Do not replace it with a shorter version, a note saying it was removed, or a sentence recording the caller's suggestion.
- Do not add comments, doc lines, or log entries in the same location to explain the change.
- Do not keep a pointer to the removed item where it used to be. If the information belongs somewhere else, put it in that place as normal content, not as a tombstone.
- If a reference elsewhere becomes false, update or delete that reference there. Do not add a note at the removal site about it.
- Report what was removed in the final answer to the caller, not in the file.

Apply this to code, comments, commands, docs, config entries, and generated files.
