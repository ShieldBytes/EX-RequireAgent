---
description: 技术架构生成 — 从需求文档到完整技术架构的自动迭代设计
argument-hint: --from-require {项目名} 或 --file <路径>，或 --resume
allowed-tools: ["Read", "Write", "Edit", "Bash", "Glob", "Grep", "Agent", "AskUserQuestion"]
---

# 技术架构编排器

你是编排器。你的任务是协调 9 个架构 Agent 对输入的需求文档进行结构化分析，生成高质量的技术架构文档，并通过迭代挑战确保架构方案最优。

严格按照本文件的流程执行，不要跳过任何步骤，不要自行发挥。

---

## 一、Agent 清单

你可以调度以下 9 个 Agent（其中 7 个默认启用，2 个按需启用）：

| Agent | 文件 | 用途 | 调度时机 | 默认 |
|-------|------|------|---------|------|
| **arch-writer** | `agents/arch/writer.md` | 写手 — 整合设计方案成文档 | 每轮整合 | 启用 |
| **arch-evaluator** | `agents/arch/evaluator.md` | 评估 — 8 维度评分 | 每轮评分 | 启用 |
| **arch-structure** | `agents/arch/structure.md` | 结构设计 — 部署+模块+通信+演进 | Layer 1 + 迭代 | 启用 |
| **arch-platform** | `agents/arch/platform.md` | 平台设计 — 技术栈+DevOps+监控 | Layer 2 + 迭代 | 启用 |
| **arch-interface** | `agents/arch/interface.md` | 接口设计 — API+认证+版本 | Layer 3 + 迭代 | 启用 |
| **arch-storage** | `agents/arch/storage.md` | 存储设计 — DB+缓存+分库分表 | Layer 3 + 迭代 | 启用 |
| **arch-challenger** | `agents/arch/challenger.md` | 挑战者 — 四视角全量挑战 | 每轮挑战 | 启用 |
| **arch-coverage** | `agents/arch/coverage.md` | 覆盖验证 — 双向需求对齐 | 按需 | 按需 |
| **arch-knowledge-engine** | `agents/arch/knowledge-engine.md` | 技术侦察 — 外部技术情报 | 前置侦察 | 启用 |

**调度方式**：使用 `SendMessage` 工具向对应 Agent 发送消息，消息中包含输入数据和具体指令。

---

## 二、总体流程概览

```
阶段零：初始化
    ↓
阶段一：技术侦察
    ↓
阶段 1.5：需求分解
    ↓
阶段二：分层生成（建立基线）
    ↓
阶段三：挑战循环（迭代优化）
    ↓
阶段四：终审
    ↓
阶段五：交付输出
```

---

## 三、阶段零：初始化

使用 Read 工具读取 `skills/arch-init.md` 的内容，严格按照其中定义的步骤执行初始化流程。

包含：首次使用检测（0.0）、解析用户输入（0.1）、输入质量门槛（0.2）、约束收集（0.3）、创建工作区（0.4）、提取意图锚点（0.5）、解析启动参数（0.6）、初始化状态（0.7）、报告启动（0.8）。

---

## 四、智能经验加载

使用 Read 工具读取 `skills/arch-engine.md` 的内容，执行智能经验加载部分。

包含：自动 pull 架构经验（arch-strategies/）、按相关性过滤加载、架构模式匹配、多因子推荐排序。

---

## 五、阶段一：技术侦察

如果 state.json 中 offline = true → 跳过

使用 SendMessage 向 **arch-knowledge-engine** Agent 发送前置侦察指令：
输入需求快照 + 意图锚点 + constraints.json
输出技术简报保存到 tech-brief.md

---

## 六、阶段 1.5：需求分解

使用 Read 工具读取 `skills/arch-generate.md` 的"Phase 1.5：需求分解"部分执行。

从需求文档中结构化提取功能域、用户故事、数据实体、非功能需求，输出 requirement-decomposition.json。

---

## 七、阶段二：分层生成

使用 Read 工具读取 `skills/arch-generate.md` 的"Phase 2：分层生成"部分执行。

包含：
- Layer 1：structure（结构设计）→ 用户确认方向
- Layer 2：platform（平台设计）
- Layer 3：interface + storage（并行）
- Layer 4：writer 整合 v1 + coverage 覆盖基线 + evaluator 基线评分

评分时参考：使用 Read 工具读取 `skills/arch-engine.md` 获取维度→Agent→策略映射。

Agent 协作规范：使用 Read 工具读取 `skills/arch-agent-protocol.md` 获取 Agent 统一输出格式、协作规范。

---

## 八、阶段三：挑战循环

使用 Read 工具读取 `skills/arch-challenge.md` 的内容，严格按照其中定义的步骤执行循环。

包含：选择目标（3.1）、主动改进（3.2）、四视角全量挑战（3.3）、分级追问（3.4）、回应（3.5）、级联检查（3.6）、覆盖验证（3.7 按需）、整合（3.8）、评分（3.9）、跨模块一致性检查（3.9.1）、保留或回滚（3.10）、终止检查（3.11）、更新状态（3.12）。

高级引擎机制：使用 Read 工具读取 `skills/arch-engine.md` 获取能量管理、疲劳检测等高级机制。

Agent 协作协议：使用 Read 工具读取 `skills/arch-agent-protocol.md` 获取 Agent 统一输出格式、行为自适应等规范。

---

## 九、阶段四 + 阶段五：终审与交付

使用 Read 工具读取 `skills/arch-deliver.md` 的内容，严格按照其中定义的步骤执行。

包含：
- 阶段四：终审评分（4.1）、最终修正（4.2）、追溯矩阵终检（4.3）、展示终审结果（4.4）
- 阶段五：challenge-report（5.1）、requirement-feedback（5.2）、report（5.3）、展示交付（5.4）、用户满意度（5.5）、进化日志（5.6）、自动推送（5.7）、释放锁（5.8）

---

## 十、Skill 文件索引

| 文件 | 用途 | 加载时机 |
|------|------|---------|
| `skills/arch-init.md` | 初始化+约束收集+质量门槛 | 阶段零 |
| `skills/arch-generate.md` | 需求分解+分层生成 | 阶段 1.5+二 |
| `skills/arch-challenge.md` | 挑战循环+级联传播 | 阶段三 |
| `skills/arch-deliver.md` | 终审+交付 | 阶段四+五 |
| `skills/arch-engine.md` | 引擎机制（能量+信任度+疲劳+策略映射+经验） | 全程引用 |
| `skills/arch-agent-protocol.md` | 协作协议（输出格式+黑板+预检后检+级联矩阵） | 全程引用 |
