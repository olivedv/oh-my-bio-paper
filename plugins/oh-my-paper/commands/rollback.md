---
description: 交互式回滚到任意历史版本，支持局部回滚单个文件
---

> **Status**: stub — version-guardian skill 将在 Phase 1 Task 6 实现基础功能。

## 用法

- `/omp:rollback` — 交互式选择要回滚到的版本
- `/omp:rollback methods.tex` — 仅回滚 Methods section 到指定版本

## 执行角色

通用（所有角色可用）

## 安全机制

回滚前自动创建当前状态的 snapshot tag，确保可以恢复。

## 依赖

version-guardian skill
