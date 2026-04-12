---
id: zotero-ref-bridge
name: zotero-ref-bridge
version: 0.1.0
description: |-
  Bridge between Claude Code and Zotero via cookjohn/zotero-mcp.
  Provides high-level citation functions: cite, batch_cite, check_missing,
  fetch_reference_paper. Syncs references.bib with Zotero library.
stages: ["preparation", "drafting", "finalization"]
tools: ["read_file", "write_file", "mcp"]
primaryIntent: reference-management
intents: ["reference-management", "citation"]
domains: ["biology", "academic-writing"]
keywords: ["zotero-ref-bridge", "zotero", "citation", "reference", "bib", "mcp"]
source: custom
status: stub
resourceFlags:
  hasReferences: false
  hasScripts: true
  hasTemplates: false
  hasAssets: false
---

# zotero-ref-bridge

> **Status**: stub — to be implemented in Phase 2.

## Purpose

Wrap cookjohn/zotero-mcp tools into high-level citation functions:
- `cite(query)` — find and insert a single citation
- `batch_cite(queries[])` — batch insert
- `check_missing()` — find uncited references or missing bib entries
- `fetch_reference_paper(key)` — retrieve full text for style analysis

## Trigger

- Called by Writer during drafting
- `/omp:check` for citation audit

## Owner Agent

**Writer** (primary), **Reviewer** (for audit)
