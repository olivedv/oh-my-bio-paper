---
id: version-guardian
name: version-guardian
version: 0.1.0
description: |-
  Local Git-based version control for manuscript. Provides auto-commit
  with intelligent messages, human-readable history, interactive rollback,
  and named snapshot tags.
stages: ["preparation", "drafting", "finalization"]
tools: ["read_file", "write_file", "bash"]
primaryIntent: version-control
intents: ["version-control", "history", "rollback"]
domains: ["general"]
keywords: ["version-guardian", "git", "commit", "history", "rollback", "snapshot", "diff"]
source: custom
status: stub
resourceFlags:
  hasReferences: false
  hasScripts: true
  hasTemplates: false
  hasAssets: false
---

# version-guardian

> **Status**: stub — Phase 1 basic functions, Phase 3 advanced features.

## Purpose

Manage local Git versioning:
- Auto-commit with debounce (30s) and smart commit messages
- `/omp:history` — human-readable commit log with section/type filters
- `/omp:rollback` — interactive rollback (full or per-file)
- `/omp:snapshot` — create named tags (e.g., pre-submission, major-revision)
- `/omp:diff` — natural-language diff between versions

## Trigger

- Hook-based auto-commit after tool writes
- Slash commands: `/omp:history`, `/omp:rollback`, `/omp:snapshot`, `/omp:diff`

## Owner Agent

Available to all agents (utility skill)
