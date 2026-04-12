---
id: manuscript-reviewer
name: manuscript-reviewer
version: 0.1.0
description: |-
  Reviews manuscript across 6 dimensions: data consistency, logic flow,
  citation completeness, attack-point prediction, language quality, and
  style compliance (against style_profile.md).
stages: ["drafting", "finalization"]
tools: ["read_file", "write_file", "search_project"]
primaryIntent: review
intents: ["review", "quality-assurance"]
domains: ["biology", "academic-writing"]
keywords: ["manuscript-reviewer", "review", "consistency", "style-compliance", "citation-audit"]
source: custom
status: stub
resourceFlags:
  hasReferences: false
  hasScripts: false
  hasTemplates: false
  hasAssets: false
---

# manuscript-reviewer

> **Status**: stub — to be implemented in Phase 3.

## Purpose

Run 6-dimensional review:
1. Data consistency (figures vs text)
2. Logic flow (argument coherence)
3. Citation completeness
4. Attack-point prediction (reviewer objections)
5. Language quality
6. Style compliance (against style_profile.md)

## Trigger

- `/omp:review`
- Auto-triggered when a section reaches `draft_complete` state

## Owner Agent

**Reviewer**
