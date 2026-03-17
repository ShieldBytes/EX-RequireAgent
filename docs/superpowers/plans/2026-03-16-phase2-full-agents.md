# EX-RequireAgent 阶段二：补齐基础 Agent + 知识引擎

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为每个评分维度配备专属 Agent，并增加知识引擎提供外部信息支持，替换阶段一中 completeness Agent 兼顾所有维度的临时方案。

**Architecture:** 新增 4 个维度 Agent + 1 个知识引擎 Agent，升级编排 Skill 的调度逻辑，使其按维度调度对应 Agent。

**前置条件：** 阶段一 MVP 已完成，以下文件已存在：
- `.claude/commands/require.md`（编排器）
- `agents/completeness.md`、`agents/evaluator.md`、`agents/red-team.md`、`agents/writer.md`
- `templates/`（三个模板）
- `evolution/seed/`（种子数据）

**工作目录：** `/Library/MonkCoding/git_Project/test-require-agent/`

---

## 子阶段总览

```
2.1  创建一致性 Agent 文件
2.2  验证一致性 Agent 格式和内容
2.3  创建用户旅程 Agent 文件
2.4  验证用户旅程 Agent 格式和内容
2.5  创建业务闭环 Agent 文件
2.6  验证业务闭环 Agent 格式和内容
2.7  创建可行性 Agent 文件
2.8  验证可行性 Agent 格式和内容
2.9  创建知识引擎 Agent 文件
2.10 验证知识引擎 Agent 格式和内容
2.11 升级编排 Skill：Agent 清单部分
2.12 升级编排 Skill：广度扫描阶段（并行调度新 Agent）
2.13 升级编排 Skill：深度优化阶段（按维度调度对应 Agent）
2.14 升级编排 Skill：知识引擎前置侦察（阶段一）
2.15 更新种子数据（补充新 Agent 的策略排名）
2.16 端到端验证
```

---

## Chunk 1: 一致性 Agent（子阶段 2.1 - 2.2）

### Task 1: 创建一致性 Agent

**Files:**
- Create: `agents/consistency.md`

**参考规范：** 设计文档附录 A #2

**YAML frontmatter 必须包含：**
```yaml
name: consistency
description: 需求一致性检查 — 找出需求中的矛盾、术语混乱、引用错误和格式不统一。
tools:
  - Read
  - Glob
```

**正文必须包含以下章节（按此顺序）：**

1. **角色定义**：一句话说明"你是谁，做什么"
2. **核心职责**：找出需求中自相矛盾的部分
3. **检查维度**（4 个，每个有详细说明和检查示例）：
   - 逻辑一致性：需求 A 和需求 B 是否矛盾、同一功能不同描述、业务规则冲突
   - 术语一致性：同一概念多种叫法（如"订单/交易/购买"）、术语定义歧义、要求生成术语对照表
   - 格式一致性：有些功能写得很细有些只有一句话、颗粒度不统一、描述风格不统一
   - 引用一致性：功能 A 引用功能 B 但 B 不存在、跨模块引用是否正确、依赖关系是否有循环
4. **策略池**（2 个，MVP 阶段）：
   - 策略 A：交叉比对法 — 逐对比较需求项，找矛盾。说明具体怎么做。
   - 策略 B：术语图谱法 — 构建术语关系图，发现同义词和歧义。说明具体怎么做。
5. **输出格式**（必须是结构化格式，与 completeness Agent 风格一致）：
   ```
   [一致性] 严重程度：高/中/低
   目标：具体的需求项或章节
   发现：矛盾/不一致的具体内容
   建议：如何修正
   ```
   附带 2 个具体示例。
6. **工作规则**（5-7 条，必须包含）：
   - 每次聚焦一个检查维度
   - 发现按严重程度排序
   - 不要泛泛而谈，要具体到需求项
   - 如果发现术语不统一，给出建议的统一用语
   - 引用检查时列出完整的引用链

- [ ] **Step 1: 创建 agents/consistency.md**
- [ ] **Step 2: Commit**
```bash
git add agents/consistency.md
git commit -m "feat: 添加一致性 Agent 定义"
```

### Task 2: 验证一致性 Agent

- [ ] **Step 1: 检查 frontmatter 格式**
确认 name、description、tools 字段存在且格式正确。

- [ ] **Step 2: 检查内容完整性**
确认 6 个章节全部存在：角色定义、核心职责、检查维度（4 个）、策略池（2 个）、输出格式（含示例）、工作规则。

- [ ] **Step 3: 对比 completeness Agent 输出格式**
读取 agents/completeness.md 的输出格式部分，确认 consistency Agent 的输出格式风格一致（都是 `[类型] 严重程度 + 目标 + 发现 + 建议`）。

---

## Chunk 2: 用户旅程 Agent（子阶段 2.3 - 2.4）

### Task 3: 创建用户旅程 Agent

**Files:**
- Create: `agents/user-journey.md`

**参考规范：** 设计文档附录 A #3

**YAML frontmatter 必须包含：**
```yaml
name: user-journey
description: 用户旅程审查 — 模拟不同角色的用户走完全部流程，找出体验断点、流程缺失和情绪痛点。
tools:
  - Read
  - Glob
```

**正文必须包含以下章节：**

1. **角色定义**：你是用户旅程 Agent，专注于模拟真实用户的使用体验
2. **核心职责**：模拟用户走完全部流程，找出断点
3. **检查维度**（5 个）：
   - 多角色旅程模拟：新手用户、普通用户、高级用户、管理员、特殊用户（访客/被封禁/过期会员）。每个角色关注什么、容易在哪里卡住。
   - 关键路径分析：核心任务能否在最短步骤内完成、是否有不必要的跳转和等待、错误恢复路径是否通畅
   - 情绪地图：标注愉悦点（成就感、惊喜）和挫败点（困惑、等待、失败）、挫败点密集区 = 流失高风险区
   - 断点检测：流程中断后能否恢复、跨设备能否延续、跨时间能否延续
   - 上下文连贯性：页面间信息不断裂、操作有及时反馈、用户始终知道自己在哪和下一步是什么
4. **策略池**（2 个，MVP 阶段）：
   - 策略 A：角色扮演法 — 选择一个角色，从注册/首次使用开始，逐步走完所有流程。每个步骤记录：用户做什么、期望什么结果、实际会怎样。
   - 策略 B：关键路径法 — 只走核心任务的最短路径，检查每步是否通畅、是否有多余步骤。
5. **输出格式**：
   ```
   [用户旅程] 严重程度：高/中/低
   角色：新手用户/普通用户/管理员/...
   位置：流程中的具体步骤或页面
   发现：断点/痛点的具体描述
   影响：用户会怎样（放弃？困惑？绕路？）
   建议：如何修复
   ```
   附带 2 个具体示例。
6. **工作规则**（5-7 条）：
   - 每次选择一个角色走完一条核心路径
   - 从用户第一次接触产品开始（不要假设用户已经知道怎么用）
   - 重点关注流程中的"转折点"（从一个状态到另一个状态）
   - 异常路径和正常路径同样重要
   - 如果需求中没有定义某个步骤的行为，标记为 [未定义]

- [ ] **Step 1: 创建 agents/user-journey.md**
- [ ] **Step 2: Commit**
```bash
git add agents/user-journey.md
git commit -m "feat: 添加用户旅程 Agent 定义"
```

### Task 4: 验证用户旅程 Agent

- [ ] **Step 1: 检查 frontmatter 格式**
- [ ] **Step 2: 检查内容完整性**（角色定义、核心职责、5 个检查维度、2 个策略、输出格式含示例、工作规则）
- [ ] **Step 3: 对比其他 Agent 输出格式风格一致性**

---

## Chunk 3: 业务闭环 Agent（子阶段 2.5 - 2.6）

### Task 5: 创建业务闭环 Agent

**Files:**
- Create: `agents/business-closure.md`

**参考规范：** 设计文档附录 A #4

**YAML frontmatter：**
```yaml
name: business-closure
description: 业务闭环验证 — 验证商业逻辑是否自洽，收入模型、增长循环、利益方关系是否完整。
tools:
  - Read
  - Glob
  - WebSearch
  - WebFetch
```

**正文必须包含以下章节：**

1. **角色定义**
2. **核心职责**：验证商业逻辑能否自洽运转
3. **检查维度**（5 个）：
   - 核心商业逻辑：价值链完整性（谁提供价值→谁获得价值→谁付费）、收入来源是否明确且可执行、成本结构是否合理
   - 增长循环验证：用户获取渠道、留存机制（什么让用户回来）、传播机制（用户会推荐吗）、变现路径
   - 单元经济模型：获客成本 CAC、用户生命周期价值 LTV、LTV > CAC 是否成立、回本周期
   - 利益方分析：所有利益相关方是否被考虑、各方核心诉求、利益冲突点
   - 商业风险识别：市场风险（需求是否真实）、竞争风险（壁垒是什么）、政策风险
4. **策略池**（2 个）：
   - 策略 A：成本收益法 — 对每个核心功能评估：投入多少、产出多少、值不值得
   - 策略 B：增长飞轮法 — 验证获客→留存→变现→再获客的循环是否闭合，每个环节是否有具体机制
5. **输出格式**：
   ```
   [业务闭环] 严重程度：高/中/低
   目标：商业模式的具体环节
   发现：缺失或不合理的部分
   风险：如果不解决会怎样
   建议：如何完善
   ```
   附带 2 个示例。
6. **工作规则**

- [ ] **Step 1: 创建 agents/business-closure.md**
- [ ] **Step 2: Commit**

### Task 6: 验证业务闭环 Agent

- [ ] **Step 1: 检查 frontmatter**
- [ ] **Step 2: 检查内容完整性**
- [ ] **Step 3: 输出格式一致性**

---

## Chunk 4: 可行性 Agent（子阶段 2.7 - 2.8）

### Task 7: 创建可行性 Agent

**Files:**
- Create: `agents/feasibility.md`

**参考规范：** 设计文档附录 A #5

**YAML frontmatter：**
```yaml
name: feasibility
description: 可行性评估 — 从技术、资源、时间、成本四个维度评估需求能否落地，标注风险等级和替代方案。
tools:
  - Read
  - Glob
  - WebSearch
  - WebFetch
```

**正文必须包含以下章节：**

1. **角色定义**
2. **核心职责**：评估需求在现实条件下能否落地
3. **检查维度**（5 个）：
   - 技术可行性：是否有成熟方案、是否涉及前沿高风险技术、技术难点标注
   - 资源可行性：需要什么团队配置、规模是否匹配、是否有人才瓶颈
   - 时间可行性：量级与时间线是否匹配、哪些可分期实现、MVP 范围建议
   - 成本可行性：开发成本预估、运营成本（服务器/第三方）、是否超预算
   - 风险分级：每个功能点标注实现风险等级（低/中/高）+ 高风险需有替代方案
4. **策略池**（2 个）：
   - 策略 A：MVP 裁剪法 — 按优先级和可行性裁剪最小可行版本，标注 P0/P1/P2/P3
   - 策略 B：风险矩阵法 — 对每个功能评估"实现概率 × 影响程度"，输出风险排序
5. **输出格式**：
   ```
   [可行性] 严重程度：高/中/低
   目标：具体功能点或需求项
   风险类型：技术/资源/时间/成本
   发现：具体风险描述
   影响：如果不处理会怎样
   建议：替代方案或缓解措施
   ```
   附带 2 个示例。
6. **工作规则**

- [ ] **Step 1: 创建 agents/feasibility.md**
- [ ] **Step 2: Commit**

### Task 8: 验证可行性 Agent

- [ ] **Step 1-3: 同上验证流程**

---

## Chunk 5: 知识引擎 Agent（子阶段 2.9 - 2.10）

### Task 9: 创建知识引擎 Agent

**Files:**
- Create: `agents/knowledge-engine.md`

**参考规范：** 设计文档第五章

**YAML frontmatter：**
```yaml
name: knowledge-engine
description: 知识引擎 — 全球范围搜索竞品、行业实践、用户痛点等外部信息，为其他 Agent 提供情报支持。
tools:
  - Read
  - Glob
  - WebSearch
  - WebFetch
```

**正文必须包含以下章节：**

1. **角色定义**：你是知识引擎 Agent，负责从外部世界获取信息来支撑需求优化
2. **核心职责**：全球范围搜索，为其他 Agent 提供情报
3. **工作模式**（MVP 阶段只实现 2 个）：
   - 模式一：前置侦察 — 项目启动时主动搜索竞品、行业标准、用户痛点，输出「领域简报」
   - 模式二：按需深挖 — 被编排器或其他 Agent 调用时，针对特定话题深度搜索
4. **搜索规则**：
   - 默认全球范围搜索，不限定项目类型
   - 同时搜索正面信息（最佳实践）和反面信息（失败案例、用户投诉）
   - 不预设渠道，根据项目内容自动判断去哪搜
   - 用户可通过 --market 参数缩窄范围
5. **来源分级**：
   - S 级（高可信）：官方文档、应用商店实际功能、权威报告 → 直接使用
   - A 级（较可信）：专业媒体、头部评测 → 直接使用
   - B 级（参考）：普通用户评论、论坛 → 标记 [待验证]
   - C 级（存疑）：单一来源、无法验证 → 不使用
6. **输出格式**：
   ```
   [知识引擎] 类型：竞品信息/行业标准/用户痛点/风险案例
   来源：具体网站或文档名称
   可信度：S/A/B/C
   内容摘要：3-5 句话的结构化摘要
   与当前需求的关系：这条信息对需求优化有什么用
   ```
   领域简报格式（前置侦察输出）：
   ```
   # 领域简报：{项目名}

   ## 竞品概览
   （列出 3-5 个主要竞品及其核心功能）

   ## 行业标准
   （该领域的通用标准和最佳实践）

   ## 用户痛点
   （目标用户群体的高频痛点）

   ## 差异化机会
   （竞品未覆盖或做得不好的领域）

   ## 风险提示
   （行业内的常见失败案例和风险）
   ```
7. **工作规则**：
   - 搜索结果去重，不重复搜同一内容
   - 输出精简摘要，不是原始网页内容
   - 关键信息尽量交叉验证（2+ 来源）
   - 搜索失败时不编造信息，明确标注"未找到相关信息"

- [ ] **Step 1: 创建 agents/knowledge-engine.md**
- [ ] **Step 2: Commit**

### Task 10: 验证知识引擎 Agent

- [ ] **Step 1: 检查 frontmatter**
- [ ] **Step 2: 检查内容完整性**（7 个章节全部存在）
- [ ] **Step 3: 确认来源分级标准清晰**
- [ ] **Step 4: 确认两种输出格式（单条信息 + 领域简报）都有定义**

---

## Chunk 6: 升级编排 Skill — Agent 清单 + 广度扫描（子阶段 2.11 - 2.12）

### Task 11: 升级编排 Skill — Agent 清单部分

**Files:**
- Modify: `.claude/commands/require.md`（Agent 清单章节）

**具体修改：**

找到"一、Agent 清单"章节，将 Agent 表格从 4 个扩展为 9 个：

| Agent | 文件 | 用途 | 调度时机 |
|-------|------|------|---------|
| writer | agents/writer.md | 写手 | 每轮整合 |
| evaluator | agents/evaluator.md | 评估 | 每轮评分 |
| completeness | agents/completeness.md | 完整性检查 | 目标维度=完整性时 |
| consistency | agents/consistency.md | 一致性检查 | 目标维度=一致性时 |
| user-journey | agents/user-journey.md | 用户旅程审查 | 目标维度=用户旅程时 |
| business-closure | agents/business-closure.md | 业务闭环验证 | 目标维度=业务闭环时 |
| feasibility | agents/feasibility.md | 可行性评估 | 目标维度=可行性时 |
| red-team | agents/red-team.md | 红队挑战 | 每轮挑战 |
| knowledge-engine | agents/knowledge-engine.md | 知识引擎 | 前置侦察 + 按需调用 |

- [ ] **Step 1: 修改 Agent 清单表格**
- [ ] **Step 2: Commit**

### Task 12: 升级编排 Skill — 广度扫描阶段

**Files:**
- Modify: `.claude/commands/require.md`（阶段二章节）

**具体修改：**

在步骤 2.1（writer 生成 v1）之后、步骤 2.2（completeness 扫描）中：

**原来**：只调度 completeness Agent 做所有扫描

**改为**：分别调度 5 个维度 Agent 各自扫描自己负责的维度

修改步骤 2.2 为：

```
步骤 2.2：多维度并行扫描

分别调度以下 5 个 Agent，每个只关注自己的维度：

a) completeness Agent → 功能遍历法扫描完整性
b) consistency Agent → 交叉比对法扫描一致性
c) user-journey Agent → 角色扮演法扫描用户旅程
d) business-closure Agent → 成本收益法扫描业务闭环
e) feasibility Agent → MVP 裁剪法扫描可行性

每个 Agent 的输入都是 v1 文档全文。
收集所有 Agent 的发现，合并为 all_findings 变量。
```

步骤 2.3（红队挑战）的输入改为 `v1 + all_findings`。
步骤 2.4（写手整合）的输入改为 `v1 + all_findings + redteam_challenges`。

- [ ] **Step 1: 修改步骤 2.2 为多 Agent 并行扫描**
- [ ] **Step 2: 修改步骤 2.3 和 2.4 的输入引用**
- [ ] **Step 3: Commit**

---

## Chunk 7: 升级编排 Skill — 深度优化 + 知识引擎（子阶段 2.13 - 2.14）

### Task 13: 升级编排 Skill — 深度优化阶段

**Files:**
- Modify: `.claude/commands/require.md`（阶段三章节）

**具体修改：**

修改步骤 3.2（优化），将"所有维度都用 completeness Agent"改为"按维度调度对应 Agent"：

```
步骤 3.2：优化 — 调度维度专属 Agent

根据步骤 3.1 选出的目标维度，调度对应的 Agent：

| 目标维度 | 调度 Agent | 使用策略 |
|---------|-----------|---------|
| 完整性 | completeness | 反向场景法 |
| 一致性 | consistency | 交叉比对法或术语图谱法 |
| 用户旅程 | user-journey | 角色扮演法 |
| 业务闭环 | business-closure | 增长飞轮法 |
| 可行性 | feasibility | 风险矩阵法 |

指令模板（根据目标维度替换 Agent 和策略）：
"你是 {Agent名} Agent。请对以下需求文档进行深度检查。
 使用 {策略名}，聚焦 {目标维度} 维度。
 需求文档：{文档内容}"
```

删除原来的"如果目标维度是其他（一致性/可行性/用户旅程/业务闭环）→ 用 completeness 兼顾"的逻辑。

- [ ] **Step 1: 修改步骤 3.2 的 Agent 调度逻辑**
- [ ] **Step 2: 确认调度指令模板清晰无歧义**
- [ ] **Step 3: Commit**

### Task 14: 升级编排 Skill — 知识引擎前置侦察

**Files:**
- Modify: `.claude/commands/require.md`

**具体修改：**

在阶段零（初始化）和阶段二（广度扫描）之间，插入新的阶段一：

```
## 阶段一：知识引擎前置侦察

### 步骤 1.1：调度知识引擎 Agent

使用 Agent 工具调度 knowledge-engine Agent：

指令：
"你是知识引擎 Agent。请对以下项目进行前置侦察。

项目描述：{raw_input}
意图锚点：{intent-anchor.json 内容}

请执行：
1. 搜索 3-5 个主要竞品及其核心功能
2. 搜索该领域的行业标准和最佳实践
3. 搜索目标用户的高频痛点
4. 搜索该领域的失败案例和风险

输出格式：按照你定义的「领域简报」格式输出。"

### 步骤 1.2：保存领域简报

将知识引擎的输出保存到：
- .require-agent/projects/{项目名}/domain-brief.md

### 步骤 1.3：向用户展示简报摘要

"🔍 前置侦察完成
 发现 {N} 个竞品，{M} 条行业标准，{K} 个用户痛点
 详细简报已保存到 .require-agent/projects/{项目名}/domain-brief.md

 进入广度扫描..."
```

同时修改阶段二步骤 2.1（writer 生成 v1），在指令中增加领域简报作为参考：

```
在 writer 的指令中追加：
"参考以下领域简报来丰富你的需求文档：
 {domain-brief.md 内容}"
```

总体流程概览也需要更新：
```
阶段零：初始化
    ↓
阶段一：知识引擎前置侦察 ← 新增
    ↓
阶段二：广度扫描
    ↓
...
```

- [ ] **Step 1: 在阶段零和阶段二之间插入阶段一**
- [ ] **Step 2: 修改步骤 2.1 的 writer 指令，加入领域简报引用**
- [ ] **Step 3: 更新总体流程概览**
- [ ] **Step 4: Commit**

---

## Chunk 8: 种子数据更新 + 端到端验证（子阶段 2.15 - 2.16）

### Task 15: 更新种子数据

**Files:**
- Modify: `evolution/seed/strategy-rankings.md`

**具体修改：**

确认策略排名中已包含所有新 Agent 的策略。当前种子数据在阶段一已创建，检查以下维度是否都有排名：

- 完整性 ✅（已有）
- 一致性 ✅（已有：交叉比对法、术语图谱法）
- 用户旅程 ✅（已有：角色扮演法、关键路径法）
- 业务闭环 ✅（已有：成本收益法、竞品对标法）
- 可行性 ✅（已有：MVP 裁剪法、技术调研法）

如果已完整则不需要修改，只做确认。

- [ ] **Step 1: 读取并确认种子数据完整性**
- [ ] **Step 2: 如有缺失则补充**

### Task 16: 端到端验证

- [ ] **Step 1: 在 test-require-agent 目录重新启动 Claude Code**

- [ ] **Step 2: 运行完整流程**
```
/require 我想做一个团队协作的项目管理工具，支持任务分配和进度跟踪
```
（故意用不同于阶段一的输入，验证通用性）

- [ ] **Step 3: 验证前置侦察**
确认知识引擎 Agent 被调度，输出了领域简报。

- [ ] **Step 4: 验证广度扫描**
确认 5 个维度 Agent 分别被调度扫描（不再只有 completeness）。

- [ ] **Step 5: 验证深度优化**
确认目标维度匹配的专属 Agent 被调度（如目标是"一致性"→ consistency Agent 被调度）。

- [ ] **Step 6: 验证输出文件**
- docs/requirements/{项目名}/requirement-overview.md
- docs/requirements/{项目名}/changelog.md
- docs/requirements/{项目名}/report.md
- .require-agent/projects/{项目名}/domain-brief.md（新增）

- [ ] **Step 7: 记录问题并修复**

**阶段二验收标准：**
- [ ] 9 个 Agent 文件全部存在且格式正确
- [ ] 知识引擎前置侦察正常运行
- [ ] 广度扫描调度 5 个专属维度 Agent
- [ ] 深度优化按维度调度对应 Agent
- [ ] 输出文件完整
- [ ] 领域简报正常生成
