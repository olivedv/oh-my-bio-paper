---
id: style-curator
name: style-curator
version: 0.2.0
description: |-
  Meta-skill for generating and maintaining project-level style profiles.
  Conducts an interactive 12-question style interview, merges journal
  presets, and produces style_profile.md that governs all writing output.
stages: ["preparation", "drafting"]
tools: ["read_file", "write_file", "search_project"]
primaryIntent: style-management
intents: ["style-management", "preparation"]
domains: ["biology", "academic-writing"]
keywords: ["style-curator", "style", "profile", "interview", "reference-analysis", "journal-preset"]
source: custom
status: minimal
resourceFlags:
  hasReferences: true
  hasScripts: false
  hasTemplates: false
  hasAssets: false
---

# style-curator

项目级语言风格档案的生成与维护者。

本 skill 的工作是把"这篇论文应该读起来像什么样子"的决策**从 Writer 的
脑子里**迁移到**一份可审计、可版本化的文件**里，使得所有后续写作动作
都有统一的风格指令可依。

> **执行角色**：StyleKeeper —— 该 skill 应由 StyleKeeper 触发。Writer / Reviewer
> 对 `style_profile.md` 只读；所有写入均走 style-curator。

---

## 何时触发

| 触发源 | 模式 | 本 MVP 支持 |
|---|---|---|
| `/omp:setup` | 首次生成 | ✅ |
| `/omp:style` | 重新生成（覆盖式） | ✅ |
| `/omp:style --refine` | 基于已写 section 迭代 | ⛔ stub（Phase 2） |
| `/omp:style --from-template <name>` | 从风格库继承 | ⛔ stub（Phase 2） |
| Writer handoff 请求 | 补充风格规则 | ⛔ stub（Phase 2） |

遇到不支持的模式时，**只提示用户该功能在 Phase 2 实现，然后退出**，
不要 fallback 执行完整流程（避免覆盖现有 profile）。

---

## 必备前置

在开始执行前检查：

1. `.pipeline/memory/` 目录存在（由 `/omp:setup` 创建）
2. `.pipeline/config/project.json` 可读，从中取 `project_name`
3. `.pipeline/memory/journal_spec.md` 可读，从中识别 `target_journal`

任一缺失则停止并提示用户先运行 `/omp:setup`。

---

## 工作流

### 步骤 1 — 期刊预设识别

读 `journal_spec.md` 提取目标期刊名。尝试匹配到：

```
skills/style-curator/references/journal-presets/
  nature-mb.md   (Nature Microbiology / Nature * 系列)
  mbio.md        (mBio / PLOS Pathogens)
  fgb.md         (Fungal Genetics and Biology / MMI)
```

匹配规则（大小写不敏感）：包含 `nature` → `nature-mb.md`；包含
`mbio` / `plos` → `mbio.md`；包含 `fungal` / `molecular microbiology`
→ `fgb.md`；其他 → 无预设。

读入预设文件。若内容为 stub（不足 10 行或含 "Status: stub" 字样），
记为"无可用预设"，后续交互不附带默认值提示。否则从预设中解析出每题
的推荐值，用于在交互时显示"基于目标期刊的推荐值：X"。

### 步骤 2 — 备份现有 profile（幂等性保障）

如果 `.pipeline/memory/style_profile.md` 已存在且非空，**先复制**到
`.pipeline/memory/style_profile.backup-<ISO8601-UTC>.md`，然后继续。
不询问用户（备份无破坏性）。

### 步骤 3 — 范本论文入口（stub）

用 AskUserQuestion 问：

> 是否现在提供 1–3 篇"我希望我的论文读起来像这样"的范本论文？

选项：
- `暂不提供` — 继续走纯交互流程
- `稍后在 Phase 2 补充` — 同上（显示一句说明）

**本 MVP 不实际接受范本论文**。无论用户选哪个都直接进入步骤 4。
如果用户文字输入 DOI 或路径，也要礼貌告知"范本论文 LLM 分析将在
Phase 2 启用，当前仅收集用户偏好"。

### 步骤 4 — 交互问卷

读取 `references/interview-questions.md`，按文件中定义的顺序依次提问。

**通用规则**：
- 每题都用 `AskUserQuestion`，绝不用纯文字替代
- 如有期刊预设推荐值，在题面第一行加一句：
  `📎 基于目标期刊 <target_journal> 的推荐值：<value>`
- 用户选 `skip` 时，按 `style-schema.md` 指定的硬默认填充
- 所有答案累积到一个内部 dict，供步骤 5 落盘

**Q11（banned phrases）特殊处理**：
先问一个预问："对 7 个常见的 AI 套话短语，你想逐个点选，还是全部采用
期刊预设默认值？"
- `逐个点选` → 对 `references/interview-questions.md` 列出的 7 个短语各问
  一次（`ban` / `allow`），收集成数组
- `采用预设默认` → 把期刊预设中的 banned list 整体赋给 `banned_expressions`

### 步骤 5 — 生成 style_profile.md

严格按 `references/style-schema.md` 定义的结构写入
`.pipeline/memory/style_profile.md`：

1. **META frontmatter**：
   - `project_name` 取自 `project.json`
   - `target_journal` 取自 `journal_spec.md`
   - `generated_at` = `last_refined` = 当前 UTC ISO8601
   - `curator_version` 取本 SKILL.md 的 `version` 字段
   - `reference_papers: []`（MVP 恒为空数组）

2. **GLOBAL STYLE / SECTION-SPECIFIC frontmatter**：
   用步骤 4 的答案填充；缺失项用 schema 硬默认。

3. **正文 6 节**：按 schema 给出的模板生成；`Preferred Phrases` 和
   `Tone Calibration Examples` 在 MVP 下使用占位文本（见 schema）。

4. **Refinement History** 表格写入一行：
   ```
   | <YYYY-MM-DD> | Initial creation | Generated from <N> interview answers (+ <journal-preset> preset) |
   ```
   若无预设，括号部分省略。

### 步骤 6 — 完成确认

用 `AskUserQuestion` 展示摘要：

> ✅ **风格档案已生成**
>
> | 字段 | 值 |
> |---|---|
> | narrative_style | <value> |
> | first_person_usage | <value> |
> | speculation_boldness | <value> |
> | sentence_complexity | <value> |
> | banned 短语条数 | <N> |
> | 文件路径 | `.pipeline/memory/style_profile.md` |
>
> 下一步：

选项：
- `查看完整 style_profile.md`（用 read_file 显示内容）
- `继续 /omp:plan 查看全局状态`
- `我先自己看看，过会儿再说`

---

## 记忆读写权限

| 文件 | 读 | 写 |
|---|---|---|
| `.pipeline/config/project.json` | ✅ | ❌ |
| `.pipeline/memory/journal_spec.md` | ✅ | ❌ |
| `.pipeline/memory/style_profile.md` | ✅ | ✅（独占） |
| `.pipeline/memory/style_profile.backup-*.md` | ❌ | ✅（仅创建） |
| `paper/sections/*.tex` | ❌ | ❌ |
| `skills/style-curator/references/*` | ✅ | ❌ |

---

## 错误与边界

- **前置缺失**：`.pipeline/` 或 `project.json` 不在 → 立即停并提示 `/omp:setup`
- **期刊预设是 stub**：按"无预设"继续，不要把 stub 文本当真答案
- **用户中途退出**：不落盘，不删除已有 profile，不创建备份
- **相同输入重复运行**：备份旧文件后完全重写新文件；refinement history
  的行数**不继承**旧文件（首次 = 1 行；后续在 Phase 2 实现增量追加）

---

## 留给 Phase 2 的接口

以下钩子已在工作流中预留位置，但本 MVP 仅以 stub 提示：

1. **范本论文 LLM 分析**（步骤 3 的实际实现）
2. **`--refine` 模式**：读取完成的 section + 当前 profile，让用户标注满意/
   不满意段落，推断需要调整的维度
3. **`--from-template <name>`**：从 `~/.omp/style-library/` 加载模板
4. **Writer handoff 处理**：响应 `agent_handoff.md` 中的"风格规则请求"条目
