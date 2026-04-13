---
description: 查看可读的 Git 提交历史，支持按 section 和 type 过滤
---

> **必须使用 AskUserQuestion 工具进行所有确认步骤，不得用纯文字替代。**

## 用法

- `/omp:history` — 查看最近 20 次提交
- `/omp:history methods` — 仅查看 Methods 相关提交
- `/omp:history --type draft` — 按类型过滤

## 执行步骤

### 第一步：调用 smart-message.py

根据用户参数构建命令：

```bash
# 默认：最近 20 条
python3 skills/version-guardian/scripts/smart-message.py --history 20

# 按 section 过滤
python3 skills/version-guardian/scripts/smart-message.py --history 20 --section results

# 按 type 过滤
python3 skills/version-guardian/scripts/smart-message.py --history 20 --type draft
```

### 第二步：展示结果

将输出格式化展示给用户，包含序号、类型、范围、描述和日期。

用 `AskUserQuestion` 询问：

> 以上是提交历史。你想：

选项：
- `查看某个提交的详情`
- `对比两个版本：/omp:diff`
- `回滚到某个版本：/omp:rollback`
- `返回`
