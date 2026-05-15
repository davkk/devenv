---
name: qfaudit
description: >
  Always write a vim quickfix file (audit.qf) AND append its contents to the response
  at the end of every turn — no exceptions. This skill must trigger for ALL responses:
  code generation, file editing, explanations, plans, research, rewrites, refactors, and
  partial task completions. The quickfix list is a machine-readable audit trail of what is
  STILL MISSING or INCOMPLETE relative to fully satisfying the user's original prompt.
  It is never used to describe what was done; only what remains undone. The file must be
  written to disk so the user can load it in neovim with :cfile /tmp/audit.qf.
---

# Vim Quickfix Audit Trail

After every response you must do two things — in this order:

1. **Write** the quickfix entries to `/tmp/audit.qf` using `bash_tool`
2. **Append** the same entries inline in the response as a fenced `quickfix` block

Both steps are mandatory every turn. The file on disk is the primary deliverable;
the inline block is for readability.

---

## Quickfix Line Format

Each line in `audit.qf` must follow this exact format:

```
{file}:{line}:{col}:{type} {message}
```

This matches the neovim `errorformat` string `%f:%l:%c:%t\ %m` (see Neovim Setup below).

| Field    | Rules                                                                                          |
|----------|-----------------------------------------------------------------------------------------------|
| `file`   | Most specific filename applicable. Use the logical target name if the file doesn't exist yet. Never leave blank or use `.`. |
| `line`   | Best-known line number. Use `1` when the file doesn't exist yet or the line is unknown.       |
| `col`    | Best-known column. Use `0` when not applicable.                                               |
| `type`   | Single character followed by a space: `E ` (error/broken/missing required), `W ` (incomplete/risky), `I ` (optional/future) |
| `message`| One short imperative sentence. Start with a verb. No trailing period.                        |

Note the single space between `{type}` and `{message}` — this is required by the errorformat.

### Valid line examples

```
app/auth.py:1:0:E missing JWT middleware — all routes unprotected
README.md:87:0:W add config reference table for all env vars
main.go:42:12:W handle error return from os.Open
task.md:1:0:I no outstanding items — all requested work appears complete
```

---

## Writing the File

Use `bash_tool` to write `/tmp/audit.qf`. Overwrite it completely
each turn — do not append across turns.

```bash
cat > /tmp/audit.qf << 'EOF'
app/auth.py:1:0:E missing JWT middleware — all routes unprotected
README.md:87:0:W add config reference table for all env vars
EOF
```

If no filesystem tool is available, write the file using whatever file-creation
mechanism is accessible in the current environment. If no file tool is available at all,
note this prominently above the inline block so the user knows the file was not written.

---

## Rules

1. **Always fires.** No response is exempt. If the task is complete, write the
   "nothing missing" sentinel (see below) — do not skip the step.

2. **audit only.** Never list completed work. Only list what is absent, broken, stubbed,
   assumed, skipped, or deferred to a future turn.

3. **Trace to the prompt.** Every entry must map back to something the user's original
   request asked for (explicitly or implicitly) that was not fully delivered this turn.

4. **No vague entries.**
   Bad: `task.md:1:0:W needs improvement`
   Good: `task.md:1:0:W add error handling for null input in parse_config`

5. **One entry per line.** No multi-line messages. No sub-bullets inside the block.

6. **No self-editing.** Do not go back and silently fix output to shrink the list.
   Entries disappear naturally when the underlying gap is addressed in a later turn.

7. **Severity discipline**
   - `E` — Output will fail, is factually wrong, or a required deliverable is absent
   - `W` — Output works but a clearly requested feature is missing or fragile
   - `I` — Optional enhancement, edge case, or stretch goal the user hinted at

---

## Nothing Missing Sentinel

If — and only if — the response fully addresses every part of the user's prompt with no
known audit, stubs, or omissions, write exactly this (one line, file on disk + inline):

```
task.md:1:0:I no outstanding items — all requested work appears complete
```

Do not use this as a default. Use it only when you can genuinely defend it.

---

## Examples

### Example A — Partial code generation

User asked for a full REST API with auth, CRUD endpoints, and tests.
Agent wrote models and two routes but skipped auth and tests.

File written to `/tmp/audit.qf`:
```
app/routes/auth.py:1:0:E auth routes not written — login and token refresh missing
app/routes/users.py:45:0:W DELETE /users/:id endpoint stubbed but not implemented
app/tests/test_routes.py:1:0:E test file not created — all endpoints untested
app/middleware/auth.py:1:0:E JWT validation middleware absent — routes are unprotected
app/routes/items.py:1:0:W pagination not implemented on GET /items as requested
```

---

### Example B — Docs task mostly done

User asked for README with install steps, usage examples, config reference, and
troubleshooting. Agent wrote everything except the config reference table.

```
README.md:87:0:W config reference table not written — all env vars undocumented
README.md:1:0:I add Contributing section — user mentioned open-source intent
```

---

### Example C — Explanation only, no files written

User asked for explanation of RAFT consensus AND a working Python demo.
Agent explained the algorithm but wrote no code.

```
raft_demo.py:1:0:E Python demo not written — only explanation was provided
raft_demo.py:1:0:W leader election logic unimplemented
raft_demo.py:1:0:W log replication step not demonstrated
raft_demo.py:1:0:I add ASCII visualization the user mentioned wanting
```

---

### Example D — Task complete

User asked for a single haiku about rain. Agent wrote it.

```
task.md:1:0:I no outstanding items — all requested work appears complete
```

---

## Response Placement

Structure of every response:

```
[response content]

---
```quickfix
{entries identical to audit.qf}
```
```

The fenced `quickfix` block is always the very last thing in the response.
Nothing follows it — no closing remarks, no "let me know if you need anything".
