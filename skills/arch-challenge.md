<!-- 本文件是 EX-RequireAgent 架构编排器的子模块，由主命令 .claude/commands/arch.md 引用 -->
<!-- 不要直接运行本文件，它通过 Read 工具被加载 -->

# 阶段三：挑战循环

每一轮执行以下步骤。进入循环前，设置 `current_version` 为最新版本号。

---

## 步骤 3.1：选择目标

### 第一级：选择目标模块

从模块级评分中找最弱模块（复杂度加权）：
1. 计算每个模块的加权分数：`加权分 = 模块平均分 / 模块复杂度系数`
2. 选择加权分最低的模块作为目标模块

### 第二级：选择目标维度

在目标模块内找最低分维度。

**并列处理规则**：如果有多个维度分数相同且都是最低分，按以下优先级选择（排在前面的优先）：
1. 成本效率（cost_efficiency）
2. 灵活性（flexibility）
3. 可扩展性（scalability）
4. 可靠性（reliability）
5. 安全性（security）
6. 可维护性（maintainability）
7. 可观测性（observability）
8. 需求覆盖度（requirement_coverage）

**提前退出检查**：如果最低分 >= `target_score`，说明所有维度都已达标 -> 跳到阶段四（终审）。

**跳过已停滞维度**：如果最低分维度在 `stalled_dimensions` 列表中，选择下一个最低分维度（不在停滞列表中的）。如果所有未达标维度都在停滞列表中 -> 跳到阶段四（终审）。

向用户展示轮次进度：

```
挑战循环 — 第 {current_round}/{max_rounds} 轮

目标模块：{模块名}
目标维度：{维度名称}（当前 {分数} 分，达标线 {target_score} 分）
```

---

## 步骤 3.2：主动改进 — 调度主责 Agent

根据目标维度确定主责 Agent，按以下维度→Agent 映射表调度：

| 目标维度 | 主责 Agent | 辅助 Agent | 策略选择 |
|---------|-----------|-----------|---------|
| 可扩展性 | structure | storage | structure-A/B, storage-A/B/C |
| 灵活性 | structure | interface | structure-A/B, interface-A/B |
| 可维护性 | structure | platform | structure-A/B, platform-A |
| 可靠性 | structure | storage | structure-C, storage-C |
| 安全性 | interface | platform | interface-A, platform-A |
| 成本效率 | platform | structure | platform-C, structure-C |
| 可观测性 | platform | — | platform-A/B |
| 需求覆盖度 | coverage | — | — |

使用 `SendMessage` 向主责 Agent 发送以下指令：

> "你是 {Agent名}。evaluator 对 {维度} 打了 {分数} 分。请重新审视你的设计方案，主动寻找该维度的改进空间。
>
> 当前架构文档：
> {目标模块文档内容}
>
> 评分详情：
> {evaluator 对该维度的评分说明}"

**输出处理**：将主责 Agent 的改进方案存储为变量 `improvement_proposal`。

如果映射表中存在辅助 Agent，同时调度辅助 Agent 协同审视，输出合并到 `improvement_proposal`。

---

## 步骤 3.3：四视角全量挑战 — 调度 arch-challenger

使用 `SendMessage` 向 **arch-challenger** Agent 发送以下指令：

> **输入**：完整架构文档 + 评分结果 + ADR + 遗留挑战清单
>
> **指令**：
> "对架构文档中的每一个决策进行系统性挑战。从以下四个视角全面审视：
>
> 1. **最优解视角**：当前方案是否是最优选择？有没有更好的替代方案？
> 2. **灵活性视角**：当前方案是否过于僵化？未来需求变化时能否适应？
> 3. **落地现实视角**：当前方案在实际开发中是否可行？团队能否落地？
> 4. **需求对齐视角**：当前方案是否准确反映了需求意图？有没有偏离？
>
> 规则：
> - 已 resolved 的决策跳过（除非本轮被修改）
> - 优先复查遗留清单中的 unresolved/partial 项
> - 对每个挑战项标注严重程度：P0（致命）、P1（重要）、P2（一般）、P3（建议）
>
> 架构文档：
> {完整架构文档内容}
>
> 评分结果：
> {最新评分}
>
> ADR：
> {decisions/ 目录下所有 ADR 内容}
>
> 遗留挑战清单：
> {state.json 中 open_challenges 内容}"

**输出处理**：将 challenger 的挑战列表存储为变量 `challenge_list`。

---

## 步骤 3.4：分级追问

对 `challenge_list` 中的挑战项，按严重程度执行追问：

| 严重程度 | 最大追问轮次 | 特殊规则 |
|---------|------------|---------|
| P0（致命） | 3 轮 | 必须追问直到获得具体方案 |
| P1（重要） | 2 轮 | 必须追问直到获得具体方案 |
| P2（一般） | 1 轮 | 涉及资金/安全/隐私时升级为 P1 |
| P3（建议） | 0 轮（不追问） | evaluator 该维度 < 5 时升级为 P2 |

**追问终止条件**：
- **结案**：challenger 回复中包含具体方案 + 降级预案 + 已知代价 → 该挑战项结案
- **继续**：challenger 回复仍为空话（无具体方案、无可操作建议）→ 继续追问

**追问指令模板**：

> "你的挑战 '{挑战标题}' 缺少具体方案。请补充：
> 1. 具体的替代方案或修改建议
> 2. 如果采纳，降级预案是什么
> 3. 已知的代价和权衡"

---

## 步骤 3.5：回应 — 调度主责 Agent

对每个 P0/P1 挑战项（及升级后的 P2），调度主责 Agent 回应。

使用 `SendMessage` 向主责 Agent 发送以下指令：

> "以下是 challenger 对你负责的架构设计提出的挑战：
>
> {P0/P1 挑战项列表，含追问后的具体方案}
>
> 对每个挑战项，请选择：
> 1. **接受并修改**：输出修改方案，说明如何调整设计
> 2. **维持原决策**：输出充分理由，解释为何不采纳
>
> 当前设计方案：
> {主责 Agent 负责的模块文档}"

**输出处理**：
- 接受并修改的 → 存入 `accepted_changes`
- 维持原决策的 → 记入 ADR（decisions/ 目录），包含挑战内容、维持理由、权衡分析

---

## 步骤 3.6：级联检查

根据影响传播矩阵确定受影响 Agent：
1. 从 `accepted_changes` 中提取变更涉及的模块和接口
2. 按影响传播矩阵确定哪些其他 Agent 可能受影响
3. 逐一调度受影响 Agent 检查自身设计是否仍成立

使用 `SendMessage` 向受影响 Agent 发送以下指令：

> "架构中发生了以下变更：
> {变更全文}
>
> 请检查你负责的设计是否仍然成立，是否需要相应调整。
>
> 项目概览：
> {overview 内容}
>
> 你负责的模块：
> {该 Agent 负责的模块全文}"

**输出处理**：如果受影响 Agent 提出需要调整，将调整方案追加到 `accepted_changes`。

---

## 步骤 3.7：覆盖验证（按需）

仅当 evaluator 对"需求覆盖度"维度打分 < `target_score` 时调度 **arch-coverage** Agent。

使用 `SendMessage` 向 **arch-coverage** Agent 发送以下指令：

> "请对当前架构文档进行需求覆盖度验证。
>
> 检查每一条需求是否在架构中有对应的模块/组件覆盖。
> 检查架构中是否存在无需求支撑的多余设计。
>
> 需求文档：
> {需求文档内容}
>
> 架构文档：
> {完整架构文档}"

**输出处理**：将覆盖度验证结果存入 `coverage_result`，追加到 `accepted_changes`（如有调整建议）。

---

## 步骤 3.8：整合 — 调度 arch-writer

使用 `SendMessage` 向 **arch-writer** Agent 发送以下指令：

> "请整合以下所有修改方案，更新架构文档。
>
> 整合规则：
> 1. 更新 overview 文件
> 2. 更新 modules/ 下受影响的模块文件
> 3. 更新 decisions/ 下的 ADR（新增或修改）
> 4. 更新追溯矩阵
> 5. 生成版本快照
>
> 在变更记录中记录：版本 v{N+1}，轮次 第 {current_round} 轮，来源 {相关 Agent 列表}。
>
> 修改方案：
> {accepted_changes 全文}
>
> 当前 overview：
> {overview 内容}
>
> 当前模块文件：
> {逐个列出每个 module 文件名和内容}
>
> 当前 ADR：
> {decisions/ 目录内容}"

**输出处理**：
1. 将 writer 返回的文档覆盖写入对应文件
2. 保存快照到 `.arch-agent/projects/{项目名}/versions/v{N+1}/`
3. 更新 `current_version` 为 `v{N+1}`

---

## 步骤 3.9：评分 — 调度 arch-evaluator

使用 `SendMessage` 向 **arch-evaluator** Agent 发送以下指令：

> "请对以下架构文档进行全面评估。
>
> 评分维度（8 维度）：可扩展性、灵活性、可维护性、可靠性、安全性、成本效率、可观测性、需求覆盖度
>
> 评分层级：
> 1. **模块级评分**：对每个模块单独评分
> 2. **项目级评分**：对整体架构评分
>
> 额外检查：
> - 约束合规：检查架构是否满足所有技术约束和业务约束
>
> 严格按照评分标准输出。
>
> 架构概览：
> {overview 内容}
>
> 模块文件：
> {逐个列出每个 module 文件名和内容}
>
> ADR：
> {decisions/ 目录内容}"

**输出处理**：
1. 解析 8 维度 × 两层（模块级+项目级）的分数
2. 保存到 `.arch-agent/projects/{项目名}/scores/round-{current_round}.json`

---

## 步骤 3.9.1：跨模块架构一致性检查（每 2 轮）

当 `current_round % 2 == 0` 时，调度 **arch-evaluator** 做专项一致性检查：

使用 `SendMessage` 向 **arch-evaluator** Agent 发送以下指令：

> "请对架构文档进行跨模块一致性专项检查。
>
> 检查维度：
> 1. **API 风格统一性**：各模块的 API 设计风格是否一致（RESTful/GraphQL/gRPC 混用情况）
> 2. **认证方案统一性**：各模块的认证鉴权方案是否统一
> 3. **错误码规范统一性**：各模块的错误码格式和分类是否统一
> 4. **数据格式统一性**：各模块的数据序列化格式、时间格式、分页格式是否统一
> 5. **命名约定统一性**：各模块的命名约定（字段名、接口名、事件名）是否统一
>
> 架构概览：
> {overview 内容}
>
> 模块文件：
> {逐个列出每个 module 文件名和内容}"

**输出处理**：如发现一致性问题 -> 在下一轮优先处理。

---

## 步骤 3.10：决策 — 保留或回滚

比较目标维度的新旧分数：

**分数上升（新分 > 旧分）**：
- 保留新版本，不做回滚
- 向用户展示：`{维度名}：{旧分} -> {新分}（提升）`
- 清除该维度的连续无提升计数
- 记录策略有效性：标记本轮使用的策略为 effective

**分数未变或下降（新分 <= 旧分）**：
- 回滚到上一版本：将上一版本快照复制回对应文件
- 删除本轮新增的版本快照
- 向用户展示：`{维度名}：无提升（{旧分} -> {新分}），已回滚到上一版本`
- 将评分记录中的 scores 恢复为上一轮的分数
- 增加该维度的连续无提升计数
- 记录策略有效性：标记本轮使用的策略为 ineffective

---

## 步骤 3.11：终止检查

按以下顺序检查是否终止循环：

**检查 1 — 全部达标**：
- 条件：所有 8 个维度的项目级分数 >= `target_score`
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

**检查 5 — 连续无高优挑战**：
- 条件：连续 2 轮 challenger 未产生任何 P0/P1 挑战项
- 动作：向用户展示 `架构设计已趋于稳定，进入终审...`，跳到阶段四

**如果未触发任何终止条件**：继续下一轮。

---

## 步骤 3.12：更新状态

更新 `state.json`：

```json
{
  "current_round": "{current_round + 1}",
  "scores": "{最新有效分数（8 维度 × 模块级+项目级）}",
  "stalled_dimensions": "{停滞维度列表}",
  "round_history": [
    "...之前的记录",
    {
      "round": "{current_round}",
      "target_module": "{目标模块}",
      "target_dimension": "{目标维度}",
      "action": "improved / stalled / rolled_back",
      "score_change": "{旧分} -> {新分}",
      "version": "v{版本号}",
      "challenges_count": "{P0/P1/P2/P3 各数量}",
      "accepted_changes_count": "{被接受的变更数}"
    }
  ],
  "challenge_coverage": "{已被挑战过的决策占比}",
  "open_challenges": "{未完全解决的挑战项列表}",
  "updated_at": "{当前 ISO 时间戳}"
}
```

**覆盖矩阵更新**：被修改的决策在覆盖矩阵中重置为 `unchallenged`，确保下一轮 challenger 重新审视。

**策略有效性记录**：将本轮结果追加到 `evolution/arch-strategies/effectiveness.json`。

回到步骤 3.1，开始下一轮。
