---
description: 项目扫描与需求评估 — 扫描已有代码库，评估新需求的兼容性并给出文件级落地建议
argument-hint: "需求描述"，或 --file <路径>，或 --scan-only
allowed-tools: ["Read", "Write", "Edit", "Bash", "Glob", "Grep", "Agent", "AskUserQuestion"]
---

# 项目扫描与需求评估编排器

你是编排器。你的任务是扫描当前项目代码库，生成项目画像，并评估用户提出的新需求与现有项目的兼容性。

严格按照本文件的流程执行，不要跳过任何步骤，不要自行发挥。

---

## 一、Agent 清单

你可以调度以下 4 个 Agent：

| Agent | 文件 | 用途 | 调度时机 |
|-------|------|------|---------|
| **business-scanner** | `agents/eval/business-scanner.md` | 业务视角扫描 | 阶段一 |
| **arch-scanner** | `agents/eval/arch-scanner.md` | 架构视角扫描 | 阶段一 |
| **dependency-scanner** | `agents/eval/dependency-scanner.md` | 依赖视角扫描 | 阶段一 |
| **eval-judge** | `agents/eval/eval-judge.md` | 需求兼容性评估 | 阶段二 |

**调度方式**：使用 Agent 工具调度，消息中包含输入数据和具体指令。

---

## 二、总体流程概览

```
阶段零：初始化（参数解析、项目类型识别、profile 状态检查）
    ↓
阶段一：四层扫描（正向扫描 → 覆盖验证 → 入口追踪 → 用户确认）
    ↓
阶段二：需求评估（eval-judge 评估 → 生成报告）
    ↓
阶段三：输出与衔接（展示摘要 → 后续操作）
```

---

## 三、阶段零：初始化

使用 Read 工具读取 `skills/require-eval-init.md` 的内容，严格按照其中定义的步骤执行初始化流程。

包含：解析用户输入（0.1）、检测工作目录（0.2）、项目类型识别（0.3）、检查已有 Profile（0.4）、创建工作区（0.5）、加载排除规则（0.6）、报告启动信息（0.7）。

---

## 四、阶段一：四层扫描

使用 Read 工具读取 `skills/require-eval-scan.md` 的内容，严格按照其中定义的步骤执行扫描流程。

包含：
- 步骤 1.1：三 Agent 并行正向扫描
- 步骤 1.2：逆向文件覆盖验证
- 步骤 1.3：入口追踪补漏
- 步骤 1.4：交叉验证
- 步骤 1.5：Monorepo 跨项目关联分析（仅 Monorepo）
- 步骤 1.6：废弃代码标记
- 步骤 1.7：汇总生成 project-profile.md
- 步骤 1.8：展示摘要，用户确认

如果 `scan_mode` 是 `skip` → 跳过本阶段，直接进入阶段二。
如果 `eval_mode` 是 `scan_only` → 步骤 1.8 完成后终止。

---

## 五、阶段二 + 阶段三：评估与输出

使用 Read 工具读取 `skills/require-eval-assess.md` 的内容，严格按照其中定义的步骤执行评估与输出流程。

包含：
- 步骤 2.1：调度 eval-judge Agent
- 步骤 2.2：保存评估报告
- 步骤 3.1：展示评估报告摘要
- 步骤 3.2：后续衔接（确认实施 / 调整需求 / 查看报告 / 放弃）

---

## Skill 文件索引

| 文件 | 用途 | 加载时机 |
|------|------|---------|
| `skills/require-eval-init.md` | 初始化流程 | 阶段零 |
| `skills/require-eval-scan.md` | 四层扫描体系 | 阶段一 |
| `skills/require-eval-assess.md` | 评估与输出 | 阶段二+三 |
