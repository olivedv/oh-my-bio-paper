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
status: active
resourceFlags:
  hasReferences: false
  hasScripts: true
  hasTemplates: false
  hasAssets: false
---

# version-guardian

> **Status**: Phase 1 basic functions implemented.

## Scripts

### auto-commit.sh
Auto-commit with 30-second debounce and smart commit messages.
- `--debounce` — Wait 30s, merge with subsequent writes
- `--type <type>` — Override commit type
- `--scope <scope>` — Override commit scope
- `--flush` — Force commit any pending changes

### smart-message.py
Intelligent commit message generation and history tools.
- Default: analyze staged changes, output suggested commit message
- `--history [N]` — Show last N commits in readable tabular format
- `--history N --section <name>` — Filter by section
- `--history N --type <type>` — Filter by commit type
- `--diff <commit1> <commit2>` — Human-readable diff description

### install-hooks.sh
Install Git hooks: pre-push guard + safety checks.

## Commit Message Convention

```
<type>(<scope>): <subject>
```

Types: draft, revise, polish, format, review, figure, ref, meta, config, checkpoint, interact
Scopes: methods, results, discussion, introduction, abstract, figures, refs, all

## Slash Commands

- `/omp:history` → calls smart-message.py --history
- `/omp:rollback` → interactive rollback with pre-rollback tag
- `/omp:snapshot` → creates named git tag
- `/omp:diff` → calls smart-message.py --diff
