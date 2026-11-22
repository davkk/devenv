---
name: nvim-subagent
description: "Use when one agent must direct other agents in Neovim splits: spawn a worker, give it one task at a time, wait for its completion signal, and read its result."
disable-model-invocation: true
---

# Nvim subagents

You are the orchestrator. A worker is an agent in its own nvim split. It stays open between turns and keeps its context. You give it one task at a time. Transport mechanics live in `nvim-control`; this skill adds the worker protocol. Everything below is harness-agnostic: it works for any command given to `spawn`.

## Setup

Spawn a worker with the command your harness provides, and give it a name so you never have to track buffer numbers:

```bash
buf=$(nvimctl spawn --name w1 <your-agent-command>)
```

`spawn` prints the buffer number and nothing else; it does not send a prompt. The name is recorded in `$DONE/names/`, and every buffer-taking command accepts either a name or a numeric buffer. Use the name from here on:

```bash
nvimctl task w1 ...
nvimctl wait w1
```

## Turn loop (preferred: named worker + @file task)

1. Spawn: `buf=$(nvimctl spawn --name w1 <your-agent-command>)`.
2. Write the task to a file, then send it: `nvimctl task w1 @/tmp/task-w1.md`. (`--file /tmp/task-w1.md` is equivalent.) The CLI reads the file, so there is no shell quoting and no giant inline paste.
3. Wait: `nvimctl wait w1`. It prints `done` (plus the result path), `idle`, `exit N`, or `timeout`.
4. On `done`, read the verbatim result: `nvimctl result w1`. Only the worker's `nvimctl done` ends a turn.
5. Send the next task, or `stop` the worker when finished.

Inline text still works: `nvimctl task w1 "Do X. Exact steps: ..."`. The completion step below is appended in both cases.

## Protocol details

- **Guards.** `task` refuses when the worker is busy or has an unread result. Run `wait` first. This keeps one task in flight and prevents two completions.
- **Safety.** `task` rejects text whose first character is `!`, and waits (bounded) until the terminal's foreground process is the spawned command rather than a shell. It then waits for the screen to stop changing for a few samples before typing, so a TUI that is still loading cannot drop the prompt. It never types into a shell prompt. If it dies with "not ready" or "screen never settled", `stop` and respawn; if the screen shows shell errors, the worker was typed into too early.
- **Completion step.** `task` appends:
  > You are a worker: do this task, ask nothing, run no memo commands.
  >
  > When this is finished, end with a short report of what you did, then run exactly this in your shell and stop:
  > `nvimctl done <buffer>`

  A worker can persist a structured result with `nvimctl done <buf> "TEXT..."` or `nvimctl done <buf> --file PATH`; it is stored verbatim at `$DONE/<buf>.result`.

## Other commands

- `peek w1` — report state (`ready`, `busy`, `done`, `exit N`) without consuming the `done` marker. `wait --keep w1` does the same.
- `result w1` — print the stored result verbatim. `wait` prints its path but leaves the file intact.
- `list` — print each worker's name, buffer, command and state.
- `doctor` — print the resolved nvim socket, whether it is live, the anchor window, whether your terminal is hosted in that instance, current workers, and any problems with next steps.
- `read w1` — print the visible screen (wrapped at split width); for a long result, have the worker write a file instead.
- `input w1 'y\r'` — raw-byte escape hatch for questions or interrupts. It does not touch turn state, so never use it to start a normal task (the completion step would be skipped).
- `stop w1` — close the split and kill the worker; only for cleanup.

## Outcomes

- `done`: read the result, then decide whether to send another task.
- `idle`: the last turn was already collected and no new task is pending; send a task or `stop` the worker.
- `exit N`: the worker died. `wait` includes the last ~10 screen lines; read them, then spawn a new worker. Do not task a dead buffer.
- `timeout`: still running. `peek`/`read` to see if it is working; `wait` again, interrupt with `input`, or `stop`.

## Rules

- Prefer named workers and `@file` tasks for every turn; reserve inline text for short prompts.
- Keep at most two workers alive at once. Use `list`, and stop a finished worker before spawning a third.
- Make all decisions yourself. Give exact instructions; do not ask a worker to judge, review, choose, or rank.
- One task per worker at a time. Reuse a finished worker when the next task builds on its context; for unrelated work, stop and spawn fresh. There is no reset command.
- `spawn` opens splits in the caller's own window (detected from process ancestry), so a worker's children stay there across tab changes. There is no window env var; a worker is given the host instance's `NVIM`. Run `nvimctl doctor` if something looks wrong.
- Do not use `--remote-send`; it types into the live user interface. Run `nvimctl --help` for the full command list.
