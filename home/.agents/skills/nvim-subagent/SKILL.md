---
name: nvim-subagent
description: "Use when one agent must direct other agents in Neovim: send a named worker one task at a time and read its result."
---

# Nvim subagents

A worker is an agent in a named nvim terminal. The script owns spawning, reuse, readiness, turn state and the worker limit. Its commands are transport names; this skill gives them their agent meaning.

- `nvimctl ask NAME @FILE [-- CMD...]` — send a task file and wait. `CMD` starts `NAME` only when it is dead. Calling it again with the same name is a follow-up; the worker keeps its context. The first output line is `done` with the result, `exit N`, or `timeout` followed by screen lines.
- `nvimctl input NAME TEXT...` — send raw bytes to a running worker without touching turn state. Use `'\003'` to interrupt or text to steer it. Escapes: `\r \n \t \e \xHH \0NNN`, `\\`. Never use it to start a task.
- `nvimctl stop NAME` — kill the worker when the job is finished or the worker is stuck.

The worker ends each turn with `nvimctl done`. The worker reads its own name from the environment.

Write each task to a file: name the files, state the goal, give exact steps, and make it self-contained. Make all decisions yourself; never ask a worker to judge, review, choose or rank.

For parallel work, run two `ask` commands in the background in one shell. For recovery, `nvimctl wait NAME` collects after a timeout and `nvimctl read NAME` prints the screen.
