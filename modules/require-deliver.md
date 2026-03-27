<!-- 本文件是 EX-RequireAgent 编排器的子模块，由主命令 .claude/commands/require.md 引用 -->
<!-- 不要直接运行本文件，它通过 Read 工具被加载 -->

# 阶段四：终审 + 阶段五：交付输出

本模块包含终审（阶段四）和交付输出（阶段五）的核心步骤。
注意：用户满意度收集（5.4.1）、进化日志写入（5.5）、自动推送（5.5.1）在 `modules/require-evolution.md` 中定义。

---

## 阶段四：终审

### 步骤 4.1：最终评分 — 调度 evaluator Agent

**输入准备**：将 overview 文件和所有 module 文件的内容合并为完整评审文本。

使用 `SendMessage` 向 **evaluator** Agent 发送以下指令：

> **输入**：将 requirement-overview.md 和 modules/ 下所有模块文件的完整内容附在消息中。
>
> **指令**：
> "你是评估 Agent。这是最终一轮评审，请对以下需求文档做全面终审评分。
>
> 按照以下维度评分：完整性、一致性、可行性、用户旅程、业务闭环
> {如果 security 在 enabled_agents 中}，以及：安全
> {如果 performance 在 enabled_agents 中}，以及：性能
> {如果 accessibility-i18n 在 enabled_agents 中}，以及：无障碍与国际化
> {如果 data 在 enabled_agents 中}，以及：数据
> {如果 dependency 在 enabled_agents 中}，以及：依赖与集成
>
> 对每个启用的维度按 0-10 分评分。
>
> 除了维度评分外，请额外检查以下终审项目：
> 1. **章节过渡**：各章节之间的逻辑衔接是否自然
> 2. **引用正确**：overview 中的模块链接是否都指向正确的 module 文件
> 3. **术语统一**：overview 和各 module 文件是否使用了统一的术语，无混用现象
> 4. **格式规范**：表格、列表、标题层级是否规范一致
> 5. **层级一致**：overview 的模块总览表是否与各 module 文件的实际内容一致（功能点数、描述等）
>
> 如果发现终审问题，在优化建议部分指出，并标明问题出现在 overview 还是哪个 module 文件。
>
> 需求文档（overview）：
> {requirement-overview.md 内容}
>
> 模块文件：
> {逐个列出每个 module 文件名和内容}"
>
> **输出处理**：
> 1. 解析所有启用维度的最终评分
> 2. 保存到 `.require-agent/projects/{项目名}/scores/final.json`

### 步骤 4.2：如果终审发现问题 — 最终修正

如果 evaluator 在终审中指出了章节过渡、引用、术语、格式方面的具体问题：

使用 `SendMessage` 向 **writer** Agent 发送修正指令：

> "你是写手 Agent。这是终审修正，请只修复以下具体问题，不要添加新内容、不要改变文档结构：
>
> {evaluator 指出的终审问题列表，包含各问题所在的文件（overview 或具体 module）}
>
> 在 overview 变更记录中记录：版本 v{final}，轮次 终审，来源 evaluator, writer。
>
> 当前 overview：
> {requirement-overview.md 内容}
>
> 当前模块文件：
> {逐个列出每个 module 文件名和内容}"

将修正后的 overview 和 module 文件保存为最终版本。

### 步骤 4.2.1：红队终审

在 writer 完成终审修正后，对修正内容进行最后一轮红队审查。

**执行条件**：步骤 4.2 执行了修正（即 evaluator 在 4.1 中发现了问题）。如果 4.1 未发现问题（跳过了 4.2），则也跳过 4.2.1。

使用 `SendMessage` 向 **red-team** Agent 发送以下指令：

> "你是红队 Agent。这是终审阶段的最后审查。
>
> writer 刚对文档做了终审修正，修正内容涉及以下方面：
> {evaluator 在 4.1 中指出的问题列表}
>
> 请只检查本次修正涉及的部分（不需要全量扫描），从以下角度快速审查：
> 1. 修正是否引入了新的漏洞或风险？
> 2. 修正是否与文档其他部分产生矛盾？
> 3. 修正内容是否充分解决了 evaluator 指出的问题？
>
> 只标注 P0 级别的问题。P1 及以下在此阶段不处理。
>
> 修正后的文档：
> {最新版文档内容}"

**输出处理**：

1. 如果红队发现 P0 问题：
   - 向用户展示红队发现的 P0 问题
   - 调度 writer 再次修正（仅针对 P0 问题）
   - 注意：此修正最多执行一次，避免终审死循环
   - 修正后不再调度红队审查

2. 如果红队未发现 P0 问题：
   - 通过终审，继续步骤 4.3
   - 向用户提示："终审红队审查通过"

### 步骤 4.3：向用户展示终审结果

```
终审完成

| 维度 | 最终分数 | 达标线 | 状态 |
|------|---------|--------|------|
| 完整性 | {分数} | {target_score} | {状态} |
| 一致性 | {分数} | {target_score} | {状态} |
| 可行性 | {分数} | {target_score} | {状态} |
| 用户旅程 | {分数} | {target_score} | {状态} |
| 业务闭环 | {分数} | {target_score} | {状态} |
{各按需维度同上，仅已启用的显示}

成熟度：{成熟度阶段}
总轮次：{总轮次数}（广度扫描 1 轮 + 深度优化 {deep_rounds} 轮）
最大提升维度：{提升幅度最大的维度}（+{提升分数} 分）
```

**评分校准**：如果用户对某个维度的评分提出异议：
1. 记录原始评分和用户调整方向
2. 追加到 `evolution/calibration/history.json`（如不存在则创建空数组）：
   ```json
   {
     "project": "{项目名}",
     "round": "final",
     "dimension": "{维度}",
     "agent_score": "{Agent分}",
     "user_adjusted": "{用户调整分}",
     "direction": "up/down",
     "date": "{日期}"
   }
   ```
3. 在当前项目中按用户调整值继续

更新 `state.json`：`phase -> delivery`。

---

## 阶段五：交付输出

### 步骤 5.1：生成 changelog.md

在 `{output_dir}/` 下创建 `changelog.md`，内容为所有轮次的变更记录表格：

```markdown
# 变更记录

| 轮次 | 目标维度 | 动作 | 分数变化 | 版本 |
|------|---------|------|---------|------|
| 广度扫描 | 全维度 | 建立基线 | — | v2 |
| 第 1 轮 | {维度} | {improved/rolled_back/stalled} | {旧->新} | v{N} |
| 第 2 轮 | {维度} | {improved/rolled_back/stalled} | {旧->新} | v{N} |
| ... | ... | ... | ... | ... |
| 终审 | 全维度 | 终审修正 | — | v{final} |
```

数据来源：`state.json` 中的 `round_history` 数组。

### 步骤 5.2：生成 report.md

在 `{output_dir}/` 下创建 `report.md`，内容为优化报告摘要：

```markdown
# 优化报告

## 项目信息

- 项目：{项目名}
- 开始时间：{created_at}
- 完成时间：{当前时间}
- 总轮次：{总轮次}
- 达标线：{target_score}

## 评分总览

| 维度 | 初始分数 | 最终分数 | 提升 |
|------|---------|---------|------|
| 完整性 | {初始} | {最终} | {+差值} |
| 一致性 | {初始} | {最终} | {+差值} |
| 可行性 | {初始} | {最终} | {+差值} |
| 用户旅程 | {初始} | {最终} | {+差值} |
| 业务闭环 | {初始} | {最终} | {+差值} |
{各按需维度同上，仅已启用的显示}

## 优化过程摘要

{对每一轮的简要描述：目标维度、做了什么、结果如何}

## 停滞维度

{如果有停滞维度，说明哪些维度达到上限以及最终分数}

## 未解决问题

{如果文档中存在 [冲突待解决] 标记，在此列出}
```

数据来源：`scores/` 目录下的评分文件和 `state.json`。

### 步骤 5.3：生成 open-questions.md

扫描 overview 文件和所有 module 文件，提取所有包含以下标记的内容：
- `[冲突待解决]`
- `[待讨论]`
- `[待确认]`
- `[TBD]`

在 `{output_dir}/` 下创建 `open-questions.md`：

```markdown
# 开放问题

以下问题在优化过程中未能完全解决，需要人工决策。

| # | 问题 | 来源文件 | 来源章节 | 标记类型 |
|---|------|---------|---------|---------|
| 1 | {问题描述} | {overview/模块文件名} | {所在章节} | {标记类型} |
| 2 | {问题描述} | {overview/模块文件名} | {所在章节} | {标记类型} |
```

如果没有找到任何标记，文件内容为：

```markdown
# 开放问题

所有问题均已在优化过程中解决，无待处理事项。
```

### 步骤 5.4：向用户展示最终交付

```
需求文档优化完成！

输出文件：
  {output_dir}/
  ├── requirement-overview.md    <- 执行摘要 + 功能全景 + 附录
  ├── modules/
  │   ├── 01-{模块名}.md         <- 模块详情
  │   ├── 02-{模块名}.md
  │   └── ...
  ├── changelog.md               <- 变更记录
  ├── report.md                  <- 优化报告
  └── open-questions.md          <- 开放问题

阅读指南：
  requirement-overview.md        -> 30 秒了解全貌
  modules/*.md                   -> 按需查看模块细节

工作区：
  .require-agent/projects/{项目名}/
  ├── state.json               <- 项目状态
  ├── intent-anchor.json       <- 意图锚点
  ├── scope-baseline.json      <- 范围基线
  ├── versions/                <- 所有版本快照
  └── scores/                  <- 所有轮次评分

后续可用操作：
  /require --resume {项目名}   <- 恢复优化
  /require --file <路径>        <- 基于文件重新开始
```

展示完成后，依次执行：
1. 加载 `modules/require-evolution.md` 执行步骤 5.4.1（收集用户满意度）
2. 执行步骤 5.5（写入进化日志）
3. 执行步骤 5.5.1（自动推送进化数据）

### 步骤 5.6：释放锁

删除 `.require-agent/projects/{项目名}/lock.json`（如果存在）。

更新 `state.json`：`phase -> completed`。
