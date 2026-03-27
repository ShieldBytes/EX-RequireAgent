<!-- 本文件是 EX-RequireAgent 编排器的子模块，由主命令 .claude/commands/require.md 引用 -->
<!-- 不要直接运行本文件，它通过 Read 工具被加载 -->

# 阶段三：深度优化循环

每一轮执行以下步骤。进入循环前，设置 `current_version` 为最新版本号（广度扫描后为 `v2`）。

---

## 步骤 3.1：选择目标维度

### 模块选择

如果 state.json 中 modular = true：

  **检查持续聚焦**：如果 `focus_module` 不为 null：
  1. 目标模块 = `focus_module`（跳过自动选择）
  2. 检查该模块是否所有维度已达标（>= `target_score`）：
     - 如果全部达标：自动清除 `focus_module`（设为 null），向用户展示：
       `聚焦模块「{模块名}」所有维度已达标，自动解除锁定，恢复全局优化。`
       然后回到自动模块选择逻辑
     - 如果未全部达标：继续优化该模块
  3. 在该模块内选择最低分维度

  **自动选择**：如果 `focus_module` 为 null：
  1. 先确定最低分模块（按模块级评分，功能点数加权）
  2. 再确定该模块最低分维度

  向用户展示：
  ```
  深度优化 — 第 {N}/{max} 轮
  目标模块：{模块名}{如果 focus_module 不为 null 则显示"（锁定聚焦）"}
  目标维度：{维度名}（当前 {分数} 分）
  ```
  后续步骤 3.2-3.7 只读取和修改目标模块文件

如果 modular = false：
  保持以下原逻辑不变。

从当前 `scores` 中找到分数最低的维度。

**并列处理规则**：如果有多个维度分数相同且都是最低分，按以下优先级选择（排在前面的优先）：
1. 完整性（completeness）
2. 用户旅程（user_journey）
3. 业务闭环（business_loop）
4. 一致性（consistency）
5. 可行性（feasibility）
6. 安全（security）— 仅在 enabled_agents 中包含时参与
7. 性能（performance）— 仅在 enabled_agents 中包含时参与
8. 无障碍与国际化（accessibility_i18n）— 仅在 enabled_agents 中包含时参与
9. 数据（data）— 仅在 enabled_agents 中包含时参与
10. 依赖与集成（dependency）— 仅在 enabled_agents 中包含时参与

**提前退出检查**：如果最低分 >= `target_score`，说明所有维度都已达标 -> 跳到阶段四（终审）。

**跳过已停滞维度**：如果最低分维度在 `stalled_dimensions` 列表中，选择下一个最低分维度（不在停滞列表中的）。如果所有未达标维度都在停滞列表中 -> 跳到阶段四（终审）。

### 耦合维度同时优化

当最低分的两个维度分差 <= 1 分且属于以下耦合维度对时，同时调度两个 Agent（步骤 3.2 中并行调度）：

| 耦合对 | 耦合原因 |
|--------|---------|
| 完整性 ↔ 用户旅程 | 功能缺失导致旅程断裂 |
| 完整性 ↔ 一致性 | 新增内容容易引入不一致 |
| 业务闭环 ↔ 可行性 | 商业模式和落地能力互相约束 |

如果触发耦合优化，向用户展示：
"检测到耦合维度：{维度A}（{分数A}）和 {维度B}（{分数B}），本轮同时优化"

### P2 清理轮

检查 state.json 中 open_challenges 的 P2 未解决数量：
- P2 未解决数 >= 5 → 向用户提示：
  "累积了 {N} 个中等优先级未解决问题，建议安排一轮专项清理。是否在本轮集中处理 P2 问题？(Y/N)"
- 用户选 Y → 本轮改为"P2 清理轮"：跳过维度选择，直接调度 writer 批量整合积压的 P2 建议
- P2 未解决数 >= 10 → 强制提醒："已积压 {N} 个中等问题，质量风险较高"

向用户展示轮次进度：

```
深度优化 — 第 {current_round}/{max_rounds} 轮

目标维度：{维度名称}（当前 {分数} 分，达标线 {target_score} 分）
```

---

## 步骤 3.2：优化 — 调度维度专属 Agent

根据步骤 3.1 选出的目标维度，调度对应的 Agent：

| 目标维度 | 调度 Agent | 使用策略 | 默认 |
|---------|-----------|---------|------|
| 完整性 | completeness | 策略 B：反向场景法 | 启用 |
| 一致性 | consistency | 策略 A：交叉比对法 | 启用 |
| 用户旅程 | user-journey | 策略 A：角色扮演法 | 启用 |
| 业务闭环 | business-closure | 策略 B：增长飞轮法 | 启用 |
| 可行性 | feasibility | 策略 B：风险矩阵法 | 启用 |
| 安全 | security | 攻击面分析法 | 按需 |
| 性能 | performance | 场景建模法 | 按需 |
| 无障碍与国际化 | accessibility-i18n | WCAG 对照法 | 按需 |
| 数据 | data | 数据流追踪法 | 按需 |
| 依赖与集成 | dependency | 故障预案法 | 按需 |

**重要**：只对已启用的 Agent 对应的维度进行优化。如果步骤 3.1 选出的最低分维度对应的 Agent 未在 `enabled_agents` 中，跳过该维度，选下一个最低分且 Agent 已启用的维度。

如果是耦合维度同时优化，并行调度两个维度 Agent，分别发送各自的指令，收集两份 `optimization_findings` 后合并。

使用 `SendMessage` 向对应 Agent 发送以下指令：

> "你是 {Agent名} Agent。请对以下需求文档进行深度检查。
>
> 使用 {策略名}，聚焦 {目标维度} 维度进行深度分析。这是深度优化阶段，请比广度扫描更深入、更具体。
>
> {如果 state.json 中 resume_instruction 不为 null}
> 用户补充说明：{resume_instruction}
> 请在优化建议中优先关注用户提出的问题。
> {/如果}
>
> 需求文档：
> {当前版本文档内容}"
>
> **输出处理**：
> 1. 将 Agent 的发现存储为变量 `optimization_findings`
> 2. 如果本轮使用了 `resume_instruction`，在本轮结束后将其从 `state.json` 中清除（设为 null）

### 知识引擎联动（如果 knowledge-engine 在 enabled_agents 中）

检查 optimization_findings 中是否有标注 `needs_research: true` 的发现项，或包含以下关键词："不确定"、"需要验证"、"行业标准"、"竞品做法"、"最佳实践"。

如果命中，调度 knowledge-engine Agent：
> "以下问题需要外部信息支撑，请针对性搜索：
> {触发搜索的发现项列表}
>
> 请输出每个问题的搜索结果，标注来源和可信度。"

将搜索结果追加到 optimization_findings 中，标注来源为 knowledge-engine。

---

## 步骤 3.3：红队挑战（增强版）

### 3.3a：准备挑战上下文

编排器准备传给红队的额外输入：
- open_challenges 中 status 为 unresolved/partial 的遗留挑战项
- 本轮被修改的功能点列表（对比上一版本快照）
- 覆盖矩阵 challenge_coverage 当前状态

### 3.3b：调度 red-team Agent

使用 `SendMessage` 向 **red-team** Agent 发送增强版指令：

> "你是红队 Agent。本轮优化目标是 {目标维度名称} 维度。
>
> **第一步：遗留复查**
> 以下挑战在上轮未彻底解决，请在最新文档中验证是否已改进：
> {open_challenges 中 unresolved/partial 项}
> 对每条遗留项判断：彻底解决→resolved / 表面修了→保持partial并说明缺什么 / 没改→保持unresolved
>
> **第二步：审查优化建议**
> {目标维度} Agent 的优化建议如下，请审查是否引入新问题：
> {optimization_findings}
> 1. 这些建议是否会引入新的漏洞或风险？
> 2. 这些建议是否偏离了产品的核心目的？
> 3. 这些建议中有没有不合理或过度设计的部分？
>
> **第三步：系统性审查**
> 从三个视角（恶意用户、刁钻甲方、需求质检员）对需求文档中与 {目标维度} 相关的功能点进行审查。
> 跳过覆盖矩阵中已 resolved 的功能点（除非本轮被修改）。
>
> **第四步：关联推理**
> 读取完整需求文档，寻找跨模块/跨功能点的业务逻辑矛盾。
> {如果模块化模式：传入 overview + 所有模块前 20 行摘要}
>
> 需求文档：
> {当前版本文档内容}"

输出处理：将 red-team 返回的完整审查结果存储为 `redteam_review`。

### 3.3c：追问处理

对 redteam_review 中的挑战项，按严重程度执行追问：

**P0 挑战处理（最多 3 轮追问）**：
1. 将 P0 挑战项发送给目标维度 Agent 回应
2. 将回应发送给 red-team 评估
3. red-team 判断：resolved / partial+继续追问 / unresolved+继续追问
4. 重复直到结案或达到 3 轮上限

**P1 挑战处理（最多 2 轮追问）**：同上流程，上限 2 轮

**P2 挑战处理（最多 1 轮追问）**：
- 默认 1 轮
- 涉及资金/安全/隐私关键词时升级为 2 轮

**P3 挑战处理**：不追问。evaluator 上轮对该维度打分 < 5 时升级为 1 轮。

追问结果合并到 redteam_review 中。

---

## 步骤 3.4：写手整合 — 调度 writer Agent

使用 `SendMessage` 向 **writer** Agent 发送以下指令：

> **输入**：将当前版本文档、`optimization_findings`、`redteam_review`、`intent-anchor.json` 附在消息中。
>
> **指令**：
> "你是写手 Agent。请将本轮优化建议整合进需求文档。本轮优化目标是**{目标维度名称}**维度。
>
> 整合规则：
> 1. 优先整合与目标维度直接相关的建议
> 2. 如果红队 Agent 否决了某条建议（指出会引入新风险），不要整合该建议
> 3. 参考意图锚点（附在下方），确保优化不偏离核心目的
> 4. 检查新增内容是否导致范围蠕变（功能点大幅增加），如果是，只保留最关键的补充
> 5. 如果评估 Agent 判定成熟度阶段发生跃迁，执行模板升级
> 6. 如果你决定不整合某条红队挑战，必须在输出中标注原因：
>    "不整合 {挑战ID}：{拒绝理由}"
>    被拒绝的挑战将进入遗留清单，状态为 deferred_by_writer
>
> 在变更记录中记录：版本 v{N+1}，轮次 第 {current_round} 轮，来源 {目标维度 Agent}, red-team, writer。
>
> 当前文档：
> {当前版本文档内容}
>
> 优化建议：
> {optimization_findings}
>
> 红队审查：
> {redteam_review}
>
> 意图锚点：
> {intent-anchor.json 内容}"
>
> **输出处理**：
> 1. 将 writer 返回的文档覆盖写入 `{output_dir}/requirement-overview.md`
> 2. 保存快照到 `.require-agent/projects/{项目名}/versions/v{N+1}.md`
> 3. 解析 writer 输出中的"不整合"标注，将对应挑战项在 open_challenges 中设为 deferred_by_writer
> 4. 检查：如果同一条挑战连续 2 轮被 writer 拒绝，但红队仍标记为 P0/P1 → 升级报告用户：
>    "红队与写手对以下问题存在分歧：
>     红队观点：{挑战内容}
>     写手观点：{拒绝理由}
>     请人工裁决。"
> 5. 更新 `current_version` 为 `v{N+1}`

---

## 步骤 3.4.1：整合验证

编排器自动检查 writer 整合质量：

1. **P0/P1 落实追踪**：
   对比 optimization_findings + redteam_review 中的 P0/P1 项，在新版文档中搜索对应修改。
   - 找到具体修改 → 通过
   - 未找到修改 → 标记"P0/P1 发现可能未落实：{发现摘要}"

2. **未落实处理**：
   如果有未落实的 P0 → 将该发现传回 writer 要求补充
   如果有未落实的 P1 → 标记警告，不强制返工

3. **无问题 → 正常进入步骤 3.5 评分**

---

## 步骤 3.5：评分 — 调度 evaluator Agent

使用 `SendMessage` 向 **evaluator** Agent 发送以下指令：

> **输入**：将新版本文档的完整内容附在消息中。
>
> **指令**：
> "你是评估 Agent。请对以下需求文档进行全面评估。
>
> 按照以下维度评分：完整性、一致性、可行性、用户旅程、业务闭环
> {如果 security 在 enabled_agents 中}，以及：安全
> {如果 performance 在 enabled_agents 中}，以及：性能
> {如果 accessibility-i18n 在 enabled_agents 中}，以及：无障碍与国际化
> {如果 data 在 enabled_agents 中}，以及：数据
> {如果 dependency 在 enabled_agents 中}，以及：依赖与集成
>
> 对每个启用的维度按 0-10 分评分。判定成熟度阶段，并给出优化建议。
>
> 以下是本轮的 P0/P1 问题，请在评分时特别验证这些问题是否已在文档中解决：
> {本轮 P0/P1 挑战清单}
>
> 请在评分输出中增加"问题验证"部分：
> | 上轮问题 | 是否解决 | 当前状态 |
> |---------|---------|---------|
>
> 严格按照你定义的输出格式输出。
>
> 需求文档：
> {新版本文档内容}"
>
> **输出处理**：
> 1. 解析所有启用维度的分数
> 2. 保存到 `.require-agent/projects/{项目名}/scores/round-{current_round}.json`：
> ```json
> {
>   "round": {current_round},
>   "phase": "deep_optimization",
>   "target_dimension": "{目标维度英文名}",
>   "version": "v{N+1}",
>   "scores": {
>     "completeness": <分数>,
>     "consistency": <分数>,
>     "feasibility": <分数>,
>     "user_journey": <分数>,
>     "business_loop": <分数>
>   },
>   "average": <所有启用维度的平均分>,
>   "maturity": "<成熟度阶段>",
>   "previous_target_score": <目标维度上一轮分数>,
>   "current_target_score": <目标维度本轮分数>
> }
> ```
> 注意：scores 中按需维度仅在对应 Agent 已启用时包含。
> 3. 解析 evaluator 的问题验证结果，更新 open_challenges 状态

---

## 步骤 3.6：决策 — 保留或回滚

比较目标维度的新旧分数：

**分数上升（新分 > 旧分）**：
- 保留新版本，不做回滚
- 向用户展示：`{维度名}：{旧分} -> {新分}（提升）`
- 清除该维度的连续无提升计数

**分数未变或下降（新分 <= 旧分）**：
- 回滚到上一版本：将上一版本快照复制回 `{output_dir}/requirement-overview.md`
- 删除本轮新增的版本快照文件
- 向用户展示：`{维度名}：无提升（{旧分} -> {新分}），已回滚到上一版本`
- 将评分记录中的 scores 恢复为上一轮的分数
- 增加该维度的连续无提升计数

---

## 步骤 3.7：终止检查

按以下顺序检查是否终止循环：

**检查 1 — 全部达标**：
- 条件：所有已启用维度（包括按需维度）的当前分数 >= `target_score`
- 动作：向用户展示 `所有维度已达标！进入终审...`，跳到阶段四

**检查 2 — 轮次耗尽**：
- 条件：`current_round` >= `max_rounds`
- 动作：向用户展示 `已达最大轮次（{max_rounds}），进入终审...`，跳到阶段四

**检查 3 — 单维度停滞**：
- 条件：某维度连续 2 轮作为目标维度但分数未提升
- 动作：将该维度加入 `stalled_dimensions` 列表，向用户展示 `{维度名} 已达当前优化上限（{分数} 分），后续轮次将跳过`

**检查 4 — 全面停滞**：
- 条件：所有未达标维度都在 `stalled_dimensions` 列表中
- 动作：向用户展示 `所有可优化维度均已停滞，进入终审...`，跳到阶段四

**如果未触发任何终止条件**：继续下一轮。

---

## 步骤 3.7.1：跨模块一致性检查（仅模块化模式）

### 增量检查（每轮执行）

如果 modular = true 且本轮修改了某个模块文件：
  调度 consistency Agent，只检查被修改模块与其直接依赖模块的一致性：
  "请检查以下模块之间的一致性：
  被修改模块：{模块名} - {完整内容}
  相关模块：{依赖模块名} - {前 20 行摘要}
  检查：术语统一、业务规则不矛盾、依赖关系准确、数据定义一致。"

### 全量检查（每 3 轮执行）

如果 modular = true 且 current_round % 3 == 0：
  调度 consistency Agent 做全量跨模块检查：

  "请对以下模块化文档进行跨模块一致性检查。

  概览文档：
  {requirement-overview.md 内容}

  各模块摘要（每个模块前 20 行）：
  {各模块前 20 行}

  检查：模块间术语统一、业务规则不矛盾、依赖关系准确。"

如发现问题 -> 在下一轮优先处理。

---

## 步骤 3.8：更新状态

更新 `state.json`：

```json
{
  "current_round": {current_round + 1},
  "scores": {最新有效分数},
  "stalled_dimensions": {停滞维度列表},
  "round_history": [
    ...之前的记录,
    {
      "round": {current_round},
      "target_dimension": "{目标维度}",
      "action": "improved / stalled / rolled_back",
      "score_change": "{旧分} -> {新分}",
      "version": "v{版本号}"
    }
  ],
  "updated_at": "{当前 ISO 时间戳}"
}
```

更新 open_challenges：
- 红队标记为 resolved 的 → 移出
- 标记为 partial/unresolved/deferred/deferred_by_writer 的 → 保留，rounds_open +1

更新 challenge_coverage：
- 本轮红队审查了的功能点×视角 → 更新对应状态
- 本轮被修改的功能点 → 该功能点所有视角重置为 unchallenged

升级报告检查：
- P0 连续 2 轮 unresolved 且 escalated=false → escalated=true，向用户报告
- P1 连续 3 轮 unresolved 且 escalated=false → escalated=true，向用户报告

**策略有效性记录**：调用 `modules/require-evolution.md` 中的"策略有效性记录"部分，将本轮结果追加到 `evolution/strategies/effectiveness.json`。

回到步骤 3.1，开始下一轮。
