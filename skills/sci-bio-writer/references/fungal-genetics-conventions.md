# Fungal Genetics Conventions — Hard-coded Domain Rules

> 本文件的规则**不受 `style_profile.md` 控制**——这些是整个学科的共识，
> 任何项目的任何 section 都必须遵守。`sci-bio-writer` skill 在生成正文
> 前会读取本文件，并在输出前做自检；违反视为错误，必须重写。

来源：PLAN §4.2 line 167–174 + CLAUDE.md §写作规范。

---

## 1. 物种名（Species names）

- **首次出现**：属名 + 种名，全部斜体
  - LaTeX：`\textit{Talaromyces marneffei}`
  - 渲染：*Talaromyces marneffei*
- **后续出现**：属名缩写 + 种名，仍然斜体
  - LaTeX：`\textit{T. marneffei}`
  - 渲染：*T. marneffei*
- **适用范围**：所有 section 的正文、Figure legend、Methods。标题和关键词
  中是否斜体以目标期刊规范为准（见 `journal_spec.md`）

**反例（禁止）**：`T. marneffei`（未斜体）、`Talaromyces Marneffei`（大小写错）、
`T.marneffei`（缺空格）

---

## 2. 基因名（Gene names）

- **格式**：斜体小写（前缀大写仅限某些物种约定，真菌中一律小写）
- LaTeX：`\textit{acuD}`、`\textit{madsA}`、`\textit{areA}`
- 渲染：*acuD*、*madsA*、*areA*

**反例（禁止）**：`acuD`（未斜体）、`AcuD`（大写 = 蛋白，不是基因）

### 2.1 基因与等位基因标记

- 野生型：`\textit{acuD}$^+$` 或直接 `\textit{acuD}`
- 敲除：`\textit{acuD}$\Delta$` 或 `$\Delta$\textit{acuD}`（两种都接受，全文一致即可）
- 过表达：`\textit{acuD}$^{OE}$`
- 互补：`\textit{acuD}^{C}`

---

## 3. 蛋白名（Protein names）

- **格式**：正体，首字母大写
- LaTeX：`AcuD`、`MadsA`、`AreA`
- 渲染：AcuD、MadsA、AreA

**反例（禁止）**：`\textit{AcuD}`（斜体 = 基因，不是蛋白）、`acud`（小写）

---

## 4. 菌株编号（Strain IDs）

- **格式**：正体，无斜体，无空格
- 示例：`PM1`、`ATCC 18224`（机构编号前可带空格）、`ΔacuD::hph`
- LaTeX：直接写 `PM1`，不加 `\textit{}`

**反例（禁止）**：`\textit{PM1}`（斜体）、`PM 1`（不必要空格）、`pm1`（小写）

---

## 5. CRISPR-Cas9 相关术语

- **CRISPR-Cas9**：**必带连字符**。LaTeX：`CRISPR-Cas9`
- 其他 Cas 系统同理：`CRISPR-Cas12a` / `CRISPR-Cas13`
- sgRNA / gRNA：正体小写
- PAM：正体大写缩写

**反例（禁止）**：`CRISPR Cas9`（缺连字符）、`CRISPR/Cas9`（错误分隔符，除非
期刊明确要求）

---

## 6. 统计显著性标注（Statistical significance）

- **P 值**：字母 P 斜体，数值正体
  - LaTeX：`\textit{P} < 0.05`
  - 渲染：*P* < 0.05
- 常用阈值（符合绝大多数期刊）：
  - `\textit{P} < 0.05`（\*）
  - `\textit{P} < 0.01`（\*\*）
  - `\textit{P} < 0.001`（\*\*\*）
- **样本量**：`\textit{n}` 斜体小写
  - LaTeX：`\textit{n} = 3`
- **自由度 / F 统计 / t 统计**：所有单字母统计符号斜体
  - LaTeX：`\textit{t}(10) = 2.5`、`\textit{F}(2, 27) = 4.3`

**反例（禁止）**：`P < 0.05`（P 未斜体）、`\textit{P < 0.05}`（整体斜体）、
`p < 0.05`（小写 p，除非期刊明确要求）

---

## 7. Fold change 格式

- **标准写法**：`3.2-fold`（数字 + 连字符 + fold）
- **多倍程度**：`a 3-fold increase`、`a 10-fold higher`
- LaTeX：直接写 `3.2-fold`，无需特殊命令

**反例（禁止）**：
- `3.2 times`（用 fold，不用 times）
- `3.2 fold`（缺连字符）
- `3.2x`（不使用字母 x 作为乘号）
- `3.2-folds`（不复数）

---

## 8. 时态规范（来自 CLAUDE.md §写作规范）

本节为**硬规则基线**，`style_profile.md` 的 `tense_strictness` 字段只控制
执行的严格程度，不能覆盖下列基线。

| Section | 主导时态 | 例外 |
|---|---|---|
| Methods | 过去时被动语态 | 普适事实（"DNA is extracted...")用现在时，但本项目中不推荐 |
| Results | 过去时主动或被动均可 | 对 Figure 的描述可以是"Figure 1A shows..."（现在时） |
| Discussion | 现在时讨论意义 / 过去时回溯本研究 | 定律 / 公理 用现在时 |
| Introduction | 按 style_profile `tense_strictness` | 历史文献综述用过去时 |
| Abstract | 一般现在时（概述） + 过去时（具体结果） | — |

---

## 9. 其他常见错误（避免清单）

以下写法在真菌生物学论文中属于新手错误，生成时严禁出现：

- **基因 / 蛋白混用**：写 "AcuD was expressed" 然后描述 "acuD protein levels" ——
  蛋白用 AcuD，基因用 *acuD*，全文一致
- **数字与单位**：数字与单位之间空格（`100 mL` 不是 `100mL`）；%  例外
  （`25%` 不是 `25 %`）
- **温度**：`30 °C`（数字、空格、°C；不要 `30°C` 或 `30 C`）
- **时间**：`24 h` 或 `24 hours`（一致）；`2 min`、`30 s`
- **体积 / 质量**：微升 `μL`（μ 是希腊字母 μ，不是 u 或 m）
- **摩尔浓度**：`mM` / `μM` / `nM`，大小写严格
- **抗体稀释**：`1:1000`（冒号无空格）
- **pH**：小写 p，大写 H，无空格（`pH 7.4`）

---

## 10. 自检清单（生成后 skill 自动扫描）

`sci-bio-writer` 在写入 `.tex` 文件**之前**，必须扫描生成的正文，确认：

1. 所有菌种名都是 `\textit{}` 包裹
2. 所有基因名（小写斜体）都是 `\textit{}` 包裹
3. 所有蛋白名（首字母大写）**没有** `\textit{}` 包裹
4. 所有 P 值中的字母 P 是 `\textit{P}`
5. 所有 "fold" 写法带连字符
6. 没有出现 `CRISPR Cas9`（未连字符）
7. 统计符号（t, F, n）都斜体

任一违反 → 该段重写，不落盘违规文本。
