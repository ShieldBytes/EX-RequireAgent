<!-- 本文件是 EX-RequireAgent 架构编排器的子模块，由主命令 .claude/commands/arch.md 引用 -->
<!-- 不要直接运行本文件，它通过 Read 工具被加载 -->

# Phase 1.5 + Phase 2：需求分解与分层生成

本模块包含需求分解（Phase 1.5）和分层架构生成（Phase 2）的全部步骤。

---

## Phase 1.5：需求分解

在技术侦察（Phase 1）完成后执行。从需求文档中进行结构化提取，为后续分层设计提供输入。

### 步骤 1.5.1：功能域提取

从 `requirement-snapshot.md` 中提取功能域列表，每个功能域包含：

```json
{
  "functional_domains": [
    {
      "id": "FD-001",
      "domain": "功能域名称",
      "source": "需求文档中的出处章节",
      "requirements": [
        { "id": "R-001", "description": "具体功能需求描述" }
      ],
      "user_stories": [
        { "id": "US-001", "story": "作为...我希望...以便..." }
      ],
      "data_entities": [
        { "id": "E-001", "name": "实体名称", "key_fields": ["字段1", "字段2"] }
      ]
    }
  ]
}
```

### 步骤 1.5.2：非功能需求提取

从需求文档和 `constraints.json` 中提取非功能需求：

```json
{
  "non_functional_requirements": [
    {
      "id": "NFR-001",
      "type": "性能/可用性/安全/可维护性/可扩展性/合规",
      "requirement": "具体非功能需求描述",
      "source": "来源（需求文档/用户约束/行业标准）"
    }
  ]
}
```

### 步骤 1.5.3：额外约束发现

从需求文档中发现 `constraints.json` 未覆盖的隐含约束：

```json
{
  "constraints_from_requirement": [
    {
      "id": "CR-001",
      "type": "技术约束/业务约束/合规约束",
      "description": "描述",
      "source": "需求文档中的出处"
    }
  ]
}
```

### 步骤 1.5.4：输出需求分解文件

将以上三部分合并，写入 `.arch-agent/projects/{项目名}/requirement-decomposition.json`。

---

## Phase 2：分层生成

目标：通过分层调度 Agent，逐层构建架构设计方案。

---

### Layer 1：结构设计 — 调度 arch-structure Agent

使用 `SendMessage` 向 **arch-structure** Agent 发送以下指令：

> **输入**：
> - 需求分解：`requirement-decomposition.json` 中的 `functional_domains`
> - 约束条件：`constraints.json`
> - 技术简报：`tech-brief.md`
>
> **指令**：
> "你是结构设计 Agent。请根据需求分解和约束条件，设计系统的整体结构。
>
> 需要输出：
> 1. 系统部署形态（单体/微服务/模块化单体等）
> 2. 模块划分及职责定义
> 3. 模块间依赖关系
> 4. 核心技术方向选型
>
> **重要约束：团队规模 {team_size}，上线时间 {timeline}，预算 {budget}。**
> **设计复杂度必须匹配约束。每个决策注明'如果不做这个，会怎样？'**
>
> 按照 arch-agent-protocol.md 中定义的设计方案输出格式返回。
>
> 需求分解（功能域）：
> {functional_domains}
>
> 约束条件：
> {constraints.json 内容}
>
> 技术简报：
> {tech-brief.md 内容}"
>
> **输出处理**：将 arch-structure 返回的方案保存到黑板。

### Layer 1 完成后 — 方向确认

向用户展示关键决策摘要：

```
结构设计完成，请确认方向

部署形态：{部署形态}
模块清单：
  - {模块1}：{职责}
  - {模块2}：{职责}
  - ...

核心技术方向：{技术选型摘要}
预估成本：{基于约束的成本估算}

是否同意此方向继续深入设计？
  Y — 继续
  N — 调整（请说明调整方向）
```

等待用户确认：
- Y -> 继续 Layer 2
- N + 调整说明 -> 将调整说明附在 arch-structure 指令中重新生成

---

### Layer 2：平台设计 — 调度 arch-platform Agent

使用 `SendMessage` 向 **arch-platform** Agent 发送以下指令：

> **输入**：
> - arch-structure 输出（结构设计方案）
> - 约束条件：`constraints.json`
> - 技术简报：`tech-brief.md`
> - NFR 列表：`requirement-decomposition.json` 中的 `non_functional_requirements`
>
> **指令**：
> "你是平台设计 Agent。请基于结构设计方案，设计系统的运行平台。
>
> 需要输出：
> 1. 基础设施方案（云服务/自建/混合）
> 2. 中间件选型（消息队列、缓存、搜索等）
> 3. 部署架构（容器化/虚拟机/Serverless）
> 4. 监控告警方案
> 5. CI/CD 流水线设计
>
> **重要约束：团队规模 {team_size}，上线时间 {timeline}，预算 {budget}。**
> **设计复杂度必须匹配约束。每个决策注明'如果不做这个，会怎样？'**
>
> 按照 arch-agent-protocol.md 中定义的设计方案输出格式返回。
>
> 结构设计方案：
> {arch-structure 输出}
>
> 约束条件：
> {constraints.json 内容}
>
> 技术简报：
> {tech-brief.md 内容}
>
> 非功能需求：
> {non_functional_requirements}"
>
> **输出处理**：将 arch-platform 返回的方案保存到黑板。

---

### Layer 3：接口设计 + 存储设计（并行）

Layer 3 的两个 Agent 可以并行调度，互相不可见对方输出。

#### 3a：接口设计 — 调度 arch-interface Agent

使用 `SendMessage` 向 **arch-interface** Agent 发送以下指令：

> **输入**：
> - arch-structure 输出
> - arch-platform 输出
> - `requirement-decomposition.json` 中的 `user_stories`
> - `constraints.json`
>
> **指令**：
> "你是接口设计 Agent。请基于结构设计和平台设计，定义模块间和对外的接口。
>
> 需要输出：
> 1. API 设计（RESTful/gRPC/GraphQL 等）
> 2. 模块间通信协议
> 3. 外部系统集成接口
> 4. 认证授权方案
> 5. 接口版本策略
>
> 按照 arch-agent-protocol.md 中定义的设计方案输出格式返回。
>
> 结构设计方案：
> {arch-structure 输出}
>
> 平台设计方案：
> {arch-platform 输出}
>
> 用户故事：
> {user_stories}
>
> 约束条件：
> {constraints.json 内容}"

#### 3b：存储设计 — 调度 arch-storage Agent

使用 `SendMessage` 向 **arch-storage** Agent 发送以下指令：

> **输入**：
> - arch-structure 输出
> - arch-platform 输出
> - `requirement-decomposition.json` 中的 `data_entities`
> - `constraints.json`
>
> **指令**：
> "你是存储设计 Agent。请基于结构设计和平台设计，定义系统的数据存储方案。
>
> 需要输出：
> 1. 数据库选型及理由
> 2. 数据模型设计（核心表/集合）
> 3. 数据分区/分库策略
> 4. 缓存策略
> 5. 数据备份与恢复方案
> 6. 数据迁移策略
>
> 按照 arch-agent-protocol.md 中定义的设计方案输出格式返回。
>
> 结构设计方案：
> {arch-structure 输出}
>
> 平台设计方案：
> {arch-platform 输出}
>
> 数据实体：
> {data_entities}
>
> 约束条件：
> {constraints.json 内容}"

**注意**：arch-interface 和 arch-storage 互不可见对方输出，确保独立性。

---

### Layer 4：整合

Layer 4 分三个步骤串行执行。

#### 步骤 4.1：文档整合 — 调度 arch-writer Agent

使用 `SendMessage` 向 **arch-writer** Agent 发送以下指令：

> **输入**：Layer 1-3 所有 Agent 的输出。
>
> **指令**：
> "你是架构写手 Agent。请将所有层级的设计方案整合为架构文档 v1。
>
> 文档结构：
> 1. `overview.md` — 架构总览（部署形态、技术栈、系统边界图）
> 2. `modules/` — 各模块详细设计
> 3. `decisions/` — 架构决策记录（ADR）
>
> 整合规则：
> 1. 检查层级间的一致性（如 interface 引用的模块是否在 structure 中定义）
> 2. 发现冲突时，优先采用上层设计（structure > platform > interface/storage）
> 3. 记录整合过程中发现的冲突到 open_questions
>
> 各层级设计方案：
> {arch-structure 输出}
> {arch-platform 输出}
> {arch-interface 输出}
> {arch-storage 输出}"
>
> **输出处理**：
> 1. 将文档写入 `{output_dir}/` 目录
> 2. 保存快照到 `.arch-agent/projects/{项目名}/versions/v1/`

#### 步骤 4.2：覆盖验证 — 调度 arch-coverage Agent

使用 `SendMessage` 向 **arch-coverage** Agent 发送以下指令：

> **输入**：
> - `requirement-decomposition.json`
> - 架构文档 v1
>
> **指令**：
> "你是覆盖验证 Agent。请执行双向验证：
>
> 1. 正向验证：需求 → 架构
>    - 检查每个功能需求（R-xxx）是否在架构中有对应模块承接
>    - 检查每个非功能需求（NFR-xxx）是否有对应的技术方案
>    - 检查每个数据实体（E-xxx）是否在存储设计中有对应
>
> 2. 反向验证：架构 → 需求
>    - 检查每个架构模块是否有需求支撑（防止过度设计）
>    - 检查每个技术选型是否有需求或约束依据
>
> 输出覆盖率报告和未覆盖项列表。
>
> 需求分解：
> {requirement-decomposition.json 内容}
>
> 架构文档：
> {v1 文档内容}"
>
> **输出处理**：将覆盖报告保存到 `.arch-agent/projects/{项目名}/scores/coverage-v1.json`。

#### 步骤 4.3：基线评分 — 调度 arch-evaluator Agent

使用 `SendMessage` 向 **arch-evaluator** Agent 发送以下指令：

> **输入**：
> - 架构文档 v1
> - 覆盖报告
> - `constraints.json`
>
> **指令**：
> "你是架构评估 Agent。请对架构文档进行全面评估。
>
> 评分维度（每维度 0-10 分）：
> 1. 功能覆盖度 — 需求是否被完整承接
> 2. 非功能满足度 — NFR 是否有技术方案支撑
> 3. 模块内聚度 — 模块职责是否清晰单一
> 4. 接口清晰度 — 接口定义是否完整、一致
> 5. 存储合理性 — 数据模型与存储选型是否合理
> 6. 可演进性 — 架构是否支持未来变化
> 7. 约束匹配度 — 设计复杂度是否匹配团队和资源约束
> 8. 决策完备性 — 关键决策是否有记录、有理由、有替代方案
>
> 同时执行约束合规检查：
> - 技术选型是否符合团队技术偏好
> - 成本估算是否在预算范围内
> - 复杂度是否与团队规模匹配
> - 时间估算是否在上线要求内
>
> 判定成熟度阶段，并给出各维度的优化建议。
>
> 架构文档：
> {v1 文档内容}
>
> 覆盖报告：
> {coverage 报告内容}
>
> 约束条件：
> {constraints.json 内容}"
>
> **输出处理**：
> 1. 解析 8 维度评分、成熟度阶段、优化建议、约束合规结果
> 2. 保存到 `.arch-agent/projects/{项目名}/scores/round-0.json`：
> ```json
> {
>   "round": 0,
>   "phase": "baseline",
>   "version": "v1",
>   "scores": {
>     "functional_coverage": 0,
>     "nfr_satisfaction": 0,
>     "module_cohesion": 0,
>     "interface_clarity": 0,
>     "storage_rationality": 0,
>     "evolvability": 0,
>     "constraint_fitness": 0,
>     "decision_completeness": 0
>   },
>   "average": 0,
>   "maturity": "成熟度阶段",
>   "constraint_compliance": {
>     "tech_match": true,
>     "budget_match": true,
>     "team_match": true,
>     "timeline_match": true,
>     "violations": []
>   },
>   "suggestions": "评估建议原文"
> }
> ```

---

### 展示基线评分

向用户输出以下信息：

```
架构基线评分（Phase 2 完成）

| 维度 | 分数 | 达标线 | 状态 |
|------|------|--------|------|
| 功能覆盖度 | {分数} | {target_score} | {>=达标线 ? 达标 : 未达标} |
| 非功能满足度 | {分数} | {target_score} | {>=达标线 ? 达标 : 未达标} |
| 模块内聚度 | {分数} | {target_score} | {>=达标线 ? 达标 : 未达标} |
| 接口清晰度 | {分数} | {target_score} | {>=达标线 ? 达标 : 未达标} |
| 存储合理性 | {分数} | {target_score} | {>=达标线 ? 达标 : 未达标} |
| 可演进性 | {分数} | {target_score} | {>=达标线 ? 达标 : 未达标} |
| 约束匹配度 | {分数} | {target_score} | {>=达标线 ? 达标 : 未达标} |
| 决策完备性 | {分数} | {target_score} | {>=达标线 ? 达标 : 未达标} |

成熟度：{成熟度阶段}
平均分：{平均分}
最需改进：{最低分维度}

约束合规：
  - 技术匹配：{是/否}
  - 预算匹配：{是/否}
  - 团队匹配：{是/否}
  - 时间匹配：{是/否}
  {如有违规项，逐条列出}

继续进入挑战循环？(Y/N)
```

**等待用户回复**：
- Y -> 进入 Phase 3（挑战循环）
- N -> 跳到交付阶段
- 如果所有维度已经 >= 达标线 -> 向用户说明已达标，询问是否仍要继续优化

---

### 建立范围基线

从 v1 架构文档中提取范围信息，创建 `.arch-agent/projects/{项目名}/scope-baseline.json`：

```json
{
  "version": "v1",
  "module_count": 0,
  "modules": ["模块1", "模块2"],
  "interface_count": 0,
  "entity_count": 0,
  "decision_count": 0,
  "created_at": "{当前 ISO 时间戳}"
}
```

> 这个基线在后续挑战循环中用于检测范围蠕变——如果模块数量增长超过基线的 50%，需要向用户发出警告。

---

### 更新状态

更新 `state.json`：

```json
{
  "phase": "challenge_loop",
  "current_round": 1,
  "scores": {
    "functional_coverage": 0,
    "nfr_satisfaction": 0,
    "module_cohesion": 0,
    "interface_clarity": 0,
    "storage_rationality": 0,
    "evolvability": 0,
    "constraint_fitness": 0,
    "decision_completeness": 0
  },
  "updated_at": "{当前 ISO 时间戳}"
}
```

完成后进入 Phase 3（挑战循环，加载 `skills/arch-challenge.md`）。
