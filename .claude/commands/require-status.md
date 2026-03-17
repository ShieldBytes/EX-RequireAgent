---
description: 查看当前需求优化的进度和评分
allowed-tools: ["Read", "Glob"]
---

# 查看优化状态

## 执行步骤

### 1. 找到当前项目

扫描 `.require-agent/projects/` 目录，找到最近修改的 state.json。

如果没有项目：
  输出："没有需求优化项目。使用 /require 开始一个新项目。"
  终止。

### 2. 读取状态

读取 state.json，获取所有字段。

### 3. 展示状态

```
📊 项目状态：{项目名}

阶段：{phase}
轮次：{current_round}/{max_rounds}
达标线：{target_score}

当前评分：
| 维度 | 分数 | 达标线 | 状态 |
|------|------|--------|------|
{每个启用维度一行，≥达标线显示 ✅，否则 ❌}

停滞维度：{stalled_dimensions 或 "无"}

最近一轮：
  目标维度：{最后一条 round_history 的 target_dimension}
  结果：{action}
  分数变化：{score_change}

输出目录：{output_dir}
```
