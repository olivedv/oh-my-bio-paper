---
description: 生成或调整项目级风格档案（style_profile.md）
---

> **必须使用 AskUserQuestion 工具进行所有确认和信息采集步骤，不得用纯文字替代。**

你正在运行 `/omp:style`。本命令的核心是**把这篇论文的语言风格从"写作过程中
的即兴决策"固化为"一份可审计、可版本化的 style_profile.md"**。

整个命令由 **StyleKeeper** 角色执行。本会话内：你暂时以 StyleKeeper 身份工作，
严格遵守其记忆读写权限（详见 `plugins/oh-my-paper/agents/stylekeeper.md`）。
在 `style_profile.md` 生成完成前，不要动 paper/sections/、figure_registry、
strain_plasmid_table 任何一个。

---

## 第一步：识别子命令

根据命令行参数分流：

| 参数 | 动作 |
|---|---|
| 无参数 / `--interview` | 走完整交互流程（步骤 2–6） |
| `--refine` | **Phase 2 stub**：用 AskUserQuestion 通知用户"refine 模式在 Phase 2 实现"，然后退出，**不改动任何文件** |
| `--from-template <name>` | **Phase 2 stub**：同上 |
| 其他参数 | 用 AskUserQuestion 告知参数未识别，列出当前支持的参数并退出 |

stub 模式的提示选项统一是：
- `了解，先走默认的 /omp:style`
- `退出`

---

## 第二步：检查前置条件

在任何交互开始前，用 `Read` 工具核验：

1. `.pipeline/` 目录存在
2. `.pipeline/config/project.json` 存在且可解析 JSON
3. `.pipeline/memory/journal_spec.md` 存在

**任一缺失** → 用 AskUserQuestion 告知用户先运行 `/omp:setup`，提供：
- `立即去运行 /omp:setup`
- `先查看项目状态`

然后退出本命令。

---

## 第三步：加载 style-curator skill

读取 `skills/style-curator/SKILL.md` 作为本次交互的指令文件。严格按其
**"工作流" 六个步骤**执行。辅助文件：

- 题目顺序与内容：`skills/style-curator/references/interview-questions.md`
- 落盘字段定义：`skills/style-curator/references/style-schema.md`
- 期刊预设：`skills/style-curator/references/journal-presets/<name>.md`
  （若为 stub 则忽略预设，不带默认值）

**不要**从记忆里重新造一遍题目或 schema —— 始终以这三份 references 为准。

---

## 第四步：执行交互问卷

按 SKILL.md 工作流的步骤 1–5 依次执行：

1. 期刊预设识别（SKILL.md §步骤 1）
2. 备份已存在的 `style_profile.md`（§步骤 2）
3. 范本论文入口 stub（§步骤 3）—— 本 MVP 仅显示提示
4. 12 题交互问卷（§步骤 4）
   - Q1–Q6 为核心维度，必须完成
   - Q7–Q12 为细化维度，用户可选 `skip` 接受默认值
   - Q11 多选拆为 7 个单问，先问预问决定是否走快捷通道
5. 生成 `.pipeline/memory/style_profile.md`（§步骤 5）

**全程使用 AskUserQuestion**。不要用纯文字列选项让用户打字选择。

---

## 第五步：完成确认

按 SKILL.md §步骤 6 展示生成摘要。在用户确认后：

- 若用户选"查看完整 style_profile.md"，`Read` 该文件显示内容
- 若用户选"继续 /omp:plan"，提示直接运行 `/omp:plan`
- 若用户选"先自己看看"，退出本命令

**不要**在本命令内自动触发 git commit —— 交给用户或后续 Hook 处理。

---

## 第六步：后续提示（可选）

在用户确认完成后，用 AskUserQuestion 提醒：

> 📎 **提醒**：
> - `style_profile.md` 已生成。后续每次 Writer 写 section 前都会自动读取它。
> - 待 Phase 2 启用后，你可以用 `/omp:style --refine` 基于已写 section 迭代风格。
> - 若要从别的项目继承风格模板，Phase 2 启用后用 `/omp:style --from-template <name>`。

选项：
- `了解，结束本命令`

---

## 本命令的硬性限制

- ❌ 不要写 paper/sections/* —— 那是 Writer 的工作
- ❌ 不要修改 figure_registry 或 strain_plasmid_table
- ❌ 不要实际执行范本论文 LLM 分析（Phase 2 功能）
- ❌ 不要自动 git commit
- ✅ 只写 `.pipeline/memory/style_profile.md` 和对应 backup 文件
