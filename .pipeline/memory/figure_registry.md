# Figure Registry — 图表注册表

<!--
  READ:  Writer, Reviewer, Formatter (写作/审查/格式化时引用)
  WRITE: figure-watcher Hook (自动登记), 用户手动补充
  
  figure-legend-gen skill 依赖本文件生成图注。
  manuscript-reviewer skill 用本文件做数据一致性校验。
-->

## 登记格式说明

每个 Figure/Table 条目包含：
- **编号**: Fig1, Fig2, Table1 等
- **文件路径**: paper/figures/ 下的源文件
- **Panel 描述**: 各 panel 的简要说明
- **统计方法**: 使用的统计检验
- **对应 Results 段落**: 在 Results 中被引用的位置
- **状态**: registered / annotated / legend_complete

---

## Figures

_暂无已登记的 Figure。运行 /omp:setup 后将 Figure 文件放入 paper/figures/，
figure-watcher Hook 会自动登记。手动登记格式如下：_

<!--
### Fig1 — [简要描述]
- **文件**: paper/figures/Fig1_xxx.tiff
- **Panels**:
  - (A) [描述]
  - (B) [描述]
- **统计方法**: [NEEDS_HUMAN_ANNOTATION]
- **对应 Results**: [待填写]
- **状态**: registered
-->

## Tables

_暂无已登记的 Table。_
