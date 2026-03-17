---
description: 预览下一轮优化计划（不实际执行）
allowed-tools: ["Read", "Glob"]
---

# 预览下一轮优化计划

你需要分析当前项目状态，预测下一轮优化将执行的操作，但**不实际执行任何修改**。

## 执行步骤

### 1. 定位最近项目

使用 Glob 扫描 `.require-agent/projects/*/state.json`，找到最近修改的项目。

如果没有找到任何项目，提示：
```
未找到任何需求优化项目。请先使用 /require 启动一个项目。
```

### 2. 读取项目状态

读取以下文件：
- `.require-agent/projects/{项目名}/state.json`
- `.require-agent/projects/{项目名}/intent-anchor.json`

### 3. 检查项目状态

如果 `state.json` 的 `phase` 不是 `deep_optimization`，提示：
```
当前项目阶段为 {phase}，不在深度优化循环中，无法预览下一轮计划。

阶段说明：
- initialization：初始化中
- breadth_scan：广度扫描中
- deep_optimization：深度优化中（可预览）
- final_review：终审中
- delivery：交付中
- completed：已完成
```

### 4. 读取最新评分

使用 Glob 扫描 `.require-agent/projects/{项目名}/scores/*.json`，找到轮次最大的评分文件并读取。

### 5. 分析下一轮目标

按照编排器的维度选择逻辑，确定下一轮的目标维度：

1. 从 `scores` 中找到分数最低的维度
2. 如果有并列，按优先级排序：完整性 > 用户旅程 > 业务闭环 > 一致性 > 可行性 > 安全 > 性能 > 无障碍与国际化 > 数据 > 依赖与集成
3. 跳过 `stalled_dimensions` 中的维度
4. 确认目标维度对应的 Agent 在 `enabled_agents` 中

### 6. 确定优化策略

根据目标维度确定将使用的策略：

| 目标维度 | Agent | 策略 |
|---------|-------|------|
| 完整性 | completeness | 策略 B：反向场景法 |
| 一致性 | consistency | 策略 A：交叉比对法 |
| 用户旅程 | user-journey | 策略 A：角色扮演法 |
| 业务闭环 | business-closure | 策略 B：增长飞轮法 |
| 可行性 | feasibility | 策略 B：风险矩阵法 |
| 安全 | security | 攻击面分析法 |
| 性能 | performance | 场景建模法 |
| 无障碍与国际化 | accessibility-i18n | WCAG 对照法 |
| 数据 | data | 数据流追踪法 |
| 依赖与集成 | dependency | 故障预案法 |

### 7. 展示预览

```
预览：第 {current_round}/{max_rounds} 轮优化计划

项目：{项目名}
当前版本：v{最新版本号}

---

## 当前评分

| 维度 | 分数 | 达标线 | 状态 |
|------|------|--------|------|
{遍历所有启用维度，展示分数和达标状态}

## 下一轮计划

目标维度：{维度名称}（当前 {分数} 分，达标线 {target_score} 分）
优化策略：{策略名称}
执行 Agent：{agent名称} + red-team + writer + evaluator

## 执行流程预览

1. 调度 {agent名称} Agent，使用「{策略名}」深度分析 {维度名称} 维度
2. 调度 red-team Agent 审查优化建议
3. 调度 writer Agent 整合优化内容
4. 调度 evaluator Agent 重新评分
5. 根据评分决定保留或回滚

## 停滞维度

{如果有停滞维度，列出；否则显示"无"}

## 剩余轮次

已用：{current_round - 1} 轮
剩余：{max_rounds - current_round + 1} 轮

---

注意：以上为预览，不会实际执行。使用 /require --resume 继续优化。
```

### 8. 特殊情况

如果所有维度已达标：
```
所有维度已达标！下一步将进入终审阶段（阶段四）。
无需继续深度优化。
```

如果所有未达标维度都已停滞：
```
所有可优化维度均已停滞，下一步将进入终审阶段（阶段四）。
停滞维度：{列出}
```

如果轮次已耗尽：
```
已达最大轮次（{max_rounds}），下一步将进入终审阶段（阶段四）。
```
