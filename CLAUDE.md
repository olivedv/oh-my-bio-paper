# Oh My Bio-Paper — Project Context

## 项目类型
这是一个湿实验生物学论文写作项目，非 ML/计算类。
所有数据和图表已就绪，当前阶段是论文撰写。

## 研究领域
真菌分子生物学，模式菌 Talaromyces marneffei。
常涉及：CRISPR-Cas9 基因敲除、转录调控、RNA-seq、荧光显微镜。

## 写作规范
- 基因名斜体（*acuD*），蛋白名正体（AcuD）
- 菌名首次全称斜体后续缩写（*Talaromyces marneffei* → *T. marneffei*）
- Methods 用过去时被动语态
- Results 用过去时
- Discussion 用现在时讨论意义，过去时回溯本研究
- 避免 AI 写作痕迹过重的表达

## 工作流
撰写顺序：Methods → Results → Discussion → Introduction → Abstract
每 section 完成后自动触发局部审查。

## 工具链
- LaTeX 排版
- Zotero 管理参考文献（通过 MCP 集成）
- 目标期刊信息见 .pipeline/memory/journal_spec.md

---

## How to interact with Writer in Interactive Writing Protocol

When you run `/omp:write <section>`, Writer enters collaborative mode by
default. You will see paragraph-level interactions like this:

  Writer: "Next paragraph plan: I will describe the Western blot in Fig 2B,
          comparing wildtype to ΔacuD strain, citing kumar2024 for antibody
          source. Estimated 4 sentences. OK to proceed?"
  You: ✓ go ahead     (or revise the plan in natural language)
  Writer: [writes the paragraph]
  Writer: "Self-check: used 'we propose' (matches moderate boldness),
          no banned phrases, cited Fig 2B correctly. Your call?"
  You: s2 换种说法强调统计显著性     (sentence-level nudge)
  Writer: [rewrites sentence 2]
  You: ✓
  Writer: [moves to next paragraph]

### Sentence-level nudge shortcuts

You can use these compact commands instead of writing full feedback:
- `s<N> <instruction>` — modify sentence N (e.g., `s2 shorter`)
- `s<N>-<M> <instruction>` — modify sentence range (e.g., `s2-3 merge`)
- `+last <text>` — append a sentence at the end
- `-s<N>` — delete sentence N
- `tone <softer|stronger|more_technical>` — adjust whole paragraph tone
- `cite needed here: <keyword>` — Writer will call zotero-ref-bridge to
  find a matching reference

### Switching interaction mode mid-section

You can change mode anytime by typing in natural language:
- "switch to dense mode" — Writer will pre-announce AND post-deliver every unit
- "go autonomous for the rest of this section" — Writer will silently finish
- "back to collaborative" — return to default

### Pause and resume

If you need to step away mid-section, just type "pause". Writer will save
state to manuscript_state.md. Next session, SessionStart will restore your
exact position.

## How to switch agent roles

Each session you can be ONE role at a time. SessionStart will ask you to
choose. To switch roles within a session, run `/omp:plan` to return to
Conductor view, then re-trigger another role command.

Common workflows:

  Day 1 (setup):
    SessionStart → choose StyleKeeper → /omp:setup → answer style questions

  Day 2-10 (writing):
    SessionStart → choose Writer → /omp:write methods --mode autonomous
    SessionStart → choose Writer → /omp:write results --mode collaborative

  Day 11 (review):
    SessionStart → choose Reviewer → /omp:review

  Day 12 (style refine):
    SessionStart → choose StyleKeeper → /omp:style --refine

  Day 13-14 (finalization):
    SessionStart → choose Formatter → /omp:format → /omp:check
