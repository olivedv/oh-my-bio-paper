---
id: methods-protocol
name: methods-protocol
version: 0.1.0
description: |-
  Generates Materials & Methods sections from built-in experiment protocol
  templates and strain_plasmid_table.md data. Covers common fungal biology
  techniques: CRISPR knockout, RNA-seq, RT-qPCR, Western blot, transformation.
stages: ["drafting"]
tools: ["read_file", "write_file"]
primaryIntent: writing
intents: ["writing", "methods"]
domains: ["biology", "fungal-genetics"]
keywords: ["methods-protocol", "methods", "protocol", "CRISPR", "RNA-seq", "qPCR", "strain"]
source: custom
status: stub
resourceFlags:
  hasReferences: true
  hasScripts: false
  hasTemplates: false
  hasAssets: false
---

# methods-protocol

> **Status**: stub — to be implemented in Phase 2.

## Purpose

Write M&M sections by combining:
1. Built-in method templates (`references/method-templates/`)
2. Project-specific strain/plasmid data from `strain_plasmid_table.md`
3. Journal formatting from `journal_spec.md`

## Trigger

- `/omp:write methods`

## Owner Agent

**Writer**
