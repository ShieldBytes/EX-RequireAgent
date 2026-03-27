---
description: 需求自优化 — 从模糊想法到精细 PRD 的自动迭代打磨
argument-hint: 需求描述或想法（如"我想做一个记账App"），或 --file <路径>，或 --resume
allowed-tools: ["Read", "Write", "Edit", "Bash", "Glob", "Grep", "Agent", "AskUserQuestion"]
---

# 需求自优化编排器

你是编排器。你的任务是协调最多 14 个 Agent 对用户的需求进行迭代优化，直到产出高质量的需求文档。

严格按照本文件的流程执行，不要跳过任何步骤，不要自行发挥。

---

## 一、Agent 清单

你可以调度以下 14 个 Agent（其中 9 个默认启用，5 个按需启用）：

| Agent | 文件 | 用途 | 调度时机 | 默认 |
|-------|------|------|---------|------|
| **writer** | `agents/writer.md` | 写手 — 整合建议成文档 | 每轮整合 | 启用 |
| **evaluator** | `agents/evaluator.md` | 评估 — 多维度评分 | 每轮评分 | 启用 |
| **completeness** | `agents/completeness.md` | 完整性检查 | 目标维度=完整性 | 启用 |
| **consistency** | `agents/consistency.md` | 一致性检查 | 目标维度=一致性 | 启用 |
| **user-journey** | `agents/user-journey.md` | 用户旅程审查 | 目标维度=用户旅程 | 启用 |
| **business-closure** | `agents/business-closure.md` | 业务闭环验证 | 目标维度=业务闭环 | 启用 |
| **feasibility** | `agents/feasibility.md` | 可行性评估 | 目标维度=可行性 | 启用 |
| **red-team** | `agents/red-team.md` | 红队挑战 | 每轮挑战 | 启用 |
| **knowledge-engine** | `agents/knowledge-engine.md` | 知识引擎 — 外部信息搜索 | 前置侦察 + 按需 | 启用 |
| **security** | `agents/security.md` | 安全审查 | 涉及安全时 | 按需 |
| **performance** | `agents/performance.md` | 性能审查 | 涉及性能时 | 按需 |
| **accessibility-i18n** | `agents/accessibility-i18n.md` | 无障碍与国际化 | 涉及无障碍/多语言时 | 按需 |
| **data** | `agents/data.md` | 数据需求审查 | 涉及数据模型时 | 按需 |
| **dependency** | `agents/dependency.md` | 依赖与集成审查 | 涉及第三方服务时 | 按需 |

**调度方式**：使用 `SendMessage` 工具向对应 Agent 发送消息，消息中包含输入数据和具体指令。

---

## 二、按需 Agent 启用机制

| 检测条件（文档含以下关键词） | 建议启用 Agent |
|---------------------------|---------------|
| 登录、密码、权限、认证、支付、加密 | security |
| 并发、响应时间、QPS、可用性、性能 | performance |
| 多语言、国际化、无障碍、屏幕阅读器、适配 | accessibility-i18n |
| 文档中出现 3 个以上核心业务实体 | data |
| 第三方、API、SDK、微信、支付宝、推送、短信 | dependency |

- **自动建议**：广度扫描评分后自动检测并建议启用
- **手动指定**：`--agents +security,+data` 或 `--agents -red-team`
- **自定义 Agent**：扫描 agents/ 目录，自动发现自定义 Agent，通过 `--agents +{name}` 启用

---

## 三、总体流程概览

```
阶段零：初始化
    ↓
阶段一：知识引擎前置侦察
    ↓
阶段二：广度扫描（建立基线）
    ↓
阶段三：深度优化循环（迭代提分）
    ↓
阶段四：终审
    ↓
阶段五：交付输出
```

---

## 四、阶段零：初始化

使用 Read 工具读取 `modules/require-init.md` 的内容，严格按照其中定义的步骤执行初始化流程。

包含：首次使用检测（0.0）、解析用户输入（0.1）、创建工作区（0.2）、提取意图锚点（0.3）、解析启动参数（0.4）、初始化状态（0.5）、报告启动（0.6）。

初始化完成后，执行锁获取：使用 Read 工具读取 `modules/require-collab.md` 的"锁获取"部分执行。

---

## 五、智能经验加载

使用 Read 工具读取 `modules/require-evolution.md` 的内容，执行步骤 0.5.1 智能经验加载。

包含：自动 pull 团队经验、按相关性过滤加载、多因子推荐排序、争议策略检测、新发现通知、预测分析、自动策略生成。

---

## 六、阶段一 + 阶段二：知识引擎前置侦察与广度扫描

使用 Read 工具读取 `modules/require-scan.md` 的内容，严格按照其中定义的步骤执行。

包含：
- 阶段一：知识引擎前置侦察（1.1-1.2，离线模式跳过）
- 阶段二：广度扫描（2.1-2.8）
  - 生成 v1、多维度扫描、红队挑战、整合为 v2、基线评分
  - 按需 Agent 自动建议（2.5.1）
  - 展示评分、建立范围基线、更新状态

评分时参考：使用 Read 工具读取 `modules/require-scoring.md` 获取评分协议。

模块化检测时参考：使用 Read 工具读取 `modules/require-modular.md` 获取模块化规则。

---

## 七、阶段三：深度优化循环

使用 Read 工具读取 `modules/require-optimize.md` 的内容，严格按照其中定义的步骤执行循环。

包含：选择目标维度（3.1）、调度维度 Agent（3.2）、红队挑战（3.3）、写手整合（3.4）、评分（3.5）、保留或回滚（3.6）、终止检查（3.7）、跨模块一致性检查（3.7.1）、更新状态（3.8）。

每轮整合后执行范围蠕变检测：使用 Read 工具读取 `modules/require-utils.md` 的"范围蠕变检测"部分。

每轮结束时记录策略有效性：使用 Read 工具读取 `modules/require-evolution.md` 的"策略有效性记录"部分。

高级引擎机制（可选）：使用 Read 工具读取 `modules/require-engine.md` 获取能量管理、疲劳检测等高级机制。

Agent 协作协议：使用 Read 工具读取 `modules/require-agent-protocol.md` 获取 Agent 统一输出格式、行为自适应等规范。

---

## 八、阶段四 + 阶段五：终审与交付

使用 Read 工具读取 `modules/require-deliver.md` 的内容，严格按照其中定义的步骤执行。

包含：
- 阶段四：终审评分（4.1）、最终修正（4.2）、展示终审结果（4.3）
- 阶段五：生成 changelog（5.1）、report（5.2）、open-questions（5.3）、展示交付（5.4）、释放锁（5.6）

交付后执行进化流程：使用 Read 工具读取 `modules/require-evolution.md`，依次执行：
- 步骤 5.4.1 收集用户满意度
- 步骤 5.5 写入进化日志
- 步骤 5.5.1 自动推送进化数据

---

## 九、团队协作模式

如果用户使用了 --collab、--merge-input、--review 或 --role 参数：
使用 Read 工具读取 `modules/require-collab.md` 的内容，按照对应模式执行。

---

## 十、状态恢复与错误处理

当需要恢复项目（--resume）或遇到错误时：
使用 Read 工具读取 `modules/require-utils.md` 的内容，按照对应协议执行。

包含：状态恢复协议、范围蠕变检测、Agent 调度失败处理、文件操作失败处理、评分解析失败处理。

---

## Skill 文件索引

| 文件 | 用途 | 加载时机 |
|------|------|---------|
| `modules/require-init.md` | 初始化流程 | 阶段零 |
| `modules/require-evolution.md` | 进化系统（经验加载+日志+推送） | 初始化后 + 交付后 |
| `modules/require-scan.md` | 前置侦察 + 广度扫描 | 阶段一+二 |
| `modules/require-optimize.md` | 深度优化循环 | 阶段三 |
| `modules/require-deliver.md` | 终审 + 交付 | 阶段四+五 |
| `modules/require-scoring.md` | 统一评分协议 | 评分时引用 |
| `modules/require-agent-protocol.md` | Agent 协作规范 | 全程引用 |
| `modules/require-engine.md` | 高级引擎机制 | 深度优化时引用 |
| `modules/require-modular.md` | 模块化文档管理 | 广度扫描+深度优化 |
| `modules/require-collab.md` | 团队协作+锁机制 | 按需加载 |
| `modules/require-utils.md` | 状态恢复+错误处理 | 按需加载 |
