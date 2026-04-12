# Execution Context — 当前任务上下文

<!--
  READ:  Writer, Reviewer, Formatter, StyleKeeper (当前执行角色可读)
  WRITE: Conductor (由 Conductor 准备任务包)
-->

## 当前状态

⏳ **等待 Conductor 分配任务**

Conductor 还没有准备好任务包。请先运行 `/omp:plan` 来制定计划。

---

_当 Conductor 准备好任务后，本文件会包含以下内容：_

- **任务目标**: 具体要做什么
- **执行角色**: 由哪个 Agent 执行
- **参考材料**: 需要读哪些记忆文件
- **禁止事项**: 不能做什么
- **预期产出**: 期望的输出文件和格式
