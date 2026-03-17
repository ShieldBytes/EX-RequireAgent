<!-- 本文件是 EX-RequireAgent 编排器的子模块，由主命令 .claude/commands/require.md 引用 -->
<!-- 不要直接运行本文件，它通过 Read 工具被加载 -->

# 阶段三：深度优化循环

每一轮执行以下步骤。进入循环前，设置 `current_version` 为最新版本号（广度扫描后为 `v2`）。

---

## 步骤 3.1：选择目标维度

如果 state.json 中 modular = true：
  1. 先确定最低分模块（按模块级评分，功能点数加权）
  2. 再确定该模块最低分维度
  3. 向用户展示：
     "深度优化 — 第 {N}/{max} 轮
      目标模块：{模块名}
      目标维度：{维度名}（当前 {分数} 分）"
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

使用 `SendMessage` 向对应 Agent 发送以下指令：

> "你是 {Agent名} Agent。请对以下需求文档进行深度检查。
>
> 使用 {策略名}，聚焦 {目标维度} 维度进行深度分析。这是深度优化阶段，请比广度扫描更深入、更具体。
>
> 需求文档：
> {当前版本文档内容}"
>
> **输出处理**：将 Agent 的发现存储为变量 `optimization_findings`。

---

## 步骤 3.3：红队挑战 — 调度 red-team Agent

使用 `SendMessage` 向 **red-team** Agent 发送以下指令：

> **输入**：将当前版本文档内容和 `optimization_findings` 附在消息中。
>
> **指令**：
> "你是红队 Agent。本轮优化目标是**{目标维度名称}**维度。{目标维度} Agent 已针对此维度给出了优化建议（附在下方）。
>
> 请审查这些优化建议：
> 1. 这些建议是否会引入新的漏洞或风险？
> 2. 这些建议是否偏离了产品的核心目的？
> 3. 这些建议中有没有不合理或过度设计的部分？
>
> 同时，从你的对抗视角检查需求文档中与{目标维度名称}相关的问题，补充维度 Agent 遗漏的挑战点。
>
> 需求文档：
> {当前版本文档内容}
>
> 维度 Agent 的优化建议：
> {optimization_findings}"
>
> **输出处理**：将 red-team Agent 的挑战列表存储为变量 `redteam_review`。

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
> 3. 更新 `current_version` 为 `v{N+1}`

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

## 步骤 3.7.1：跨模块一致性检查（仅模块化模式，每 3 轮一次）

如果 modular = true 且 current_round % 3 == 0：

调度 consistency Agent：
"请对以下模块化文档进行跨模块一致性检查。

概览文档：
{requirement-overview.md 内容}

各模块摘要（每个模块前 20 行）：
{各模块前 20 行}

检查：模块间术语统一、业务规则不矛盾、依赖关系准确。"

如发现问题 -> 在下一轮优先处理

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

**策略有效性记录**：调用 `skills/require-evolution.md` 中的"策略有效性记录"部分，将本轮结果追加到 `evolution/strategies/effectiveness.json`。

回到步骤 3.1，开始下一轮。
