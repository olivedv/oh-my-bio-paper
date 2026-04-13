---
description: 创建命名 tag 快照（如投稿前、大改前）
---

> **必须使用 AskUserQuestion 工具进行所有确认步骤，不得用纯文字替代。**

## 用法

- `/omp:snapshot pre-submission` — 创建命名快照
- `/omp:snapshot` — 自动生成带时间戳的快照名

## 执行步骤

### 第一步：确定快照名称

如果用户提供了名称，直接使用。否则用 `AskUserQuestion` 询问：

> **创建快照** — 请为这个快照命名（用于标记重要节点）：
>
> 常用名称示例：
> - `pre-submission` — 投稿前
> - `before-major-revision` — 大改前
> - `boss-review` — 发给老板看之前
> - `submission-v1` — 第一次投稿版本

选项（可自由输入）：
- `pre-submission`
- `before-major-revision`
- `自动命名（使用时间戳）`

### 第二步：检查工作区

```bash
# 确保没有未提交的更改
git status --short
```

如果有未提交的更改，先用 auto-commit.sh 提交：

```bash
bash skills/version-guardian/scripts/auto-commit.sh --type checkpoint --scope all
```

### 第三步：创建 tag

```bash
# 用户命名的快照
git tag "checkpoint/<label>"

# 或自动命名
git tag "checkpoint/$(date +%Y%m%d-%H%M%S)"
```

### 第四步：确认

读取 manuscript_state.md 获取当前状态摘要。

> ✅ **快照已创建**: `checkpoint/<label>`
>
> **当前稿件状态**:
> - Methods: [status]
> - Results: [status]
> - ...
>
> 恢复命令：`git reset --hard checkpoint/<label>`

选项：
- `继续工作`
- `查看快照列表：git tag -l "checkpoint/*"`
