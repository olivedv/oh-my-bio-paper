---
id: journal-formatter
name: journal-formatter
version: 0.1.0
description: |-
  Adapts manuscript to target journal formatting requirements.
  Generates journal_spec.md during Preparation and applies formatting
  rules during Finalization.
stages: ["preparation", "finalization"]
tools: ["read_file", "write_file"]
primaryIntent: formatting
intents: ["formatting", "journal-adaptation"]
domains: ["biology", "academic-writing"]
keywords: ["journal-formatter", "journal", "format", "template", "submission"]
source: custom
status: stub
resourceFlags:
  hasReferences: true
  hasScripts: false
  hasTemplates: false
  hasAssets: false
---

# journal-formatter

> **Status**: stub — to be implemented in Phase 2.

## Purpose

1. During Preparation: generate `journal_spec.md` from journal template
2. During Finalization: reformat manuscript to meet journal requirements

## Trigger

- `/omp:setup` (generate journal_spec.md)
- `/omp:format --journal`

## Owner Agent

**Formatter**
