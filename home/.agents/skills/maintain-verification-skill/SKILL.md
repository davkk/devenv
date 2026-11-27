---
name: maintain-verification-skill
description: Use for a periodic pass that keeps a verification skill and its feature map current. Use for /maintain-verification-skill or when the user asks to audit the verify skill.
---

# Maintain a verification skill

A feature map rots when the app changes. Use this skill as the upkeep loop for a skill that `/create-verification-skill` generated. You can also use it for any project-local verification skill that has a feature map. Cover every feature from source. Drive every feature live. Do not rewrite every sentence.

## Outcomes

Pick one outcome. Say which one you picked.

1. clean: every feature got source coverage and live coverage. Nothing is worth shipping. Do not create a branch or a PR.
2. changed: one PR ships proven corrections to the documentation, the harness, or the map.
3. blocked: coverage did not finish or a proven fix did not ship safely. Say what blocked it.

## Edit scope

Edit only the verification skill's own directory. This includes its `SKILL.md`, `features/`, and harness scripts that it owns. Do not edit product code during a run. Doc drift means the map no longer matches the app. If the app no longer does what the map describes, treat it as doc drift or a product regression. Fix doc drift in the map. Report a product regression to the user. Do not hide it in the documentation.

## Pass

0. Locate the target. Find the verification skill to maintain. Look for a project-local skill with launch and drive sections and a feature map. It is usually `verify-*/` in the project skill folder, such as `.cursor/skills/`, `.claude/skills/`, `.pi/skills/`, or `.agents/skills/`. If several candidates exist, ask which one to use. If none exists, stop. Point the user at `/create-verification-skill`. Do not invent a target.

1. Clean the index. Read the feature map README. List its sibling files. Fix missing, extra, duplicate, or dead entries. Keep this step light. Do not generate an inventory.

2. Run the source wave. Use the nvim-subagent skill. Start one read-only worker per feature file. Run the workers at the same time. Each worker explains how the feature works from source. Each worker flags likely drift with citations. Each worker returns one short live-verification recipe. Workers do not drive the app. Workers do not edit files. Each worker returns a feature summary, source entry points, likely drift or none, and one recipe.

3. Reconcile the results. Make sure that every feature file has a summary. Merge overlapping recipes into as few app states as practical. Inspect a few cited drift claims. Do not re-prove clean claims. Sweep recent changes for user-facing surfaces missing from the map. Require a concrete source path before you call a surface missing.

4. Run the live pass. Do this even when the source looks clean. The coordinator drives every instance. Follow the launch model in the verification skill. Use one long-lived instance for a server or a UI. Use a fresh isolated session for each drive of a short-lived CLI. The verification skill decides, not this one. Exercise every feature at least once. Hold three invariants throughout the pass, whatever fails.

   - Doctor before the first drive. Doctor on each fresh session when sessions are the unit. Doctor again after any failed drive. If the doctor cannot see the failure, reset to a known state or relaunch. Do not hope that the state recovers.
   - Make sure that evidence captured so far survives every cleanup. Make sure that it is at its named location. Do not assume that it exists.
   - Do not let anything that a drive starts outlive that drive's usefulness. Clean failed-iteration residue whether the session is stuck, exited, or shared. For a shared instance, clean the residue, not the instance.

   If the doctor fails because the skill drifted, treat it as drift. Fix it within the edit scope. Retry once. Restart only what the fix invalidated. If the failure stays, call the pass blocked.

   If a feature cannot be reached, mark it verified-unreachable only with the concrete prerequisite and the route you attempted. Prerequisites include auth, entitlement, OS, and external state. If the map omits that prerequisite, treat it as drift. Re-drive any harness fix live before you ship it. Run final teardown after the last drive of the run. Include re-proofs. Make sure that nothing outlives the run. Keep the evidence.

5. Triage each finding. If the user-POV description is wrong or missing, treat it as doc drift. Fix it. If the harness cannot drive working behavior, treat it as a harness gap. Fix it. Use the same helpers rule as generation. Make scripts executable. Document the invocation in the skill body. If the app behavior is broken, record it for the user. Keep it out of this PR.

6. Ship or stop. For changed, create one PR with proven corrections. Re-read every changed file first. For clean or blocked, create no PR. Report the outcome and the coverage.

Keep short run notes in a scratch location. Record features covered, unreachable prerequisites, confirmed drift, and the outcome. Do not commit them.
