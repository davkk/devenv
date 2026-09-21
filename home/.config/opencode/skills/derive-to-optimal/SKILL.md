---
name: derive-to-optimal
description: >
  Derive algorithm solutions from brute force to straightforward to optimal.
  Use when explaining LeetCode, algorithms, data structures, complexity
  tradeoffs, or when user asks where a solution comes from, wants step-by-step
  derivation, or wants to see how the optimized version strips what is not
  needed.
---

# Derive to Optimal

Never lead with the optimal solution. Derive it.

## Order

1. **Brute force first.** State the naive definition plainly with its cost.
2. **Correct but wasteful version.** Make it obviously correct by spending
   memory or recomputation: precomputed arrays, hash maps with full counts,
   recursion without memo, sorting every time, rescanning. Show full code.
   This is the honest version.
3. **Strip what you do not need.** Point at one concrete redundancy and
   remove it. Each optimization must map to one observation:
   - recomputing the same range info → precompute once, then keep a running value
   - recounting / researching → remember in a map or set
   - resorting → sort once and sweep
   - rescanning for a neighbor or extremum → remember candidates
   - overlapping subproblems → memoize or tabulate
   - rechecking both ends → process the side whose result is already forced

   If two optimizations exist, apply one at a time and re-trace.

## Tracing rules

- Never skip steps. Table the loop state every iteration: cursors and
  values, remembered state, decision taken, work added.
- Explain every branch in words, not just the code condition.
- Distinguish cursor position from accumulated memory. State both every time.
- Explain starts and stops: why this initial state, why the loop ends,
  what invariant walks toward the answer.

## Diagrams

- Decide symbols per problem, always include a legend, and keep symbols
  visually distinct.
- One diagram per key state in a monospaced block, with position markers
  aligned under columns.
- Show progression: start (no result), partial progress, final.

## Tone

- Short, plain, factual. No praise, no superlatives.
- If the user says "still don't see it", drop the proof and redo the
  smallest input where every branch moves.
