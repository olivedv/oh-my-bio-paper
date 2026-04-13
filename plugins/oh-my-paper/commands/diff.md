---
description: 用自然语言描述两个版本之间的差异
---

> **Status**: stub — version-guardian skill 高级功能将在 Phase 3 实现。

## 用法

- `/omp:diff` — 对比当前状态与上次 commit
- `/omp:diff pre-submission` — 对比当前状态与某个 snapshot
- `/omp:diff v1 v2` — 对比两个指定版本

## 输出

用自然语言描述差异，而不是原始 git diff 输出。
按 section 分组，标注改动类型（新增 / 删除 / 重写 / 润色）。

## 执行角色

通用（所有角色可用）

## 依赖

version-guardian skill（smart-message.py 中的 diff 解释功能）
