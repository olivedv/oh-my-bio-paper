# Oh My Bio-Paper — Project Context

## 项目类型
本仓库是一个**工程项目：开发一套面向湿实验生物学的论文写作流水线**
（`oh-my-paper` 的生物学分支，当前在 `bio-paper-v1.4`），
**不是**在撰写某一篇具体论文。交付物是流水线本身：Claude Code 与 Codex 插件、
agent 角色（Conductor / Writer / Reviewer / StyleKeeper / Formatter 等）、
skills、`/omp:*` 命令、生命周期 hooks，以及配套的桌面工作台
（Tauri 应用，见 `src-tauri/` + `src/`）。
`sections/` 下的 LaTeX 是用来自测（dogfood）流水线的样例稿件，不是最终科研论文，
改动它时不要当成真实论文来对待。

## 目标领域
流水线服务的对象是**湿实验生物学论文**（非 ML/计算类），
以真菌分子生物学为典型场景，模式菌 *Talaromyces marneffei*，
常见实验类型：CRISPR-Cas9 基因敲除、转录调控、RNA-seq、荧光显微镜。
下面的写作规范是**流水线需要理解并对生成内容强制执行**的领域约定，
而非某篇论文的私有要求。

## 流水线需强制的写作规范（领域约定）
- 基因名斜体（*acuD*），蛋白名正体（AcuD）
- 菌名首次全称斜体后续缩写（*Talaromyces marneffei* → *T. marneffei*）
- Methods 用过去时被动语态
- Results 用过去时
- Discussion 用现在时讨论意义，过去时回溯本研究
- 避免 AI 写作痕迹过重的表达

## 流水线定义的写作工作流
撰写顺序：Methods → Results → Discussion → Introduction → Abstract
每 section 完成后自动触发局部审查。

## 技术栈
- 流水线交付形态：Claude Code 插件（`plugins/oh-my-paper`）、Codex 插件
  （`plugins/oh-my-paper-codex`）、`skills/`、`templates/`、`sidecar/`、`workers/`，
  以及 `src-tauri/` + `src/` 的桌面工作台
- 稿件产物：LaTeX 排版
- 参考文献：Zotero 通过 MCP 集成
- 目标期刊信息（样例/模板）见 `.pipeline/memory/journal_spec.md`

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
