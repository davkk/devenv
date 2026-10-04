---
name: qf
description: >
  vim quickfix format spec + writer for /tmp/qf. Standalone skill for
  producing structured bug/gap/issue lists in vim errorformat.
---

<format>
Each line must follow this exact format:

  {file}:{line}:{col}: {severity}: {description}

Fields:
- file        - most specific filename; logical target name if file doesn't exist yet; never "."
- line        - best-known line number; use 1 if unknown
- col         - best-known column; use 1 if not applicable
- severity    - one of: error, note, warning
- description - be descriptive about the entry

Matches vim errorformat:
  %E%f:%l:%c: error: %m
  %I%f:%l:%c: note: %m
  %W%f:%l:%c: warning: %m

Examples:
  app/auth.py:1:1: error: JWT middleware missing - all routes unprotected
  README.md:87:1: note: add config reference table for all env vars
  main.go:42:12: warning: handle error return from os.Open
  task.md:1:1: note: no outstanding items - all requested work appears complete
</format>

<write_file>
Use bash to write the file:

  cat > /tmp/qf << 'QFEOF'
  app/auth.py:1:1: warning: JWT middleware missing - all routes unprotected
  QFEOF
</write_file>
