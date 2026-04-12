---
id: submission-checklist
name: submission-checklist
version: 0.1.0
description: |-
  Pre-submission checklist runner. Validates manuscript completeness,
  formatting compliance, figure quality, citation integrity, and
  generates a pass/fail report.
stages: ["finalization"]
tools: ["read_file", "write_file", "search_project"]
primaryIntent: quality-assurance
intents: ["quality-assurance", "submission"]
domains: ["biology", "academic-writing"]
keywords: ["submission-checklist", "checklist", "submission", "validation", "pre-submit"]
source: custom
status: stub
resourceFlags:
  hasReferences: true
  hasScripts: false
  hasTemplates: false
  hasAssets: false
---

# submission-checklist

> **Status**: stub — to be implemented in Phase 3.

## Purpose

Run a comprehensive pre-submission check:
- All sections present and in `final` state
- Figure legends match figure_registry
- All citations resolved in references.bib
- Journal formatting requirements met
- Cover letter drafted

## Trigger

- `/omp:check`

## Owner Agent

**Formatter** / **Reviewer**
