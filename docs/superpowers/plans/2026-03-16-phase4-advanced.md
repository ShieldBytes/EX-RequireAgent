# EX-RequireAgent 阶段四：进化系统 + 模块化文档 + 团队协作 + 高级功能

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现跨项目进化系统、大文档模块化拆分、多人协作机制和高级用户体验功能，使插件从"能用"升级到"好用"。

**前置条件：** 阶段三已完成，test-require-agent 目录下已有 14 个 Agent + 按需启用机制 + 编排 Skill。

**工作目录：** `/Library/MonkCoding/git_Project/test-require-agent/`

---

## 子阶段总览（40 个原子任务，分 4 个 Part）

```
Part A：进化系统（12 个任务）
  4.1  创建进化日志写入模板（项目结束时记录什么）
  4.2  编排 Skill：阶段五交付后追加进化日志写入逻辑
  4.3  验证进化日志写入
  4.4  创建策略有效性记录机制（每轮策略结果写入）
  4.5  编排 Skill：步骤 3.8 追加策略有效性记录
  4.6  验证策略有效性记录
  4.7  创建评分校准历史机制（人工校准时记录）
  4.8  编排 Skill：人工校准点追加校准记录
  4.9  验证评分校准记录
  4.10 创建跨项目经验加载逻辑（启动时读取历史经验）
  4.11 编排 Skill：阶段零追加经验加载
  4.12 端到端验证进化系统

Part B：模块化文档（10 个任务）
  4.13 创建模块化拆分逻辑定义
  4.14 编排 Skill：广度扫描后追加自动拆分检测
  4.15 创建 requirement-overview.md 模块化模板
  4.16 编排 Skill：写手调度指令适配模块化
  4.17 编排 Skill：评分适配模块级评分
  4.18 编排 Skill：深度优化适配模块级优化
  4.19 创建跨模块一致性检查逻辑
  4.20 编排 Skill：新增模块管理命令（lock/unlock/split）
  4.21 验证模块化拆分流程
  4.22 端到端验证模块化文档

Part C：团队协作（8 个任务）
  4.23 创建锁机制定义（lock.json 格式和规则）
  4.24 编排 Skill：启动时加入锁检测和获取
  4.25 编排 Skill：结束时释放锁
  4.26 创建团队输入模板（team-input/ 结构）
  4.27 编排 Skill：新增 --collab 协作模式
  4.28 编排 Skill：新增 --review 评审模式
  4.29 编排 Skill：新增 --resume --role 接力模式
  4.30 端到端验证团队协作

Part D：高级功能（10 个任务）
  4.31 编排 Skill：新增 /require:help 帮助输出
  4.32 编排 Skill：新增版本标签（/require:tag）
  4.33 编排 Skill：新增版本对比（/require:diff）
  4.34 编排 Skill：新增预览模式（/require:preview）
  4.35 编排 Skill：新增增量需求注入（/require:add）
  4.36 编排 Skill：新增离线模式（--offline）
  4.37 编排 Skill：新增项目管理命令（list/archive/clean/stats）
  4.38 编排 Skill：新增用户满意度反馈（交付后评分）
  4.39 创建首次引导流程
  4.40 端到端验证高级功能

---

## Part A：进化系统

---

### Chunk 1: 进化日志（子阶段 4.1 - 4.3）

#### Task 1: 创建进化日志写入模板

**Files:**
- Create: `evolution/templates/project-log-template.md`

**目的：** 每个项目结束后，按此模板记录一份进化日志，供后续项目参考。

```markdown
# 项目进化日志：{项目名}

## 基本信息
- 项目名：{项目名}
- 创建时间：{created_at}
- 完成时间：{completed_at}
- 总轮次：{total_rounds}
- 达标线：{target_score}
- 启用 Agent：{enabled_agents 列表}

## 评分变化
| 维度 | 初始分 | 最终分 | 提升 |
|------|--------|--------|------|
{每个启用维度一行}

## 策略有效性
| 轮次 | 目标维度 | 使用策略 | 结果 | 分数变化 |
|------|---------|---------|------|---------|
{每轮一行}

## 最有效策略 TOP3
1. {策略名} — {维度} +{提升分数}
2. {策略名} — {维度} +{提升分数}
3. {策略名} — {维度} +{提升分数}

## 无效策略
{列出所有结果为"回滚"或"停滞"的策略}

## 用户满意度
- 评分：{1-10}
- 反馈：{用户反馈内容}

## 经验标签
- 项目类型：{工具类/平台类/电商/社交/...}
- 关键词：{从意图锚点提取}
```

- [ ] **Step 1: 创建 evolution/templates/ 目录和模板文件**
- [ ] **Step 2: Commit**

#### Task 2: 编排 Skill 追加进化日志写入

**Files:**
- Modify: `.claude/commands/require.md`（阶段五交付章节）

在步骤 5.4（展示最终交付）之后，新增步骤 5.5：

```markdown
### 步骤 5.5：写入进化日志

读取 `evolution/templates/project-log-template.md` 模板，用当前项目数据填充：

数据来源：
- 基本信息 → state.json
- 评分变化 → scores/ 目录下 round-0.json（初始）和 final.json（最终）
- 策略有效性 → state.json 的 round_history
- 最有效策略 → 从 round_history 中筛选 action=improved，按分数提升排序取 TOP3
- 无效策略 → round_history 中 action=rolled_back 或 stalled 的记录
- 用户满意度 → 步骤 5.6 收集（见 Task 38）
- 经验标签 → intent-anchor.json

保存到 `evolution/projects/{项目名}-{日期}.md`

如果 evolution/projects/ 目录不存在，创建它。
```

- [ ] **Step 1: 在阶段五追加步骤 5.5**
- [ ] **Step 2: Commit**

#### Task 3: 验证进化日志写入

- [ ] **Step 1: 确认模板文件存在且占位符清晰**
- [ ] **Step 2: 确认编排 Skill 中数据来源映射正确**
- [ ] **Step 3: 确认保存路径正确**

---

### Chunk 2: 策略有效性记录（子阶段 4.4 - 4.6）

#### Task 4: 创建策略有效性记录机制

**Files:**
- Create: `evolution/templates/strategy-effectiveness.md`

**目的：** 汇总所有项目的策略使用记录，积累"什么策略在什么场景下有效"。

```markdown
# 策略有效性汇总

> 自动生成，每个项目结束后追加。越靠前的策略在更多项目中验证有效。

## {维度名}

### {策略名}
- 使用次数：{N}
- 成功次数：{M}（分数提升）
- 成功率：{M/N * 100}%
- 平均提升：{平均分数提升}
- 适用项目类型：{从成功案例中提取}
- 最近使用：{日期}

（按成功率排序）
```

- [ ] **Step 1: 创建模板文件**
- [ ] **Step 2: Commit**

#### Task 5: 编排 Skill 追加策略有效性记录

**Files:**
- Modify: `.claude/commands/require.md`（深度优化章节 步骤 3.8）

在步骤 3.8（更新状态）中追加：

```markdown
**策略有效性追加记录**：

将本轮策略使用结果追加到 `evolution/strategies/effectiveness.json`：

如果文件不存在，创建空 JSON 对象。

追加记录格式：
{
  "dimension": "{目标维度}",
  "strategy": "{使用的策略名}",
  "result": "improved / rolled_back / stalled",
  "score_change": {新分 - 旧分},
  "project": "{项目名}",
  "project_type": "{从意图锚点推断}",
  "date": "{当前日期}"
}
```

- [ ] **Step 1: 修改步骤 3.8**
- [ ] **Step 2: Commit**

#### Task 6: 验证策略有效性记录

- [ ] **Step 1: 确认 JSON 追加格式正确**
- [ ] **Step 2: 确认文件不存在时的创建逻辑**

---

### Chunk 3: 评分校准历史（子阶段 4.7 - 4.9）

#### Task 7: 创建评分校准历史机制

**Files:**
- Create: `evolution/calibration/README.md`

说明校准历史的格式和用途：当用户在人工校准点调整评分时，记录调整方向和原因，供后续项目参考。

校准记录格式（JSON，追加到 `evolution/calibration/history.json`）：
```json
{
  "project": "{项目名}",
  "round": "{轮次}",
  "dimension": "{维度}",
  "agent_score": "{Agent 给的分}",
  "user_adjusted": "{用户调整后的分}",
  "direction": "up / down",
  "reason": "{用户给的理由，如有}",
  "date": "{日期}"
}
```

- [ ] **Step 1: 创建 README**
- [ ] **Step 2: Commit**

#### Task 8: 编排 Skill 追加校准记录

**Files:**
- Modify: `.claude/commands/require.md`

在两个人工校准点（步骤 2.6 基线确认 + 步骤 4.3 终审确认）中：

当用户对评分提出调整时，追加记录到 `evolution/calibration/history.json`。

```markdown
如果用户对某个维度的评分提出异议（如"完整性应该更高/更低"）：
1. 记录原始评分和用户调整方向
2. 追加到 evolution/calibration/history.json
3. 在当前项目中按用户调整值继续
```

- [ ] **Step 1: 修改两个人工校准点**
- [ ] **Step 2: Commit**

#### Task 9: 验证评分校准记录

- [ ] **Step 1: 确认两个校准点都有记录逻辑**
- [ ] **Step 2: 确认 JSON 格式正确**

---

### Chunk 4: 跨项目经验加载 + 验证（子阶段 4.10 - 4.12）

#### Task 10: 创建跨项目经验加载逻辑

**目的：** 新项目启动时，读取历史进化数据来优化策略选择。

定义加载规则（写入编排 Skill）：

```
1. 读取 evolution/strategies/effectiveness.json（如存在）
   → 按维度统计每个策略的成功率
   → 成功率高的策略在该维度优先使用

2. 读取 evolution/calibration/history.json（如存在）
   → 如果某维度历史上用户总是调高/调低
   → 在该维度的评分上预先微调

3. 读取 evolution/projects/ 目录下的项目日志
   → 匹配当前项目的关键词/类型
   → 如有匹配，加载该项目的有效策略 TOP3 作为优先策略
```

- [ ] **Step 1: 设计加载规则文档**

#### Task 11: 编排 Skill 追加经验加载

**Files:**
- Modify: `.claude/commands/require.md`（阶段零初始化）

在步骤 0.5（初始化状态）之后、步骤 0.6（报告启动）之前，新增步骤 0.5.1：

```markdown
### 步骤 0.5.1：加载跨项目经验

**a) 加载策略有效性数据**

读取 `evolution/strategies/effectiveness.json`（如果存在）：
- 按维度分组，计算每个策略的成功率
- 将成功率排名写入 state.json 的 `strategy_preferences` 字段：
  ```json
  "strategy_preferences": {
    "completeness": ["反向场景法", "功能遍历法"],
    "consistency": ["交叉比对法", "术语图谱法"],
    ...
  }
  ```
- 在后续步骤 3.2 选择策略时，优先使用排名靠前的策略

如果文件不存在（首次使用），使用 `evolution/seed/strategy-rankings.md` 中的种子排名。

**b) 加载校准历史**

读取 `evolution/calibration/history.json`（如果存在）：
- 如果某维度历史上用户调整方向一致（如完整性总是调高）
- 记录到 state.json 的 `calibration_hints` 字段
- 在评估 Agent 的指令中提示："历史数据显示，{维度}维度的评分可能偏{低/高}"

**c) 加载相似项目经验**

扫描 `evolution/projects/` 目录：
- 读取每个项目日志的"经验标签"部分
- 与当前项目的意图锚点做关键词匹配
- 如果找到匹配度高的历史项目：
  向用户提示："发现相似项目 {项目名}，其最有效策略为 {TOP3}。参考该经验？(Y/N)"
  用户回复 Y → 加载该项目的策略排名作为优先策略
```

- [ ] **Step 1: 新增步骤 0.5.1**
- [ ] **Step 2: Commit**

#### Task 12: 端到端验证进化系统

- [ ] **Step 1: 运行一个完整项目**
```
/require "待办清单工具"
```
完成后检查：
- `evolution/projects/` 下有进化日志
- `evolution/strategies/effectiveness.json` 有记录

- [ ] **Step 2: 运行第二个相似项目**
```
/require "任务管理工具"
```
验证：
- 启动时提示发现相似项目
- 策略选择优先使用第一个项目验证有效的策略

---

## Part B：模块化文档

---

### Chunk 5: 模块化拆分逻辑（子阶段 4.13 - 4.15）

#### Task 13: 创建模块化拆分逻辑定义

**Files:**
- Create: `templates/module-structure.md`

定义模块化后的目录结构模板：

```markdown
<!-- 模块化文档结构模板 -->

# {项目名}/
# ├── requirement-overview.md    ← 主文档（目录+概览）
# ├── modules/
# │   ├── 01-{模块名}.md
# │   ├── 02-{模块名}.md
# │   └── ...
# ├── cross-cutting/
# │   └── (安全/性能等跨模块需求)
# ├── changelog.md
# ├── open-questions.md
# └── report.md
```

同时定义拆分触发条件：
- 功能模块 ≤ 3 → 单文件
- 功能模块 4-8 → 建议模块化（询问用户）
- 功能模块 > 8 → 自动模块化
- 单文件超过 50 页 → 触发拆分建议

- [ ] **Step 1: 创建模板文件**
- [ ] **Step 2: Commit**

#### Task 14: 编排 Skill 追加自动拆分检测

**Files:**
- Modify: `.claude/commands/require.md`

在广度扫描步骤 2.7（建立范围基线）之后，新增步骤 2.7.1：

```markdown
### 步骤 2.7.1：模块化检测

统计 v2 文档中的功能模块数量（一级章节数）：

- 模块数 ≤ 3 → 保持单文件模式，跳过
- 模块数 4-8 → 向用户建议：
  "📂 检测到 {N} 个功能模块，建议拆分为模块化文档结构。
   模块化后每个模块独立管理、可并行优化。
   拆分？(Y/N)"
  用户回复 Y → 执行拆分
  用户回复 N → 保持单文件
- 模块数 > 8 → 自动拆分，通知用户：
  "📂 检测到 {N} 个功能模块，已自动拆分为模块化文档结构。"

**执行拆分**：
1. 创建 {output_dir}/modules/ 目录
2. 将 requirement-overview.md 中每个功能模块章节提取为独立文件：
   modules/01-{模块名}.md、modules/02-{模块名}.md ...
3. 将 requirement-overview.md 改写为概览文档（只保留产品概述 + 模块总览表 + 术语表 + 全局规则）
4. 如果有跨模块需求（安全/性能等），创建 cross-cutting/ 目录
5. 在 state.json 中标记 `"modular": true`
6. 更新 scope-baseline.json，按模块记录功能点

模块总览表格式：
| 模块 | 文件 | 功能点数 | 状态 |
|------|------|---------|------|
| {模块名} | modules/01-xxx.md | {N} | 草稿 |
```

- [ ] **Step 1: 新增步骤 2.7.1**
- [ ] **Step 2: Commit**

#### Task 15: 创建模块化 requirement-overview.md 模板

**Files:**
- Create: `templates/requirement-overview-modular.md`

```markdown
# {项目名} 需求文档

<!-- 模块化模式：主文档只包含概览，详细需求在 modules/ 目录 -->

## 产品概述
{产品定位、目标用户、核心价值}

## 模块总览
| # | 模块 | 文件 | 功能点数 | 评分 | 状态 |
|---|------|------|---------|------|------|
| 1 | {模块名} | modules/01-xxx.md | {N} | {分数} | {草稿/优化中/已锁定} |

## 模块依赖关系
{模块间依赖说明}

## 术语表
| 术语 | 定义 |
|------|------|

## 全局业务规则
{适用于所有模块的规则}

## 变更记录
| 版本 | 轮次 | 变更内容 | 来源 |
|------|------|---------|------|
```

- [ ] **Step 1: 创建模板**
- [ ] **Step 2: Commit**

---

### Chunk 6: 写手和评分适配模块化（子阶段 4.16 - 4.18）

#### Task 16: 编排 Skill 写手调度适配模块化

**Files:**
- Modify: `.claude/commands/require.md`

在所有调度 writer Agent 的步骤中，增加模块化判断：

```markdown
在调度 writer 之前检查 state.json 的 modular 字段：

如果 modular = false（单文件模式）：
  → 指令不变，读写 requirement-overview.md

如果 modular = true（模块化模式）：
  → 指令调整为：
  "你是写手 Agent。当前文档已模块化。
   本轮优化目标模块：{目标模块文件路径}
   请只修改目标模块文件，不要修改其他模块。
   同时更新 requirement-overview.md 中该模块的评分和状态。

   目标模块内容：
   {模块文件内容}

   概览文档：
   {requirement-overview.md 内容}"
```

- [ ] **Step 1: 修改所有 writer 调度步骤（步骤 2.1、2.4、3.4、4.2）**
- [ ] **Step 2: Commit**

#### Task 17: 编排 Skill 评分适配模块化

**Files:**
- Modify: `.claude/commands/require.md`

模块化模式下评分变为两层：

```markdown
如果 modular = true：

评估 Agent 指令调整为：
"当前文档已模块化。请对以下模块进行评分。

目标模块：{模块名}
模块内容：
{模块文件内容}

概览文档（供参考全局上下文）：
{requirement-overview.md 内容}

按维度对此模块评分（0-10）。"

评分保存格式调整：
scores/round-{N}.json 增加 module 字段：
{
  "round": N,
  "module": "{模块名}" 或 "global",
  "scores": { ... }
}

全局评分 = 各模块评分按功能点数加权平均
```

- [ ] **Step 1: 修改所有 evaluator 调度步骤**
- [ ] **Step 2: 修改评分保存格式**
- [ ] **Step 3: Commit**

#### Task 18: 编排 Skill 深度优化适配模块化

**Files:**
- Modify: `.claude/commands/require.md`（步骤 3.1）

模块化模式下目标选择变为两级：

```markdown
如果 modular = true：

步骤 3.1 改为：
1. 先确定最低分模块（全局评分最低的模块）
2. 再确定该模块最低分维度
3. 本轮优化目标 = {模块名} 的 {维度名}

向用户展示：
"🔄 深度优化 — 第 {N}/{max} 轮
 目标模块：{模块名}
 目标维度：{维度名}（当前 {分数} 分）"

后续步骤（3.2-3.7）中，Agent 只读取和修改目标模块的文件。
```

- [ ] **Step 1: 修改步骤 3.1 为两级目标选择**
- [ ] **Step 2: 修改步骤 3.2-3.7 中的文件读写路径**
- [ ] **Step 3: Commit**

---

### Chunk 7: 跨模块一致性 + 模块命令 + 验证（子阶段 4.19 - 4.22）

#### Task 19: 创建跨模块一致性检查逻辑

**Files:**
- Modify: `.claude/commands/require.md`

在深度优化循环中，每 3 轮插入一次跨模块一致性检查：

```markdown
### 跨模块一致性检查（每 3 轮触发一次）

如果 modular = true 且 current_round % 3 == 0：

调度 consistency Agent：
"你是一致性 Agent。请对以下模块化文档进行跨模块一致性检查。

概览文档：
{requirement-overview.md}

各模块摘要（每个模块前 20 行）：
{各模块前 20 行}

检查：
1. 模块间术语是否统一
2. 模块间业务规则是否矛盾
3. 模块依赖关系描述是否准确
4. 同一概念在不同模块中定义是否一致"

发现问题 → 写入下一轮优化目标
```

- [ ] **Step 1: 添加跨模块一致性检查逻辑**
- [ ] **Step 2: Commit**

#### Task 20: 编排 Skill 新增模块管理命令

**Files:**
- Modify: `.claude/commands/require.md`

在状态恢复协议章节之后，新增模块管理章节：

```markdown
## 模块管理命令

### /require:split
手动触发文档模块化拆分（同步骤 2.7.1 的拆分逻辑）。

### /require:lock --module {模块名}
将指定模块状态改为"已锁定"。锁定后：
- Agent 不再修改该模块
- 如果其他模块的修改影响了锁定模块，提示用户而非自动修改

### /require:unlock --module {模块名}
解锁指定模块，恢复为"优化中"状态。

### /require:focus --module {模块名}
下一轮优先优化指定模块（覆盖默认的"最低分模块优先"逻辑）。

### /require:skip --module {模块名}
跳过指定模块不再优化。

### /require:status --module {模块名}
显示指定模块的详细评分和优化历史。
```

- [ ] **Step 1: 新增模块管理章节**
- [ ] **Step 2: Commit**

#### Task 21: 验证模块化拆分流程

- [ ] **Step 1: 确认拆分触发条件清晰**
- [ ] **Step 2: 确认 writer 模块化指令有目标模块和概览双输入**
- [ ] **Step 3: 确认评分有 module 字段**
- [ ] **Step 4: 确认深度优化有两级目标选择**

#### Task 22: 端到端验证模块化文档

- [ ] **Step 1: 运行一个功能模块多的需求**
```
/require "电商平台，包含用户系统、商品管理、购物车、订单、支付、物流、评价、客服、营销活动、数据统计"
```
- [ ] **Step 2: 验证自动拆分触发**（>8 个模块应自动拆分）
- [ ] **Step 3: 验证 modules/ 目录下有独立文件**
- [ ] **Step 4: 验证 requirement-overview.md 变为概览格式**

---

## Part C：团队协作

---

### Chunk 8: 锁机制（子阶段 4.23 - 4.25）

#### Task 23: 创建锁机制定义

**Files:**
- 在编排 Skill 中定义 lock.json 格式

lock.json 格式：
```json
{
  "locked": true,
  "user": "{用户标识}",
  "started": "{ISO 时间}",
  "last_heartbeat": "{ISO 时间}",
  "pid": "{进程 ID}",
  "project": "{项目名}"
}
```

解锁条件（任一）：
- last_heartbeat 超过 2 分钟未更新
- pid 对应进程不存在
- 用户使用 --force 强制接管

- [ ] **Step 1: 定义 lock.json 格式和规则**

#### Task 24: 编排 Skill 启动时锁检测

**Files:**
- Modify: `.claude/commands/require.md`（阶段零）

在步骤 0.2（创建工作区）之后，新增步骤 0.2.1：

```markdown
### 步骤 0.2.1：锁检测

检查 `.require-agent/projects/{项目名}/lock.json` 是否存在：

如果不存在 → 创建锁文件，继续
如果存在：
  读取锁文件，检查是否过期：
  - last_heartbeat > 2 分钟前 → 视为过期，覆盖创建新锁
  - 否则 → 向用户提示：
    "⚠️ {user} 正在优化「{project}」，开始于 {started}。
     1. 等待对方完成后 --resume
     2. 使用 --force 强制接管"
    如果用户未使用 --force → 终止
```

- [ ] **Step 1: 新增锁检测步骤**
- [ ] **Step 2: Commit**

#### Task 25: 编排 Skill 结束时释放锁

**Files:**
- Modify: `.claude/commands/require.md`

在阶段五步骤 5.4 之后，追加锁释放：

```markdown
### 步骤 5.6：释放锁

删除 `.require-agent/projects/{项目名}/lock.json`。

同时在错误处理章节追加：
如果流程异常终止（任何未捕获的错误），尝试释放锁。
```

- [ ] **Step 1: 追加锁释放逻辑**
- [ ] **Step 2: Commit**

---

### Chunk 9: 协作模式（子阶段 4.26 - 4.30）

#### Task 26: 创建团队输入模板

**Files:**
- Create: `templates/team-input-template.md`

```markdown
---
role: {产品经理/开发/设计师/其他}
focus: {关注的维度，逗号分隔}
---

## 补充需求
- {需要新增的需求}

## 质疑点
- {对现有需求的质疑或反对意见}

## 约束
- {新增的约束条件，如时间、预算、技术限制}
```

- [ ] **Step 1: 创建模板**
- [ ] **Step 2: Commit**

#### Task 27: 编排 Skill 新增 --collab 模式

**Files:**
- Modify: `.claude/commands/require.md`

在参数解析步骤中增加 --collab 处理：

```markdown
如果用户使用了 --collab 参数：
1. 在 {output_dir}/team-input/ 目录下生成输入模板：
   - pm-input.md（产品经理）
   - dev-input.md（开发）
   - design-input.md（设计师）
2. 向用户提示："团队输入模板已生成到 {output_dir}/team-input/，请各角色填写后运行 /require --merge-input"
3. 终止当前流程，等待填写

如果用户使用了 --merge-input 参数：
1. 读取 team-input/ 目录下所有文件
2. 解析每个文件的补充需求、质疑点、约束
3. 共识（多人提到的）→ 直接纳入
4. 分歧（有人赞成有人反对）→ 标记为 [团队分歧待讨论]
5. 将合并结果作为 raw_input，继续正常流程
```

- [ ] **Step 1: 新增 --collab 和 --merge-input 逻辑**
- [ ] **Step 2: Commit**

#### Task 28: 编排 Skill 新增 --review 模式

**Files:**
- Modify: `.claude/commands/require.md`

```markdown
如果用户使用了 --review 参数：
1. 读取 requirement-overview.md（及 modules/ 如果模块化）
2. 扫描所有 <!-- @review xxx: yyy --> 标注
3. 提取评审意见列表
4. 将评审意见作为优化输入，调度对应 Agent 处理
5. 冲突的意见标记为决策点
```

- [ ] **Step 1: 新增 --review 逻辑**
- [ ] **Step 2: Commit**

#### Task 29: 编排 Skill 新增 --role 接力模式

**Files:**
- Modify: `.claude/commands/require.md`

```markdown
如果 --resume 同时带有 --role 参数：
  根据角色调整优化偏好：
  - --role pm → 侧重业务闭环和用户旅程维度
  - --role developer → 侧重可行性和数据维度
  - --role designer → 侧重用户旅程和无障碍维度

  调整方式：将对应维度的达标线 +1（使其更容易成为优化目标）
```

- [ ] **Step 1: 新增 --role 逻辑**
- [ ] **Step 2: Commit**

#### Task 30: 端到端验证团队协作

- [ ] **Step 1: 测试 --collab 模式**（生成团队输入模板）
- [ ] **Step 2: 测试锁机制**（两个终端同时运行 /require）
- [ ] **Step 3: 测试 --review 模式**（在文档中加标注后运行）

---

## Part D：高级功能

---

### Chunk 10: 帮助 + 版本管理命令（子阶段 4.31 - 4.33）

#### Task 31: 新增 /require:help

**Files:**
- Create: `.claude/commands/require-help.md`

创建独立的帮助命令文件：

```yaml
---
description: 显示 EX-RequireAgent 的帮助信息
---
```

内容输出完整的命令列表（参考设计文档附录 B）。

- [ ] **Step 1: 创建 require-help.md**
- [ ] **Step 2: Commit**

#### Task 32: 新增版本标签

**Files:**
- Create: `.claude/commands/require-tag.md`

```yaml
---
description: 给需求文档版本打标签
argument-hint: <版本号> "标签描述"（如 v5 "客户演示版"）
---
```

逻辑：在 state.json 的 `version_tags` 字段中记录 `{"v5": "客户演示版"}`。

- [ ] **Step 1: 创建 require-tag.md**
- [ ] **Step 2: Commit**

#### Task 33: 新增版本对比

**Files:**
- Create: `.claude/commands/require-diff.md`

```yaml
---
description: 对比需求文档的两个版本
argument-hint: <版本1> <版本2>（如 v3 v7）
---
```

逻辑：读取 versions/ 下的两个版本文件，生成差异摘要（新增/修改/删除的需求项）。

- [ ] **Step 1: 创建 require-diff.md**
- [ ] **Step 2: Commit**

---

### Chunk 11: 预览 + 增量注入 + 离线（子阶段 4.34 - 4.36）

#### Task 34: 新增预览模式

**Files:**
- Create: `.claude/commands/require-preview.md`

```yaml
---
description: 预览下一轮优化会做什么（不实际执行）
---
```

逻辑：读取 state.json，分析下一轮的目标维度和策略，展示预计修改但不执行。

- [ ] **Step 1: 创建 require-preview.md**
- [ ] **Step 2: Commit**

#### Task 35: 新增增量需求注入

**Files:**
- Create: `.claude/commands/require-add.md`

```yaml
---
description: 中途追加需求而不重置优化进度
argument-hint: "新增需求描述"
---
```

逻辑：
1. 将新需求写入 intent-anchor.json 的 explicit_requirements
2. 更新 scope-baseline.json（标记为用户主动扩展）
3. 调度 writer 整合新需求到文档
4. 触发一轮快速评估

- [ ] **Step 1: 创建 require-add.md**
- [ ] **Step 2: Commit**

#### Task 36: 新增离线模式

**Files:**
- Modify: `.claude/commands/require.md`

在参数解析中增加 --offline 处理：

```markdown
如果用户使用了 --offline 参数：
  在 state.json 中标记 offline: true

  影响：
  - 跳过阶段一（知识引擎前置侦察）
  - 所有 Agent 的 WebSearch/WebFetch 工具不可用
  - 知识引擎 Agent 不被调度
  - 向用户提示："离线模式，外部搜索功能不可用"
```

- [ ] **Step 1: 新增 --offline 逻辑**
- [ ] **Step 2: Commit**

---

### Chunk 12: 项目管理 + 满意度 + 首次引导 + 验证（子阶段 4.37 - 4.40）

#### Task 37: 新增项目管理命令

**Files:**
- Create: `.claude/commands/require-list.md`
- Create: `.claude/commands/require-clean.md`
- Create: `.claude/commands/require-stats.md`

**require-list.md**：扫描 .require-agent/projects/ 列出所有项目及状态。
**require-clean.md**：清理已完成项目的中间文件（保留最终版本和进化日志）。
**require-stats.md**：读取所有进化日志，输出全局统计（项目数、平均轮次、TOP 策略等）。

- [ ] **Step 1: 创建三个命令文件**
- [ ] **Step 2: Commit**

#### Task 38: 新增用户满意度反馈

**Files:**
- Modify: `.claude/commands/require.md`（阶段五）

在步骤 5.4 之后、步骤 5.5（进化日志）之前，新增步骤 5.4.1：

```markdown
### 步骤 5.4.1：收集用户满意度

向用户提问：
"请对本次优化结果打分（1-10，直接输入数字，或输入 skip 跳过）："

如果用户输入数字：
  保存到 state.json 的 user_satisfaction 字段
  可选追问："有什么建议或反馈吗？（输入 skip 跳过）"
  保存到 state.json 的 user_feedback 字段

这些数据会写入进化日志（步骤 5.5）供后续项目参考。
```

- [ ] **Step 1: 新增满意度收集步骤**
- [ ] **Step 2: Commit**

#### Task 39: 创建首次引导流程

**Files:**
- Modify: `.claude/commands/require.md`（阶段零开头）

在步骤 0.1 之前，新增步骤 0.0：

```markdown
### 步骤 0.0：首次使用检测

检查 `.require-agent/config.json` 是否存在：

如果不存在（首次使用）：
  向用户展示欢迎信息并引导配置：

  "👋 欢迎使用 EX-RequireAgent！

   快速配置（回车使用默认值）：

   1. 输出目录？(默认 ./docs/requirements/)
   2. 默认达标分数？(默认 7，范围 1-10)

   配置已保存，以后可通过编辑 .require-agent/config.json 修改。"

  创建 config.json：
  {
    "output_dir": "{用户选择}",
    "target_score": {用户选择},
    "first_run": false
  }

如果已存在 → 读取配置作为默认值，跳过引导。
```

- [ ] **Step 1: 新增首次引导步骤**
- [ ] **Step 2: Commit**

#### Task 40: 端到端验证高级功能

- [ ] **Step 1: 测试 /require:help** — 应显示完整命令列表
- [ ] **Step 2: 测试离线模式** — `/require "xxx" --offline`，应跳过前置侦察
- [ ] **Step 3: 测试首次引导** — 删除 config.json 后重新运行，应出现引导
- [ ] **Step 4: 测试版本标签** — `/require:tag v3 "测试版"`
- [ ] **Step 5: 测试增量注入** — 优化中途 `/require:add "新增XX功能"`
- [ ] **Step 6: 测试项目列表** — `/require:list`

---

**阶段四验收标准：**
- [ ] 进化日志在项目结束后自动生成
- [ ] 策略有效性跨项目积累
- [ ] 第二个相似项目能加载第一个的经验
- [ ] 大文档自动拆分为模块
- [ ] 模块化模式下评分和优化正常工作
- [ ] 锁机制防止并发冲突
- [ ] 团队协作三种模式可用
- [ ] 所有高级命令正常工作
- [ ] 首次引导正常触发
- [ ] 用户满意度反馈被记录到进化日志
