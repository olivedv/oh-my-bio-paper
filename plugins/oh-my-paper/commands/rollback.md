---
description: 交互式回滚到任意历史版本，支持局部回滚单个文件
---

> **必须使用 AskUserQuestion 工具进行所有确认步骤，不得用纯文字替代。**

## 用法

- `/omp:rollback` — 交互式选择回滚版本
- `/omp:rollback methods.tex` — 仅回滚 Methods section

## 执行步骤

### 第一步：展示最近提交

```bash
python3 skills/version-guardian/scripts/smart-message.py --history 15
```

用 `AskUserQuestion` 展示历史并询问：

> **选择要回滚到的版本**（输入序号或 commit hash）：
>
> [展示历史表格]

选项：
- `[序号] 回滚到此版本`
- `取消`

### 第二步：确认回滚范围

用 `AskUserQuestion` 确认：

> **⚠️ 回滚确认**
>
> - **目标版本**: [commit hash] — [subject]
> - **回滚范围**: [全部 / 仅 <filename>]
> - **当前状态将自动创建安全快照**: `pre-rollback/[时间戳]`
>
> 确认回滚？

选项：
- `确认，执行回滚`
- `只回滚某个文件`
- `取消`

### 第三步：执行回滚

```bash
# 1. 创建安全快照
git tag "pre-rollback/$(date +%Y%m%d-%H%M%S)"

# 2a. 全局回滚
git reset --hard <target_commit>

# 2b. 或局部回滚（仅某个文件）
git checkout <target_commit> -- paper/sections/<filename>
git add paper/sections/<filename>
git commit -m "rollback(<scope>): revert to [commit_hash]"
```

### 第四步：确认结果

> ✅ 回滚完成。安全快照已创建为 `pre-rollback/[tag]`。
> 如需恢复，运行：`git reset --hard pre-rollback/[tag]`
