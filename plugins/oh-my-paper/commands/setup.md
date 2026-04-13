---
description: 初始化生物论文写作项目（.pipeline/、Git 仓库、记忆文件、Hooks）
---

> **必须使用 AskUserQuestion 工具进行所有确认和信息采集步骤，不得用纯文字替代。**

你正在为当前目录初始化 Oh My Bio-Paper 论文写作环境。

---

## 第一步：采集项目信息

用 `AskUserQuestion` 依次收集以下信息：

### 1a. 项目名称

> 请为本论文项目命名（用于目录和 commit 标识）：
>
> 例如：`acud_transcription_regulation`、`madsa_virulence_factor`

用户自由输入。

### 1b. 目标期刊

> 目标投稿期刊？

选项（可自由输入其他期刊）：
- `Nature Microbiology`
- `mBio`
- `PLOS Pathogens`
- `Fungal Genetics and Biology`
- `eLife`
- `其他（请输入）`

### 1c. 通讯作者邮箱

> 通讯作者邮箱？（用于期刊投稿系统和 cover letter）

用户自由输入。

---

## 第二步：创建目录结构

如果以下目录不存在，则创建：

```bash
# 论文写作工作区
mkdir -p paper/sections paper/refs paper/figures

# 补充材料
mkdir -p supplementary/tables supplementary/figures

# 投稿文件
mkdir -p submission/figures

# Pipeline 目录
mkdir -p .pipeline/memory/reference_analysis .pipeline/tasks .pipeline/config .pipeline/docs

# Hooks
mkdir -p hooks/figure-watcher
```

---

## 第三步：初始化 Git 仓库

检查当前目录是否已有 Git 仓库：

```bash
git rev-parse --git-dir 2>/dev/null && echo "Git repo exists" || git init
```

如果是新初始化的仓库，告知用户。

### 3a. 安装 pre-push Hook

写入 `.git/hooks/pre-push`，防止任何 push 操作：

```bash
cat > .git/hooks/pre-push << 'HOOK'
#!/bin/bash
# Oh My Bio-Paper: 禁止任何 push 操作
echo "================================================"
echo "ERROR: This repository is LOCAL-ONLY."
echo "Pushing to any remote is blocked by pre-push hook."
echo "If you really need to back up, use rsync to an"
echo "encrypted external drive or a private NAS."
echo "================================================"
exit 1
HOOK
chmod +x .git/hooks/pre-push
```

### 3b. 生成 .gitignore

写入项目根目录的 `.gitignore`（v1.3.1 含 PDF）：

```gitignore
# Figure 源文件（TIFF/PNG/SVG/PDF，体积大且不适合 diff）
paper/figures/*.tiff
paper/figures/*.tif
paper/figures/*.png
paper/figures/*.svg
paper/figures/*.pdf
paper/figures/*.ai
paper/figures/*.psd

# LaTeX 编译产物
*.aux
*.log
*.out
*.toc
*.bbl
*.blg
*.synctex.gz
*.fdb_latexmk
*.fls
paper/main.pdf
submission/*.pdf

# 补充数据文件
supplementary/raw_data/
supplementary/*.xlsx
supplementary/*.csv

# Zotero 缓存和临时文件
.pipeline/config/zotero_cache/
*.tmp
*.bak

# 操作系统文件
.DS_Store
Thumbs.db
```

---

## 第四步：初始化记忆文件

读取 `.pipeline/memory/` 下的所有模板文件。将以下信息填入对应的占位符：

### 4a. project_truth.md

用采集到的信息填写 `项目名称`、`目标期刊`、`通讯作者`、`创建时间`（当前日期）。

### 4b. project.json

写入 `.pipeline/config/project.json`：

```json
{
  "project_name": "[用户填写的项目名]",
  "target_journal": "[用户选择的期刊]",
  "corresponding_author": "",
  "corresponding_email": "[用户填写的邮箱]",
  "stage": "preparation",
  "created": "[当前日期 ISO 格式]"
}
```

### 4c. journal_spec.md

如果用户选择的期刊在 `skills/journal-formatter/references/journal-templates/` 下有对应模板，
读取模板内容填入 `journal_spec.md` 的相应字段。否则标记为待手动填写。

### 4d. tasks.json

写入初始任务树：

```json
{
  "version": "1.0.0",
  "created": "[当前日期 ISO 格式]",
  "tasks": [
    {
      "id": "prep-001",
      "title": "Complete style profile setup",
      "status": "pending",
      "assignee": "StyleKeeper"
    },
    {
      "id": "prep-002",
      "title": "Register all figures",
      "status": "pending",
      "assignee": "user"
    },
    {
      "id": "prep-003",
      "title": "Fill strain/plasmid table",
      "status": "pending",
      "assignee": "user"
    }
  ]
}
```

---

## 第五步：注册 SessionStart Hook

确保 `.claude/settings.json` 中注册了 SessionStart hook，每次启动时弹出角色选择：

```bash
node -e "
const fs = require('fs');
const path = require('path');
const f = path.join('.claude', 'settings.json');
const s = fs.existsSync(f) ? JSON.parse(fs.readFileSync(f,'utf8')) : {};
if (!s.hooks) s.hooks = {};
if (!s.hooks.SessionStart) s.hooks.SessionStart = [];
const cmd = 'node \"\${CLAUDE_PLUGIN_ROOT}/scripts/on-session-start.mjs\"';
const already = s.hooks.SessionStart.some(h =>
  Array.isArray(h.hooks) && h.hooks.some(hh => (hh.command||'').includes('on-session-start'))
);
if (!already) {
  s.hooks.SessionStart.push({ matcher: '', hooks: [{ type: 'command', command: cmd }] });
  fs.mkdirSync('.claude', { recursive: true });
  fs.writeFileSync(f, JSON.stringify(s, null, 2));
  console.log('SessionStart hook registered');
} else { console.log('SessionStart hook already registered'); }
"
```

---

## 第六步：style-curator 和 figure-watcher（Stub）

> ⚠️ 以下功能在 Phase 2 实现，当前仅显示提示信息。

### 6a. style-curator stub

用 `AskUserQuestion` 告知用户：

> **风格档案初始化（Phase 2）**
>
> style-curator skill 尚未实现。风格档案 (`style_profile.md`) 当前为空模板。
> Phase 2 完成后，`/omp:setup` 将在此步自动运行风格交互问卷和范本论文分析。
>
> 你可以稍后运行 `/omp:style` 来手动触发风格档案生成。

选项：
- `了解，继续`

### 6b. figure-watcher stub

用 `AskUserQuestion` 告知用户：

> **Figure 自动登记（Phase 2）**
>
> figure-watcher Hook 尚未实现。如果你已有 Figure 文件，请将它们放入
> `paper/figures/` 目录，后续 Hook 启用后会自动登记到 `figure_registry.md`。
>
> 当前你可以手动编辑 `.pipeline/memory/figure_registry.md` 登记 Figure。

选项：
- `了解，继续`

---

## 第七步：首次 Git 提交

将所有初始化文件提交：

```bash
git add -A
git commit -m "meta(setup): initial project scaffolding

Project: [项目名]
Journal: [期刊]
Stage: preparation"
```

---

## 第八步：完成确认

用 `AskUserQuestion` 显示初始化摘要：

> ✅ **Oh My Bio-Paper 项目初始化完成！**
>
> | 项目 | 值 |
> |------|------|
> | **名称** | [项目名] |
> | **期刊** | [期刊] |
> | **通讯作者** | [邮箱] |
> | **阶段** | Preparation |
> | **Git** | 已初始化（pre-push hook 已安装，本地仓库禁止 push） |
>
> **待完成事项**：
> 1. 将 Figure 文件放入 `paper/figures/`
> 2. 填写菌株表：`.pipeline/memory/strain_plasmid_table.md`
> 3. 运行 `/omp:style` 生成风格档案（Phase 2 启用后）
>
> **下一步**：

选项：
- `运行 /omp:plan 查看全局状态`
- `先手动填写菌株表和 Figure 信息`
- `我先自己看看文件结构`
