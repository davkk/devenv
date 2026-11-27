---
name: no-comments
description: Use when you want comments cleaned up. Delete the ones that carry no information. Put doubtful ones on a quickfix list for the caller. Flag code that needs reshaping instead of prose.
---

# No comments

Delete the comments that carry no information. Send the doubtful ones to a quickfix list. A doubtful comment is never yours to delete.

## Scope

If the caller names files or a diff, use them. Otherwise, use the working tree diff against the base branch. The default base branch is `main`.

## Delete

Delete these comments:

- Narration that restates the line below.
- Section banners and commented-out code.
- Workaround sermons that explain why a workaround exists. If the workaround is in our own code, delete the comment and flag the symbol.
- `IMPORTANT`, `do not remove`, `too risky`, `fine for now`, and long justifications. If you trace and refute the claim, delete the comment. If the claim concerns our own code, delete the comment.
- Any comment that the code beside it contradicts.
- Suppressions whose rule catches real bugs or protects correctness or safety. Delete the suppression. Flag the symbol that it protected.

Do not shorten a comment to save it.

## Keep

Keep these comments:

- Legal or license headers.
- Behavior that an external dependency, platform, vendor, or protocol forces. We cannot reshape that behavior.
- `// prettier-ignore`.
- Lint suppressions whose rule is faulty, pedantic, or style only.
- Doc comments that define a public API contract.
- Issue or RFC links that explain a constraint that code cannot express.

A keep needs proof, not a claim. Read the nearby code. Trace the named symbol or call. If the history matters, run the `why` skill. Without proof, the comment is a doubt, not a keep.

## Doubt

Leave the comment in place and report it.

Severity:

- `warning`: delete the comment if the caller agrees.
- `note`: keep the comment. You cannot prove the exception.

## Review list

Follow the `qf` skill. Produce a quickfix list with one line per doubtful comment. Give the reason. State what settles the doubt.

## Fix

If you have a confident verdict, act. If the comment concerns our own code, make the smallest change in scope that removes the reason for the comment. Delete the dead path. Drop the unused parameter. Rename the symbol. Add the type. Call the real API. Do not add guards that only hide the symptom.

If the root cause sits outside the scope, land the smallest in-scope fix. Leave the rest open.

## Report

Name the files that you touched. Give the deletion count. Give the review list size. Name the comments that you kept and the exception that saved each one. Name the fixes. State what stays open.
