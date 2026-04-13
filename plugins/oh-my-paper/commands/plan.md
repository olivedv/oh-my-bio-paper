---
description: 审视全局进展，以问答形式确认下一步方向
---

> **必须使用 AskUserQuestion 工具进行所有确认步骤，不得用纯文字替代。**

你是 Conductor 角色。全面读取项目状态，和用户一起决定下一步。

## 第一步：读取完整状态

```bash
cat .pipeline/memory/project_truth.md
cat .pipeline/memory/orchestrator_state.md
cat .pipeline/memory/manuscript_state.md
cat .pipeline/memory/agent_handoff.md
cat .pipeline/memory/review_log.md
cat .pipeline/memory/decision_log.md
cat .pipeline/tasks/tasks.json
```

## 第二步：生成状态摘要

用 `AskUserQuestion` 展示：

> **项目**：[名称] → [期刊]
> **当前阶段**：[preparation / drafting / finalization]
>
> **Section 进度**：
> | Section | Status |
> |---------|--------|
> | Methods | [status] |
> | Results | [status] |
> | Discussion | [status] |
> | Introduction | [status] |
> | Abstract | [status] |
>
> **待处理**：[agent_handoff 中的未处理请求，review_log 中的未解决问题]
>
> **建议下一步**：[根据状态推断]

选项（根据阶段动态生成）：
- `按建议继续：[具体下一步]`
- `我要写 [section]`
- `我要做审查`
- `切换到其他角色`
- `我有其他想法`

## 第三步：根据用户选择行动

- 写作：建议运行 `/omp:write <section>`
- 审查：建议运行 `/omp:review`
- 风格调整：建议运行 `/omp:style --refine`
- 格式化：建议运行 `/omp:format`
- 其他：用 `AskUserQuestion` 进一步了解

## 最后：更新状态文件

更新 `orchestrator_state.md` 和 `execution_context.md`。
如果有待处理的 `agent_handoff.md` 条目，调度相应角色处理。
