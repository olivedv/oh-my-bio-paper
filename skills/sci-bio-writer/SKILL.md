---
id: sci-bio-writer
name: sci-bio-writer
version: 0.2.0
description: |-
  Core writing engine for fungal molecular biology research papers.
  Reads style_profile.md at runtime for all project-specific style rules;
  enforces hard-coded domain conventions from fungal-genetics-conventions.md;
  generates LaTeX section output; updates manuscript_state.md.
stages: ["drafting"]
tools: ["read_file", "write_file", "search_project"]
primaryIntent: writing
intents: ["writing", "drafting"]
domains: ["biology", "fungal-genetics", "academic-writing"]
keywords: ["sci-bio-writer", "writer", "section", "drafting", "latex", "methods", "results", "discussion", "introduction"]
source: custom
status: minimal
resourceFlags:
  hasReferences: true
  hasScripts: false
  hasTemplates: false
  hasAssets: false
---

# sci-bio-writer

按 section 生成论文正文的核心写作引擎。**所有风格维度都在运行时从
`style_profile.md` 读取；领域硬规则来自 `fungal-genetics-conventions.md`；
本 skill 本身不内嵌任何项目级风格假设。**

> **执行角色**：Writer —— 只读 style_profile.md，可写 paper/sections/ 和
> manuscript_state.md。

---

## 本 MVP 的能力与限制

| 能力 | 状态 |
|---|---|
| autonomous 模式一次性生成整个 section | ✅ |
| 读 style_profile / journal_spec / figure_registry / manuscript_state | ✅ |
| 遵守 fungal-genetics-conventions.md 硬规则 | ✅ |
| 读 strain_plasmid_table.md（Methods 专用上下文） | ✅ |
| 更新 manuscript_state.md 状态 → `draft_complete` | ✅ |
| 段落级交互写作协议（pre-announce → draft → check） | ⛔ Phase 3 |
| 调用 methods-protocol skill（插入标准方法段） | ⛔ Phase 3 |
| 调用 zotero-ref-bridge 插入引用 | ⛔ Phase 3 —— 本 MVP 使用 `[CITE: keyword]` 占位符 |
| 自动 git commit | ❌（交给 Hook 或用户） |
| 自动触发 Reviewer | ❌（交给 Hook 或用户） |

---

## 核心工作流（7 步）

### 步骤 1 — 读 style_profile.md（风格规则）

从 `.pipeline/memory/style_profile.md` 的 YAML frontmatter 读取：

- Global：`narrative_style` / `sentence_complexity` / `speculation_boldness`
  / `first_person_usage` / `passive_voice_preference` / `tense_strictness`
- Section-specific：`introduction.*` / `results.*` / `discussion.*`
  / `methods.*` / `abstract.*`

从正文读取：
- `## Banned Expressions` → 所有列出的短语一律不得出现
- `## Preferred Phrases` → 优先使用（如 transitions / mechanism_openers）
- `## Domain-Specific Conventions` → 硬规则基线（与 fungal-genetics-conventions.md 重合，二者都必须遵守）
- `## Tone Calibration Examples` → 生成时的语气参照

**严禁**：自行推断任何上述字段的默认值。缺失 → 报错退出，不得凑默认值继续。

### 步骤 2 — 读 journal_spec.md（期刊硬约束）

提取：
- 字数限制（total / abstract / introduction / discussion）
- Section 顺序与命名规范
- 引用格式（Vancouver / Author-Year / Nature 上标）
- Figure reference format（若 style_profile 未指定）

字数超限必须在生成末尾自检并警告（不自动截断）。

### 步骤 3 — 读 figure_registry.md（可引用图表）

解析每个 Figure / Table 的：`id` / `panels` / `statistics` / `linked_results_paragraph`。
只有出现在 registry 中的 Figure 才可以在正文中引用；引用未登记的 Figure
视为错误。

对 Introduction / Methods，figure_registry 是**参考性读入**（通常不直接引用图表）。
对 Results / Discussion，figure_registry 是**硬依赖**。

### 步骤 4 — 读 manuscript_state.md（section 状态）

确认目标 section 当前状态。根据状态决定动作：

| 当前状态 | 本 MVP 的动作 |
|---|---|
| `not_started` | 正常撰写，标记为 `drafting` → 完成后 `draft_complete` |
| `drafting` | 用户可能中断过；覆盖式重写，警告用户 |
| `draft_complete` / `reviewed` / `revised` | **拒绝覆盖**，提示用户先显式确认 |
| `final` | 拒绝覆盖，提示用户此 section 已锁定 |

### 步骤 5 — 写作

按读入的 style_profile 规则 + fungal-genetics-conventions 硬规则 +
journal_spec 硬约束撰写整个 section。**autonomous 模式**：一次性生成完整
文本，不暂停、不征询用户。

**section 特定规则**（硬编码的领域分工，与风格无关）：

- **Methods**：
  - 时态：过去时被动语态（CLAUDE.md §写作规范已明示）
  - 额外读入：`strain_plasmid_table.md`（如存在），把菌株 / 质粒信息直接嵌入正文
  - 统计方法段：每个子段末声明使用的检验及软件版本
  - 缺失的 catalog / lot number 用 `[CATALOG: <supplier>]` 占位
- **Results**：
  - 时态：过去时
  - 每个 Figure 的引用必须出现在正文且对应 registry 中的 panel 编号
  - `summary_sentences` 由 style_profile 控制（不硬编码）
- **Discussion**：
  - 时态：现在时（意义）+ 过去时（回溯本研究）—— CLAUDE.md §写作规范
  - 结构（findings_first / context_first / hypothesis_first）由 style_profile 控制
  - Limitations 位置由 style_profile 控制
- **Introduction**：
  - 时态：按 style_profile `tense_strictness`
  - 开场风格由 style_profile.introduction.opening_style 控制
  - 引用密度由 style_profile.introduction.citation_density 控制

**引用处理（本 MVP）**：所有文献引用统一使用 `[CITE: keyword]` 占位符，
例如 `...has been reported [CITE: kumar2024 virulence]`。Phase 3 启用
zotero-ref-bridge 后由 skill 批量回填 `\cite{}`。

**LaTeX 输出细节**：
- Section heading 用 `\section{...}`（除非 journal_spec 另有指定）
- Figure 引用用 `Figure~\ref{fig:N}` 或 style_profile 指定的格式
- 斜体基因名：`\textit{acuD}`
- 斜体物种名：`\textit{Talaromyces marneffei}`
- 斜体 P 值：`\textit{P} < 0.05`
- 段落间留空行

### 步骤 6 — 写入 paper/sections/\<section\>.tex

写入绝对路径：`paper/sections/<section>.tex`。

若文件已存在：
- 本 MVP 先备份旧文件为 `paper/sections/<section>.backup-<ISO>.tex`
- 再写入新版本

不写 `paper/main.tex` —— 由 `/omp:format` 或用户手动管理。

### 步骤 7 — 更新 manuscript_state.md

把目标 section 的状态改为 `draft_complete`，记录 `last_updated` 时间戳。
保留其他 section 的状态不变。

---

## 记忆读写权限

| 文件 | 读 | 写 |
|---|---|---|
| `.pipeline/memory/style_profile.md` | ✅ | ❌ |
| `.pipeline/memory/journal_spec.md` | ✅ | ❌ |
| `.pipeline/memory/figure_registry.md` | ✅ | ❌ |
| `.pipeline/memory/strain_plasmid_table.md` | ✅（Methods 时） | ❌ |
| `.pipeline/memory/manuscript_state.md` | ✅ | ✅ |
| `paper/sections/*.tex` | ✅ | ✅ |
| `paper/main.tex` | ❌ | ❌ |
| `.pipeline/memory/style_profile.md` 以外的风格定义 | ❌ | ❌ |
| `skills/sci-bio-writer/references/*` | ✅ | ❌ |

---

## 错误与边界

- **style_profile.md 缺失或为空** → 立即停并提示 `/omp:style`，不得 fallback
- **journal_spec.md 缺失** → 立即停并提示 `/omp:setup`
- **figure_registry 为空而目标是 Results/Discussion** → 警告"无已登记图表，正文将缺少具体数据引用"，仍可继续但需用户二次确认
- **目标 section 已是 reviewed / final 状态** → 拒绝覆盖
- **style_profile 的 banned expression 被违反** → 生成前自检，如检出则整段重写（不落盘违规文本）

---

## 留给 Phase 3 的接口

1. **Interactive Writing Protocol**（collaborative / dense 模式）
2. **methods-protocol skill 调用**：自动填入标准实验方法段
3. **zotero-ref-bridge skill 调用**：把 `[CITE: ...]` 占位符回填为实际 `\cite{}`
4. **自动触发 reviewer**：draft_complete 后自动跑 `/omp:review <section>`
5. **段落级 undo / redo**：允许单段回滚而不丢失整个 section
