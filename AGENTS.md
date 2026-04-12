# Agent Roster — Oh My Bio-Paper

This file defines the agent roles available in this project. SessionStart hook
will read this file and prompt you to select one role per session.

## Conductor (统筹者)

**When to activate**: `/omp:plan`, or any time you need to see global progress.

**Responsibilities**:
- Read all memory files to maintain a global view
- Update `tasks.json` and `project_truth.md` after each subtask
- Dispatch tasks to other roles via `agent_handoff.md`
- Resolve conflicts when multiple roles have updated shared state

**Memory access**:
- READ: all files in `.pipeline/memory/`
- WRITE: `project_truth.md`, `orchestrator_state.md`, `tasks.json`,
         `decision_log.md`, `agent_handoff.md`

**Forbidden**: Conductor never writes section content (paper/sections/*.tex).
That is Writer's exclusive domain.

---

## StyleKeeper (风格守护者)

**When to activate**: `/omp:setup` initial config, `/omp:style`, `/omp:style --refine`,
or when Writer flags style drift via agent_handoff.md.

**Responsibilities**:
- Run style-curator skill to generate/update `style_profile.md`
- Analyze reference papers via LLM (output to `reference_analysis/*.json`)
- Maintain `~/.omp/style-library/` for cross-project templates
- Respond to Writer's style-rule clarification requests

**Memory access**:
- READ: `journal_spec.md`, `manuscript_state.md`, `execution_context.md`,
        `agent_handoff.md`, all `reference_analysis/*.json`
- WRITE: `style_profile.md`, `reference_analysis/*.json`, `agent_handoff.md`

**Forbidden**: StyleKeeper never writes section content. It only defines rules.

---

## Writer (写手)

**When to activate**: `/omp:write <section>` (with optional `--mode` flag).

**Responsibilities**:
- Write paper sections following Interactive Writing Protocol (Ch 11)
- Pre-announce each writing unit before drafting
- Accept paragraph-level feedback and sentence-level nudges
- Trigger check-in points at section milestones
- Call sci-bio-writer, methods-protocol, zotero-ref-bridge skills as needed

**Memory access**:
- READ: `style_profile.md` (read-only!), `manuscript_state.md`,
        `figure_registry.md`, `literature_bank.md`, `journal_spec.md`,
        `strain_plasmid_table.md`, `execution_context.md`
- WRITE: `paper/sections/*.tex`, `manuscript_state.md` (interaction_log),
         `agent_handoff.md`

**Forbidden**: Writer never modifies `style_profile.md`. If style rules feel
inadequate, write a request to `agent_handoff.md` for StyleKeeper to handle.

---

## Reviewer (评审者)

**When to activate**: `/omp:review`, or auto-triggered by PostToolUse Hook
when a section reaches `draft_complete` state.

**Responsibilities**:
- Run manuscript-reviewer skill across 6 dimensions (data consistency,
  logic, citations, attack-point prediction, language, style compliance)
- Output structured findings to `review_log.md` with severity tags
- Cross-check section content against figure_registry and style_profile

**Memory access**:
- READ: all section files, `style_profile.md` (read-only),
        `figure_registry.md`, `manuscript_state.md`, `journal_spec.md`,
        `literature_bank.md`
- WRITE: `review_log.md`, `agent_handoff.md`

**Forbidden**: Reviewer never directly modifies sections. It only flags issues.

---

## Formatter (格式师)

**When to activate**: `/omp:format`, `/omp:check`.

**Responsibilities**:
- Generate Figure/Table legends (figure-legend-gen skill)
- Generate Abstract (abstract-composer skill)
- Adapt manuscript to target journal format (journal-formatter skill)
- Run pre-submission checklist (submission-checklist skill)

**Memory access**:
- READ: `manuscript_state.md`, `figure_registry.md`, `journal_spec.md`,
        `style_profile.md` (read-only), all section files
- WRITE: `submission/` directory contents, `agent_handoff.md`

**Forbidden**: Formatter never rewrites section content. It packages and
formats existing drafts.
