---
name: how
description: Use for "how does X work", code walkthroughs before changing something, and placement questions. Use it for ownership and layering questions. Explains subsystem architecture, runtime flow, and onboarding mental models. Use why for motivation.
---

# How

If exploration is necessary, use the nvim-subagent skill to explore the codebase. Answer "how does X work?" questions. Write explanations at the level of a senior engineer who is new to the subsystem. Give enough detail to build a working mental model. Do not give so much detail that the text reads like annotated source code.

Every spawn is a Task for the nvim-subagent skill. For each Task, pick the model, the reasoning level, and the speed. Use fast or standard speed for the job.

## 1. Assess complexity

If the scope is ambiguous, state your interpretation and explore. The user can redirect you.

- Simple (one module, one utility, or one narrow question): do not spawn explorers. Spawn one explainer. Let it explore and explain in one pass. Go to step 4.
- Complex (a subsystem that spans files or services, a cross-cutting feature, or a full architecture overview): go to step 2.

When in doubt, take the Simple path.

## 2. Explore (complex only)

Split the question into 2 to 4 angles. Each angle is a distinct slice of the subsystem. Spawn all explorers in one message. Fill in the angle for each explorer.

## 3. Synthesize (complex only)

After all explorers return, spawn one explainer. Give it every explorer's findings.

## 4. Present

Present the explainer's output. You can make light edits for clarity or for context from the conversation. Do not rewrite it substantially.

## Output format

If a section does not apply, drop it. The sections are Overview, Key Concepts, How It Works, Where Things Live, and Gotchas.
