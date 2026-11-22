---
name: create-verification-skill
description: "Use when a repo has no scripted way to prove that user-facing behavior works, or when the user asks for a verification skill, a control skill for this repo, or an end-to-end setup that proves the app works. Generates a project-local skill that launches the real app, drives it the way a user does, and captures evidence, for any language, framework, or platform."
---

# Create a verification skill

Every serious project needs a scripted way to drive the real app and prove behavior: launch it, exercise a feature the way a user would, and capture evidence. This skill generates that as a project-local skill at `.agents/skills/verify-<app>/`, tailored to the repo. Write the output for the next agent, not for a human. It will be read cold, mid-task, by an agent that has never seen the app.

Keep the generated skill harness agnostic. Drive the app through shell commands, HTTP, a browser over CDP, or a PTY, which any agent with a shell can run. Do not rely on slash commands, a specific skill tool, or editor-specific paths inside the generated skill. Name the operation, not the UI that triggers it.

## 1. Interview the repo, not the user

Answer these from the codebase, and ask the user only what you cannot observe:

- **Surface:** what does a user actually touch? A web UI, a CLI/TUI, a desktop app, an API, a mobile app, a library? A repo can have several. Pick the primary one and note the rest.
- **Run:** how does the app start locally? Prefer the repo's own documented dev command (package scripts, Makefile, README quickstart). Note ports, env vars, seed data, and auth.
- **Drive:** how can an agent interact with it programmatically? Existing harnesses first: Playwright or Cypress specs, expect scripts, PTY helpers, curl-able endpoints, a debug port. Only then pick a generic recipe: browser automation over CDP for web and Electron, a PTY for CLI and TUI (or the host's terminal control skill, such as `nvim-control`, when one is available), plain HTTP for services.
- **Observe:** what evidence can be captured? Screenshots, terminal transcripts, response bodies, logs, exit codes, database state.
- **Isolate:** can two instances run side by side (ports, data dirs, profiles)? If not, say so in the generated skill. Refusing to double-drive a shared instance beats corrupting the user's session.

If the checkout does not build or start as-is, fix that first, or report it precisely, before generating. A skill written against a broken base teaches wrong steps. When an irrelevant missing asset blocks startup (a static dir the API never serves, a sample config), the generated skill may create it, clearly marked as verification scaffolding, and remove it in cleanup.

## 2. Generate the skill

Write `.agents/skills/verify-<app>/SKILL.md`. Both opencode and pi discover skills there, in the project and in ancestor directories. Do not write to a harness-specific directory. Keep the skill self-contained: `SKILL.md`, a `features/` directory, and helper scripts only when a shell one-liner is not enough. No `references/` tree and no external links that a cold reader has to chase.

The frontmatter must carry `name: verify-<app>` and a description that names the app, the surface, and when to reach for it. Without valid frontmatter the skill never registers.

Then write these sections, each grounded in what the interview actually found, with no placeholders left:

- **Launch:** the exact command that starts the app for verification, and how to tell it is ready (a log line, a prompt). Launch must reach a usable state from an empty data dir, including migrations and seed data. Ready means usable, not just that a process answers. A database health check can pass while its init scripts are still running. Include teardown. For a short-lived CLI or TUI there is no server to keep alive: launch means build the binary or install dependencies once, then start each drive in its own isolated PTY or terminal split.
- **Doctor:** one read-only check that answers "is this instance worth driving?" Process up, right version or build, port owned by us, auth valid. An agent runs this first whenever anything looks off.
- **Drive:** the harness recipe with real selectors and commands from this repo, not examples. Prefer stable handles (ARIA labels, data attributes, prompt strings, route paths) over coordinates and tab order.
- **Evidence:** what to capture for a proof, and where it goes. State the proof standards: exercise the real user path, not internal setters or test-only endpoints; capture the action and the resulting state, not only the final screen; verify side effects (files written, rows inserted, messages sent) alongside what is visible; mock only where a production boundary already isolates the external system. When the safe path is a dry run or test mode, verify what it actually skips by observing files, network, and git refs rather than trusting its name. Some dry runs still touch the network or open a browser.
- **Cleanup:** how to tear down instances that the run created. Never kill by process name. Kill what you started. Cleanup removes instances and scratch state, never the evidence. Proof artifacts survive teardown, in a location the skill names.
- **Helpers:** any script the skill ships is executable, and its invocation appears in the skill body. A helper that the reader has to reverse engineer is not a helper.

## 3. Seed the feature map

Create `.agents/skills/verify-<app>/features/README.md` plus one file per user-facing feature that you can identify. Aim for the top 3 to 5 to start, from routes, commands, menus, or docs. The README is an index: feature name, one line, and a link to its file.

Each feature file answers, from the user's point of view: what the feature is, how to reach it, how to drive it with the harness, and what observable end state proves it works. Use these four H2s:

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

If the seed data lacks a precondition that a journey needs, the journey reports a failure and the reason goes in that feature's Gotchas. Never weaken the journey to make it pass. The map is the repo's maintained verification source. A proof that drives one convenient entry point is incomplete when the map lists others.

Commit the generated skill with the repo so every agent and teammate gets the same path.

## 4. Prove the generated skill before handing it over

Run its own instructions end to end once: launch, doctor, drive one mapped feature, capture evidence, clean up. One feature is enough. The map exists so later runs can cover the rest. After cleanup, confirm that the evidence still exists at the named location. A cleanup that eats the proof fails this step. Fix what fails, and run the generated cleanup after every failed iteration too, so broken attempts do not strand processes and ports. A generated skill that was never executed is a draft, not a deliverable.

If you proved it in a stand-in for the real target (a container in place of a fresh VM, a local stack in place of a remote one), list every setup step that the stand-in did and the target will not. Those steps stay unverified until a run on the real target covers them.

## 5. Keep the map honest

The generated skill is only as good as its feature files. When the app changes, update the affected feature file in the same change. A stale step is worse than a missing one. It fails silently, or it passes while proving nothing.

For a repeatable upkeep pass, use the `maintain-verification-skill` skill: it updates the feature map and the drive steps when the app changes.
