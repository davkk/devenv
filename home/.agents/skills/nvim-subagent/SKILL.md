---
name: nvim-subagent
description: "Use when one agent must direct other agents in Neovim splits: spawn a worker, give it one task at a time, wait for its completion signal, and read its result."
disable-model-invocation: true
---

# Nvim subagents

You are the orchestrator. A worker is an agent in its own nvim split. The worker stays open between turns and keeps its context. You give it one task at a time. Transport mechanics live in `nvim-control`; this skill adds the worker protocol.

## Setup

Use the spawn line for your own harness. If you are not sure, run `echo $AI_AGENT; ps -o comm= -p $PPID` and ask the human when that does not settle it.

| Harness  | Spawn line                      |
| -------- | ------------------------------- |
| opencode | `buf=$(nvimctl spawn opencode)` |
| pi       | `buf=$(nvimctl spawn pi)`       |
| codex    | `buf=$(nvimctl spawn codex)`    |
| claude   | `buf=$(nvimctl spawn claude)`   |

`spawn` prints the buffer number and nothing else. It does not send a prompt.

## Turn loop

1. Spawn a worker: `buf=$(nvimctl spawn opencode)`.
2. Send one task: `nvimctl task "$buf" "Do X. Exact steps: ..."`.
3. Wait: `nvimctl wait "$buf"`. It prints `done`, `exit N`, or `timeout`.
4. On `done`, read the result: `nvimctl read "$buf"`.
5. Send the next task, or stop the worker when you are done with it.

`task` refuses when the worker is busy or has an unread result. Run `wait` first. This is deliberate: it keeps one task in flight and stops a queued prompt from producing two completions.

**Task text safety.** `task` writes raw bytes into the split's terminal. Long prompts, and any prompt that starts with `!`, have landed in the split's bash shell instead of the agent TUI, where bash executed them as commands. `task` now rejects a leading `!` and waits for the TUI's `ctrl+p commands` footer before typing (override with `NVIMCTL_READY_PATTERN`, empty disables the wait). Still prefer a short pointer task and verify it landed:

```bash
nvimctl task "$buf" "Read /tmp/opencode/my-task.md and do exactly what it says."
nvimctl read "$buf" | head       # confirm it is in the agent input, not a shell
```

If the screen shows bash errors (`/bin/bash: line ...: ... command not found`), the worker was typed into before its TUI was ready: `stop` it and respawn.

`task` appends this completion step to every task:

> You are a worker: do this task, ask nothing, run no memo commands.
>
> When this is finished, end with a short report of what you did, then run exactly this in your shell and stop:
> `nvimctl done <buffer>`

The worker's `nvimctl done` is the only completion signal. `wait` returns `done` only when it sees that marker.

## Input

`input` is the escape hatch. It sends raw bytes and does not touch turn state, so it is safe while a task is in flight.

```bash
nvimctl input "$buf" 'y\r'       # answer a question
nvimctl input "$buf" '\003'      # interrupt
nvimctl input "$buf" '/new\r'    # a harness slash command, when you mean it
```

Do not use `input` to start a normal task. Use `task`, or the completion protocol is skipped.

## Outcomes

- `done`: read the result, then decide whether to send another task.
- `exit N`: the worker died. Read the screen once, then spawn a new worker. Do not try to task a dead buffer.
- `timeout`: the worker is still running. Read the screen. If it is working, run `wait` again. If it is stuck, use `input` to interrupt, or `stop` it.
- An unread result or a busy worker makes `task` refuse. Resolve it with `wait` or `stop`, not by bypassing the guard.

## Rules

- Keep at most two workers alive at once. Run `nvimctl list` to count them, and stop a finished worker before you spawn a third.
- Make all decisions yourself. Give exact instructions. Do not ask a worker to judge, review, choose, or rank.
- One task per worker at a time. `task` enforces this; do not bypass it with `input`.
- Reuse a finished worker as-is when the next task builds on its context. For an unrelated task, stop it and spawn a new one. There is no reset command.
- Do not stop or close a worker unless you are cleaning up. A closed split kills the worker.
- `read` prints the visible screen, wrapped at split width. For a long result, tell the worker to write a file and read that file.
- `opencode` starts the full TUI. The TUI has no model flag; it uses the global `opencode.json` model, which is already DeepSeek V4.1 Flash Free. Do not pass `-m` to the TUI.
- `spawn` opens splits in the caller's own window, so a worker's children stay in that window when you change tabs. An anchored worker inherits `NVIM` and `NVIMCTL_WIN` from its host split, so it drives the right instance (`echo $NVIM` shows the socket); if `$NVIM` is unset here, `nvimctl` resolves the socket from the caller's terminal.
- Do not use `--remote-send`. It types into the live user interface.
- Run `nvimctl --help` for the command list.
