---
name: nvim-control
description: "Use when you need to run a command in a Neovim split and drive it: spawn a terminal, send raw input, read the screen, wait for exit, and clean up. Transport only."
---

# Neovim control

`nvimctl` runs a command in a split inside the host Neovim and talks to that Neovim over the socket it resolves: `$NVIM` when it names a live server, otherwise the instance that hosts the terminal `nvimctl` runs in. It knows nothing about the command: a split is a terminal, not an agent. Use this skill for transport. The worker protocol lives in `nvim-subagent`.

Every command is a shell command, so any agent with a shell can run it.

## Commands

| Command | Result |
| --- | --- |
| `nvimctl spawn CMD...` | split, run `CMD`, print the new buffer number |
| `nvimctl input BUF TEXT...` | send raw bytes, no newline added |
| `nvimctl read BUF` | print what the split shows now |
| `nvimctl wait BUF [SECS]` | print `done`, `idle`, `exit N`, or `timeout` |
| `nvimctl stop BUF` | close the split and kill the process |
| `nvimctl list` | print each worker's name, buffer, command and state (`ready`, `busy`, `done`, `exit`) |

`nvimctl` also has `task` and `done` for the worker protocol. See `nvim-subagent` before you use them. A plain command never calls `done`, so `wait` on it returns `exit N` or `timeout`.

## Input

`input` sends exactly the bytes you give it. It does not add `\r`. It expands backslash escapes in the text, so include the newline yourself:

```bash
nvimctl input "$buf" 'y\r'          # answer yes and submit
nvimctl input "$buf" '\003'         # Ctrl-C
nvimctl input "$buf" '\e'           # Escape
nvimctl input "$buf" 'hello\r'      # submit a line
```

Escapes: `\r`, `\n`, `\t`, `\e`, `\xHH`, and `\0NNN`. Use `\\` for a literal backslash.

## Reading and waiting

- `read` prints the visible screen. Lines wrap at split width, not logical lines. For long output, make the command write a file and read that file.
- `wait` polls every 3 seconds, default 300 seconds. `done` requires a `nvimctl done BUF` call. `exit N` exposes the process exit code. `timeout` means the process is still alive.
- `wait` consumes the `done` marker. One marker means one turn. Calling `wait` again on a task worker with no new task prints `idle` at once instead of blocking to timeout.
- `list` is recovery only: use it to find a buffer number you lost. It is not a status command.

## Spawning

```bash
buf=$(nvimctl spawn bash)
nvimctl input "$buf" 'echo hello\r'
nvimctl read "$buf"
nvimctl stop "$buf"
```

`spawn` always splits the caller's own window, detected from the caller's process ancestry, so switching tabs won't move a worker's child splits. There is no window env var to set or inherit.

The socket is `$NVIM` when it names a live server; when `$NVIM` is unset or points nowhere, `nvimctl` finds the instance that hosts the terminal it runs in, so splits never open in the wrong instance. `nvimctl` refuses when `$NVIM` names a different live instance than the one running the caller's terminal. Workers spawned by `spawn` are given the host instance's `NVIM` so they drive the same instance.

## Rules

- Do not use `--remote-send`. It types into the live user interface.
- `stop` is cleanup, not pause. A closed split kills the process.
- One Neovim can host many splits. Use `list` before spawning a duplicate when you are recovering.
