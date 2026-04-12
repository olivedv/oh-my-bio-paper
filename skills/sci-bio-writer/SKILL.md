---
id: sci-bio-writer
name: sci-bio-writer
version: 0.1.0
description: |-
  Core writing engine for biological research papers. Dynamically reads
  style_profile.md for project-specific style rules, enforces fungal genetics
  conventions, and supports paragraph-level interactive drafting.
stages: ["drafting"]
tools: ["read_file", "write_file", "search_project"]
primaryIntent: writing
intents: ["writing", "drafting"]
domains: ["biology", "fungal-genetics", "academic-writing"]
keywords: ["sci-bio-writer", "writer", "section", "drafting", "interactive", "paragraph"]
source: custom
status: stub
resourceFlags:
  hasReferences: true
  hasScripts: false
  hasTemplates: false
  hasAssets: false
---

# sci-bio-writer

> **Status**: stub — to be implemented in Phase 2.

## Purpose

Write paper sections (Methods → Results → Discussion → Introduction) following:
1. Hard-coded domain conventions (`references/fungal-genetics-conventions.md`)
2. Dynamic style rules from `style_profile.md` (read-only)
3. Journal constraints from `journal_spec.md`
4. Interactive Writing Protocol (pre-announce → draft → feedback → refine)

## Trigger

- `/omp:write <section>` with optional `--mode autonomous|collaborative|dense`

## Owner Agent

**Writer** (reads style_profile.md, writes paper/sections/*.tex)
