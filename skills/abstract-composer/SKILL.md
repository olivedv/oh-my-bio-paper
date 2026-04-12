---
id: abstract-composer
name: abstract-composer
version: 0.1.0
description: |-
  Generates structured abstracts from completed manuscript sections.
  Respects journal word limits and style_profile.md preferences.
stages: ["finalization"]
tools: ["read_file", "write_file"]
primaryIntent: writing
intents: ["writing", "abstract"]
domains: ["biology", "academic-writing"]
keywords: ["abstract-composer", "abstract", "summary", "structured-abstract"]
source: custom
status: stub
resourceFlags:
  hasReferences: false
  hasScripts: false
  hasTemplates: false
  hasAssets: false
---

# abstract-composer

> **Status**: stub — to be implemented in Phase 3.

## Purpose

Generate a structured abstract by synthesizing all completed sections,
respecting journal word limits from `journal_spec.md` and style from
`style_profile.md`.

## Trigger

- `/omp:format --abstract`

## Owner Agent

**Formatter**
