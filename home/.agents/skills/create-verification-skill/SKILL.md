---
name: create-verification-skill
description: "Use when a repo has no scripted way to prove that user-facing behavior works. Use when the user asks for a verification skill, a control skill for this repo, or an end-to-end setup that proves the app works. Generates a project-local skill that launches the real app, drives it as a user does, and captures evidence for any language, framework, or platform."
---

# Create a verification skill

Every serious project needs a scripted way to drive the real app and prove behavior. Launch the app. Exercise a feature the way a user does. Capture evidence. `create-verification-skill` writes that harness as a project-local skill at `.agents/skills/verify-<app>/`. It tailors the result to the repo. Write the output for the next agent, not for a human. An agent that has never seen the app will read it cold, mid-task.

Keep the generated skill harness agnostic. Drive the app through shell commands, HTTP, a browser over CDP, or a PTY. Any agent with a shell can run those. Do not rely on slash commands, a specific skill tool, or editor-specific paths inside the generated skill. Name the operation, not the UI that triggers it.

## 1. Interview the repo, not the user

Answer these questions from the codebase. Ask the caller only what you cannot observe:

- Surface: what does a user touch? A web UI, a CLI/TUI, a desktop app, an API, a mobile app, or a library. A repo can have several. Pick the primary surface. Note the rest.
- Run: how does the app start locally? Prefer the documented dev command in the repo (package scripts, Makefile, README quickstart). Note ports, env vars, seed data, and auth.
- Drive: how can an agent interact with it programmatically? Use existing harnesses first. Look for Playwright or Cypress specs, expect scripts, PTY helpers, curl-able endpoints, and a debug port. Then pick a generic recipe. Use browser automation over CDP for web and Electron. Use a PTY for CLI and TUI. Use plain HTTP for services.
- Observe: what evidence can you capture? Screenshots, terminal transcripts, response bodies, logs, exit codes, and database state.
- Isolate: can two instances run side by side? Make sure that ports, data dirs, and profiles do not conflict. If they cannot, say so in the generated skill. Refuse to drive a shared instance twice. That protects the caller's session.

If the checkout does not build or start as-is, fix that first. Otherwise, report the problem precisely. Do this before you generate the skill. A skill that you write against a broken base teaches wrong steps. If an irrelevant missing asset blocks startup, the generated skill can create it. A static dir that the API never serves is one example. A sample configuration file is another. Mark the asset as verification scaffolding. Remove it in cleanup.

## 2. Generate the skill

Write `.agents/skills/verify-<app>/SKILL.md`. Both opencode and pi discover skills there, in the project and in ancestor directories. Do not write to a harness-specific directory. Keep the generated skill self-contained. Include `SKILL.md` and a `features/` directory. Add helper scripts only when a shell one-liner is not enough. Do not add a `references/` tree. Do not add external links that a cold reader has to chase.

The frontmatter must carry `name: verify-<app>`. Add a description that names the app, the surface, and the trigger. Without valid frontmatter, the generated skill never registers.

Then write these sections. Ground each one in what the interview found. Leave no placeholders:

- Launch: give the exact command that starts the app for verification. Say how to make sure that it is ready. Use a log line or a prompt. Launch must reach a usable state from an empty data dir. Include migrations and seed data. Ready means usable, not just that a process answers. A database health probe can pass while its init scripts still run. Include teardown. If the app is a short-lived CLI or TUI, no server stays alive. Build the binary or install dependencies once. Then start each drive in its own isolated PTY or terminal split.
- Doctor: give one read-only probe that answers "is this instance worth driving?" Make sure that the process is up, the version or build is right, we own the port, and auth is valid. An agent runs this probe first whenever anything looks off.
- Drive: give the harness recipe with real selectors and commands from this repo, not examples. Prefer stable handles (ARIA labels, data attributes, prompt strings, route paths) over coordinates and tab order.
- Evidence: name what to capture for a proof and where it goes. State the proof standards. Exercise the real user path, not internal setters or test-only endpoints. Capture the action and the resulting state, not only the final screen. Make sure that side effects are correct. Also make sure that files written, rows inserted, and messages sent are correct. Mock only where a production boundary already isolates the external system. If the path is a dry run or test mode, make sure that it skips steps it claims to skip. Observe files, network, and git refs. Do not trust the name of the mode. Some dry runs still touch the network or open a browser.
- Cleanup: tell how to tear down instances that the run created. Do not kill by process name. Kill what you started. Cleanup removes instances and scratch state. It never removes the evidence. Proof artifacts survive teardown in a location that the skill names.
- Helpers: make each script that the generated skill ships executable. Show its invocation in the skill body. A helper that the reader must reverse engineer is not a helper.

## 3. Seed the feature map

Create `.agents/skills/verify-<app>/features/README.md`. Create one file per user-facing feature that you can identify. Aim for the top 3 to 5 features to start. Find them in routes, commands, menus, or documentation. The README is an index. Give each feature a name, one line, and a link to its file.

Each feature file answers four questions from the user's point of view. What is the feature? How does the user reach it? How does the harness drive it? What observable end state proves that it works? Use these four H2s:

```markdown
# <Feature>

## Sub-features

- <user-visible capability>

## How to get to it (user POV)

<steps a user follows, starting from launch>

## Driving it with <harness>

<real commands and selectors that exercise the path above>

## Gotchas

<preconditions, flaky steps, seed data gaps>
```

If the seed data lacks a precondition that a journey needs, the journey reports a failure. Put the reason in that feature's Gotchas. Do not weaken the journey to make it pass. The map is the maintained verification source in the repo. A proof that drives one convenient entry point is incomplete when the map lists other entry points.

Commit the generated skill with the repo. Then every agent and teammate gets the same path.

## 4. Prove the generated skill before handing it over

Run its own instructions end to end once. Launch the app. Run the doctor. Drive one mapped feature. Capture evidence. Clean up. One feature is enough. The map exists so later runs can cover the rest. After cleanup, make sure that the evidence still exists at the named location. A cleanup that eats the proof fails this step. Fix what fails. Run the generated cleanup after every failed iteration. Broken attempts must not strand processes and ports. A generated skill that you never executed is a draft, not a deliverable.

If you proved it in a stand-in for the real target, list every setup step that the stand-in did. A container can replace a fresh VM. A local stack can replace a remote one. The target will not do those steps. Those steps stay unverified until a run on the real target covers them.

## 5. Keep the map honest

The generated skill is only as good as its feature files. If the app changes, update the affected feature file in the same change. A stale step is worse than a missing one. It fails without a message. Or it passes while it proves nothing.

For a repeatable upkeep pass, use the `maintain-verification-skill` skill. It updates the feature map and the drive steps when the app changes.
