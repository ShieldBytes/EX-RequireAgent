---
description: 终止当前需求优化，输出当前最优版本
allowed-tools: ["Read", "Write", "Glob", "Bash"]
---

# 终止需求优化

你需要终止当前正在进行的需求优化，输出当前最优版本。

## 执行步骤

### 1. 找到当前项目

扫描 `.require-agent/projects/` 目录，找到 state.json 中 phase 不是 `completed` 的项目。

如果没有进行中的项目：
  输出："没有正在进行的优化任务。"
  终止。

### 2. 读取当前状态

读取该项目的 state.json，获取：
- 项目名
- 当前轮次
- 当前评分
- 输出目录

### 3. 展示当前状态

```
⏹ 终止优化「{项目名}」

当前轮次：{current_round}
当前评分：
| 维度 | 分数 |
|------|------|
{每个启用维度一行}

最新版本：{最新版本号}
```

### 4. 生成交付文件

按照编排器阶段五的交付逻辑，生成：
- changelog.md（变更记录）
- report.md（优化报告，标注"手动终止"）
- open-questions.md（开放问题）

### 5. 更新状态

将 state.json 的 phase 改为 `completed`。
删除 lock.json（如存在）。

### 6. 输出

```
✅ 已终止并输出当前最优版本。

📁 输出文件：
  {output_dir}/
  ├── requirement-overview.md
  ├── changelog.md
  ├── report.md
  └── open-questions.md
```
