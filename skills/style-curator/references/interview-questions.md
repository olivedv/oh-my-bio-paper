# Style Curator — Initial Interview Questions

此文件是 style-curator skill 初次配置风格档案时的"题库"。skill
按本文件列出的顺序依次用 AskUserQuestion 向用户提问，把答案写入
`.pipeline/memory/style_profile.md` 的对应字段（见 `memory_field`）。

每题可选字段：
- `id`：问题编号，与 PLAN §14.D.1 对齐
- `memory_field`：答案要写入的 YAML key（见 style-schema.md）
- `required`：必答（核心维度）或可跳过（细化维度）
- `default_hint`：由 skill 在运行时根据 journal-preset 动态填入，
  题面会附一行"基于目标期刊的推荐值：<X>"

---

## 核心维度（必答，Q1–Q6）

### Q1. Narrative style
- id: 1
- memory_field: `narrative_style`
- required: true
- prompt: 这篇论文更接近"讲一个发现的故事"，还是"严格陈述技术结果"？
- options:
  - `story_driven` — 强叙事感，适合 Nature / Science 系列
  - `technical` — 严谨技术报告，适合 FGB / MMI 系列
  - `hybrid` — 两者混合，适合 mBio / PLOS Pathogens

### Q2. First-person usage
- id: 2
- memory_field: `first_person_usage`
- required: true
- prompt: Results 和 Discussion 中是否允许 "We found / We propose"？
- options:
  - `avoid` — 完全避免（全被动）
  - `we_allowed` — 允许但克制使用
  - `we_frequent` — 频繁使用 "We"

### Q3. Speculation boldness
- id: 3
- memory_field: `speculation_boldness`
- required: true
- prompt: Discussion 中推测分子机制时的措辞强度？
- options:
  - `conservative` — "suggests", "may indicate", "is consistent with"
  - `moderate` — "we propose", "raises the possibility that"
  - `bold` — "we demonstrate", "establishes that"

### Q4. Sentence complexity
- id: 4
- memory_field: `sentence_complexity`
- required: true
- prompt: 句子复杂度偏好？
- options:
  - `short` — 每句 ≤ 20 词，节奏紧凑
  - `medium` — 复合句可用，不超过 30 词
  - `complex` — 允许长复合句，学术化

### Q5. Results paragraph structure
- id: 5
- memory_field: `results.summary_sentences`
- required: true
- prompt: 每个 Results 小段是否需要总结句？
- options:
  - `per_figure` — 每段末加一句 "These data establish..."
  - `per_section` — 只在 subsection 末尾加总结句
  - `none` — 不加总结句，让数据自己说话

### Q6. Discussion structure
- id: 6
- memory_field: `discussion.structure`
- required: true
- prompt: Discussion 的整体组织方式？
- options:
  - `findings_first` — 先回顾本研究发现，再延伸
  - `context_first` — 先回到领域背景
  - `hypothesis_first` — 先提出新假设，用本研究支持

---

## 细化维度（可跳过，Q7–Q12）

### Q7. Introduction opening
- id: 7
- memory_field: `introduction.opening_style`
- required: false
- prompt: Introduction 的开篇方式？
- options:
  - `factual` — 直接事实陈述
  - `hook_with_question` — 设问式
  - `hook_with_paradox` — 反直觉观察
  - `broad_context` — 宽泛背景铺垫
  - `skip` — 跳过，使用默认值

### Q8. Citation density
- id: 8
- memory_field: `introduction.citation_density`
- required: false
- prompt: Introduction 的引用密度？
- options:
  - `low` — 每段 1–2 引用
  - `medium` — 每段 3–4 引用
  - `high` — 每段 5+ 引用（文献综述风格）
  - `skip` — 跳过

### Q9. Limitations placement
- id: 9
- memory_field: `discussion.limitations_placement`
- required: false
- prompt: Discussion 中局限性的位置？
- options:
  - `dedicated_paragraph` — 单独一段
  - `integrated` — 穿插在各论点中
  - `none` — 不主动讨论，仅在审稿要求时加
  - `skip` — 跳过

### Q10. Mechanism speculation marker
- id: 10
- memory_field: `discussion.mechanism_speculation_marker`
- required: false
- prompt: 提出机制猜想时的固定开场白？
- options:
  - `We propose that...`
  - `One plausible explanation is that...`
  - `These findings raise the possibility that...`
  - `It is tempting to speculate that...`
  - `skip` — 跳过

### Q11. Banned phrases（多选，拆成 7 个单题循环）
- id: 11
- memory_field: `banned_expressions`（array，skill 按 user 回答累积）
- required: false
- prompt 模板: 是否禁用 `<phrase>`？
- phrases（逐个问，y/n）：
  - `plays a crucial role`
  - `sheds light on`
  - `paves the way for`
  - `It is worth noting that`
  - `Interestingly,`
  - `In this study, we aim to`
  - `has garnered significant attention`
- options per phrase:
  - `ban` — 完全禁用
  - `allow` — 允许使用
- skip_all: 在开始前提供一个"全部采用期刊预设默认值"的快捷选项，用户选了就
  跳过这 7 个小题

### Q12. Figure reference format
- id: 12
- memory_field: `results.figure_reference_format`
- required: false
- prompt: 引用图表的格式？
- options:
  - `Fig. 1A` — Nature 风格
  - `Figure 1A` — PLOS 风格
  - `panel A of Fig. 1` — mBio 风格
  - `skip` — 跳过
