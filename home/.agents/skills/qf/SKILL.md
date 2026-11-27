---
name: qf
description: Use when user wants your output as a vim quickfix list.
---

<format>
Each line must follow this exact format:

  {file}:{line}:{col}: {description}

Fields:
- file: the most specific filename. If the file does not exist yet, use the logical target name. Do not set the filename to ".".
- line: the best-known line number. If the line is unknown, use 1.
- col: the best-known column. If no column applies, use 1.
- description: starts with the severity word (error, warning, note). Then give the entry.

Examples:
  app/auth.py:1:1: warning: JWT middleware missing - all routes unprotected
  README.md:87:1: note: add configuration reference table for all env vars
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
