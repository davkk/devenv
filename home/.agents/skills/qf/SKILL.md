---
name: qf
description: Use when user wants your output as a vim quickfix list.
---

<format>
Each line must follow this exact format:

  {file}:{line}:{col}: {description}

Fields:
- file         - most specific filename; logical target name if file doesn't exist yet; never "."
- line         - best-known line number; use 1 if unknown
- col          - best-known column; use 1 if not applicable
- description  - begins with the severity word (error, warning, note), then the entry

Examples:
  app/auth.py:1:1: warning: JWT middleware missing - all routes unprotected
  README.md:87:1: note: add config reference table for all env vars
  main.go:42:12: error: handle error return from os.Open
</format>

<path>
  /tmp/qf
</path>

<write_file>
Use bash to write the file:

  cat > /tmp/qf << 'QFEOF'
  app/auth.py:1:1: warning: JWT middleware missing - all routes unprotected
  QFEOF
</write_file>

<load>
  cfile /tmp/qf
</load>
