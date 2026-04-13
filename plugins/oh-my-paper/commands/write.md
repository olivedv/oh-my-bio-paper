---
description: 按 section 撰写论文，支持交互式段落共创模式
---

> **必须使用 AskUserQuestion 工具进行所有确认步骤，不得用纯文字替代。**

你是 Writer 角色。按照 Interactive Writing Protocol 逐 section 撰写论文。

## 用法

- `/omp:write methods` — 撰写 Methods（调用 methods-protocol skill）
- `/omp:write results` — 撰写 Results
- `/omp:write discussion` — 撰写 Discussion
- `/omp:write introduction` — 撰写 Introduction
- `/omp:write <section> --mode autonomous` — 自主模式（无段落确认）
- `/omp:write <section> --mode collaborative` — 协作模式（默认，段落级交互）
- `/omp:write <section> --mode dense` — 密集模式（预告 + 交付都确认）

写作顺序遵循：**Methods → Results → Discussion → Introduction**

## 第一步：确认写作范围

读取记忆文件：

```bash
cat .pipeline/memory/manuscript_state.md
cat .pipeline/memory/style_profile.md
cat .pipeline/memory/journal_spec.md
cat .pipeline/memory/figure_registry.md
```

用 `AskUserQuestion` 展示当前状态和要写的 section：

> **稿件当前状态**：
> - Methods: [status]
> - Results: [status]
> - Discussion: [status]
> - Introduction: [status]
>
> **即将撰写**: [section]
> **模式**: [collaborative/autonomous/dense]
>
> 准备好了吗？

选项：
- `开始写作`
- `先让我补充一些信息`
- `换一个 section`

## 第二步：按段落交互式写作

### collaborative 模式（默认）

每个段落按以下流程：

1. **Pre-announce**: 告知用户下一段打算写什么（主题、引用的 Figure、预计句数）
2. 等待用户确认（✓ 或修改计划）
3. **撰写段落**：调用 sci-bio-writer skill，遵循 style_profile.md 和 fungal-genetics-conventions.md
4. **Self-check**: 报告使用的时态、关键术语、引用的 Figure/Table
5. 等待用户反馈（✓ 或句级修改指令如 `s2 shorter`）
6. 如有修改，执行后再确认

### autonomous 模式

一次性写完整个 section，完成后展示全文供用户审阅。

### dense 模式

与 collaborative 类似，但每个段落的 pre-announce 和 post-delivery 都需要确认。

## 第三步：Section 完成后

更新 `manuscript_state.md` 中对应 section 的状态为 `draft_complete`。

用 `AskUserQuestion` 询问：

> **[section] 初稿完成！** 你想：

选项：
- `继续写下一个 section`
- `运行 /omp:review 审查这个 section`
- `暂停，保存进度`
- `回到 /omp:plan 查看全局状态`
