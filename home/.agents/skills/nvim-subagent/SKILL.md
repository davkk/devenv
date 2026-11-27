---
name: nvim-subagent
description: "Use when one agent must direct other agents in Neovim: send a named worker one task at a time and read its result."
---

# Nvim subagents

A worker is an agent in a named nvim terminal. Run `nvimctl --help` to learn the commands and how to run them.

A harness is the agent program that runs this session. Read its name from `$AI_AGENT`. Use that harness for each worker. The worker reads files, edits files, and runs shell commands in that harness. Do not start a different agent CLI.

## Rules

The worker ends each turn with `nvimctl done`. The worker reads its own name from the environment. Send a short task as inline text. Write a long task to a file to avoid shell quoting. State the goal and give exact steps. Make each task self-contained. Make all decisions yourself. Never ask a worker to judge, review, choose, or rank.
