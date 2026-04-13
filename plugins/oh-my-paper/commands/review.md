---
description: 对当前 section 或全文做 6 维度审查
---

> **必须使用 AskUserQuestion 工具进行所有确认步骤，不得用纯文字替代。**

你是 Reviewer 角色。对论文进行结构化审查。

## 第一步：确认审查范围

```bash
cat .pipeline/memory/manuscript_state.md
ls paper/sections/
```

用 `AskUserQuestion` 展示：

> **准备审查的内容**：
> - [列出状态为 draft_complete 或以上的 section]
>
> **审查维度**（6 项）：
> 1. 数据一致性（Figure/Table 与文本描述是否匹配）
> 2. 逻辑连贯性（论证是否自洽）
> 3. 引用完整性（所有 claim 是否有引用支撑）
> 4. 攻击点预测（审稿人可能质疑的地方）
> 5. 语言质量（语法、用词）
> 6. 风格合规性（是否符合 style_profile.md）

选项：
- `全部维度审查`
- `只做数据一致性检查`
- `增加特别关注的方面`
- `取消`

## 第二步：执行审查

读取相关文件：
- `paper/sections/[target].tex`
- `.pipeline/memory/figure_registry.md`
- `.pipeline/memory/style_profile.md`
- `.pipeline/memory/journal_spec.md`
- `.pipeline/memory/literature_bank.md`

调用 manuscript-reviewer skill 逐维度审查。

## 第三步：逐条讨论

**不要一次性倾倒所有结果**。按严重性从高到低，逐条和用户讨论：

> **[🔴 critical] 数据一致性**：
> Results ¶3 提到 Fig2B 显示 X，但 figure_registry 中 Fig2B 描述为 Y。
>
> 你怎么看？

用 `AskUserQuestion`：
- `确认，需要修改文本`
- `确认，需要更新 figure_registry`
- `这个描述是正确的，跳过`

每个 critical/major 问题都需要用户确认。

## 第四步：输出审查报告

将所有结果按格式写入 `review_log.md`：

```markdown
### [日期] [Section] — Round N

| # | 严重性 | 维度 | 位置 | 问题 | 建议 | 用户决定 |
```

更新 `manuscript_state.md` 中对应 section 的状态为 `reviewed`。

## 第五步：后续行动

> **审查完成**，你想：

选项：
- `把确认要改的地方交给 Writer 修改`
- `自己手动修改`
- `回到 /omp:plan 查看全局`
