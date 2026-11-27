---
name: why
description: Use for "why does X work this way", "why we picked Y", design rationale, regressions, postmortems, or data-backed thresholds. Queries each evidence category (tags file, source control, long-form docs, error tracking) in parallel, then returns a cited read on decisions and tradeoffs. Use how for runtime behavior.
---

# Why

Investigate the motivation and intent behind code. The companion `how` skill answers what the code does and how it works. The `why` skill answers what forces shaped it.

For each Task for the nvim-subagent skill, pick the model, the reasoning level, and the speed. Use fast or standard speed for the job.

Investigators must not write anything.

Stay inside the repository that owns the target. Never read, search, or spawn investigators in the user's other projects, even to look for precedent, habit, or similar patterns. A developer's other repos are not evidence about this one. If a cross-project comparison genuinely helps, ask first. Wait for a yes.

## Operating Posture

Operate as a careful, cautious, and precise investigator. Be honest about what you know and what you infer.

## Step 1. Understand the Target and the Question

The target is usually a chunk of code, a pattern, a feature, or a named design decision. The question is usually a design rationale or a tradeoff. It can also be a motivating edge case, an external constraint, dead code, or a broad history sweep.

If the target is vague, make your best guess from the conversation. A vague target has no clear referent. "Why do we do it this way?" is an example. Use open files, recent edits, the cursor location, and the last topic. State your interpretation in a few words. If your interpretation is wrong, the user can redirect you. Then proceed.

## Step 2. Establish the Code Anchor

Before spawning investigators, build the seed context inline. Include file paths and line ranges. Include key symbols, which are functions, classes, and constants. Include the last few commits that touch the target. Run `git blame -L <start>,<end> <file>` for last-touch commits. Run `git log --follow -p -- <file>` for full history with patches through renames. Run `git log --oneline -20 -- <file>` for recent commits with PR numbers visible. Send this anchor to every investigator and to the synthesizer.

## Step 3. Spawn Parallel Investigators

Default to the full parallel investigation. The goal is a complete coverage map, not a minimal one. Document the null result. Do not skip the search.

## Step 5. Present

Present the synthesizer's output to the user. You can make light edits for clarity or add context from the conversation. Do not rewrite the confidence language.

## Output Format

Use these sections: The Question, The Code in Question, What We Found, What We Can Reasonably Infer. Add Competing Hypotheses, What We Don't Know, Sources Consulted, and Confidence Summary. Adapt as needed. Keep the confidence separation intact. Keep Sources Consulted as one line per investigator. Include the investigators that returned nothing or were skipped. Give the reason for each.

If the user asks `why` before a change to this code, convert the lineage findings into a constraint set. Use four groups: Preserve, Change, Avoid, Risk. Put the set after Sources Consulted. Use it to plan the change.

## Common Failure Modes to Avoid

- Recency bias. Do not assume that the most recent commit is authoritative. The current shape is often the result of many earlier decisions. Trace back.
- Scope creep into other repositories. Do not search sibling projects for precedent or for "how it is usually done". Read only the repo that owns the target.
