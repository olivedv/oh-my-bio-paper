# Agent Handoff — 角色间交接

<!--
  READ:  全角色可读 (接收交接指令)
  WRITE: 全角色可写 (发起交接请求)
  
  本文件用于角色间异步通信。一个角色写入请求，
  下次 /omp:plan 时 Conductor 会读取并调度相应角色处理。
  处理完成后，Conductor 清理已处理的条目。
-->

## 待处理的交接请求

_暂无待处理的交接请求。_

<!--
交接条目格式示例：

### [2025-01-15 14:30] Writer → StyleKeeper

**类型**: style_rule_request
**优先级**: normal
**描述**: Results 写作中发现 style_profile 缺少关于 fold-change 表达偏好的规则。
建议添加：使用 "N-fold increase/decrease" 而非 "increased/decreased by N times"。
**状态**: pending

### [2025-01-15 16:00] Reviewer → Writer

**类型**: revision_request
**优先级**: high
**描述**: Results ¶3 中 Fig2B 的描述与实际图片不符，需要核实。
**相关审查**: review_log.md #3
**状态**: pending
-->

## 已处理的交接记录

_暂无。_
