---
name: no-comments
description: Use when you want comments cleaned up. Deletes the ones that carry no information, puts the doubtful ones on a quickfix list for the caller to decide, and flags code that needs reshaping instead of prose.
---

# No comments

Delete the comments that carry no information. Send the doubtful ones to a quickfix list. A doubtful comment is never yours to delete.

## Scope

Use the caller's files or diff. Otherwise use the working tree diff against the base branch, default `main`.

## Delete

- Narration, and comments that restate the line below.
- Section banners, and commented-out code.
- Workaround sermons: comments that explain why a workaround exists, when the workaround is in our own code. Delete the comment and flag the symbol.
- `IMPORTANT`, `do not remove`, `too risky`, `fine for now`, and long justifications, once the claim is traced and refuted, or once the claim turns out to be about our own code.
- Any comment the code beside it contradicts.
- Suppressions whose rule catches real bugs or protects correctness or safety. Delete the suppression and flag the symbol it protected.

Never shorten a comment to save it.

## Keep

- Legal or license headers.
- Behavior forced by an external dependency, platform, vendor, or protocol we cannot reshape.
- `// prettier-ignore`.
- Lint suppressions whose rule is faulty, pedantic, or style only.
- Doc comments that define a public API contract.
- Issue or RFC links that explain a constraint code cannot express.

A keep needs proof, not a claim. Read the nearby code, trace the named symbol or call, and run the `why` skill when the history matters. Without proof it is not a keep, it is a doubt.

## Doubt

Leave the comment in place and report it.

Severity:

- `warning` - you would delete it if the caller agrees.
- `note` - you would keep it, but cannot prove the exception.

## Review list

Produce a quickfix list following the `qf` skill. One line per doubtful comment, with the reason and what it would take to settle it.

## Fix

Only act on a confident verdict. For a comment about our own code, make the smallest change in scope that removes the reason for the comment: delete the dead path, drop the unused parameter, rename the symbol, add the type, call the real API. Do not add guards that only hide the symptom.

If the root cause sits outside the scope, land the smallest in-scope fix and leave the rest open.

## Report

Name the files touched, the deletion count, the review list size, the comments kept with the exception that saved them, the fixes made, and what stays open.
