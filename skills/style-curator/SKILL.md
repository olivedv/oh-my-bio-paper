---
id: style-curator
name: style-curator
version: 0.1.0
description: |-
  Meta-skill for generating and maintaining project-level style profiles.
  Conducts interactive style interviews, analyzes reference papers via LLM,
  and produces style_profile.md that governs all writing output.
stages: ["preparation", "drafting"]
tools: ["read_file", "write_file", "search_project"]
primaryIntent: style-management
intents: ["style-management", "preparation"]
domains: ["biology", "academic-writing"]
keywords: ["style-curator", "style", "profile", "interview", "reference-analysis", "journal-preset"]
source: custom
status: stub
resourceFlags:
  hasReferences: true
  hasScripts: false
  hasTemplates: false
  hasAssets: false
---

# style-curator

> **Status**: stub — to be implemented in Phase 2.

## Purpose

Generate and maintain a project-level style profile (`style_profile.md`) by:
1. Running an interactive style interview with the user
2. Analyzing reference papers via LLM (output to `reference_analysis/*.json`)
3. Merging journal presets with user preferences

## Trigger

- `/omp:setup` (initial generation)
- `/omp:style` (re-run or adjust)
- `/omp:style --refine` (iterate based on completed sections)
- `/omp:style --from-template <name>` (inherit from style library)

## Owner Agent

**StyleKeeper** (exclusive write access to `style_profile.md`)
