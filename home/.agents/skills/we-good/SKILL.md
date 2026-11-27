---
name: we-good
description: Use when the user asks "are we good", after a long session, or before new work on the same task. Compares the discussion record with the current codebase. Reports what the user does not know, what the user is wrong about, and what is not yet agreed.
---

# We good

Answer one question: are we still on the same page about this work?
Compare the record of what we discussed with the code as it is now.
Report only the differences that change a decision.

## Inputs

- Your memory. Run `~/.optmem/memo wake`, then recall and zoom the entries that name this project.
- This conversation and earlier sessions. Use what the user said.
- Notes in the project or in `~/notes`, when they exist.
- The code, the working tree, and the diff.

The code is the fact. Memory, notes, and conversation are claims about the code.
When a claim disagrees with the code, report the difference. Say what changed.

## Steps

1. Name the work. State in one sentence what you think the user is building or changing.
2. Gather the discussion record. Read the relevant memory entries and what the user said. List the decisions, the assumptions, and the open questions.
3. Read the current state. Open the files that the work touches. Read the diff and the recent commits. Run no tests for this skill.
4. Compare each item from step 2 with step 3. Sort each difference into one group: missing, wrong, or open.
5. Report in this order. Say what changed since the last sync. Say what the user does not know. Say what the user believes that the code contradicts. Say what you must decide together.

## Rules

- Do not delegate this work. The discussion record lives in this session and in your memory. A subagent does not have it.
- Cite the file and line, or the memory number, for every finding. No citation, no finding.
- Separate fact from inference. Say "the code does X" for a fact. Say "I think you expect Y" for an inference.
- Challenge a weak assumption. If a plan rests on a belief that the code does not support, say so.
- Report only differences that change a decision. Skip trivia.
- If no difference matters, say so in one sentence.

## Output

Load the `simple-english` skill. Reply in prose. No headers, no lists.
Lead with the verdict: we are aligned, or we are not.
Then give each finding in one short paragraph. Name the gap, the contradiction, or the open question, and cite its source.
If a decision is needed, end with one question.
