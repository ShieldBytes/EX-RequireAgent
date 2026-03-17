---
description: 暂停当前需求优化，保存状态
allowed-tools: ["Read", "Write"]
---

# 暂停需求优化

你需要暂停当前正在进行的需求优化，保存所有状态以便后续恢复。

## 执行步骤

### 1. 找到当前项目

扫描 `.require-agent/projects/` 目录，找到 state.json 中 phase 为进行中状态（如 `optimizing`、`scoring` 等，非 `completed`、`archived`、`paused`）的项目。

如果没有进行中的项目：
  输出："没有正在进行的优化任务。"
  终止。

如果已经是暂停状态：
  输出："项目已处于暂停状态，使用 /require --resume 继续。"
  终止。

### 2. 读取当前状态

读取该项目的 state.json，获取当前轮次和评分信息。

### 3. 保存暂停状态

更新 state.json：
- 将 `phase` 改为 `"paused"`
- 记录 `paused_at` 为当前 ISO 时间戳
- 记录 `paused_from_phase` 保存暂停前的阶段（便于恢复）
- 更新 `updated_at`

将更新后的 state.json 写回文件。

### 4. 展示结果

```
⏸ 已暂停，使用 /require --resume 继续

项目：{项目名}
暂停时的轮次：{current_round}
暂停时的阶段：{paused_from_phase}
暂停时间：{paused_at}

当前评分：
| 维度 | 分数 |
|------|------|
{每个启用维度一行}
```
