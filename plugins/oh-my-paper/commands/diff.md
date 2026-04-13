---
description: 用自然语言描述两个版本之间的差异
---

> **必须使用 AskUserQuestion 工具进行所有确认步骤，不得用纯文字替代。**

## 用法

- `/omp:diff` — 对比当前状态与上次 commit
- `/omp:diff pre-submission` — 对比当前与某个 snapshot
- `/omp:diff <commit1> <commit2>` — 对比两个指定版本

## 执行步骤

### 第一步：确定对比范围

如果用户没有指定版本，用 `AskUserQuestion` 询问：

> **选择对比方式**：

选项：
- `与上次提交对比`
- `与某个快照对比（列出可用快照）`
- `指定两个 commit hash`

如果选择快照，先列出：

```bash
git tag -l "checkpoint/*" --sort=-creatordate
```

### 第二步：调用 smart-message.py 分析

```bash
# 默认：当前 vs HEAD
python3 skills/version-guardian/scripts/smart-message.py --diff HEAD~1 HEAD

# 与快照
python3 skills/version-guardian/scripts/smart-message.py --diff checkpoint/<label> HEAD

# 两个 commit
python3 skills/version-guardian/scripts/smart-message.py --diff <c1> <c2>
```

### 第三步：展示结果

输出按以下结构组织：
1. **Paper sections 变更** — 每个 section 的增删行数
2. **Memory files 变更** — 哪些记忆文件被修改
3. **其他文件** — 配置、skill 等

对于 section 级别的变更，额外读取实际 diff 并用自然语言描述：
"这次修改主要是在 Discussion 第二段增加了对 off-target 效应的讨论，
并新增了 2 个引用 (Chen 2023, Kumar 2024)"
