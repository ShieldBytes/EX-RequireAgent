<!-- 本文件是 EX-RequireAgent 架构编排器的子模块，由主命令 .claude/commands/arch.md 引用 -->
<!-- 不要直接运行本文件，它通过 Read 工具被加载 -->

# Agent 协作协议

本模块定义架构 Agent 之间的统一协作规范，包括输出格式、黑板规则、上下文传递、检查清单、行为自适应和级联影响传播机制。

---

## 一、三种输出格式定义

所有 Agent 返回结果时，编排器应期望并解析以下三种 JSON 标准结构之一。

### 1. 设计方案输出（Phase 2 生成阶段）

```json
{
  "agent": "{agent名}",
  "type": "design",
  "decisions": [
    {
      "id": "D-001",
      "topic": "决策主题",
      "decision": "选择的方案",
      "rationale": "选择理由",
      "alternatives": [
        { "option": "备选方案A", "pros": "优点", "cons": "缺点", "rejected_reason": "放弃原因" }
      ],
      "requirement_refs": ["R-001", "NFR-002"],
      "impact_if_not_done": "如果不做这个决策，会怎样"
    }
  ],
  "artifacts": {
    "diagrams": "mermaid 代码（架构图、部署图、序列图等）",
    "tables": [
      { "title": "表格标题", "headers": ["列1", "列2"], "rows": [["值1", "值2"]] }
    ],
    "api_specs": [
      { "method": "POST", "path": "/api/v1/xxx", "description": "接口描述", "request": {}, "response": {} }
    ]
  },
  "open_questions": [
    { "id": "Q-001", "question": "待确认的问题", "context": "背景", "suggested_answer": "建议答案" }
  ]
}
```

**解析规则**：
- 必须解析的字段：decisions（含 id、decision、rationale、requirement_refs）
- 每个 decision 必须包含 `requirement_refs` 关联到具体需求 ID
- `impact_if_not_done` 字段体现减法意识，帮助避免过度设计
- 可选字段：artifacts、open_questions

### 2. 改进发现输出（Phase 3 主动深挖）

```json
{
  "agent": "{agent名}",
  "type": "findings",
  "findings": [
    {
      "id": "F-001",
      "priority": "P0 / P1 / P2 / P3",
      "dimension": "维度名（功能覆盖度/非功能满足度/模块内聚度/接口清晰度/存储合理性/可演进性/约束匹配度/决策完备性）",
      "title": "发现标题",
      "description": "问题详细描述",
      "suggestion": "具体改进建议",
      "evidence": "依据或引用的文档位置",
      "confidence": "高 / 中 / 低"
    }
  ],
  "summary": "一句话总结本次发现",
  "metadata": {
    "strategy_used": "使用的策略名",
    "duration_hint": "预估消耗描述",
    "new_findings_count": 0,
    "repeated_findings_count": 0
  }
}
```

**解析规则**：
- 必须解析的字段：findings（含 priority 和 suggestion）
- findings 中的 suggestion 必须是可操作的具体方案
- 可选字段：metadata、confidence

### 3. 挑战回应输出（Phase 3 回应挑战）

```json
{
  "agent": "{agent名}",
  "type": "response",
  "responses": [
    {
      "challenge_id": "C-001",
      "action": "accept / maintain",
      "changes": "接受挑战时的具体修改内容",
      "rationale": "接受或维持的理由",
      "adr_needed": true
    }
  ]
}
```

**解析规则**：
- `action` 只能是 `accept`（接受挑战并修改）或 `maintain`（维持原设计）
- `accept` 时 `changes` 不能为空，必须说明具体修改内容
- `maintain` 时 `rationale` 不能为空，必须给出充分理由
- `adr_needed` 为 true 时，需要在 decisions/ 中新增或更新 ADR 记录

---

## 二、黑板分阶段读写规则

黑板（Blackboard）指 `.arch-agent/projects/{项目名}/` 下的所有共享数据文件。

### Phase 2：分层生成阶段

| 阶段 | Agent | 可读 | 可写 |
|------|-------|------|------|
| Layer 1 | arch-structure | 需求分解 + 约束条件 + 技术简报 | 结构设计方案 |
| Layer 2 | arch-platform | 上述全部 + arch-structure 输出 | 平台设计方案 |
| Layer 3 | arch-interface | 上述全部 + arch-platform 输出 | 接口设计方案 |
| Layer 3 | arch-storage | 上述全部 + arch-platform 输出 | 存储设计方案 |
| Layer 3 | arch-interface ↔ arch-storage | **互不可见** | — |
| Layer 4 | arch-writer | 全部层级输出 | 架构文档 v1 |
| Layer 4 | arch-coverage | 需求分解 + 架构文档 v1 | 覆盖报告 |
| Layer 4 | arch-evaluator | 架构文档 v1 + 覆盖报告 + 约束条件 | 评分结果 |

**关键原则**：Layer 3 中 arch-interface 和 arch-storage 互不可见对方输出，确保独立性。

### Phase 3：挑战循环阶段

| 步骤 | Agent | 可读 | 可写 |
|------|-------|------|------|
| 评分 | arch-evaluator | 完整架构文档（只读） | 评分结果 |
| 主动改进 | 主责 Agent | overview + 目标模块 + 评分反馈 | 改进发现（findings） |
| 挑战 | arch-challenger | 完整架构文档 + 评分 + ADR | 挑战项（challenges） |
| 回应 | 主责 Agent | 挑战项 + overview + 相关模块 | 回应（responses） |
| 级联 | 受影响 Agent | 变更全文 + overview + 自己的模块 | 确认/调整 |
| 覆盖 | arch-coverage | 需求分解 + 完整架构文档 | 覆盖报告 |
| 整合 | arch-writer | 全部 | 新版文档 |

---

## 三、上下文传递规则

### 默认规则：传全量

调度 Agent 时，将所有可读范围内的数据完整传递，不做裁剪。

### 降级规则：文档总量 > 30000 字时启用

当传递给 Agent 的上下文总字数超过 30000 字时，启用降级策略：

1. **目标模块**：传完整内容
2. **非目标模块**：仅传前 30 行摘要
3. **overview.md**：始终传完整内容
4. **约束条件**：始终传完整内容
5. **评分反馈**：仅传与目标维度相关的部分

降级时向 Agent 说明：
> "以下内容因篇幅限制已做摘要处理。如需查看某模块完整内容，请在 open_questions 中标注。"

---

## 四、Agent 预检清单

在调度每个 Agent 之前，编排器必须检查：

| 检查项 | 条件 | 不满足时动作 |
|--------|------|------------|
| 依赖满足 | 前置层级 Agent 已返回结果 | 等待或报错 |
| 信息具备 | 需要的输入数据（文档、设计方案等）已准备好 | 报错并记录 |
| 状态正常 | Agent 对应维度未在 stalled_dimensions 中 | 跳过该 Agent |
| Agent 已启用 | Agent 在 enabled_agents 中 | 跳过该 Agent |
| 非重复调度 | 本轮未对同一 Agent 发送过相同指令 | 跳过 |

---

## 五、Agent 后检清单

在收到 Agent 返回结果后，编排器必须验证：

| 检查项 | 验证规则 | 不合格时动作 |
|--------|---------|------------|
| 具体性 | decisions/findings 中的内容必须是可操作的（非"需要改进"这种泛泛之言） | 要求 Agent 重新生成 |
| 依据性 | decisions 中应引用需求 ID（R-xxx、NFR-xxx）或文档具体位置 | 标记为低置信度 |
| 可操作性 | suggestion/changes 必须能直接指导 arch-writer 修改文档 | 要求 Agent 细化 |
| 去重 | 检查与前轮 findings 的重复度 | 重复率 >50% 时标记疲劳 |
| 需求关联 | 每个 decision 是否标注了关联的需求 ID（requirement_refs） | 要求补充关联 |

**去重逻辑**：
- 比较当前 findings 的 title 和 description 与前轮是否高度相似
- 相似度判定：关键词重叠 >70% 视为重复
- 重复的 findings 不计入本轮有效发现

---

## 六、Agent 行为阶段自适应

不同阶段对 Agent 的行为期望不同：

| 阶段 | 行为模式 | Agent 应该做什么 | Agent 不应该做什么 |
|------|---------|----------------|------------------|
| 生成阶段（Phase 2） | 建设模式 | 输出完整设计方案，覆盖所有必要决策 | 过度设计，引入超出约束的复杂方案 |
| 主动改进（Phase 3） | 深挖模式 | 针对弱项维度深入分析，给出具体改进方案 | 大范围重构已有设计 |
| 回应挑战（Phase 3） | 精准模式 | 直接回应挑战点，给出具体方案或充分理由 | 回避问题或用泛泛之言搪塞 |
| 终审（Phase 4） | 终结模式 | 检查格式、一致性、术语统一等表面问题 | 提出新的架构变更建议 |

编排器在向 Agent 发送指令时，根据当前阶段追加行为提示：
- 生成阶段：追加 "请输出完整方案，注意约束匹配"
- 深挖阶段：追加 "请聚焦弱项，给出可落地的具体改进"
- 精准阶段：追加 "请直接回应挑战，给出具体修改或充分维持理由"
- 终结阶段：追加 "只检查表面问题，不要建议新增架构变更"

---

## 七、级联影响传播矩阵

当某一层级的设计发生变更时，需要检查是否影响其他层级：

```
             arch-structure  arch-platform  arch-interface  arch-storage
arch-structure       —           必须            必须           必须
arch-platform      可能           —             可能           可能
arch-interface    不影响        不影响             —            可能
arch-storage      不影响        不影响           可能             —
```

### 规则说明

1. **上游变更必须检查下游**：
   - arch-structure 变更 -> 必须通知 arch-platform、arch-interface、arch-storage 检查是否需要调整
   - arch-platform 变更 -> 必须通知 arch-interface、arch-storage 检查是否需要调整

2. **同层可能互相影响**：
   - arch-interface 变更 -> 检查是否影响 arch-storage（如接口的数据格式变化可能影响存储模型）
   - arch-storage 变更 -> 检查是否影响 arch-interface（如存储模型变化可能影响查询接口）

3. **下游不影响上游**：
   - arch-interface 或 arch-storage 的局部调整不应要求 arch-structure 或 arch-platform 重新设计
   - 如果下游发现上游设计存在根本性问题，应作为 finding 上报，由编排器决定是否回溯

### 级联处理流程

当某个 Agent 的回应（response）中 `action: "accept"` 且变更内容涉及其他层级时：

1. 查询传播矩阵，确定受影响的 Agent 列表
2. 向受影响 Agent 发送级联通知：
   > "上游/同层 Agent {agent名} 做出了以下变更：
   > {changes 内容}
   >
   > 请检查你负责的部分是否需要调整。
   > 如需调整，按挑战回应输出格式返回；如无影响，回复确认即可。"
3. 收集所有受影响 Agent 的回应
4. 如果级联产生了新的变更，递归检查是否触发进一步级联（最多递归 2 层，防止无限循环）
