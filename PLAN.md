# Oh My Bio-Paper：基于 Oh-my-paper 的真菌分子生物学论文写作系统

## 改造方案 v1.4

> **v1.4 更新**：新增第十四章"实操参考附录"，包含 4 个可直接复用的样板：（A）AGENTS.md 完整定义，（B）CLAUDE.md 用户侧指引，（C）端到端使用脚本，（D）style-curator 的 interview-questions 和 check-in-prompts 完整版清单。
>
> **v1.3.1 补丁**：`.gitignore` 和 `figure-watcher` Hook 都将 `.pdf` 加入 `paper/figures/` 的识别范围 —— 适配从 Illustrator / Inkscape / Adobe Acrobat 直接导出 PDF 矢量图作为 Figure 源文件的常见工作流。注意 `paper/figures/*.pdf` 与 LaTeX 编译产生的 `paper/main.pdf` 路径不同，两条规则不冲突。
>
> **v1.3 更新**：五项深化 ——（1）新增 **StyleKeeper** agent 角色，风格管理从 skill 临时占用升级为独立角色；（2）范本论文分析改为 **LLM 原生分析**，抛弃脚本化路线，输出结构化 JSON；（3）新增 **figure-watcher** Hook，自动把 `paper/figures/` 中的新 TIFF 登记到 `figure_registry.md`；（4）Writer 的工作模式从"一次性生成 section"升级为 **段落级交互式共创**，新增 `interactive_draft_protocol`；（5）新增第十三章"交互式写作协议"。
>
> **v1.2 更新**：引入"风格闭环"概念 —— 新增 `style-curator` 元 skill；`sci-bio-writer` 改造为动态读取 style-profile；`manuscript-reviewer` 增加风格合规性检查；zotero-ref-bridge 基于 cookjohn/zotero-mcp 的真实接口。
>
> **v1.1 更新**：新增版本控制系统，引入本地 Git + `version-guardian` skill。

---

## 一、总体定位

Oh-my-paper 是面向 ML/AI 方向的通用科研流水线，核心假设是"从零开始做研究"——包括文献调研、idea 生成、实验执行、论文撰写。但你的场景不同：你是**数据和图表已就绪，进入论文撰写阶段**的实验生物学研究者。因此改造思路是：

**砍掉上游（Survey → Ideation → Experiment），重塑下游（Publication），深化领域适配。**

保留 Oh-my-paper 的架构骨架（Agent 团队 + 记忆系统 + Hook 机制 + Skill 按需加载），但将 34 个通用 skill 替换/重写为 10 个高度专业化的生物论文 skill，将 5 阶段流水线压缩为 3 阶段写作流水线，引入基于本地 Git 的版本控制层，并建立"风格闭环"机制保证每篇论文的语言风格都是项目专属的。

---

## 二、架构对比：原版 vs 改造版

### 2.1 流水线重构

原版 Oh-my-paper 5 阶段：
```
Survey → Ideation → Experiment → Publication → Promotion
```

改造后 3 阶段：
```
Preparation → Drafting → Finalization
```

各阶段具体内容：

**Stage 1: Preparation（准备）**
输入你的实验数据、图表、菌株表等原始材料，建立项目上下文。这一阶段对应原版的 `/omp:setup`，但初始化内容不同——不是空白科研项目，而是一个已有数据的论文写作项目。初始化时需要填入：目标期刊、通讯作者信息、菌株/质粒信息、已有图表清单。

**Stage 2: Drafting（撰写）**
核心写作阶段。按照 Methods → Results → Discussion → Introduction 的顺序（这是生物论文的实际写作顺序，不是最终排版顺序）逐 section 撰写。每个 section 完成后自动触发局部审查。

**Stage 3: Finalization（定稿）**
Abstract 生成、Figure legend 统一、全文 Review、引用核查、投稿格式适配、Checklist 终检。

### 2.2 Agent 角色重构

原版 5 个 Agent 中，Literature Scout 和 Experiment Driver 对你的场景价值有限。改造后保留 4+1 个角色（v1.3 新增 StyleKeeper）：

| 角色 | 原版对应 | 改造后职责 | 记忆范围 |
|------|---------|-----------|---------|
| **Conductor（统筹者）** | 保留 | 不变：全局规划、任务派发、状态同步 | `project_truth` · `orchestrator_state` · `tasks.json` · `review_log` · `decision_log` |
| **StyleKeeper（风格守护者）** | **新增 v1.3** | 定义和维护项目风格档案，分析范本论文，接受用户的风格反馈，调用 style-curator skill | `style_profile` · `journal_spec` · `execution_context` · `agent_handoff` |
| **Writer（写手）** | Paper Writer 扩展 | 核心角色：逐 section 撰写，调用 sci-bio-writer + zotero-ref-bridge + methods-protocol；v1.3 起支持段落级交互式共创 | `execution_context` · `manuscript_state` · `literature_bank` · `figure_registry` · `style_profile` (只读) · `agent_handoff` |
| **Reviewer（评审者）** | 保留 | 扩展：不仅做逻辑审查，还包含数据一致性检查、投稿规范检查、风格合规性检查 | `execution_context` · `project_truth` · `manuscript_state` · `style_profile` (只读) · `review_log` |
| **Formatter（格式师）** | 新增 | Figure legend 生成、Abstract 生成、期刊格式适配、投稿 checklist | `manuscript_state` · `figure_registry` · `journal_spec` · `style_profile` (只读) · `agent_handoff` |

删掉 Literature Scout 和 Experiment Driver。如果后续需要文献调研，Writer 角色可以直接调用 zotero-ref-bridge skill 完成，不需要单独的 agent。

**关于 StyleKeeper 的设计考量**：v1.2 版本里 style-curator skill 是 "谁都可以调用" 的工具，但实际使用中会遇到权责模糊的问题 —— Writer 写到一半觉得风格不对、想调整风格档案时，到底是 Writer 直接改 `style_profile.md` 还是需要切换到别的角色？有一个专门的 StyleKeeper 角色能让这件事更清晰：**所有对风格档案的写操作都必须通过 StyleKeeper 完成，Writer 和 Reviewer 只能读取**。这遵循了 Oh-my-paper 原版的"记忆隔离"原则，避免写作过程中 Writer 一边写一边"偷偷改变规则"导致风格漂移。

StyleKeeper 的典型触发时机：
1. `/omp:setup` 时首次被激活，完成风格档案初始化（通过交互和范本分析）
2. `/omp:style --refine` 时被激活，基于已完成 section 迭代风格
3. Writer 在交互式写作中发现风格档案规则不够用时，通过 `agent_handoff.md` 写入"风格规则请求"，下一次 `/omp:plan` 时 Conductor 会调度 StyleKeeper 处理

### 2.3 记忆文件重构

```
.pipeline/memory/
├── project_truth.md          # [保留] 项目基准 + 进展日志
├── orchestrator_state.md     # [保留] Conductor 编排状态
├── execution_context.md      # [保留] 当前任务上下文
├── manuscript_state.md       # [新增，替代 result_summary] 各 section 完成状态和版本
├── figure_registry.md        # [新增] 所有 Figure/Table 的元数据注册表
├── literature_bank.md        # [保留] 引用文献库（由 Zotero 同步）
├── journal_spec.md           # [新增] 目标期刊的具体要求快照
├── strain_plasmid_table.md   # [新增] 菌株和质粒信息表（Methods 写作依赖）
├── style_profile.md          # [新增 v1.2] 项目级语言风格档案（由 style-curator 生成）
├── review_log.md             # [保留] 审查反馈历史
├── agent_handoff.md          # [保留] 角色间交接
└── decision_log.md           # [保留] 已否决方向

.pipeline/tasks/
└── tasks.json                # [保留] 共享任务树
```

关键新增说明：

`manuscript_state.md` 记录每个 section 的状态（not_started / drafting / draft_complete / reviewed / revised / final），Writer 和 Reviewer 都读写它，Formatter 读取它判断是否可以进入 Finalization 阶段。

`figure_registry.md` 是所有 Figure 和 Table 的结构化登记簿，包含：编号、文件路径、panel 描述、统计方法、对应 Results 段落。figure-legend-gen skill 依赖这个文件生成图注，manuscript-reviewer skill 用它做数据一致性校验。

`strain_plasmid_table.md` 是你的菌株库快照，methods-protocol skill 写 M&M 时直接从这里拉取菌株名称、基因型、来源等信息，避免每次手动输入。

`journal_spec.md` 由 journal-formatter skill 在 Preparation 阶段根据目标期刊生成，后续所有 skill 都可以查阅字数限制、引用格式等约束。

`style_profile.md` 是 v1.2 新增的核心文件，由 `style-curator` 通过和你交互 + 分析范本论文生成，记录这个项目专属的语言风格规则。`sci-bio-writer` 写作时严格遵循它，`manuscript-reviewer` 用它做风格合规性审查，`abstract-composer` 生成摘要时也参考它的措辞偏好。详见第十一章。

---

## 三、Slash Commands 重构

| 命令 | 对应原版 | 作用 |
|------|---------|------|
| `/omp:setup` | 保留，逻辑改写 | 初始化论文项目：创建 `.pipeline/`，录入目标期刊、作者信息、菌株表，注册 Figure/Table，生成 journal_spec，**初始化 Git 仓库并安装 pre-push hook**，**调用 style-curator 生成项目级风格档案** |
| `/omp:style` | **新增 v1.2** | 重新运行或调整风格档案。`--refine` 基于已写 section 迭代风格；`--from-template <name>` 从风格库继承 |
| `/omp:write` | 保留，逻辑改写 | 按 section 写作，自动调用 Writer agent，遵循 M→R→D→I 顺序 |
| `/omp:review` | 保留 | Reviewer 对当前或全文做审查，输出到 review_log |
| `/omp:format` | 新增，替代 `/omp:experiment` | Formatter 生成 figure legend、abstract，适配期刊格式 |
| `/omp:check` | 新增，替代 `/omp:ideate` | 投稿前终检：运行 submission-checklist skill |
| `/omp:plan` | 保留 | 查看全局进展，确认下一步 |
| `/omp:history` | 新增（版本控制） | 查看可读的提交历史，支持按 section 和 type 过滤 |
| `/omp:rollback` | 新增（版本控制） | 交互式回滚到任意历史版本，支持局部回滚单个文件 |
| `/omp:snapshot` | 新增（版本控制） | 创建命名 tag 快照（如投稿前、大改前） |
| `/omp:diff` | 新增（版本控制） | 用自然语言描述两个版本之间的差异 |

删掉 `/omp:survey`、`/omp:ideate`、`/omp:experiment`、`/omp:delegate`。

---

## 四、10 个 Skill 详细设计

### 4.1 Skill 总览与原版 Skill 映射

| 新 Skill | 替代/改造的原版 Skill | 所属阶段 |
|----------|---------------------|---------|
| `style-curator` | **新增 v1.2（元 skill）** | Preparation + 写作过程中迭代 |
| `sci-bio-writer` | `inno-paper-writing` + `ml-paper-writing` + `scientific-writing` 合并重写 | Drafting |
| `figure-legend-gen` | `inno-figure-gen` 重写 | Finalization |
| `zotero-ref-bridge` | `inno-reference-audit` + `paper-finder` 合并重写 | 贯穿全程 |
| `journal-formatter` | 新增（原版无对应） | Preparation + Finalization |
| `methods-protocol` | 新增（原版无对应） | Drafting |
| `manuscript-reviewer` | `inno-paper-reviewer` 重写 | Drafting + Finalization |
| `abstract-composer` | 从 `inno-paper-writing` 中拆出 | Finalization |
| `submission-checklist` | `inno-prepare-resources` 重写 | Finalization |
| `version-guardian` | 新增（原版无对应） | 贯穿全程 |

原版 34 个 skill 中完全不保留的（与湿实验生物学无关）：`inno-deep-research`, `gemini-deep-research`, `inno-code-survey`, `inno-idea-generation`, `inno-idea-eval`, `research-idea-convergence`, `inno-experiment-dev`, `inno-experiment-analysis`, `research-experiment-driver`, `remote-experiment`, `biorxiv-database`, `dataset-discovery`, `paper-image-extractor`, `research-literature-trace`, `inno-rclone-to-overleaf`, `making-academic-presentations`, `inno-grant-proposal`, `claude-code-dispatch`, `codex-dispatch`, `academic-researcher`, `bioinformatics-init-analysis`, `research-news`, `inno-pipeline-planner`, `research-pipeline-planner`, `research-paper-handoff`, `inno-code-survey`。

### 4.2 各 Skill 详细规格

---

#### Skill 1: `sci-bio-writer`

**触发条件**：用户要求撰写论文任何 section（Introduction, Results, Discussion），或要求润色、改写某段学术文本。

**架构变更（v1.2）**：不再硬编码风格规则，改为**动态读取 `style_profile.md`**（由 `style-curator` 生成）作为写作指令。这使得同一个 skill 可以服务不同风格取向的项目——写一篇投 Nature Microbiology 的论文和一篇投 Fungal Genetics 的论文，Writer 的行为会自然地不同。

**核心工作流**：

1. 读取 `manuscript_state.md` 确定当前 section 和状态
2. 读取 `style_profile.md` 加载项目级风格规则（时态、语气、句式、禁用词、偏好短语）
3. 读取 `journal_spec.md` 加载期刊硬约束（字数、章节格式）
4. 读取 `figure_registry.md` 获取可引用的图表
5. 调用 `zotero-ref-bridge` 插入引用
6. 调用 `methods-protocol`（仅 Methods 写作时）
7. 写出 section 文本

**硬编码的领域规范**（不由 style_profile 控制，因为这些是生物学共识）：
- 物种名首次全称斜体（*Talaromyces marneffei*），后续缩写斜体（*T. marneffei*）
- 基因名斜体（*acuD*），蛋白名正体（AcuD）
- CRISPR-Cas9 连字符规范
- 菌株编号格式规范（如 PM1 正体无斜体）
- 统计显著性标注格式（*P* < 0.05, 斜体 P）

这部分规范存放在 skill 自带的 `references/fungal-genetics-conventions.md`，作为任何项目都必须遵守的基线。

**由 `style_profile.md` 动态控制的维度**（由项目决定）：
- 时态使用的具体倾向（Introduction 用多少过去时 vs 现在时）
- 段落结构偏好（Results 是否每段加小结句）
- 机制推测的大胆程度
- 连接词和过渡词偏好
- 数据描述句式
- 禁用短语清单
- 第一人称使用策略

**依赖**：`manuscript_state.md`, `style_profile.md`, `journal_spec.md`, `figure_registry.md`, `zotero-ref-bridge` skill。

**输出**：LaTeX 或 Markdown 格式的 section 文本，写入 `paper/sections/` 目录。写作结束后由 Hook 自动触发 Git commit 和局部 review。

---

#### Skill 2: `figure-legend-gen`

**触发条件**：用户要求生成 Figure legend 或 Table legend，或在 `/omp:format` 阶段自动触发。

**核心规则**：

标准格式模板：
```
Figure N. [粗体标题：一句话概括性描述]
(A) [Panel A 描述，含实验方法和关键结果]
(B) [Panel B 描述]
...
Data are presented as mean ± SD (or SEM) from N independent experiments.
Statistical significance was determined by [test name]; *P < 0.05, **P < 0.01, ***P < 0.001.
Scale bar: X μm (如适用).
[缩写定义]
```

不同图表类型的描述范式：
- 荧光显微镜图：需注明 scale bar、放大倍数、染料/荧光蛋白通道
- Western blot：需注明抗体信息、分子量 marker、loading control
- 柱状图/折线图：需注明 n 值、误差线类型（SD vs SEM）、统计检验方法
- 热图：需注明 color scale 含义、聚类方法
- 基因组浏览器截图：需注明基因组版本、坐标范围

**依赖**：读取 `figure_registry.md` 获取每个 Figure 的 panel 信息和统计方法。

---

#### Skill 3: `zotero-ref-bridge`

**触发条件**：写作中需要插入引用、查找支撑文献，或在 Review 阶段做引用完整性检查。style-curator 分析范本论文时也调用此 skill 拉取范本全文。

**底层 MCP 集成**：基于 [cookjohn/zotero-mcp](https://github.com/cookjohn/zotero-mcp) —— 这是一个 Zotero 插件（非独立 server），直接在 Zotero 客户端内运行一个 Streamable HTTP MCP server。相比其他 Zotero MCP 实现（如 54yyyu/zotero-mcp 需要单独的 Python 进程），cookjohn 版本的优势是：
- 单一部署：只需在 Zotero 里安装一个 .xpi 插件
- 实时同步：插件直接读取 Zotero 本地数据库，不经过 API 中转
- 零延迟：HTTP server 监听本地 127.0.0.1:23120
- 支持全文检索：可以检索 PDF 内容，而不仅是元数据

**前置条件**：
- Zotero 7.0+
- 安装 `zotero-mcp-plugin.xpi`（从 [Releases 页面](https://github.com/cookjohn/zotero-mcp/releases) 下载）
- 在 Zotero 偏好设置 → Zotero MCP Plugin 中启用 server
- 推荐同时安装 Better BibTeX 插件（更好的 citekey 管理）

**Claude Code MCP 配置**（写入 `.mcp.json` 或 `~/.claude.json`）：
```json
{
  "mcpServers": {
    "zotero": {
      "type": "http",
      "url": "http://127.0.0.1:23120/mcp"
    }
  }
}
```

或通过 CLI 添加：
```bash
claude mcp add zotero http://127.0.0.1:23120/mcp -t http
```

**可调用的底层 MCP 工具**（由 cookjohn/zotero-mcp 提供）：

| 工具名 | 功能 | 关键参数 |
|--------|------|---------|
| `search_library` | 智能搜索文献库 | `q`, `title`, `creator`, `year`, `yearRange`, `tag`, `itemType`, `fulltext`, `fulltextMode`, `mode` (minimal/preview/standard/complete), `relevanceScoring`, `sort`, `limit`, `offset` |
| `get_item_details` | 获取单条文献完整元数据 | `itemKey` (必需), `mode` |
| `get_item_abstract` | 获取文献摘要 | `itemKey` (必需), `format` (json/text) |
| `search_annotations` | 搜索笔记和批注 | `q`, `itemKeys`, `types`, `colors`, `tags`, `mode` |
| `search_fulltext` | 全文检索所有文献 PDF 内容 | `q` (必需), `itemKeys`, `contextLength`, `caseSensitive` |
| `search_collections` | 按名称搜索 collection | `q`, `limit` |
| `find_by_identifier` | 按 DOI/ISBN 查找 | identifier |

**zotero-ref-bridge 在底层 MCP 之上提供的高层封装**（skill 特有逻辑，非 MCP 原生）：

| 高层功能 | 实现方式 |
|---------|---------|
| `cite(citekey)` | 调 `get_item_details` 获取元数据 → 按 `journal_spec.md` 中的引用格式输出 `\cite{}` 或内联引用 |
| `batch_cite(citekeys[])` | 多次调 `get_item_details` → 按年份/字母排序 → 批量格式化 |
| `suggest_refs(paragraph_text)` | 从段落提取关键词 → 调 `search_library` 用 `fulltext` + `relevanceScoring` 返回 Top 5 候选 |
| `check_missing()` | 扫描 `paper/sections/*.tex` 中的 `\cite{}` → 检查 Zotero 库中是否存在该 citekey |
| `check_unused()` | 扫描 `paper/refs/references.bib` → 检查每个 entry 是否被正文引用 |
| `fetch_reference_paper(doi_or_key)` | 调 `get_item_details` + `search_fulltext` 获取范本论文的全文,供 style-curator 分析 |
| `sync_bib()` | 从 Zotero collection 导出 .bib 到 `paper/refs/references.bib`（需 Better BibTeX 配合） |

**引用格式切换**：
- 根据 `journal_spec.md` 自动选择：
  - Vancouver 编号制（mBio, Nature Microbiology: [1], [2, 3]）
  - Author-Year 制（PLOS, Molecular Microbiology: (Zhang et al., 2024)）
  - Nature 上标制

**依赖**：读取 `journal_spec.md` 确定引用格式。依赖 Zotero 客户端正在运行且插件已启用。

**配置文件** `.pipeline/config/zotero.json`（由 `/omp:setup` 生成）：
```json
{
  "mcp_url": "http://127.0.0.1:23120/mcp",
  "collection_name": "T_marneffei_project",
  "bib_style": "vancouver",
  "bib_output_path": "paper/refs/references.bib",
  "auto_sync_on_save": true,
  "fulltext_search_enabled": true
}
```

**健壮性处理**：
- Zotero 未运行时：skill 检测到连接失败 → 提示"请先启动 Zotero 客户端" → 不阻塞写作流程，允许 Writer 先用占位符 `[CITE: keyword]` 继续写作，后续统一回填
- MCP server 响应慢：设置 30 秒超时
- 搜索无结果：提示用户可能需要先将文献添加到 Zotero 库，或检查 collection 过滤是否过严

---

#### Skill 4: `journal-formatter`

**触发条件**：`/omp:setup` 初始化时自动触发（生成 journal_spec），`/omp:format` 阶段适配最终格式。

**内置期刊模板**（references/journal-templates/ 目录）：

优先支持的真菌学/微生物学期刊：
- mBio（ASM 格式，Abstract ≤250 words，正文无字数限制，Vancouver 引用）
- PLOS Pathogens（Author-Year 引用，structured abstract 不要求，正文无硬性字数限制）
- Fungal Genetics and Biology（Elsevier 格式，graphical abstract 可选）
- eLife（无字数限制，structured digest，CC-BY）
- Nature Microbiology（Abstract ≤150 words，正文 ≤5000 words，Methods 单独 section）
- mSphere（ASM 短报告格式）
- Molecular Microbiology（Wiley，Author-Year）
- Genetics（GSA 格式）

每个模板包含：
- 章节顺序和命名规范
- Abstract 格式和字数限制
- 引用格式
- Figure/Table 的格式要求（分辨率、文件格式、尺寸）
- Supplementary materials 的组织规范
- Cover letter 模板
- 特殊要求（如 Data Availability Statement 的具体措辞）

**输出**：写入 `journal_spec.md`，供所有其他 skill 查阅。

---

#### Skill 5: `methods-protocol`

**触发条件**：Writer 进入 Methods section 撰写时自动触发。

**内置实验方法模板**（references/method-templates/ 目录）：

真菌遗传学核心方法：
- 菌株培养条件（YPD / PDA / MM，温度，时间）
- 基因敲除构建：CRISPR-Cas9 方案（sgRNA 设计软件、供体 DNA 构建、转化方法）
- 同源重组方案（split-marker / fusion PCR）
- 原生质体制备和转化（PEG 介导 / 电转）
- 荧光蛋白标记菌株构建

分子生物学核心方法：
- RNA 提取（TRIzol / kit + 具体 catalog number 模板）
- RT-qPCR（引物设计原则、内参基因选择、ΔΔCt 计算）
- RNA-seq 文库构建（polyA 富集 vs rRNA 去除，测序平台和参数）
- Western blot（蛋白提取、抗体信息表模板、ECL 检测）
- Southern blot（限制酶选择、探针标记方法）

生物信息学分析方法：
- RNA-seq 分析 pipeline（比对工具 + 版本号、参考基因组版本、定量方法）
- 差异表达分析（DESeq2 参数、padj 阈值、fold change 阈值）
- GO / KEGG 富集分析（使用工具、校正方法、显著性阈值）
- 系统发育分析（比对工具、建树方法、bootstrap 值）

统计方法声明模板：
- Student's t-test（两组比较）
- One-way ANOVA + Tukey's post-hoc（多组比较）
- Mann-Whitney U test（非参数）
- 注明软件版本（GraphPad Prism X.X / R X.X.X）

**依赖**：读取 `strain_plasmid_table.md` 自动填入菌株信息。自动提醒缺失的 catalog number 和 lot number。

---

#### Skill 6: `manuscript-reviewer`

**触发条件**：每个 section 的 draft_complete 状态触发局部 review，或 `/omp:review` 手动触发全文 review。

**审查维度（按优先级排序）**：

1. 数据一致性：
   - Figure 中的数据趋势与 Results 文字描述是否一致
   - 统计显著性标注（* P < 0.05）与文字中的"significantly"是否对应
   - 样本量 n 值在 Methods 和 Figure legend 中是否一致

2. 逻辑完整性：
   - Results 中的每个发现是否在 Discussion 中被讨论
   - Introduction 提出的问题是否在 Results 中被回答
   - Discussion 中的推测是否有 Results 数据支撑

3. 引用完整性：
   - 关键声明（"It has been reported that..."）是否有引用
   - 引用是否是一手文献（不推荐引用 review 来支撑具体数据）
   - 引用是否足够新（同领域 3 年内有新文献是否遗漏）

4. Reviewer 常见攻击点预判：
   - 对照实验是否完整（阴性/阳性对照）
   - 是否存在 overclaim（"prove" 应改为 "suggest/indicate"）
   - 生物学重复次数是否充分（n ≥ 3）
   - 是否有 complementation 实验验证 knockout 表型
   - 是否讨论了 off-target 可能性（CRISPR 相关）

5. 语言质量：
   - 被动/主动语态是否恰当
   - 时态一致性
   - 拼写和语法（尤其是菌名斜体、基因名斜体）

6. **风格合规性（v1.2 新增）**：
   - 是否使用了 `style_profile.md` 中列出的禁用短语
   - 句子复杂度是否符合项目设定（短句 vs 复合句偏好）
   - 段落结构是否符合 section 特定的偏好（如 "Results 每段是否有小结句"）
   - 机制推测的措辞强度是否符合 `speculation_boldness` 设定
   - 第一人称使用是否符合 `first_person_usage` 设定
   - 偏好短语的覆盖率是否足够（如果 style_profile 列出了 10 个偏好过渡词，但正文一个都没用，可能说明 Writer 没有充分遵循风格）

风格合规性审查的输出会被单独标记为 `[STYLE]` 类别，方便和内容类问题区分。轻微的风格偏离只会标为 Suggestion，但如果命中明确的禁用词或严重违反设定，会升级为 Minor 或 Major。

**输出**：结构化 review report 写入 `review_log.md`，包含严重程度分级（Critical / Major / Minor / Suggestion）和类别标签（[DATA] / [LOGIC] / [REF] / [ATTACK] / [LANG] / [STYLE]）。

---

#### Skill 7: `abstract-composer`

**触发条件**：所有 section 进入 reviewed 状态后，`/omp:format` 阶段触发。

**核心规则**：

非结构化摘要（一段式，如 Nature 系列）：
- 1-2 句背景 → 1 句知识空白 → 1 句 "Here, we..." → 3-4 句主要发现（含关键数据）→ 1-2 句意义
- 严格控制字数（从 journal_spec 读取限制）

结构化摘要（如 PLOS 系列，如需）：
- Background / Methods / Results / Conclusion 四段
- 每段独立可读

通用规则：
- 不引入正文中没有的信息
- 不包含引用（除非期刊特别要求）
- 必须包含关键定量数据（fold change、P 值等）
- 首次出现缩写需要全称

**依赖**：读取全部已完成的 section，读取 `journal_spec.md` 确定格式和字数。

---

#### Skill 8: `submission-checklist`

**触发条件**：`/omp:check` 命令触发。

**检查清单（分区块）**：

作者信息：
- [ ] 所有作者姓名、单位、ORCID
- [ ] 通讯作者标注（星号 + email）
- [ ] 作者贡献声明（CRediT taxonomy）

稿件完整性：
- [ ] Title（字数限制、是否含物种名）
- [ ] Running title / Short title
- [ ] Abstract（字数检查）
- [ ] Keywords（数量和格式）
- [ ] 所有 section 按期刊要求排序
- [ ] 所有缩写在首次出现时定义

引用完整性：
- [ ] 正文中所有 \cite{} 在 .bib 中存在
- [ ] .bib 中无未引用的条目
- [ ] 引用格式符合期刊要求

Figure / Table：
- [ ] 所有 Figure/Table 在正文中被引用
- [ ] Figure 文件格式和分辨率符合要求（TIFF 300 dpi / EPS）
- [ ] Figure legend 完整（panel 描述、统计信息、缩写）
- [ ] Supplementary Figure/Table 命名规范

声明类：
- [ ] Data Availability Statement（GEO/SRA accession number）
- [ ] Ethics Statement（动物实验/人体实验审批号，如适用）
- [ ] Conflict of Interest Declaration
- [ ] Funding Statement
- [ ] Acknowledgments

投稿文件：
- [ ] Cover Letter
- [ ] Manuscript（Word/LaTeX/PDF）
- [ ] Figure files（单独文件）
- [ ] Supplementary materials
- [ ] Highlights / Graphical Abstract（如期刊要求）

**输出**：带 ✓/✗ 状态的 checklist 报告，未通过项标红并给出修复建议。

---

## 五、项目目录结构重构

```
my-bio-paper/
├── paper/                          # 写作工作区
│   ├── main.tex                    # 主 LaTeX 文件
│   ├── sections/
│   │   ├── introduction.tex
│   │   ├── results.tex
│   │   ├── discussion.tex
│   │   └── methods.tex
│   ├── refs/
│   │   └── references.bib          # Zotero 导出/同步
│   └── figures/                    # Figure 源文件
│       ├── Fig1_xxx.tiff
│       └── Fig2_xxx.tiff
│
├── supplementary/                  # 补充材料
│   ├── tables/
│   └── figures/
│
├── submission/                     # 投稿文件（最终产物）
│   ├── manuscript.pdf
│   ├── cover_letter.docx
│   └── figures/
│
├── skills/                         # 10 个自定义 skill
│   ├── style-curator/               # [新增 v1.2]
│   │   ├── SKILL.md
│   │   └── references/
│   │       ├── interview-questions.md   # 风格配置交互问题清单
│   │       ├── style-schema.md          # style_profile.md 的 schema 定义
│   │       ├── llm-analysis-prompt.md   # [v1.3] 范本论文 LLM 分析的 prompt 模板
│   │       └── journal-presets/         # 按期刊的默认风格预设
│   │           ├── nature-mb.md
│   │           ├── mbio.md
│   │           └── fgb.md
│   ├── sci-bio-writer/
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── fungal-genetics-conventions.md  # 只保留领域硬规范,风格由 style_profile 动态注入
│   ├── figure-legend-gen/
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── legend-templates.md
│   ├── zotero-ref-bridge/
│   │   ├── SKILL.md
│   │   └── scripts/
│   │       ├── check-citations.py
│   │       └── sync-bib.sh
│   ├── journal-formatter/
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── journal-templates/
│   │           ├── mbio.md
│   │           ├── plos-pathogens.md
│   │           ├── fgb.md
│   │           ├── elife.md
│   │           └── nature-microbiology.md
│   ├── methods-protocol/
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── method-templates/
│   │           ├── crispr-knockout.md
│   │           ├── rnaseq-pipeline.md
│   │           ├── rt-qpcr.md
│   │           ├── western-blot.md
│   │           └── fungal-transformation.md
│   ├── manuscript-reviewer/
│   │   └── SKILL.md
│   ├── abstract-composer/
│   │   └── SKILL.md
│   ├── submission-checklist/
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── checklist-template.md
│   └── version-guardian/
│       ├── SKILL.md
│       └── scripts/
│           ├── auto-commit.sh
│           ├── smart-message.py
│           └── install-hooks.sh
│
├── hooks/                          # [v1.3] 独立的 Hook 脚本目录
│   └── figure-watcher/
│       ├── watch-figures.sh        # 监听 paper/figures/ 变化
│       ├── parse-metadata.py       # 提取图像尺寸/DPI/色彩空间
│       └── register-figure.py      # 写入 figure_registry.md
│
├── ~/.omp/                         # [新增 v1.2] 用户全局目录
│   └── style-library/              # 跨项目风格模板库
│       ├── nature-mb-fungal.md
│       └── mbio-transcription.md
│
├── .git/                           # 本地 Git 仓库（不推送到任何远程）
│   └── hooks/
│       └── pre-push                # 硬拦截任何 push 操作
├── .gitignore                      # 严格过滤数据和编译产物
│
├── .pipeline/
│   ├── tasks/
│   │   └── tasks.json
│   ├── config/
│   │   ├── zotero.json             # Zotero MCP 配置
│   │   └── project.json            # 项目元信息（期刊、作者等）
│   ├── docs/
│   │   └── research_brief.json     # 保留兼容原版
│   └── memory/                     # 11 个记忆文件 (v1.3: +style_profile, +reference_analysis/)
│       └── reference_analysis/     # [v1.3] 范本论文 LLM 分析结果
│           ├── zhang2023fungal.json
│           ├── kumar2024virulence.json
│           └── _merged.json         # 多范本合成档案
│
├── .claude/
│   └── settings.json               # Hook 注册
├── CLAUDE.md                       # 项目级 Claude 指令
└── AGENTS.md                       # Agent 角色定义
```

---

## 六、Hook 机制调整

| Hook | 触发时机 | 改造内容 |
|------|---------|---------|
| **SessionStart** | 每次打开 Claude Code | 注入 `project_truth` + `manuscript_state` 摘要，提示选择角色（v1.3: Writer / Reviewer / Formatter / StyleKeeper 四选一，Conductor 在 `/omp:plan` 时自动激活） |
| **Stop** | 任务完成时 | 自动更新 `manuscript_state.md` 中对应 section 的状态 |
| **PostToolUse (Write)** | 任何 `paper/sections/` 下文件写入后 | 检测 section 完成，触发自动局部 review（可配置开关） |

新增 Hook：

| Hook | 触发时机 | 作用 |
|------|---------|------|
| **PostToolUse (BibWrite)** | `references.bib` 文件变更后 | 自动运行引用一致性检查（check_unused + check_missing） |
| **figure-watcher（v1.3）** | `paper/figures/` 目录下新增或修改 .tiff/.tif/.png/.svg/.pdf 文件时 | 自动登记到 `figure_registry.md`，提示用户补充 panel 描述和统计方法 |

### 6.1 figure-watcher Hook 详细设计（v1.3 新增）

**工作流程**：

1. **检测触发**：通过 Claude Code 的 `PostToolUse` Hook 监听任何写入 `paper/figures/` 的操作。也可以由用户手动 `/omp:figures scan` 触发全目录扫描。

2. **文件名智能解析**：期望的命名规范是 `Fig<N>_<brief_description>.<ext>`，例如：
   - `Fig1_growth_curves.tiff` → 识别为 Figure 1，初始描述 "growth curves"
   - `Fig2_western_blot_AcuD.tiff` → 识别为 Figure 2，初始描述 "western blot AcuD"
   - `FigS1_supplementary_strains.png` → 识别为 Supplementary Figure 1
   - `Table1_strain_list.tiff` → 识别为 Table 1

   如果文件名不符合规范（如 `image1.tiff` 或 `最终版.tiff`），Hook 会提示重命名建议但不强制执行，并把文件标记为 `[需要人工确认]`。

3. **提取图像元数据**：使用 `identify` (ImageMagick) 或 Python PIL 读取：
   - 尺寸（宽 × 高，像素）
   - DPI（分辨率，用于判断是否满足期刊要求的 300 dpi）
   - 色彩空间（RGB / CMYK / Grayscale）
   - 文件大小
   - 创建时间

4. **登记到 figure_registry.md**：追加一个条目，例如：

   ```markdown
   ## Figure 2
   
   - **File**: `paper/figures/Fig2_western_blot_AcuD.tiff`
   - **Registered**: 2026-04-07T15:20:00 (auto by figure-watcher)
   - **Dimensions**: 2480 × 1860 px
   - **DPI**: 300 ✓ (meets journal requirement)
   - **Color**: RGB
   - **File size**: 4.2 MB
   - **Parsed title**: western blot AcuD
   - **Status**: [NEEDS_HUMAN_ANNOTATION] ⚠️
   
   ### Panels
   _to be filled by user or during /omp:write results_
   - (A) _description pending_
   - (B) _description pending_
   
   ### Statistics
   _to be filled_
   - Test: ?
   - n: ?
   - Error bars: ?
   
   ### Referenced in
   - Results section: _not yet referenced_
   ```

5. **状态标记**：新登记的 Figure 默认状态是 `[NEEDS_HUMAN_ANNOTATION]`。`figure-legend-gen` skill 在 Finalization 阶段会扫描所有 Figure，遇到这个状态的条目时**强制中断并要求用户补全 panel 描述和统计信息**——这是一个质量 gate。

6. **Git 联动**：figure-watcher 登记后，`version-guardian` 自动生成一个 `figure(registry): auto-register Fig2_western_blot_AcuD` 的 commit。

7. **用户交互（重要）**：Hook 不会直接打断你当前的工作流，但会在 agent_handoff.md 里留下一条提醒消息。下次 SessionStart 时，Claude 会在注入上下文时说："注意：距上次会话以来新增了 2 个 Figure 尚未完成元数据登记。是否现在补全？"

**实现位置**：
- Hook 脚本：`skills/figure-watcher/scripts/watch-figures.sh`
- 元数据解析逻辑：`skills/figure-watcher/scripts/parse-metadata.py`
- 注册机制：在 `/omp:setup` 时把 Hook 写入 `.claude/settings.json`

**失败容错**：
- ImageMagick 或 PIL 不可用时，降级为只解析文件名，跳过尺寸/DPI 检查（记录 `[METADATA_INCOMPLETE]`）
- 文件被频繁覆盖时（如用户反复导出同一版本），使用 debounce 避免重复注册（同一路径 5 分钟内只登记一次）

**figure-watcher 是否算一个独立的 "skill"？** v1.3 的设计选择是：它本质上是一个 Hook 脚本集合，不是完整的 skill（没有 SKILL.md、没有 references），所以它不进入 10 个 skill 的计数。它直接由 `/omp:setup` 安装到 `.claude/settings.json` 作为持续运行的后台 Hook。

---

## 七、Skill 间数据流与联动

```
/omp:setup
  ├── 初始化 Git 仓库 + pre-push hook
  ├── journal-formatter → 生成 journal_spec.md
  ├── 用户输入 → 生成 strain_plasmid_table.md
  ├── 用户输入 → 生成 figure_registry.md
  └── style-curator → 生成 style_profile.md
      ├── 读 journal_spec 获取期刊默认风格
      ├── 询问是否提供范本论文
      │   └── 如提供 → 调 zotero-ref-bridge.fetch_reference_paper → 分析全文提取特征
      └── 交互式问题链 → 确定风格维度 → 写入 style_profile.md

/omp:style --refine（写作过程中按需调用）
  └── style-curator
      ├── 读取已完成的 section
      ├── 询问哪段最满意/最不满意
      └── 更新 style_profile.md

/omp:write (Methods)
  └── Writer Agent
      ├── 读 style_profile.md（加载风格规则）
      ├── 调用 methods-protocol（读 strain_plasmid_table）
      ├── 调用 sci-bio-writer（按 style_profile 写作）
      └── 调用 zotero-ref-bridge（插入引用）
      → 写入 sections/methods.tex
      → 更新 manuscript_state.md 为 draft_complete
      → PostToolUse Hook 触发 manuscript-reviewer 局部审查
      → version-guardian 自动 commit

/omp:write (Results)
  └── Writer Agent
      ├── 读 style_profile.md
      ├── 调用 sci-bio-writer（读 figure_registry 引用图表）
      └── 调用 zotero-ref-bridge
      → 写入 sections/results.tex

/omp:write (Discussion)
  └── Writer Agent
      ├── 读 style_profile.md
      ├── 调用 sci-bio-writer（读 manuscript_state 关联 Results 发现）
      └── 调用 zotero-ref-bridge
      → 写入 sections/discussion.tex

/omp:write (Introduction)
  └── Writer Agent
      ├── 读 style_profile.md
      ├── 调用 sci-bio-writer
      └── 调用 zotero-ref-bridge（此阶段引用最密集）
      → 写入 sections/introduction.tex

/omp:format
  └── Formatter Agent
      ├── 调用 figure-legend-gen（读 figure_registry）
      ├── 调用 abstract-composer（读所有 sections + style_profile）
      └── 调用 journal-formatter（最终格式适配）
      → 输出到 submission/ 目录

/omp:review（全文）
  └── Reviewer Agent
      └── 调用 manuscript-reviewer
          └── 包含风格合规性检查（对照 style_profile.md）
      → 写入 review_log.md（带类别标签）

/omp:check
  └── 调用 submission-checklist
      ├── 读 manuscript_state（所有 section 是否 final）
      ├── 读 figure_registry（图表完整性）
      ├── 读 journal_spec（格式合规性）
      └── 调用 zotero-ref-bridge.check_missing/unused
      → 输出 checklist 报告
```

---

## 八、CLAUDE.md 核心指令

写入项目根目录的 `CLAUDE.md`，作为 Claude Code 的持久上下文：

```markdown
# Oh My Bio-Paper — Project Context

## 项目类型
这是一个湿实验生物学论文写作项目，非 ML/计算类。
所有数据和图表已就绪，当前阶段是论文撰写。

## 研究领域
真菌分子生物学，模式菌 Talaromyces marneffei。
常涉及：CRISPR-Cas9 基因敲除、转录调控、RNA-seq、荧光显微镜。

## 写作规范
- 基因名斜体（*acuD*），蛋白名正体（AcuD）
- 菌名首次全称斜体后续缩写（*Talaromyces marneffei* → *T. marneffei*）
- Methods 用过去时被动语态
- Results 用过去时
- Discussion 用现在时讨论意义，过去时回溯本研究
- 避免 AI 写作痕迹过重的表达

## 工作流
撰写顺序：Methods → Results → Discussion → Introduction → Abstract
每 section 完成后自动触发局部审查。

## 工具链
- LaTeX 排版
- Zotero 管理参考文献（通过 MCP 集成）
- 目标期刊信息见 .pipeline/memory/journal_spec.md
```

---

## 九、版本控制系统（本地 Git）

### 9.1 为什么需要版本控制

论文写作过程中会出现大量反复修改：Writer agent 重写段落、Reviewer 提出修订、你自己手动润色、Formatter 调整格式。如果没有版本控制，你会面临三个痛点：

第一，**回滚困难**。Agent 自动改写了某个段落，但你觉得原来那版其实更好——没有 Git 的话就只能凭记忆找回来。第二，**无法追溯**。两周前的 Discussion 和现在的有什么区别？哪些是 Reviewer 建议改的、哪些是你自己改的？第三，**协作边界模糊**。当 Writer、Reviewer、你自己都在改同一份 `results.tex` 时，需要清晰的提交记录来区分谁做了什么。

Git 天然解决这三个问题。关键约束是：**仓库只存在本地**，不 push 到任何远程。这保证了未发表数据的安全性，也避免了 .gitignore 配置出错导致泄露的风险。

### 9.2 仓库范围与 .gitignore 策略

Git 仓库的 root 设在项目根目录（`my-bio-paper/`），tracking 范围经过严格筛选——只追踪文本类的写作产物，不追踪数据文件、图片源文件、编译产物、Zotero 缓存。

`.gitignore` 模板：

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

# 绝对禁止推送到任何远程
# （这个注释是提醒，实际通过 pre-push hook 强制拦截）
```

明确**会**被追踪的内容：
- `paper/sections/*.tex`（所有正文 section，核心追踪目标）
- `paper/main.tex`（主文件）
- `paper/refs/references.bib`（引用库快照）
- `.pipeline/memory/*.md`（所有记忆文件，这样每次 agent 修改记忆都能回溯）
- `.pipeline/tasks/tasks.json`
- `.pipeline/config/project.json`（不含 zotero.json，因为里面可能有 API key）
- `skills/**/*.md`（skill 定义本身也纳入版本控制，方便迭代 skill）
- `CLAUDE.md`, `AGENTS.md`

### 9.3 防止推送到远程的硬保护

即使 tracking 范围已经排除了数据文件，仍然要用 pre-push hook 做最后一道防线，万一将来某一天你或 agent 不小心 `git remote add` 了一个仓库并尝试推送，hook 会直接拦截。

`.git/hooks/pre-push` 脚本内容：

```bash
#!/bin/bash
# Oh My Bio-Paper: 禁止任何 push 操作
echo "================================================"
echo "ERROR: This repository is LOCAL-ONLY."
echo "Pushing to any remote is blocked by pre-push hook."
echo "If you really need to back up, use rsync to an"
echo "encrypted external drive or a private NAS."
echo "================================================"
exit 1
```

此 hook 在 `/omp:setup` 时自动创建并设置可执行权限。额外的双保险：`/omp:setup` 检查 `git remote -v` 输出，如果发现有 remote 配置，立即警告并让用户确认是否要移除。

### 9.4 提交规范（由 version-guardian 执行）

为了让 Git 历史真正有用（而不是一串 "update" 提交），所有 agent 触发的提交都必须遵循结构化 commit message 规范：

```
<type>(<scope>): <subject>

<body>

<footer>
```

`type` 枚举：
- `draft` — Writer 新增草稿内容（如 `draft(results): add Fig2 description`）
- `revise` — Writer 根据 review 反馈修订（如 `revise(discussion): address reviewer critical #3`）
- `polish` — 你手动润色（如 `polish(introduction): tighten opening paragraph`）
- `format` — Formatter 调整格式（如 `format(all): switch to mBio citation style`)
- `review` — Reviewer 写入 review_log（如 `review(results): 2 critical, 4 major issues`）
- `figure` — figure-legend-gen 更新 legend
- `ref` — zotero-ref-bridge 更新引用
- `meta` — 记忆文件更新（如 `meta(state): mark methods as draft_complete`）
- `config` — 期刊 spec、项目配置变更
- `checkpoint` — 重要节点快照（手动打 tag）

`scope` 对应 section 名或模块名：`methods`, `results`, `discussion`, `introduction`, `abstract`, `figures`, `refs`, `all`。

`footer` 包含触发来源和 agent 角色：
```
Agent: Writer
Skill: sci-bio-writer, zotero-ref-bridge
Trigger: /omp:write results
```

这样后续用 `git log --oneline --grep="revise.*critical"` 就能快速定位所有针对 critical 评审意见的修订。

### 9.5 分支策略

保持简单：**不使用多分支，所有工作都在 `main` 分支上线性推进。**

这是因为论文写作不像代码开发——它本质上是一个线性迭代过程，不会有并行的 feature 需要合并。多分支反而会增加心智负担。需要实验性尝试时（比如"我想试试换一种 Discussion 的叙事角度"），用 Git tag 打快照而不是开分支：

```bash
git tag checkpoint/before-discussion-rewrite-20260407
```

事后如果新版不好，`git reset --hard checkpoint/before-discussion-rewrite-20260407` 就能回到快照点。

**唯一的例外**：投稿前创建一个 `submission/v1` tag 作为永久快照；如果收到 reviewer 意见后做 major revision，创建 `submission/v2` tag。这样将来能精确追溯"我们当初投出去的到底是哪一版"。

### 9.6 Skill 9: `version-guardian`

**触发条件**：自动触发（由 Hook 调用）或手动 `/omp:history`, `/omp:rollback`, `/omp:snapshot` 命令触发。

**核心功能**：

1. **自动提交**（由 Hook 驱动，见 9.7）：
   - 每次 Writer 完成一个 section draft → `draft(section): ...`
   - 每次 Reviewer 写入 review_log → `review(section): N critical, M major`
   - 每次 Formatter 调整格式 → `format(scope): ...`
   - 每次记忆文件更新 → `meta(file): ...`

2. **智能 commit message 生成**：
   - Agent 完成任务后，version-guardian 分析 git diff，自动提炼 subject 和 body
   - 比如检测到 `results.tex` 新增了 200 行且提到 "Fig. 3"，自动生成 `draft(results): add Fig3 analysis and discussion`

3. **历史查询**（`/omp:history`）：
   - 展示最近 N 次提交的可读历史
   - 支持按 section 过滤：`/omp:history results` 只看 Results 的修改历史
   - 支持按 type 过滤：`/omp:history --type revise` 只看修订类提交

4. **回滚**（`/omp:rollback`）：
   - 列出最近的提交，让你选择回滚到哪一个
   - 回滚前强制创建一个 `pre-rollback/` tag，防止误操作
   - 支持局部回滚：只回滚某个文件（`git checkout <commit> -- paper/sections/results.tex`）而不影响其他 section

5. **快照**（`/omp:snapshot <label>`）：
   - 手动创建命名 tag，用于标记重要节点
   - 例：`/omp:snapshot before-boss-review`, `/omp:snapshot submission-v1`

6. **Diff 解释**（`/omp:diff <commit1> <commit2>`）：
   - 不是简单输出 `git diff`，而是用 Claude 的理解能力生成人类可读的差异描述
   - 例：输入两个 commit，输出"这次修改主要是在 Discussion 第二段增加了对 off-target 效应的讨论，并新增了 2 个引用 (Chen 2023, Kumar 2024)"

7. **安全检查**（`/omp:setup` 时调用）：
   - 验证 `.gitignore` 存在且包含必要规则
   - 验证 pre-push hook 已安装
   - 扫描 `git remote -v`，发现任何 remote 都警告
   - 扫描已 track 的文件，如果发现任何 .tiff/.xlsx/.csv 被误 track，警告并提供清理命令

**依赖**：Git 命令行（系统预装）。无需额外 Python 包。

### 9.7 Hook 扩展

在原有 3 个 Hook 基础上，增加 Git 自动提交 Hook：

| Hook | 触发时机 | version-guardian 行为 |
|------|---------|---------------------|
| **SessionStart** | 打开 Claude Code | 输出"上次会话以来的提交摘要"（`git log` 最近 5 条），让你快速回忆上下文 |
| **PostToolUse (Write)** | 写入 `paper/sections/*.tex` | 延迟 30 秒（允许同一次任务的多次写入合并），然后调用 version-guardian 自动提交 |
| **PostToolUse (Write)** | 写入 `.pipeline/memory/*.md` | 立即提交，type=meta |
| **PostToolUse (Write)** | 写入 `paper/refs/references.bib` | 立即提交，type=ref |
| **Stop** | 任务完成时 | 如果有未提交的更改，强制做一次 flush commit |

**延迟合并策略**：Writer 写一个 Results section 可能分多次调用 Write 工具（先写框架、再填内容、再插引用）。如果每次 Write 都触发 commit，会产生一堆零碎的无意义提交。version-guardian 用一个 30 秒的 debounce 窗口——在这段时间内的连续写入会被合并为一个 commit，提交消息综合描述所有变更。

### 9.8 新增 Slash Commands

| 命令 | 作用 |
|------|------|
| `/omp:history [section] [--type <type>]` | 查看提交历史 |
| `/omp:rollback` | 交互式回滚 |
| `/omp:snapshot <label>` | 创建命名 tag 快照 |
| `/omp:diff <commit1> [commit2]` | 用自然语言描述两个版本的差异 |

### 9.9 典型使用场景

**场景 1：Agent 改坏了我的段落**
```
我手写了一段精心打磨的 Discussion 开头。
Writer 执行 /omp:write discussion 时自动重写了这一段，我觉得新版本不如原版。
解决：/omp:history discussion 查看最近提交，找到 Writer 那次提交之前的 hash，
     /omp:rollback 选择回滚该文件到前一个状态。
```

**场景 2：投稿前想对比大幅修改**
```
收到导师反馈后做了大量修订。
我想清楚知道"导师反馈前"vs"修订后"全文差异。
解决：修订前先 /omp:snapshot before-advisor-feedback。
     完成修订后 /omp:diff before-advisor-feedback HEAD，
     version-guardian 输出人类可读的 section-by-section 差异报告。
```

**场景 3：Reviewer 质疑某个声明从哪来**
```
Reviewer 2 问："Line 234 这个数据的来源是哪次实验？"
我想查这句话是什么时候加进去的，依据是什么。
解决：git blame paper/sections/results.tex（version-guardian 封装为 /omp:blame），
     找到对应 commit，查看 commit message 和 body 里的 agent 触发记录。
```

**场景 4：实验性尝试**
```
我想试试把 Discussion 改成"从机制角度切入"而不是"从表型角度切入"。
不确定是否比当前版本好。
解决：/omp:snapshot before-discussion-angle-change，
     放手让 Writer 重写。如果效果不好，/omp:rollback 一键回到快照。
```

---

## 十、风格闭环系统（Style Closed Loop）

### 10.1 问题背景

v1.0 和 v1.1 的 `sci-bio-writer` 把风格规则硬编码在 skill 的 references 文件里，这带来了一个根本性问题：**每篇论文的最佳风格是不同的**。

一篇投 Nature Microbiology 的论文需要故事感和强卖点；一篇投 Fungal Genetics 的技术型论文需要克制精确；综述和原创研究的语气更是天差地别。如果 `sci-bio-writer` 是静态的，你每次写新论文都要手动修改 skill 的 references 文件，改完之后上一篇论文的配置又丢了。

v1.2 的解决方案是把"风格配置"从 skill 内部剥离出来，变成**项目级的动态产物**，由一个专门的元 skill 负责生成和维护。这就形成了一个三角闭环：

```
style-curator ──生成──> style_profile.md
                             │
                             │ 读取
                             ↓
                      sci-bio-writer ──> 写出 section
                             ↑                │
                             │                │ 审查
                             │                ↓
                      manuscript-reviewer ←── 风格合规性检查
                             │
                             │ 反馈
                             ↓
                   /omp:style --refine 迭代风格档案
```

定义风格 → 执行风格 → 审查风格 → 反馈迭代。这让整个系统从"一次性配置"变成"持续演进"。

### 10.2 Skill 10: `style-curator`

**触发条件**：`/omp:setup` 初始化时自动调用，`/omp:style` 手动调用（含 `--refine` 和 `--from-template` 选项）。

**核心功能**：

1. **分析目标期刊风格倾向**
   读取 `journal_spec.md`，根据期刊类型加载对应的默认风格预设（存放在 `skills/style-curator/references/journal-presets/`）。例如 Nature Microbiology 预设倾向故事性强、第一人称使用、机制推测相对大胆；FGB 预设倾向被动语态、技术严谨、保守措辞。

2. **分析范本论文（可选但强烈推荐）—— v1.3 改为 LLM 原生分析**
   询问你是否提供 1-3 篇 "我希望我的论文读起来像这样" 的范本论文。接受的输入形式：
   - Zotero 中已有的条目（提供 citekey 或让你从 collection 中选）
   - DOI（自动通过 zotero-ref-bridge 查找或导入）
   - 本地 PDF 路径

   拿到范本后，通过 `zotero-ref-bridge.fetch_reference_paper` 调用 cookjohn/zotero-mcp 的 `search_fulltext` 和 `get_item_details` 工具提取全文。**然后直接由当前会话的大语言模型（Claude 或你使用的任何其他模型）对全文进行风格分析**，而不是运行任何外部脚本（如 v1.2 中的 `analyze-reference.py`）。

   **为什么改为 LLM 原生分析**：
   - 脚本化路线（regex + spaCy + POS tagging）能捕捉统计特征（时态比例、句子长度），但捕捉不到真正重要的"写作感觉"——比如"作者在 Discussion 开头用了一个反直觉的观察作为钩子"，这种高层结构只有 LLM 能理解。
   - 脚本化路线需要额外依赖（spaCy 模型、语言学库），增加环境配置成本。
   - LLM 原生分析可以直接输出结构化 JSON，供后续 skill 消费，中间不需要额外的解析层。

   **LLM 分析任务的 prompt 结构**：StyleKeeper 调用 style-curator skill，后者构造一个高度结构化的分析 prompt，内容包括：
   - 完整的范本论文全文（按 section 切分）
   - 明确的分析维度清单（对应 style_profile schema 的每一项）
   - 强制 JSON 输出格式的 schema（包含每一项的枚举值）
   - 要求 LLM 为每个判断提供至少 1 条原文引用作为证据

   **输出文件**：分析结果写入 `.pipeline/memory/reference_analysis/<citekey>.json`，格式如下：

   ```json
   {
     "citekey": "zhang2023fungal",
     "analyzed_at": "2026-04-07T14:30:00",
     "analyzed_by": "claude-opus-4-6",
     "global_style": {
       "narrative_style": {
         "value": "story_driven",
         "confidence": 0.9,
         "evidence": [
           "The introduction opens with a paradox: 'Although X is essential for Y, how it achieves Z has remained elusive.'",
           "Results section uses narrative transitions like 'Building on this observation, we next asked...'"
         ]
       },
       "sentence_complexity": {
         "value": "medium",
         "avg_words_per_sentence": 22,
         "confidence": 0.85,
         "evidence": ["Sentences range from 15-30 words with occasional compound structures"]
       },
       "speculation_boldness": {
         "value": "moderate",
         "confidence": 0.8,
         "evidence": [
           "Uses 'We propose a model in which...' rather than 'We demonstrate that...'",
           "Avoids strong causal claims; prefers 'consistent with' over 'shows that'"
         ]
       },
       "first_person_usage": {
         "value": "we_allowed",
         "frequency_per_1000_words": 8,
         "confidence": 0.95
       },
       "passive_voice_preference": {
         "value": "balanced",
         "passive_ratio_in_methods": 0.85,
         "passive_ratio_in_results": 0.45
       }
     },
     "section_specific": {
       "introduction": {
         "opening_style": "hook_with_paradox",
         "paragraph_count": 4,
         "citation_density": "high",
         "knowledge_gap_location": "end_of_paragraph_3",
         "ending_strategy": "direct_statement_of_findings"
       },
       "results": {
         "summary_sentences_per_subsection": true,
         "typical_subsection_structure": "purpose → approach → data → brief_interpretation",
         "transition_style": "explicit",
         "uses_sub_headings": true,
         "figure_reference_format": "Fig. 1A"
       },
       "discussion": {
         "overall_structure": "findings_first → context → mechanism → limitations → outlook",
         "limitations_placement": "dedicated_paragraph_near_end",
         "paragraph_count": 5,
         "uses_alternative_explanations": true
       }
     },
     "preferred_phrases": {
       "transitions": [
         {"phrase": "Consistent with this observation,", "count": 4, "sections": ["results", "discussion"]},
         {"phrase": "Notably,", "count": 6, "sections": ["results"]},
         {"phrase": "Of particular interest,", "count": 2, "sections": ["discussion"]}
       ],
       "data_description": [
         {"phrase": "a X-fold increase", "count": 5},
         {"phrase": "markedly reduced", "count": 3},
         {"phrase": "exhibited attenuated", "count": 2}
       ],
       "mechanism_openers": [
         {"phrase": "One plausible explanation is that", "count": 2},
         {"phrase": "We propose a model in which", "count": 1},
         {"phrase": "These findings raise the possibility that", "count": 3}
       ]
     },
     "avoided_phrases": [
       "plays a crucial role",
       "sheds light on",
       "paves the way for"
     ],
     "tone_calibration_examples": [
       {
         "section": "introduction",
         "purpose": "setting up knowledge gap",
         "text": "Despite extensive characterization of the dimorphic switch, the upstream signals that initiate the transition remain poorly defined."
       },
       {
         "section": "discussion",
         "purpose": "mechanism speculation",
         "text": "We propose that MadsA acts as a thermostatic rheostat, integrating temperature and nutrient cues to tune the rate of morphogenetic transition."
       }
     ],
     "qualitative_summary": "This paper reads as a focused story. It opens with a clearly framed biological paradox, marches through Results with narrative cohesion (each subsection ends with a one-sentence bridge to the next), and concludes with restrained but specific mechanism speculation. The prose is technical but not dry; the author isn't afraid to use 'we' and occasionally adds a brief editorial framing ('Perhaps most strikingly,'). Not flashy—but confident."
   }
   ```

   当有多篇范本论文时，style-curator 会让 LLM 做一次"合成分析"——读取多个 JSON 然后输出一个加权合并的综合档案（根据 style_profile.md 中 `reference_papers` 的 weight 字段加权）。

   **中间产物保留**：这些 JSON 文件不会被删除，保存在 `.pipeline/memory/reference_analysis/` 供后续参考。`/omp:style --refine` 时可以重新加载这些分析结果而不必重新读取范本全文。Git 会追踪这些文件（它们是文本）。

3. **交互式问题链**
   使用 Claude Code 的 AskUserQuestion 机制，分批次提问 8-12 个关键风格维度问题。每个问题都带 2-4 个可点选项，并标注"基于范本论文的默认值"。

4. **生成 style_profile.md**
   输出一份结构化文档（见 10.3 schema），Writer 后续的每次调用都从这里读规则。

5. **支持迭代（`/omp:style --refine`）**
   当你写完第一个 section 并阅读后，可能发现实际效果和预期有差距。此时运行 refine 模式：style-curator 读取已完成的 section 和当前 style_profile，让你标注"满意/不满意"的段落，然后推断需要调整的维度并更新 profile。

6. **支持风格库继承（`/omp:style --from-template <name>`）**
   从 `~/.omp/style-library/` 加载之前项目保存的风格模板，跳过大部分交互，只问"这个模板是否需要针对新项目微调"。

### 10.3 style_profile.md 的完整 Schema

`style_profile.md` 是一份混合格式文档：上半部分是 YAML frontmatter 形式的结构化配置，下半部分是自由文本的详细风格描述。这种混合格式既方便 skill 机器读取（解析 YAML），又方便你手动编辑时理解上下文。

```markdown
---
# ============ META ============
project_name: T_marneffei_transcription_factor_study
target_journal: Nature Microbiology
generated_at: 2026-04-07T14:30:00
last_refined: 2026-04-07T14:30:00
curator_version: 1.0
reference_papers:
  - doi: 10.1038/s41564-023-01234-5
    citekey: zhang2023fungal
    weight: 0.5   # 在风格提取中的权重
  - doi: 10.1128/mbio.00789-24
    citekey: kumar2024virulence
    weight: 0.3
  - doi: 10.1016/j.fgb.2024.103856
    citekey: liu2024crispr
    weight: 0.2

# ============ GLOBAL STYLE ============
narrative_style: story_driven         # technical | story_driven | hybrid
sentence_complexity: medium            # short | medium | complex
speculation_boldness: moderate         # conservative | moderate | bold
first_person_usage: we_allowed         # avoid | we_allowed | we_frequent
passive_voice_preference: balanced     # heavy | balanced | active_first
tense_strictness: strict               # strict | flexible

# ============ SECTION-SPECIFIC ============
introduction:
  opening_style: hook_with_question    # factual | hook_with_question | broad_context
  paragraph_count_target: 4
  citation_density: high               # low | medium | high
  knowledge_gap_placement: end_of_para_3
  
results:
  summary_sentences: per_figure        # none | per_figure | per_section
  transition_style: explicit           # implicit | explicit
  tense: past
  figure_reference_format: "Fig. 1A"   # "Fig. 1A" | "Figure 1A" | "panel A of Fig. 1"
  sub_heading_allowed: true
  
discussion:
  structure: findings_first            # findings_first | hypothesis_first | context_first
  limitations_placement: dedicated_paragraph
  mechanism_speculation_marker: "We propose that"
  paragraph_count_target: 5
  
methods:
  voice: strictly_passive              # 硬性规则,不可更改
  citation_for_kit: supplier_and_cat_number
  statistical_test_declaration: required_in_each_subsection

abstract:
  structure: narrative                 # narrative | structured
  word_limit: 150                      # 从 journal_spec 继承
  key_numbers_required: 2              # 必须包含至少 2 个定量数据
---

# Style Profile: T_marneffei_transcription_factor_study

## Style Summary

This paper tells the story of how a newly characterized transcription factor 
regulates dimorphic switching in *Talaromyces marneffei*. The writing should 
feel narrative-driven yet grounded in rigorous molecular evidence. Mechanism 
speculation in Discussion is welcomed but should be clearly framed as 
hypothesis rather than conclusion.

## Preferred Phrases (from reference paper analysis)

### Transition phrases (high frequency in reference papers)
- Consistent with this observation, ...
- In line with these findings, ...
- Notably, ...
- Of particular interest, ...
- Strikingly, ... (use sparingly, max 2 times per section)

### Data description patterns
- "We observed a X-fold increase in Y" (preferred)
- "Quantitative analysis revealed..." (use sparingly)
- "The expression of X was significantly upregulated" (Results)
- "X displayed markedly reduced Y" (Results)

### Mechanism discussion openers
- "One plausible explanation is that..."
- "These findings raise the possibility that..."
- "We propose a model in which..."
- "It is tempting to speculate that..." (at most once per Discussion)

### Introduction transition formulas
- "Despite these advances, ..." (for knowledge gap)
- "However, whether X remains unclear" (for setting up the question)
- "Here, we..." (for stating the study aim — NOT "In this study, we aim to...")

## Banned Expressions

These phrases are AI-cliché or overused in this subfield; avoid them entirely:
- "plays a crucial/pivotal/vital role"
- "has garnered significant attention"
- "sheds light on"
- "paves the way for"
- "It is worth noting that" (use "Notably," instead)
- "In this study, we aim to" (use "Here, we")
- "Interestingly, " (prefer specific transitions)
- "Furthermore, " (overused; vary with "Moreover," "In addition," or restructure)

## Domain-Specific Conventions (HARD RULES — inherited from sci-bio-writer)

These override all style preferences above:
- Species: *Talaromyces marneffei* (first), *T. marneffei* (subsequent)
- Genes: italic (*acuD*, *madsA*)
- Proteins: non-italic (AcuD, MadsA)
- Strain names: PM1 style (no italics, no spaces)
- Statistical P values: italic P (P < 0.05)
- CRISPR-Cas9: with hyphen
- Fold changes: "3.2-fold" not "3.2 times"

## Tone Calibration Examples (from reference papers)

The following sentences exemplify the target tone. The Writer should aim 
for writing that fits naturally among these:

> "In this work, we identify MadsA as a master regulator of the yeast-to-hypha 
> transition in *T. marneffei*, providing mechanistic insight into how 
> temperature cues are translated into morphogenetic decisions." 
> (from zhang2023fungal)

> "Disruption of *acuD* led to a pronounced attenuation of virulence in 
> a murine infection model, consistent with previous observations in 
> related thermally dimorphic fungi." 
> (from kumar2024virulence)

## Refinement History

| Date | Trigger | Changes |
|------|---------|---------|
| 2026-04-07 | Initial creation | Generated from 3 reference papers + Nature MB preset |
```

### 10.4 交互式问题清单（示例）

`style-curator` 在初次运行时会问类似这样的问题（使用 AskUserQuestion 多选按钮）：

1. **叙事取向**：这篇论文更接近"讲一个发现的故事"还是"严格陈述技术结果"？
   - 故事驱动 / 技术驱动 / 两者混合

2. **第一人称使用**：Results 和 Discussion 中是否允许使用 "We found", "We propose"？
   - 完全避免（全被动）/ 允许但克制使用 / 频繁使用

3. **机制推测大胆程度**：Discussion 中推测分子机制时的措辞强度？
   - 保守（"suggests", "may indicate"）
   - 中等（"we propose", "these findings raise the possibility"）
   - 大胆（"we demonstrate", "establishes that"）

4. **Results 段落结构**：每个 Results 小段是否需要一句总结句？
   - 需要（"These data establish X"）
   - 不需要（让数据自己说话）

5. **Introduction 开场方式**：
   - 直接事实陈述 / 设问式开场 / 宽泛背景铺垫

6. **Discussion 结构**：
   - 先回顾本研究发现 / 先回到领域背景 / 先提出新假设

7. **句子复杂度偏好**：
   - 短句为主（每句 ≤ 20 词）
   - 中等长度（复合句可用但不超过 30 词）
   - 允许长复合句

8. **禁用短语**：以下哪些你希望完全避免？（多选）
   - "plays a crucial role"
   - "sheds light on"
   - "It is worth noting that"
   - "Interestingly,"
   - "In this study, we aim to"

如果提供了范本论文，每个问题会附带"基于你的范本论文，推荐值是 X"的提示，减轻你的决策负担。

### 10.5 新增 Slash Commands

| 命令 | 作用 |
|------|------|
| `/omp:style` | 初次配置或查看当前 style_profile |
| `/omp:style --refine` | 基于已写 section 迭代调整 |
| `/omp:style --from-template <name>` | 从风格库继承 |
| `/omp:style --save-as <name>` | 把当前 profile 保存到全局风格库，供未来项目复用 |
| `/omp:style --show` | 以易读形式展示当前风格规则 |

### 10.6 风格库（`~/.omp/style-library/`）

这是一个跨项目的用户级目录，存放你积累的风格模板。每个文件是一份去掉项目特定元信息（如 reference_papers 的 DOI）的 style_profile 模板。

典型的文件命名：
- `nature-mb-fungal-virulence.md` — 投 Nature Microbiology 的真菌毒力研究风格
- `mbio-transcription-regulation.md` — 投 mBio 的转录调控研究风格
- `fgb-crispr-methods.md` — 投 FGB 的 CRISPR 方法学论文风格

使用场景：完成一篇论文后，如果你对最终的 style_profile 很满意，可以运行 `/omp:style --save-as nature-mb-fungal-virulence`，系统会把当前 profile 去掉项目特定信息后保存到全局库。下一篇类似方向的论文 `/omp:setup` 时，可以选择 "从已有模板继承"，style-curator 会加载该模板并只问少量差异化问题。

### 10.7 风格闭环的迭代示例

**Scenario**：你正在写第一篇投 Nature Microbiology 的真菌论文。

```
第 1 天：
/omp:setup
  → 选择 Nature Microbiology 作为目标期刊
  → 提供 3 篇范本论文（zhang2023, kumar2024, liu2024）
  → 回答 8 个风格问题
  → 生成 style_profile.md v1

/omp:write methods
  → Writer 读 style_profile → 写 Methods → 自动 commit
  → Reviewer 自动局部审查 → 风格合规 ✓

第 2 天：
/omp:write results
  → Writer 写 Results → Reviewer 发现 Writer 没有按 style_profile 要求
     每段加小结句 → 标记为 [STYLE] Minor 问题
  → 你手动修订 Results 第 2 段,新增小结句
  → version-guardian 提交 revise(results): add summary sentence per profile

第 3 天：
读完 Results,你觉得整体节奏太慢,想让叙事更紧凑
/omp:style --refine
  → style-curator 让你选最满意/最不满意的段落
  → 你标记了 Results 第 3 段为"节奏合适",第 1、2 段为"太冗长"
  → style-curator 推断需要调整 sentence_complexity: medium → short
  → 询问是否要调整 → 确认 → 更新 style_profile.md v2
  → 提醒你"要不要根据新 profile 重写 Results 第 1、2 段?"
  → 你选择只重写第 1 段作为测试 → 效果更好

第 10 天（全文完成后）：
/omp:review（全文审查）
  → 包含对全文的风格一致性检查（vs 最新 style_profile）
  → 发现 Introduction 是按 v1 写的,节奏与 v2 不一致
  → 标记建议重写

第 12 天（准备投稿）：
/omp:style --save-as nature-mb-fungal-virulence
  → 保存当前 profile 到全局库
  
第 90 天（开始写第二篇）：
/omp:setup 新项目
  → /omp:style --from-template nature-mb-fungal-virulence
  → 跳过大部分交互,只询问目标期刊是否有变化
  → 5 分钟完成风格配置
```

这就是"风格闭环"带来的核心价值：**每次写作都有明确的风格指令可依、有审查机制可查、有反馈机制可调、有积累机制可用。**

---

## 十一、交互式写作协议（Interactive Writing Protocol）

### 11.1 问题：为什么"一次性生成整个 section"是有问题的

v1.2 及之前的 Writer 工作模式是："用户运行 `/omp:write results`，Writer 读取所有上下文，一次性生成完整的 Results section"。这种模式有几个实际问题：

第一，**你对 section 走向的感觉只有在看到部分草稿后才会清晰**。论文写作不是信息提取，而是论证构建。Writer 在没有你反馈的情况下写完整个 section，大概率会在某个关键段落偏离你的真实意图，结果你只能从头改起。

第二，**过长的生成会放大 LLM 的漂移风险**。写一个 Results 段落时可能完美符合 style_profile，但写到第 5 个段落时可能就开始出现 "plays a crucial role" 或其他禁用词——因为上下文窗口里的最近写作比 style_profile 占据更大权重。

第三，**无法在过程中发现图表引用错误或数据理解偏差**。比如你口头说"Fig 2A 显示 knockout 菌株生长减慢"，但 Writer 可能理解成"生长加快"。一次性生成完成后才发现错误，为时已晚。

第四，**真实写作中，你对每个段落的要求其实不一样**。有些段落你有明确的表达想法、只需要 Writer 润色；有些段落你完全没想好、需要 Writer 先给几个方向你选；还有些段落需要 Writer 先查文献再写。一刀切的"生成整个 section"无法适配这种差异。

### 11.2 解决方案：段落级的交互式共创

v1.3 引入 **Interactive Writing Protocol**（交互写作协议），彻底改变 Writer 的工作模式。核心原则：

**Writer 不再一次性生成整个 section，而是以"写作单元"（writing unit）为粒度推进，每完成一个单元就主动停下来征求你的反馈，然后决定下一步。**

"写作单元"的粒度是**一个段落**（Methods 是一个子标题下的方法描述、Results 是围绕一个 Figure panel 或一组相关数据的段落、Discussion 是一个论点段落、Introduction 是一个结构功能段落）。

### 11.3 交互模式：三档可切换

不是所有场景都需要密集交互。Writer 支持三档交互强度，由你在 `/omp:write` 时指定，默认是 `collaborative`：

| 模式 | 交互频率 | 适用场景 |
|------|---------|---------|
| `autonomous` | 每 section 结束时才交互 | 你想快速看整体草稿，细节以后再说；或者 Methods 这种高度公式化的 section |
| `collaborative` ⭐默认 | 每个写作单元结束时交互 | 大部分 Results、Discussion、Introduction 写作 |
| `dense` | 每个写作单元开始前和结束后都交互 | 核心 Results 段落、Discussion 的关键论点、Introduction 的故事框架 |

通过命令行指定：
```
/omp:write results                    # 默认 collaborative
/omp:write results --mode autonomous   # 低交互
/omp:write results --mode dense        # 高交互
/omp:write discussion --mode dense     # Discussion 建议用 dense
```

你也可以在任何时候通过自然语言切换："切换到 dense 模式" → Writer 从下一个写作单元开始改变行为。

### 11.4 collaborative 模式下的标准交互循环

这是默认模式的完整工作流。一个 section 内每个段落都经历以下循环：

```
Writer Agent
    ↓
[1] 读取上下文
    - style_profile.md
    - figure_registry.md（Results）
    - 已完成的同 section 前面段落
    - 对应的 Figure panel 描述（Results）
    ↓
[2] 识别下一个写作单元
    - "下一段应该描述 Fig 2B 的 Western blot 结果"
    - "下一段应该讨论 off-target 效应"
    ↓
[3] 预告（Pre-announce）
    Writer 向你说明它计划怎么写这一段，包括:
    - 这段的中心论点
    - 引用哪个 Figure panel 或哪些数据
    - 打算引用哪些文献（如有）
    - 预计多少句
    ↓
[4] 写作
    Writer 按 style_profile 和 fungal-genetics-conventions 写出该段落
    ↓
[5] 交付 + 征求反馈
    Writer 展示写好的段落 + 它的"自我评估"（比如"这段我用了 'We propose',
    符合 moderate speculation boldness; 没有使用禁用词"）
    ↓
[6] 用户响应（三选一或自由文本）
    - ✓ 接受,继续下一段
    - ✏️ 修订 + 反馈建议（自然语言）
    - ⏸️ 暂停,我想重新考虑这段的方向
    ↓
[7] 处理反馈
    - 如果是接受,进入下一段
    - 如果是修订,Writer 根据反馈重写,回到 step 5
    - 如果是暂停,Writer 保存当前状态到 manuscript_state.md 并等待用户指令
    ↓
回到 [1] 继续下一个写作单元
```

**Pre-announce 步骤的价值**：这是协议最重要的设计点。它让你在 Writer 写之前就能纠正方向。比如 Writer 说 "下一段我打算先描述 Fig 2A 的数据，然后过渡到 Fig 2B"，你可以直接说"不，先写 2B 再写 2A，因为 2B 才是核心发现"。这避免了"Writer 写完一整段、你才发现结构错了"的浪费。

### 11.5 写作单元内的快速微调协议

即使在 collaborative 模式里，"一段写完一次性交付"有时也太粗。某些复杂段落你可能希望 Writer 写完一句就停下来看看。为此增加一个**句级微调（sentence-level nudge）**机制：

在 Writer 展示段落时，你可以用以下简短指令快速干预：

- `s1 换一种说法` → 重写第 1 句
- `s2-3 合并` → 把第 2 和第 3 句合并
- `+last 加一句强调 complementation` → 在段落末尾追加一句
- `-s4` → 删除第 4 句
- `tone softer` → 把整段语气改温和
- `cite needed here: [关键词]` → 在某位置插入一个引用（Writer 调 zotero-ref-bridge）

这些快捷指令不需要 Writer 重新理解完整段落，只是局部修改，响应速度快。

### 11.6 check-in 点：section 内的大节点

除了段落级的交互，Writer 还会在**写作单元之间的关键节点**主动暂停，询问更高层的决策。这些节点在不同 section 有不同位置：

**Methods section 的 check-in 点**：
- 写完"菌株和培养条件"后 → "接下来是基因操作方法，你希望按 CRISPR → 互补 → 验证的顺序，还是按时间顺序？"
- 写完"分子生物学方法"后 → "接下来是生物信息学分析，你希望多详细？（ultra-detail 含所有参数 / standard 含关键参数 / brief 只列工具名）"

**Results section 的 check-in 点**：
- 写完第 1 个发现后 → "第一个发现写完了，你想要的下一个 Figure 是按逻辑顺序还是按重要性排序？"
- 写到中段 → "目前 Results 已经 800 字，期刊限制 1500 字。剩余 4 个 Figure 中你希望优先详述哪一个？"

**Discussion section 的 check-in 点**：
- 开头前 → "Discussion 的开篇是选择 (a) 直接重述主要发现、(b) 先回到 Introduction 提出的问题、还是 (c) 用一个对比性观察作为钩子？"
- 写完主要发现回顾后 → "接下来要讨论局限性。你希望列几个？最主要的关切是什么？"
- 结尾前 → "Discussion 结尾你希望是 (a) 对未来研究的展望、(b) 对当前领域的意义总结、还是 (c) 一句凝练的结论句？"

**Introduction section 的 check-in 点**：
- 开头前 → "Introduction 的第一句话是整篇论文最重要的句子之一。你已经有想法了吗？还是让我先给 3 个候选开场句？"
- 写到最后一段前 → "最后一段通常陈述研究目的和主要发现。你希望透露多少结论？（teaser / partial / full）"

这些 check-in 点的具体问题清单存放在 `skills/sci-bio-writer/references/check-in-prompts.md`，按 section 分类。

### 11.7 交互历史的记录

所有交互（你的反馈、Writer 的重写、check-in 的决策）都被记录到 `manuscript_state.md` 中的 `interaction_log` 字段，同时每次交互触发 version-guardian 的 commit，commit message 类别为 `interact`：

```
interact(results): revise Fig 2B paragraph per user feedback "emphasize complementation"

Paragraph 3 of Results was rewritten to explicitly mention the complementation 
experiment and its rescue of the phenotype.

Agent: Writer
Skill: sci-bio-writer
Trigger: /omp:write results (collaborative mode, sentence-level nudge)
User feedback: "emphasize complementation"
```

这样将来你可以用 `git log --grep="interact"` 回顾所有交互过程，或者用 `/omp:history --type interact` 查看交互频率——如果发现某个 section 的 interact commits 特别多，说明这个 section 写得比较艰难，值得记录经验教训。

### 11.8 状态保存与中断恢复

交互式写作的一个风险是：你在写到一半时被打断（比如导师喊你去开会），回来后需要恢复上下文。协议对此有明确支持：

Writer 在每个交付点都会更新 `manuscript_state.md`：

```yaml
current_section: results
current_unit: 4  # 正在写第 4 个段落
current_unit_focus: "Fig 3A - growth curve comparison"
units_completed: 3
units_total_estimated: 7
last_interaction_at: 2026-04-07T16:45:00
last_interaction_type: pre_announce  # Writer 刚刚宣布要写下一段,等待用户批准
pending_user_decision: "approve/revise the plan for paragraph 4"
interaction_log:
  - unit: 1
    pre_announce: "..."
    draft: "..."
    user_feedback: "accepted"
    final_text: "..."
  - unit: 2
    pre_announce: "..."
    draft: "..."
    user_feedback: "s2 换种说法强调统计显著性"
    revisions: 1
    final_text: "..."
  - unit: 3
    ...
```

中断后重新打开 Claude Code，SessionStart hook 读取这个状态，会告诉你："你上次在 Results section 写到第 4 段（关于 Fig 3A 的生长曲线对比），Writer 当时正在等你批准写作计划。是否继续？"

### 11.9 autonomous 模式的例外

虽然 collaborative 是默认模式，但某些 section 或任务适合 autonomous：

- **Methods section**：高度公式化，大部分内容由 methods-protocol skill 从模板生成，交互价值低。推荐用 `/omp:write methods --mode autonomous`。
- **补写已删除的小段落**：如果你只是需要补回一段之前误删的内容，不需要密集交互。
- **快速出 v0 草稿**：有些研究者喜欢先让 AI 快速出一个完整草稿然后大改，而不是边写边改。这是合法的工作流，autonomous 模式支持它。

但即使在 autonomous 模式下，Writer 仍然会在 section 结束时做一次汇报，展示写了什么、哪些地方它不太确定、哪些地方建议你重点检查。

### 11.10 与其他 skill/agent 的联动

交互式写作协议主要由 Writer agent + sci-bio-writer skill 实现，但它的每个交互点都可能触发其他 skill：

- 用户在 pre-announce 阶段说"这段需要引用最新的 off-target 综述" → Writer 调 `zotero-ref-bridge.suggest_refs` → 返回候选 → 用户选择 → 插入
- 用户在交付点说"这段不太符合 Nature MB 的调性" → Writer 读取 `style_profile.md` 中的 tone_calibration_examples → 对比 → 调整
- 用户连续 3 次反馈"语气太激进" → Writer 通过 agent_handoff.md 提醒：建议运行 `/omp:style --refine` 调整 style_profile，而不是每次都手动纠正

最后一点很重要：**Writer 不会偷偷修改 style_profile**（那是 StyleKeeper 的专属权限），但它会检测到风格漂移的模式并主动建议用户触发 StyleKeeper 介入。这是 4+1 角色架构的一个具体体现。

---

## 十二、实施路线图

### Phase 1：基础架构（第 1 周）
- Fork Oh-my-paper，清理不需要的 skill 文件
- 重写 `/omp:setup` 命令逻辑（包括初始化 Git 仓库、安装 pre-push hook、生成 .gitignore、调用 style-curator、安装 figure-watcher hook）
- 创建新的记忆文件模板（manuscript_state, figure_registry, strain_plasmid_table, journal_spec, style_profile, reference_analysis/）
- 重写 AGENTS.md 加入 **StyleKeeper 角色定义**（v1.3）
- 重写 CLAUDE.md
- 调整 Hook 逻辑（Git 自动提交 + figure-watcher）
- 开发 `version-guardian` skill 的基础功能（自动提交、history、rollback）
- 安装和测试 cookjohn/zotero-mcp 插件，打通 Claude Code ↔ Zotero 连接
- **开发 figure-watcher Hook 脚本**（v1.3）：文件名解析、元数据提取、自动登记

### Phase 2：核心 Skill 开发（第 2-3 周）
- **`style-curator` 优先开发**：作为整个风格闭环的起点，先实现交互式问题链和期刊预设
  - **v1.3 关键任务**：设计并测试 LLM 原生范本论文分析 prompt，验证 JSON 输出的稳定性和质量
  - 定义 reference_analysis/*.json 的完整 schema
- `sci-bio-writer`：改造为读 style_profile 的动态执行引擎，硬编码领域规范到 fungal-genetics-conventions.md
  - **v1.3 关键任务**：实现 **Interactive Writing Protocol** —— pre-announce、段落级交互、句级微调、check-in 点
  - 编写 `check-in-prompts.md`（按 section 分类的 check-in 问题清单）
- `methods-protocol`：内置实验方法模板，用真实项目数据测试
- `zotero-ref-bridge`：封装 cookjohn/zotero-mcp 的底层工具，实现 cite/batch_cite/check_missing/fetch_reference_paper 等高层函数
- `journal-formatter`：先做你最常投的 2-3 个期刊的模板
- 第一次端到端测试：用一个真实项目跑通 Preparation + Methods 写作

### Phase 3：辅助 Skill 开发（第 4 周）
- `figure-legend-gen`：用已有 Figure 测试不同图表类型的描述生成，与 figure-watcher 注册的 `[NEEDS_HUMAN_ANNOTATION]` 状态配合
- `manuscript-reviewer`：实现全部 6 个审查维度，重点打磨风格合规性检查的准确率
- `abstract-composer`：用已完成的全文测试
- `submission-checklist`：整理完整 checklist
- 补完 `version-guardian` 的高级功能（智能 diff 解释、blame 封装）
- 补完 `style-curator` 的 refine 流程

### Phase 4：集成测试与迭代（第 5 周+）
- 用一篇真实在写的论文跑完整流水线
- 根据实际使用体验调整 skill 规则
- 补充期刊模板
- 优化 skill 间的联动和记忆同步
- 检查 Git 历史可读性，调整 commit message 生成策略
- **风格闭环专项测试**：写完一个 section 后运行 `/omp:style --refine`，验证迭代机制是否真的有效改善风格一致性
- **交互式写作模式专项测试**（v1.3）：
  - 对比 autonomous / collaborative / dense 三档模式的实际体验
  - 检验 check-in 点的触发时机是否合适
  - 评估 pre-announce 机制是否真的减少了"白写一段"的情况
  - 根据实际使用调整段落级反馈的快捷指令（s1, s2-3, +last 等）
- 开始积累第一批风格模板到 `~/.omp/style-library/`

---

## 十三、与原版 Oh-my-paper 的兼容性

改造后的项目**不需要保持与原版的向后兼容**——这是一个 fork，不是插件。但保持以下接口兼容有助于将来合并社区更新：

- `.pipeline/` 目录结构保持一致
- `tasks.json` schema 不变
- `project_truth.md` 和 `agent_handoff.md` 的读写约定不变
- Hook 注册机制不变
- Skill 的 YAML frontmatter 格式不变

核心差异点需要在 fork 的 README 中明确标注，方便将来与上游对比。

---

## 十四、实操参考附录

本章包含可直接复用的样板和清单。每个样板都是 v1.4 之前章节中"详细定义"的具体实例化版本。

### 14.A AGENTS.md 完整样板

`AGENTS.md` 是 Oh-my-paper 原版的角色定义文件，每次 SessionStart 时被注入上下文。v1.3 改造后包含 4+1 个角色，下面是一份可直接使用的模板：

```markdown
# Agent Roster — Oh My Bio-Paper

This file defines the agent roles available in this project. SessionStart hook
will read this file and prompt you to select one role per session.

## Conductor (统筹者)

**When to activate**: `/omp:plan`, or any time you need to see global progress.

**Responsibilities**:
- Read all memory files to maintain a global view
- Update `tasks.json` and `project_truth.md` after each subtask
- Dispatch tasks to other roles via `agent_handoff.md`
- Resolve conflicts when multiple roles have updated shared state

**Memory access**:
- READ: all files in `.pipeline/memory/`
- WRITE: `project_truth.md`, `orchestrator_state.md`, `tasks.json`,
         `decision_log.md`, `agent_handoff.md`

**Forbidden**: Conductor never writes section content (paper/sections/*.tex).
That is Writer's exclusive domain.

---

## StyleKeeper (风格守护者)

**When to activate**: `/omp:setup` initial config, `/omp:style`, `/omp:style --refine`,
or when Writer flags style drift via agent_handoff.md.

**Responsibilities**:
- Run style-curator skill to generate/update `style_profile.md`
- Analyze reference papers via LLM (output to `reference_analysis/*.json`)
- Maintain `~/.omp/style-library/` for cross-project templates
- Respond to Writer's style-rule clarification requests

**Memory access**:
- READ: `journal_spec.md`, `manuscript_state.md`, `execution_context.md`,
        `agent_handoff.md`, all `reference_analysis/*.json`
- WRITE: `style_profile.md`, `reference_analysis/*.json`, `agent_handoff.md`

**Forbidden**: StyleKeeper never writes section content. It only defines rules.

---

## Writer (写手)

**When to activate**: `/omp:write <section>` (with optional `--mode` flag).

**Responsibilities**:
- Write paper sections following Interactive Writing Protocol (Ch 11)
- Pre-announce each writing unit before drafting
- Accept paragraph-level feedback and sentence-level nudges
- Trigger check-in points at section milestones
- Call sci-bio-writer, methods-protocol, zotero-ref-bridge skills as needed

**Memory access**:
- READ: `style_profile.md` (read-only!), `manuscript_state.md`,
        `figure_registry.md`, `literature_bank.md`, `journal_spec.md`,
        `strain_plasmid_table.md`, `execution_context.md`
- WRITE: `paper/sections/*.tex`, `manuscript_state.md` (interaction_log),
         `agent_handoff.md`

**Forbidden**: Writer never modifies `style_profile.md`. If style rules feel
inadequate, write a request to `agent_handoff.md` for StyleKeeper to handle.

---

## Reviewer (评审者)

**When to activate**: `/omp:review`, or auto-triggered by PostToolUse Hook
when a section reaches `draft_complete` state.

**Responsibilities**:
- Run manuscript-reviewer skill across 6 dimensions (data consistency,
  logic, citations, attack-point prediction, language, style compliance)
- Output structured findings to `review_log.md` with severity tags
- Cross-check section content against figure_registry and style_profile

**Memory access**:
- READ: all section files, `style_profile.md` (read-only),
        `figure_registry.md`, `manuscript_state.md`, `journal_spec.md`,
        `literature_bank.md`
- WRITE: `review_log.md`, `agent_handoff.md`

**Forbidden**: Reviewer never directly modifies sections. It only flags issues.

---

## Formatter (格式师)

**When to activate**: `/omp:format`, `/omp:check`.

**Responsibilities**:
- Generate Figure/Table legends (figure-legend-gen skill)
- Generate Abstract (abstract-composer skill)
- Adapt manuscript to target journal format (journal-formatter skill)
- Run pre-submission checklist (submission-checklist skill)

**Memory access**:
- READ: `manuscript_state.md`, `figure_registry.md`, `journal_spec.md`,
        `style_profile.md` (read-only), all section files
- WRITE: `submission/` directory contents, `agent_handoff.md`

**Forbidden**: Formatter never rewrites section content. It packages and
formats existing drafts.
```

### 14.B CLAUDE.md 用户侧扩展

在第八章基础之上，加入交互协议和角色切换的用户侧指引：

```markdown
# Oh My Bio-Paper — Project Context (User Guide section)

## How to interact with Writer in Interactive Writing Protocol

When you run `/omp:write <section>`, Writer enters collaborative mode by
default. You will see paragraph-level interactions like this:

  Writer: "Next paragraph plan: I will describe the Western blot in Fig 2B,
          comparing wildtype to ΔacuD strain, citing kumar2024 for antibody
          source. Estimated 4 sentences. OK to proceed?"
  You: ✓ go ahead     (or revise the plan in natural language)
  Writer: [writes the paragraph]
  Writer: "Self-check: used 'we propose' (matches moderate boldness),
          no banned phrases, cited Fig 2B correctly. Your call?"
  You: s2 换种说法强调统计显著性     (sentence-level nudge)
  Writer: [rewrites sentence 2]
  You: ✓
  Writer: [moves to next paragraph]

### Sentence-level nudge shortcuts

You can use these compact commands instead of writing full feedback:
- `s<N> <instruction>` — modify sentence N (e.g., `s2 shorter`)
- `s<N>-<M> <instruction>` — modify sentence range (e.g., `s2-3 merge`)
- `+last <text>` — append a sentence at the end
- `-s<N>` — delete sentence N
- `tone <softer|stronger|more_technical>` — adjust whole paragraph tone
- `cite needed here: <keyword>` — Writer will call zotero-ref-bridge to
  find a matching reference

### Switching interaction mode mid-section

You can change mode anytime by typing in natural language:
- "switch to dense mode" — Writer will pre-announce AND post-deliver every unit
- "go autonomous for the rest of this section" — Writer will silently finish
- "back to collaborative" — return to default

### Pause and resume

If you need to step away mid-section, just type "pause". Writer will save
state to manuscript_state.md. Next session, SessionStart will restore your
exact position.

## How to switch agent roles

Each session you can be ONE role at a time. SessionStart will ask you to
choose. To switch roles within a session, run `/omp:plan` to return to
Conductor view, then re-trigger another role command.

Common workflows:

  Day 1 (setup):
    SessionStart → choose StyleKeeper → /omp:setup → answer style questions

  Day 2-10 (writing):
    SessionStart → choose Writer → /omp:write methods --mode autonomous
    SessionStart → choose Writer → /omp:write results --mode collaborative

  Day 11 (review):
    SessionStart → choose Reviewer → /omp:review

  Day 12 (style refine):
    SessionStart → choose StyleKeeper → /omp:style --refine

  Day 13-14 (finalization):
    SessionStart → choose Formatter → /omp:format → /omp:check
```

### 14.C 端到端使用脚本（典型 14 天工作流）

下面是一篇真菌 transcription factor 论文从零到投稿的完整命令流水账。可以直接当作"用户手册"使用：

```bash
# ============================================================
# Day 1: 项目初始化
# ============================================================

# 假设你已经有了实验数据和 Figure 文件,放在某个目录
cd ~/research/madsa_paper

# 把 Figure 文件复制到 paper/figures/ (figure-watcher 会自动登记)
mkdir -p paper/figures
cp ~/raw_figures/Fig*.tiff paper/figures/

# 启动 Claude Code,SessionStart hook 会提示选择角色
claude
# > 选择: StyleKeeper

# 初始化项目
> /omp:setup
# 系统会问:
#   - 项目名称: madsa_transcription_factor
#   - 目标期刊: Nature Microbiology
#   - 通讯作者邮箱: kent@example.edu
#   - 主要菌株 (将填入 strain_plasmid_table.md)
#   - 是否提供范本论文? Yes
#     → 通过 zotero-ref-bridge 选择 3 篇已有 Zotero 条目
#     → StyleKeeper 自动调用 LLM 分析,生成 reference_analysis/*.json
#   - 8 个风格问题 (interview-questions, 见 14.D)
# → 自动生成: journal_spec.md, style_profile.md, figure_registry.md
# → 自动初始化 Git 仓库, 安装 pre-push hook 和 figure-watcher hook
# → version-guardian 第一次 commit: meta(setup): initial project scaffolding

# 检查初始化结果
> /omp:plan
# Conductor 显示: Preparation 完成,可以开始 Drafting

# ============================================================
# Day 2-3: Methods (autonomous 模式,因为高度公式化)
# ============================================================

# 重启会话,这次选 Writer
claude
# > 选择: Writer

> /omp:write methods --mode autonomous
# Writer 调用 methods-protocol skill, 从 strain_plasmid_table 拉取菌株信息
# 写完后自动 commit, 自动触发 manuscript-reviewer 局部审查
# Reviewer 报告: 0 critical, 1 minor (建议补充 RNA-seq 数据库版本)

# 手动修订
> 在 RNA-seq 子段落补充 GRCh38 → 应该是 PMRSA1 v2 基因组版本

# Writer 修订后再次 commit: revise(methods): correct genome version

# ============================================================
# Day 4-7: Results (collaborative 模式,核心写作)
# ============================================================

claude
# > 选择: Writer

> /omp:write results
# 默认 collaborative 模式
# Writer 进入交互循环:
#   Writer: "Section plan: I'll cover 5 main findings in this order:
#            (1) MadsA expression profile across temperatures
#            (2) ΔmadsA growth phenotype
#            (3) Transcriptome changes in ΔmadsA  
#            (4) Direct binding targets via ChIP-seq
#            (5) Complementation rescue
#            OK?"
#   You: ✓
#
#   Writer: "Paragraph 1 plan: describe Fig 1A-C, RT-qPCR showing 
#            temperature-dependent expression. ~5 sentences. OK?"
#   You: 加一句对照: also show housekeeping gene as control
#   Writer: [writes with the additional control mention]
#   Writer: "Self-check: used past tense, no banned phrases, cited Fig 1A-C 
#            correctly. Your call?"
#   You: s3 too long, split into two
#   Writer: [splits sentence 3]
#   You: ✓
#
# ... 继续到 paragraph 5 ...
#
#   Writer (check-in point): "We've used 800 words so far, journal limit 
#                             is 1500. Remaining 4 figures - which to detail?"
#   You: 重点 detail Fig 4 (ChIP-seq), 其他简略
#
# ... 完成 Results section ...

# Reviewer 自动局部审查
# 报告: 0 critical, 2 minor (style suggestions)

# ============================================================
# Day 8: 发现风格不对劲, refine
# ============================================================

# 你阅读 Results 后觉得整体节奏太慢
claude
# > 选择: StyleKeeper

> /omp:style --refine
# StyleKeeper 让你标注 Results 各段的"满意/不满意"
# 推断需要把 sentence_complexity 从 medium 调到 short
# 更新 style_profile.md (v2)
# 询问是否要按新 profile 重写之前的段落
# 你选择只重写 Results paragraphs 1-2 作为测试

# ============================================================
# Day 9-10: Discussion (dense 模式,关键论点)
# ============================================================

claude
# > 选择: Writer

> /omp:write discussion --mode dense
# dense 模式下 Writer 在每个段落开始前和结束后都交互
# Discussion 的每个 check-in 点都会停下来 (见 14.D)

# ============================================================
# Day 11: Introduction (collaborative)
# ============================================================

> /omp:write introduction
# Introduction 最后写, 因为现在已经知道全文叙事了

# ============================================================
# Day 12: 全文 Review
# ============================================================

claude
# > 选择: Reviewer

> /omp:review
# 全文 6 维度审查
# 报告: 1 critical (Discussion 第 3 段引用了 Results 中没有的数据)
#       3 major, 5 minor

# 切换回 Writer 修订
claude  
# > 选择: Writer
> 修订 Discussion 第 3 段 (按 review_log 中的 critical 项)

# ============================================================
# Day 13: Format + Check
# ============================================================

claude
# > 选择: Formatter

> /omp:format
# 调用 figure-legend-gen 生成所有 Figure legends
#   (figure-watcher 之前登记的 [NEEDS_HUMAN_ANNOTATION] 状态在此 gate)
#   → Formatter 中断: "Fig 2 panels 未填写, 请补全"
> Fig 2A: growth curves at 25C; 2B: growth curves at 37C; 2C: viability assay
# 继续生成 legends
# 调用 abstract-composer 生成摘要 (≤150 words for Nature MB)
# 调用 journal-formatter 适配 Nature MB 格式

> /omp:check
# 运行投稿前 checklist
# 报告: 38 项通过, 2 项待办 (ORCID 缺失 + funding statement 缺失)
> 补全 ORCID: 0000-0001-xxxx-xxxx; funding: NSFC 32000123

> /omp:check
# 全部通过

# 创建投稿快照
> /omp:snapshot submission/v1
# version-guardian 创建 git tag

# ============================================================
# Day 14: 投稿
# ============================================================

# 投稿文件已就绪在 submission/ 目录
ls submission/
#   manuscript.pdf
#   cover_letter.pdf
#   figures/Fig1.tiff ... Fig5.tiff
#   supplementary.pdf

# 保存当前风格档案到全局库,供下篇论文复用
> /omp:style --save-as nature-mb-fungal-tf
```

### 14.D Style-Curator 完整问题清单

#### 14.D.1 interview-questions.md (style-curator 初次配置时的 12 个核心问题)

```markdown
# Style Curator - Initial Interview Questions

每个问题都使用 AskUserQuestion 工具呈现可点选项。
如果有 reference_analysis,每个问题都会标注"基于范本论文的推荐值"。

## 核心维度 (必问)

1. **Narrative style** — 这篇论文更接近"讲一个发现的故事"还是"严格陈述技术结果"?
   - [ ] story_driven (强叙事感, 适合 Nature/Science 系列)
   - [ ] technical (严谨技术报告, 适合 FGB/MMI 系列)
   - [ ] hybrid (两者混合, 适合 mBio/PLOS Pathogens)

2. **First-person usage** — Results 和 Discussion 中是否允许使用 "We found"?
   - [ ] avoid (完全被动语态)
   - [ ] we_allowed (允许但克制使用)
   - [ ] we_frequent (频繁使用 "We")

3. **Speculation boldness** — Discussion 中推测分子机制时的措辞强度?
   - [ ] conservative ("suggests", "may indicate", "is consistent with")
   - [ ] moderate ("we propose", "raises the possibility that")
   - [ ] bold ("we demonstrate", "establishes that")

4. **Sentence complexity** — 句子复杂度偏好?
   - [ ] short (每句 ≤20 词, 节奏紧凑)
   - [ ] medium (复合句可用,不超过 30 词)
   - [ ] complex (允许长复合句, 学术化)

5. **Results paragraph structure** — 每个 Results 小段是否需要总结句?
   - [ ] with_summary (每段末加 "These data establish...")
   - [ ] without_summary (让数据自己说话)

6. **Discussion structure** — Discussion 的整体组织方式?
   - [ ] findings_first (先回顾本研究发现, 再延伸)
   - [ ] context_first (先回到领域背景)
   - [ ] hypothesis_first (先提出新假设, 用本研究支持)

## 细化维度 (可跳过)

7. **Introduction opening** — Introduction 的开篇方式?
   - [ ] factual (直接事实陈述)
   - [ ] hook_with_question (设问式)
   - [ ] hook_with_paradox (反直觉观察)
   - [ ] broad_context (宽泛背景铺垫)

8. **Citation density** — Introduction 的引用密度?
   - [ ] low (每段 1-2 引用)
   - [ ] medium (每段 3-4 引用)
   - [ ] high (每段 5+ 引用,文献综述风格)

9. **Limitations placement** — Discussion 中局限性的位置?
   - [ ] dedicated_paragraph (单独一段)
   - [ ] integrated (穿插在各论点中)
   - [ ] none (不主动讨论, 仅在审稿要求时加)

10. **Mechanism speculation marker** — 提出机制猜想时的固定开场白?
    - [ ] "We propose that..."
    - [ ] "One plausible explanation is that..."
    - [ ] "These findings raise the possibility that..."
    - [ ] "It is tempting to speculate that..."

11. **Banned phrases** — 哪些短语完全避免? (多选)
    - [ ] "plays a crucial role"
    - [ ] "sheds light on"
    - [ ] "paves the way for"
    - [ ] "It is worth noting that"
    - [ ] "Interestingly,"
    - [ ] "In this study, we aim to"
    - [ ] "has garnered significant attention"

12. **Figure reference format** — 引用图表的格式?
    - [ ] "Fig. 1A" (Nature 风格)
    - [ ] "Figure 1A" (PLOS 风格)  
    - [ ] "panel A of Fig. 1" (mBio 风格)
```

#### 14.D.2 check-in-prompts.md (Writer 在 section 内的 check-in 点)

```markdown
# Section Check-in Prompts (sci-bio-writer)

每个 section 在特定节点 Writer 会暂停询问更高层决策。

## Methods Section

- **Before strain section**: "Methods 通常按 (a) 实验目的分组 (b) 时间顺序 
  (c) 技术类别 组织。你倾向哪种?"
- **After strain section**: "接下来是基因操作方法。CRISPR → 互补 → 验证 顺序,
  还是按你实际做的时间顺序?"
- **After molecular biology section**: "生物信息学分析多详细? 
  (ultra-detail 含所有参数 / standard 含关键参数 / brief 仅工具名)"
- **Before stats section**: "统计方法在哪写? 
  (a) Methods 末尾单独段 (b) 散在各方法中 (c) 都写一遍以求完整)"

## Results Section

- **Before first paragraph**: "Results 第一句通常引出整个研究的核心发现。
  你想要 (a) 直接陈述发现 (b) 先复述 Introduction 的问题 (c) 用一个意外观察破题?"
- **After first finding**: "第一个发现写完了。下一个 Figure 按 (a) 逻辑递进 
  还是 (b) 按重要性排序?"
- **Mid-section (50%)**: "目前 Results 已 [字数],期刊限制 [限制]。剩余 [N] 
  个 Figure 中优先详述哪一个? (我会简化其他)"
- **Before last paragraph**: "Results 最后一段通常是最强的发现 + 自然过渡到 
  Discussion。你的最强发现是? 是否要在末尾埋一个 Discussion 钩子?"

## Discussion Section

- **Before opening**: "Discussion 开篇是 (a) 直接重述主要发现 (b) 回到 Introduction 
  问题 (c) 用一个对比观察作为钩子?"
- **After main findings recap (~20%)**: "接下来要把发现放进领域背景。你想强调 
  (a) 与之前文献一致 (b) 与之前文献矛盾 (c) 填补了空白?"
- **Mid-section (~50%)**: "现在要进入机制推测部分。基于 style_profile 设定的 
  [boldness level],你希望讨论 (a) 一个保守的、有数据支持的模型 (b) 一个大胆的、
  需要后续验证的假设 (c) 都讨论"
- **Before limitations**: "接下来是局限性。你希望列几个? 最主要的关切是? 
  审稿人最可能 attack 的点是?"
- **Before closing**: "Discussion 结尾选项: (a) 未来研究展望 (b) 对领域意义的 
  总结 (c) 一句凝练结论 (d) 三者结合"

## Introduction Section

- **Before opening sentence**: "Introduction 第一句话是整篇论文最重要的句子之一。
  你已经有想法了吗? 还是让我先给 3 个候选?"
- **After background paragraphs (~70%)**: "现在到了知识空白(knowledge gap)段落。
  你认为最关键的未解问题是什么? 一句话告诉我。"
- **Before final paragraph**: "最后一段陈述研究目的和主要发现。你希望透露多少结论? 
  (teaser 仅暗示 / partial 列出 1-2 个 / full 列出全部主要发现)"

## Abstract (由 Formatter 触发,但仍需 check-in)

- **Before drafting**: "目标期刊字数限制 [N]。你希望抽象偏 (a) 方法论侧重 
  (b) 结果数据侧重 (c) 概念意义侧重?"
- **After draft**: "草稿 [实际字数] / 限制 [N]。是否需要砍? 哪部分可以缩?"
```
