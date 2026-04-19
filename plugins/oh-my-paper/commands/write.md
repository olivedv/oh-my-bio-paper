---
description: 按 section 撰写论文（autonomous 模式，遵循 style_profile.md）
---

> **必须使用 AskUserQuestion 工具进行所有确认和信息采集步骤，不得用纯文字替代。**

你正在运行 `/omp:write`。本命令的核心是**为指定 section 生成 LaTeX
正文，严格遵循项目级 `style_profile.md` 规则和领域硬规范**。

整个命令由 **Writer** 角色执行。本会话内：你以 Writer 身份工作，严格遵守
其记忆读写权限（详见 `plugins/oh-my-paper/agents/writer.md`）。**本命令期间
不得修改 style_profile.md、figure_registry.md、strain_plasmid_table.md**。

---

## 第一步：确定目标 section

参数约定：`/omp:write <section>`，其中 `<section>` ∈
`{methods, results, discussion, introduction}`。

分流：
- 参数为上述 4 个之一 → 进入第二步
- 无参数或非法值 → 用 AskUserQuestion 询问：
  > 要撰写哪个 section？

  选项：
  - `methods` — 按实验方法撰写 Methods（读 strain_plasmid_table）
  - `results` — 按 figure_registry 撰写 Results
  - `discussion` — 基于 manuscript_state 的已写内容撰写 Discussion
  - `introduction` — 撰写 Introduction
  - `退出` — 不写，退出命令

**顺序建议**（非硬性）：Methods → Results → Discussion → Introduction。
用户可任意顺序，但如果检测到前置 section 尚未完成，**只提示不阻塞**：

> 📎 建议顺序：Methods → Results → Discussion → Introduction。
> 当前 `<prev_section>` 状态为 `<status>`，你仍要先写 `<target_section>` 吗？

选项：
- `继续写 <target_section>`
- `改为先写 <prev_section>`
- `退出`

---

## 第二步：前置条件检查

用 `Read` 工具核验以下文件存在且可读：

1. `.pipeline/config/project.json`
2. `.pipeline/memory/style_profile.md` ← **最关键，若不存在立即退出**
3. `.pipeline/memory/journal_spec.md`
4. `.pipeline/memory/manuscript_state.md`
5. `.pipeline/memory/figure_registry.md`

**缺失 `style_profile.md`** → 用 AskUserQuestion 告知用户：

> ⛔ 风格档案 `style_profile.md` 不存在。Writer 无法在没有风格规则的情况下
> 写作。请先运行 `/omp:style` 生成风格档案。

选项：
- `立即去运行 /omp:style`
- `退出`

然后**直接退出本命令**，不执行任何后续步骤。

**其他文件缺失** → 提示用户先运行 `/omp:setup` 后退出。

### 2.1 检查目标 section 当前状态

从 `manuscript_state.md` 解析目标 section 的状态：

| 当前状态 | 动作 |
|---|---|
| `not_started` | 正常继续 |
| `drafting` | AskUserQuestion 确认是否覆盖：`覆盖重写 / 退出` |
| `draft_complete` / `reviewed` / `revised` | AskUserQuestion 确认是否覆盖，默认倾向退出 |
| `final` | **拒绝覆盖**，提示用户该 section 已锁定，退出命令 |

---

## 第三步：加载 sci-bio-writer skill

**你必须现在立即用 Read 工具依次读取以下 2 个文件的完整内容，然后严格
按这些文件中的定义执行，不得自行编造任何风格规则或领域规范。**

1. `skills/sci-bio-writer/SKILL.md` — 工作流 + section 特定规则
2. `skills/sci-bio-writer/references/fungal-genetics-conventions.md` — 硬编码领域规范

**硬性规则**：所有风格维度必须从 `style_profile.md` 读取运行时值；本 skill
文件或本命令中均未定义任何风格默认值。读完后以 SKILL.md 工作流为准。

---

## 第四步：加载运行时记忆

**你必须现在立即用 Read 工具依次读取以下文件的完整内容**：

1. `.pipeline/memory/style_profile.md` — 项目级风格规则（YAML frontmatter + 正文）
2. `.pipeline/memory/journal_spec.md` — 期刊硬约束（字数 / 引用格式）
3. `.pipeline/memory/manuscript_state.md` — 各 section 状态
4. `.pipeline/memory/figure_registry.md` — 可引用的图表

**若目标 section 是 `methods`**，额外读取：

5. `.pipeline/memory/strain_plasmid_table.md` — 菌株 / 质粒信息（若存在）

**硬性规则**：
- Q1–Q* 的风格维度必须逐字从 `style_profile.md` 的 YAML frontmatter 字段读取
- 不得用自己的语言理解替代任何字段值
- 不得从记忆里编造任何"默认"风格规则

---

## 第五步：生成 section 正文

按 SKILL.md §步骤 5 执行 autonomous 写作：

- **模式**：autonomous（一次性生成完整 section，不暂停、不征询）
- **输出格式**：LaTeX（`\section{...}` / `\textit{}` / `\cite{}` / 等）
- **引用处理**：所有文献引用统一用 `[CITE: keyword]` 占位符
  - 例：`...has been reported [CITE: kumar2024 virulence]`
  - Phase 3 由 zotero-ref-bridge 批量回填
- **Figure 引用**：按 `style_profile.results.figure_reference_format` 字段指定格式
- **section 特定规则**：严格按 SKILL.md 中 Methods / Results / Discussion /
  Introduction 的对应规则生成

### 5.1 生成前的硬检查

在写入文件**前**，对生成文本自检（对应 fungal-genetics-conventions §10）：

1. 所有菌种名都在 `\textit{}` 内
2. 所有基因名（小写斜体）都在 `\textit{}` 内
3. 所有蛋白名（首字母大写）**不**在 `\textit{}` 内
4. P 值的字母 P 在 `\textit{P}` 内
5. 所有 fold 写法带连字符
6. 无 `CRISPR Cas9`（未连字符）
7. **不包含任何 style_profile.md 中 `## Banned Expressions` 列出的短语**

任一违反 → 局部重写，不落盘违规文本。

---

## 第六步：写入文件

目标路径：`paper/sections/<section>.tex`

- **文件不存在** → 直接创建
- **文件存在** → 先备份为 `paper/sections/<section>.backup-<ISO8601>.tex`，
  然后覆盖写入

写入后，用 `Read` 工具确认文件已落盘。

---

## 第七步：更新 manuscript_state.md

把目标 section 的状态改为 `draft_complete`，记录 `last_updated` 为当前
ISO8601 时间戳。保留其他 section 的状态不变。

---

## 第八步：完成确认

用 AskUserQuestion 展示摘要：

> ✅ **`<section>` 初稿完成**
>
> | 字段 | 值 |
> |---|---|
> | 文件 | `paper/sections/<section>.tex` |
> | 字数 | `<N>` words |
> | 引用占位符数量 | `<N>` 个 `[CITE: ...]` |
> | Figure 引用数量 | `<N>` |
> | 状态 | `draft_complete` |
>
> 下一步：

选项：
- `查看完整 section 内容`（用 Read 显示）
- `继续写下一个 section`（提示用户运行 `/omp:write <next>`）
- `运行 /omp:review <section> 审查这个 section`
- `暂停，先看看`

**不要**在本命令内自动触发 git commit —— 交给用户或后续 Hook 处理。
**不要**自动触发 Reviewer —— 交给用户或 Hook 处理。

---

## 本命令的硬性限制

- ❌ 不得修改 `style_profile.md` / `figure_registry.md` / `strain_plasmid_table.md`
- ❌ 不得自行编造任何风格规则（时态、禁用词、偏好短语）；所有风格维度都从
  `style_profile.md` 读
- ❌ 不得自动 git commit
- ❌ 不得自动触发 Reviewer
- ❌ 不得写 `paper/main.tex`（由 `/omp:format` 管理）
- ✅ 只写 `paper/sections/<section>.tex` 和对应备份文件，以及 `manuscript_state.md`
