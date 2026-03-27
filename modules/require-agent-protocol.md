<!-- 本文件是 EX-RequireAgent 编排器的子模块，由主命令 .claude/commands/require.md 引用 -->
<!-- 不要直接运行本文件，它通过 Read 工具被加载 -->

# Agent 协作协议

本模块定义 Agent 之间的统一协作规范，包括输出格式、黑板规则、问答规则、依赖链、检查清单和行为自适应机制。

---

## 一、Agent 统一输出格式定义

所有 Agent 返回结果时，编排器应期望并解析以下 JSON 标准结构：

```json
{
  "agent": "{agent名称}",
  "phase": "{当前阶段：breadth_scan / deep_optimization / final_review}",
  "round": {轮次编号},
  "findings": [
    {
      "id": "{agent名}-{序号}",
      "priority": "P0 / P1 / P2 / P3",
      "dimension": "{关联维度}",
      "title": "{问题/建议标题}",
      "description": "{详细描述}",
      "suggestion": "{具体改进建议}",
      "evidence": "{依据或引用的文档位置}",
      "confidence": "高 / 中 / 低"
    }
  ],
  "summary": "{一句话总结本次发现}",
  "metadata": {
    "strategy_used": "{使用的策略名}",
    "duration_hint": "{预估消耗描述}",
    "new_findings_count": {新发现数量},
    "repeated_findings_count": {与前轮重复的发现数量}
  }
}
```

**解析规则**：
- 如果 Agent 返回的不是严格 JSON 格式，编排器从文本中提取关键信息
- 必须解析的字段：findings（含 priority 和 suggestion）
- 可选字段：metadata、confidence

---

## 二、黑板分阶段读写规则

黑板（Blackboard）指 `.require-agent/projects/{项目名}/` 下的所有共享数据文件。

| 阶段 | Agent 行为 | 规则说明 |
|------|-----------|---------|
| 阶段一（前置侦察） | 只写 | knowledge-engine 写入 domain-brief.md，其他 Agent 不参与 |
| 阶段二（广度扫描） | 各 Agent 只写自己的发现 | 写入 all_findings，不读取其他 Agent 的发现（避免锚定偏见） |
| 阶段二（红队） | 可读 | red-team 可读取 all_findings，以避免重复 |
| 阶段三（深度优化前） | 目标 Agent 只写 | 目标维度 Agent 独立分析，写入 optimization_findings |
| 阶段三（红队审查） | 可读+挑战 | red-team 读取 optimization_findings 并挑战 |
| 阶段三（写手整合） | 可读+整合 | writer 读取所有发现，整合进文档 |
| 阶段四（终审） | 只读+评分 | evaluator 只读最终文档，独立评分 |

**关键原则**：广度扫描阶段，维度 Agent 之间互不可见对方发现，确保独立性。

---

## 三、Agent 直接问答规则

当 Agent 在分析过程中遇到信息不足的情况：

1. **问答次数限制**：每轮每个 Agent 最多向用户提问 2 次
2. **问答深度限制**：追问深度最多 2 层（即一个问题最多追问一次）
3. **问答触发条件**：
   - 发现关键信息缺失，且无法从文档上下文推断
   - 发现重大歧义，两种理解导致完全不同的设计方向
4. **问答格式**：
   ```
   [{agent名}] 需要确认：
   {问题描述}

   背景：{为什么需要这个信息}
   建议选项：A) {选项A} B) {选项B}（如适用）
   ```
5. **超出限制时**：Agent 应基于最合理的假设继续，并在 findings 中标注 `[待确认]`

---

## 四、Agent 依赖链定义

Agent 按层级分组，同层可并行，跨层需等待上层完成：

| 层级 | Agent | 前置依赖 |
|------|-------|---------|
| 层级一（独立层） | knowledge-engine | 无 |
| 层级二（基础层） | completeness, consistency, user-journey, business-closure, feasibility | 层级一完成（如在线模式） |
| 层级二（基础层-按需） | security, performance, accessibility-i18n, data, dependency | 同上 |
| 层级三（挑战层） | red-team | 层级二全部完成 |
| 层级四（整合层） | writer, evaluator | 层级三完成 |

**并行调度规则**：
- 层级二的所有 Agent 可以并行调度（广度扫描阶段）
- 深度优化阶段只调度单个维度 Agent（串行）
- writer 和 evaluator 始终串行（先写后评）

---

## 五、Agent 预检清单

在调度每个 Agent 之前，编排器必须检查：

| 检查项 | 条件 | 不满足时动作 |
|--------|------|------------|
| 依赖满足 | 前置层级 Agent 已返回结果 | 等待或跳过 |
| 信息具备 | 需要的输入数据（文档、发现列表等）已准备好 | 报错并记录 |
| 状态正常 | Agent 对应维度未在 stalled_dimensions 中 | 跳过该 Agent |
| Agent 已启用 | Agent 在 enabled_agents 中 | 跳过该 Agent |
| 非重复调度 | 本轮未对同一 Agent 发送过相同指令 | 跳过 |

---

## 六、Agent 后检清单

在收到 Agent 返回结果后，编排器必须验证：

| 检查项 | 验证规则 | 不合格时动作 |
|--------|---------|------------|
| 具体性 | findings 中的 suggestion 必须是可操作的（非"需要改进"这种泛泛之言） | 要求 Agent 重新生成 |
| 依据性 | findings 中应引用文档具体位置或章节 | 标记为低置信度 |
| 可操作性 | suggestion 必须能直接指导 writer 修改文档 | 要求 Agent 细化 |
| 去重 | 检查与前轮 findings 的重复度 | 重复率 >50% 时标记疲劳 |

**去重逻辑**：
- 比较当前 findings 的 title 和 description 与前轮是否高度相似
- 相似度判定：关键词重叠 >70% 视为重复
- 重复的 findings 不计入本轮有效发现

---

## 七、Agent 行为阶段自适应

不同阶段对 Agent 的行为期望不同：

| 阶段 | 行为模式 | Agent 应该做什么 | Agent 不应该做什么 |
|------|---------|----------------|------------------|
| 广度扫描 | 探索模式 | 广泛发现问题，不放过任何线索 | 深入纠缠单一问题 |
| 深度优化前期（轮次 1-3） | 建设模式 | 提出结构性改进建议 | 提出锦上添花的微调 |
| 深度优化后期（轮次 4+） | 打磨模式 | 精准定位具体问题并给出精确修改 | 提出大范围重构建议 |
| 终审/收敛 | 终结模式 | 只检查格式、术语、引用等表面问题 | 提出新的功能建议 |

编排器在向 Agent 发送指令时，根据当前阶段追加行为提示：
- 广度阶段：追加 "请广泛探索，宁多勿漏"
- 建设阶段：追加 "请聚焦结构性问题，给出系统性改进建议"
- 打磨阶段：追加 "请精准定位，给出可直接应用的具体修改"
- 终结阶段：追加 "只检查表面问题，不要建议新增内容"

---

## 八、收敛信号放大

当多个 Agent 指向同一个问题时，标记为关键问题优先处理。

### Phase 2（广度扫描）触发规则

当 3 个或以上 Agent 在同一轮中指向同一个问题（findings 的 title 关键词重叠 >50%）：

1. 标记该问题为**关键问题**（Critical Issue）
2. 在 state.json 中记录：
   ```json
   {
     "critical_issues": [
       {
         "description": "{问题描述}",
         "reported_by": ["{agent1}", "{agent2}", "{agent3}"],
         "round": {轮次},
         "resolved": false
       }
     ]
   }
   ```
3. 在下一轮优化中，即使该问题不在最低分维度中，也优先处理
4. 向用户提示："多个 Agent 同时发现了同一问题：{问题描述}，已标记为关键问题优先处理"
5. 关键问题解决后标记 `resolved: true`

### Phase 3（深度优化）触发规则

**同轮触发**：当 2 个或以上 Agent 在同一轮中指向同一个问题即触发。
理由：Phase 3 每轮只有 1 个维度 Agent + red-team = 2 个 Agent，原来的"3 个以上"永远触发不了。

**跨轮次触发**：如果不同轮次的不同 Agent 累计指向同一个问题达到 3 个以上，也触发。
编排器在步骤 3.8 更新状态时，扫描最近 3 轮的所有 findings，检测跨轮次收敛信号。

标记为关键问题后的处理逻辑不变（记录 critical_issues、下轮优先处理、向用户提示）。

---

## 九、红队追问协议

当红队对 P0/P1 挑战发起追问时，编排器按以下协议执行多轮对话：

### 追问流程

**Step 1：将挑战传给目标维度 Agent**

使用 SendMessage 向目标维度 Agent 发送：
> "红队提出以下挑战，请回应：
>
> [{挑战严重程度}] {挑战内容}
>
> 你可以：
> a) 给出修改建议（具体到需求文档的哪个章节/功能点改什么内容）
> b) 说明为什么当前设计是合理的（给出充分理由和证据）
>
> 需求文档相关部分：
> {与挑战相关的文档段落}"

**Step 2：将维度 Agent 的回应传给红队**

使用 SendMessage 向 red-team Agent 发送：
> "目标维度 Agent 对你的挑战做出了以下回应：
>
> {维度 Agent 的回应内容}
>
> 请判断：
> a) 回应充分（具体方案 + 边界条件 + 异常处理都涵盖）→ 标记 resolved
> b) 回应部分解决（有方向但缺少关键细节）→ 标记 partial + 说明剩余疑点 + 追问
> c) 回应不充分（空话、回避、或引入新问题）→ 标记 unresolved + 具体指出不足 + 追问"

**Step 3：循环或终止**

- 如果红队标记 resolved → 追问结束，该挑战结案
- 如果红队标记 partial/unresolved 且未达最大追问轮数 → 回到 Step 1
- 如果达到最大追问轮数 → 以最后的状态（partial/unresolved）结案

### 追问深度上限

| 严重程度 | 最大追问轮数 | 升级条件 |
|---------|-----------|---------|
| P0-致命 | 3 轮 | — |
| P1-严重 | 2 轮 | — |
| P2-一般 | 1 轮 | 涉及资金/安全/隐私 → 升级为 2 轮 |
| P3-轻微 | 0 轮 | evaluator 该维度 < 5 → 升级为 1 轮 |

### 追问记录

所有追问对话记录附加到 redteam_review 中，格式：
```json
{
  "challenge_id": "RT-xxx",
  "followup_rounds": [
    {
      "round": 1,
      "agent_response": "{维度 Agent 回应}",
      "redteam_verdict": "partial",
      "remaining_concern": "{剩余疑点}"
    },
    {
      "round": 2,
      "agent_response": "{维度 Agent 回应}",
      "redteam_verdict": "resolved",
      "remaining_concern": null
    }
  ],
  "final_status": "resolved"
}
```

---

## 十、知识引擎联动协议

### 触发条件

在步骤 3.2 维度 Agent 产出 optimization_findings 后，编排器检查以下条件：

**显式触发**：findings 中包含 `"needs_research": true` 标注和 `"research_query": "搜索关键词"` 字段。

**隐式触发**：findings 的 description 或 suggestion 中包含以下关键词：
"不确定"、"需要验证"、"行业标准"、"竞品做法"、"最佳实践"、"是否可行"、"数据支撑"

### 联动流程

1. 编排器提取需要搜索的问题列表
2. 调度 knowledge-engine Agent：
   > "以下问题来自 {维度名} Agent 的分析，需要外部信息支撑：
   > {问题列表}
   > 请针对性搜索，输出每个问题的搜索结果，标注来源和可信度。"
3. 将搜索结果追加到 optimization_findings 中，标注来源为 knowledge-engine
4. 如果搜索结果与维度 Agent 的判断矛盾，标注 [待验证] 由红队仲裁

### Agent 端标注方式

维度 Agent 可以在 findings 的 JSON 中增加标注：
```json
{
  "id": "completeness-003",
  "priority": "P1",
  "title": "实时推送延迟要求不明确",
  "suggestion": "建议明确推送延迟 SLA",
  "needs_research": true,
  "research_query": "移动端推送服务延迟 行业标准 P95"
}
```

编排器检测到 needs_research=true → 自动触发知识引擎。
