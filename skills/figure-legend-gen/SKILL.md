---
id: figure-legend-gen
name: figure-legend-gen
version: 0.1.0
description: |-
  Generates structured figure legends from figure_registry.md metadata.
  Supports multi-panel figures, statistical annotations, and journal-specific
  formatting requirements.
stages: ["finalization"]
tools: ["read_file", "write_file"]
primaryIntent: formatting
intents: ["formatting", "figure-legend"]
domains: ["biology", "academic-writing"]
keywords: ["figure-legend-gen", "figure", "legend", "caption", "panel"]
source: custom
status: stub
resourceFlags:
  hasReferences: true
  hasScripts: false
  hasTemplates: false
  hasAssets: false
---

# figure-legend-gen

> **Status**: stub — to be implemented in Phase 3.

## Purpose

Generate figure legends by reading `figure_registry.md` entries and applying
journal-specific formatting from `journal_spec.md`.

## Trigger

- `/omp:format --legends`

## Owner Agent

**Formatter**
