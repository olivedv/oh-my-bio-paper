# Style Profile Schema

`style_profile.md` 是项目级的风格档案，Writer / Reviewer / Formatter
都从这里读取风格规则。文件采用 **YAML frontmatter + 自由文本正文** 的混合
格式 —— 上半部分供 skill 程序读，下半部分供人阅读编辑。

本文件定义所有字段的名称、类型、枚举值、默认值来源和填充逻辑。
style-curator skill 在生成 profile 时必须严格按此 schema 落盘。

---

## 结构总览

```
---
# META
# GLOBAL STYLE
# SECTION-SPECIFIC
#   introduction / results / discussion / methods / abstract
---

# Style Profile: <project_name>

## Style Summary
## Preferred Phrases
## Banned Expressions
## Domain-Specific Conventions (HARD RULES)
## Tone Calibration Examples
## Refinement History
```

---

## META 块（YAML frontmatter）

| key | 类型 | 说明 | 来源 |
|---|---|---|---|
| `project_name` | string | 项目名 | `.pipeline/config/project.json.project_name` |
| `target_journal` | string | 目标期刊 | `.pipeline/memory/journal_spec.md` |
| `generated_at` | ISO8601 | 首次生成时间 | 运行时 |
| `last_refined` | ISO8601 | 上次调整时间；首次生成时等于 `generated_at` | 运行时 |
| `curator_version` | string | style-curator skill 版本 | skill frontmatter |
| `reference_papers` | array | 范本论文列表，每项 `{ doi, citekey, weight }` | Phase 2 填充；MVP 留空 `[]` |

---

## GLOBAL STYLE 块（YAML frontmatter）

六个维度对应 interview Q1–Q4，其余两项由期刊预设或硬默认决定。

| key | 类型 | 枚举值 | 来源 |
|---|---|---|---|
| `narrative_style` | enum | `technical` / `story_driven` / `hybrid` | Q1 |
| `sentence_complexity` | enum | `short` / `medium` / `complex` | Q4 |
| `speculation_boldness` | enum | `conservative` / `moderate` / `bold` | Q3 |
| `first_person_usage` | enum | `avoid` / `we_allowed` / `we_frequent` | Q2 |
| `passive_voice_preference` | enum | `heavy` / `balanced` / `active_first` | 期刊预设 → 默认 `balanced` |
| `tense_strictness` | enum | `strict` / `flexible` | 默认 `strict` |

---

## SECTION-SPECIFIC 块（YAML frontmatter）

### `introduction`

| key | 类型 | 枚举值 | 来源 |
|---|---|---|---|
| `opening_style` | enum | `factual` / `hook_with_question` / `hook_with_paradox` / `broad_context` | Q7（skip → 默认 `factual`） |
| `paragraph_count_target` | int | 3–5 | 默认 `4` |
| `citation_density` | enum | `low` / `medium` / `high` | Q8（skip → 默认 `medium`） |
| `knowledge_gap_placement` | string | 自由文本 | 默认 `end_of_final_background_paragraph` |

### `results`

| key | 类型 | 枚举值 | 来源 |
|---|---|---|---|
| `summary_sentences` | enum | `none` / `per_figure` / `per_section` | Q5 |
| `transition_style` | enum | `implicit` / `explicit` | 默认 `explicit` |
| `tense` | enum | `past` | 硬默认（生物论文规范） |
| `figure_reference_format` | enum | `Fig. 1A` / `Figure 1A` / `panel A of Fig. 1` | Q12（skip → 默认 `Fig. 1A`） |
| `sub_heading_allowed` | bool | — | 默认 `true` |

### `discussion`

| key | 类型 | 枚举值 | 来源 |
|---|---|---|---|
| `structure` | enum | `findings_first` / `context_first` / `hypothesis_first` | Q6 |
| `limitations_placement` | enum | `dedicated_paragraph` / `integrated` / `none` | Q9（skip → 默认 `dedicated_paragraph`） |
| `mechanism_speculation_marker` | string | 4 个固定短语之一 | Q10（skip → 默认 `We propose that...`） |
| `paragraph_count_target` | int | 4–6 | 默认 `5` |

### `methods`（硬规则，不由交互决定）

| key | 类型 | 值 |
|---|---|---|
| `voice` | enum | `strictly_passive` |
| `citation_for_kit` | enum | `supplier_and_cat_number` |
| `statistical_test_declaration` | enum | `required_in_each_subsection` |

### `abstract`

| key | 类型 | 来源 |
|---|---|---|
| `structure` | enum（`narrative` / `structured`） | 期刊预设 → 默认 `narrative` |
| `word_limit` | int | 继承自 `journal_spec.md`；缺失时写 `150` |
| `key_numbers_required` | int | 默认 `2` |

---

## 正文块（自由文本）

### `# Style Profile: <project_name>`
一级标题，值 = META 的 `project_name`。

### `## Style Summary`
一段 3–5 行的自然语言总结，由 skill 根据交互答案拼装：
"This paper <narrative_style> · <first_person_usage> · <speculation_boldness>.
Reference model: <target_journal>."
用户可在后续手动精修这一段。

### `## Preferred Phrases`
MVP 版本由 skill 按期刊预设写入默认短语列表（分 transitions /
data_description / mechanism_openers / intro_transitions 四类）；如期刊预设
为 stub，则写入 `# (to be populated in Phase 2 after reference-paper analysis)`
占位。

### `## Banned Expressions`
由 Q11 的"禁用"答案拼装成 markdown bullet 列表。每条一行，末尾可附一句
中文理由（如 `"plays a crucial role" — AI 套话，在生物论文中几乎无信息量`）。

### `## Domain-Specific Conventions (HARD RULES)`
硬编码区域，**不受交互影响**，每次生成都原样写入：

```
- Species: *Talaromyces marneffei* (first), *T. marneffei* (subsequent)
- Genes: italic (*acuD*, *madsA*)
- Proteins: non-italic (AcuD, MadsA)
- Strain names: PM1 style (no italics, no spaces)
- Statistical P values: italic P (P < 0.05)
- CRISPR-Cas9: with hyphen
- Fold changes: "3.2-fold" not "3.2 times"
```

### `## Tone Calibration Examples`
MVP 版本留空占位：
```
> _No reference papers analyzed yet. Will be populated when reference-paper
> LLM analysis is implemented in Phase 2._
```

### `## Refinement History`
Markdown 表格，首次生成时只有一行：
```
| Date | Trigger | Changes |
|------|---------|---------|
| <YYYY-MM-DD> | Initial creation | Generated from <N> interview answers + <journal> preset |
```

---

## 字段填充优先级

当一个字段有多个潜在来源时，按以下优先级（高 → 低）决定最终值：

1. 用户在交互问卷中给出的明确答案
2. 目标期刊 preset 的推荐值
3. 本 schema 指定的硬默认
4. Phase 2 将来接入的范本论文分析结果（暂未启用）
