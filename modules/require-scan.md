<!-- 本文件是 EX-RequireAgent 编排器的子模块，由主命令 .claude/commands/require.md 引用 -->
<!-- 不要直接运行本文件，它通过 Read 工具被加载 -->

# 阶段一 + 阶段二：知识引擎前置侦察与广度扫描

本模块包含知识引擎前置侦察（阶段一）和广度扫描（阶段二）的全部步骤。

---

## 阶段一：知识引擎前置侦察

如果 state.json 中 offline = true：
  向用户提示："离线模式，跳过前置侦察"
  跳到阶段二

### 步骤 1.1：调度知识引擎 Agent

使用 `SendMessage` 向 **knowledge-engine** Agent 发送以下指令：

> **指令**：
> "你是知识引擎 Agent。请对以下项目进行前置侦察。
>
> 项目描述：
> {raw_input}
>
> 意图锚点：
> {intent-anchor.json 内容}
>
> 请按照你定义的「领域简报」格式输出，包含：竞品概览、行业标准、用户痛点、差异化机会、风险提示。"
>
> **输出处理**：将知识引擎返回的领域简报保存到 `.require-agent/projects/{项目名}/domain-brief.md`

### 步骤 1.2：向用户展示简报摘要

向用户输出：

```
前置侦察完成

已搜索竞品、行业标准、用户痛点等外部信息。
领域简报已保存到 .require-agent/projects/{项目名}/domain-brief.md

进入广度扫描...
```

更新 `state.json`：`phase -> breadth_scan`

---

## 阶段二：广度扫描

目标：从零建立需求文档基线，得到首次评分。

### 步骤 2.0.5：提前检测按需 Agent

在生成 v1 之前，先扫描 raw_input 中的关键词，提前检测是否需要启用按需 Agent：

检测规则（与步骤 2.5.1 相同）：
- raw_input 含"登录"、"密码"、"权限"、"认证"、"支付"、"加密"→ 建议 security
- raw_input 含"并发"、"响应时间"、"QPS"、"可用性"、"性能"→ 建议 performance
- raw_input 含"多语言"、"国际化"、"无障碍"、"屏幕阅读器"→ 建议 accessibility-i18n
- raw_input 中出现 3 个以上核心业务实体 → 建议 data
- raw_input 含"第三方"、"API"、"SDK"、"微信"、"支付宝"、"推送"→ 建议 dependency

过滤掉已在 enabled_agents 中的。

如果有建议项，向用户提示：
"输入中检测到以下领域关键词，建议提前启用按需 Agent（提前参与广度扫描效果更好）：
- {agent名}: 检测到关键词 "{匹配的关键词}"
- ...

请选择：Y — 全部启用 / N — 不启用 / 或输入 Agent 名称选择性启用"

根据用户回复更新 enabled_agents 和 state.json。

这样按需 Agent 可以在步骤 2.2 广度扫描中就参与，而不是等到 v2 评分后才被发现。

### 步骤 2.1：生成 v1 — 调度 writer Agent

使用 `SendMessage` 向 **writer** Agent 发送以下指令：

> **输入**：将 `raw_input` 的完整内容附在消息中。
>
> **指令**：
> "你是写手 Agent。请根据以下用户原始输入，生成第一版需求文档。这是从零开始，没有历史版本。
>
> 先判断输入的完整程度：如果信息极少（只有模糊想法），使用 `templates/outline.md` 大纲模板；如果有一定结构（有功能点），使用 `templates/checklist.md` 功能清单模板；如果比较完整（有详细描述），使用 `templates/prd.md` PRD 模板。
>
> 在变更记录中记录：版本 v1，轮次 第 0 轮，来源 writer。
>
> 参考以下领域简报（来自知识引擎的前置侦察）来丰富你的需求文档：
> {domain-brief.md 内容}
>
> 用户原始输入：
> {raw_input}"
>
> **输出处理**：将 writer 返回的文档保存到两个位置：
> 1. `{output_dir}/requirement-overview.md` — 工作副本（后续所有修改基于此文件）
> 2. `.require-agent/projects/{项目名}/versions/v1.md` — 版本快照（只读存档）

### 步骤 2.2：多维度扫描

分别调度 5 个维度 Agent 进行广度扫描。每个 Agent 只关注自己负责的维度。

**a) completeness Agent — 完整性扫描**

使用 `SendMessage` 向 **completeness** Agent 发送以下指令：
> "你是完整性 Agent。请对以下需求文档进行广度扫描。使用策略 A：功能遍历法，检查功能缺失、场景遗漏、要素不全、状态未定义。
>
> 需求文档：
> {v1 文档内容}"

**b) consistency Agent — 一致性扫描**

使用 `SendMessage` 向 **consistency** Agent 发送以下指令：
> "你是一致性 Agent。请对以下需求文档进行广度扫描。使用策略 A：交叉比对法，检查逻辑矛盾、术语不统一、格式不一致、引用错误。
>
> 需求文档：
> {v1 文档内容}"

**c) user-journey Agent — 用户旅程扫描**

使用 `SendMessage` 向 **user-journey** Agent 发送以下指令：
> "你是用户旅程 Agent。请对以下需求文档进行广度扫描。使用策略 B：关键路径法，快速走一遍核心用户流程，找出明显的断点和缺失。
>
> 需求文档：
> {v1 文档内容}"

**d) business-closure Agent — 业务闭环扫描**

使用 `SendMessage` 向 **business-closure** Agent 发送以下指令：
> "你是业务闭环 Agent。请对以下需求文档进行广度扫描。使用策略 A：成本收益法，快速评估商业逻辑是否成立。
>
> 需求文档：
> {v1 文档内容}"

**e) feasibility Agent — 可行性扫描**

使用 `SendMessage` 向 **feasibility** Agent 发送以下指令：
> "你是可行性 Agent。请对以下需求文档进行广度扫描。使用策略 A：MVP 裁剪法，快速评估需求的可落地性。
>
> 需求文档：
> {v1 文档内容}"

**输出处理**：收集所有 5 个默认维度 Agent 的发现，合并为 `all_findings` 变量。

**f) 按需 Agent 扫描（如已启用）**

对每个已在 `enabled_agents` 中的按需 Agent 执行广度扫描：

如果 **security** 已启用：
使用 `SendMessage` 向 **security** Agent 发送以下指令：
> "使用策略 A：OWASP Top 10 对照法，对需求文档进行安全广度扫描。需求文档：{v1 文档内容}"

如果 **performance** 已启用：
使用 `SendMessage` 向 **performance** Agent 发送以下指令：
> "使用策略 B：SLA 定义法。需求文档：{v1 文档内容}"

如果 **accessibility-i18n** 已启用：
使用 `SendMessage` 向 **accessibility-i18n** Agent 发送以下指令：
> "使用策略 A：WCAG 对照法。需求文档：{v1 文档内容}"

如果 **data** 已启用：
使用 `SendMessage` 向 **data** Agent 发送以下指令：
> "使用策略 A：实体梳理法。需求文档：{v1 文档内容}"

如果 **dependency** 已启用：
使用 `SendMessage` 向 **dependency** Agent 发送以下指令：
> "使用策略 A：依赖图谱法。需求文档：{v1 文档内容}"

将按需 Agent 的发现也合并到 `all_findings` 中。

### 步骤 2.3：红队挑战 — 调度 red-team Agent

使用 `SendMessage` 向 **red-team** Agent 发送以下指令：

> **输入**：将 v1 文档内容和 `all_findings` 附在消息中。
>
> **指令**：
> "你是红队 Agent。请对以下需求文档进行挑战。5 个维度 Agent 已经做了初步扫描，它们的发现也附在下方供你参考（避免重复提出相同问题）。
>
> 同时使用**恶意用户**和**刁钻甲方**两个视角审视需求。优先输出 P0 和 P1 级别的挑战。
>
> 需求文档：
> {v1 文档内容}
>
> 各维度 Agent 的发现：
> {all_findings}"
>
> **输出处理**：将 red-team Agent 的挑战列表存储为变量 `redteam_challenges`。

**P0 追问（广度扫描阶段）**：

如果 redteam_challenges 中包含 P0 级别挑战：
1. 对每条 P0 挑战，调度对应维度的 Agent 回应（判断维度归属：安全类→security/completeness，业务类→business-closure，定义类→consistency）
2. 将回应传给 red-team 评估
3. 红队判断：resolved / partial / unresolved
4. 最多追问 2 轮（广度扫描阶段限制为 2 轮，因为文档还不完善，深度追问意义有限）
5. 追问结果合并到 redteam_challenges 中

**初始化 open_challenges**：

将 redteam_challenges 中所有 P0/P1 项写入 state.json 的 open_challenges 初始列表：
```json
{
  "open_challenges": [
    {
      "id": "RT-001",
      "priority": "{P0/P1}",
      "status": "{resolved/partial/unresolved}",
      "target": "{目标}",
      "challenge": "{挑战内容}",
      "perspective": "{视角}",
      "first_round": 0,
      "last_round": 0,
      "rounds_open": 0,
      "escalated": false,
      "writer_rejection_count": 0,
      "writer_rejection_reason": null
    }
  ]
}
```

这样 Phase 3 第一轮可以直接读取遗留清单，不需要从零发现。

### 步骤 2.3.5：发现冲突检测

在 writer 整合之前，编排器自动检测 all_findings + redteam_challenges 中的矛盾建议。

**检测方法**：
扫描所有 findings 的 suggestion 字段，识别方向相反的建议对：
- 一个建议"增加/新增/补充"某功能，另一个建议"简化/移除/合并"同一功能
- 一个建议"放宽"某限制，另一个建议"收紧"同一限制
- 一个建议"拆分"某模块，另一个建议"合并"同一模块

**冲突处理**：
1. 对检测到的矛盾建议对，标注 [冲突]，附带两方 Agent 名称和建议摘要
2. 冲突标注随 all_findings 一起传给 writer
3. writer 对冲突项使用其冲突处理规则：
   - 轻微冲突：选择更具体的版本
   - 严重冲突：标注 [冲突待解决]，保留双方观点

**向用户展示**：
如果检测到 2 个以上冲突，向用户提示：
"广度扫描中检测到 {N} 处 Agent 建议冲突，已标注交给写手处理。"

### 步骤 2.4：整合为 v2 — 调度 writer Agent

使用 `SendMessage` 向 **writer** Agent 发送以下指令：

> **输入**：将 v1 文档内容、`all_findings`、`redteam_challenges` 附在消息中。
>
> **指令**：
> "你是写手 Agent。请将各维度 Agent 和红队 Agent 的发现整合进需求文档。
>
> 整合规则：
> 1. P0 和 P1 级别的发现必须全部整合
> 2. P2 级别的发现选择最重要的整合
> 3. P3 级别的发现暂不整合
> 4. 整合时注意不要偏离项目核心目的
> 5. 如果需要升级模板（如从大纲升级到功能清单），执行模板升级
>
> 在变更记录中记录：版本 v2，轮次 第 0 轮，来源 completeness, consistency, user-journey, business-closure, feasibility, red-team, writer。
>
> 当前文档（v1）：
> {v1 文档内容}
>
> 各维度发现：
> {all_findings}
>
> 红队挑战：
> {redteam_challenges}"
>
> **输出处理**：
> 1. 将 writer 返回的文档覆盖写入 `{output_dir}/requirement-overview.md`
> 2. 保存快照到 `.require-agent/projects/{项目名}/versions/v2.md`

### 步骤 2.5：基线评分 — 调度 evaluator Agent

使用 `SendMessage` 向 **evaluator** Agent 发送以下指令：

> **输入**：将 v2 文档的完整内容附在消息中。
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
> {v2 文档内容}"
>
> **输出处理**：
> 1. 从 evaluator 的输出中解析所有启用维度的分数、成熟度阶段、优化建议
> 2. 将评分结果保存到 `.require-agent/projects/{项目名}/scores/round-0.json`：
> ```json
> {
>   "round": 0,
>   "phase": "breadth_scan",
>   "version": "v2",
>   "scores": {
>     "completeness": <分数>,
>     "consistency": <分数>,
>     "feasibility": <分数>,
>     "user_journey": <分数>,
>     "business_loop": <分数>,
>     "security": <分数>,
>     "performance": <分数>,
>     "accessibility_i18n": <分数>,
>     "data": <分数>,
>     "dependency": <分数>
>   },
>   "average": <所有启用维度的平均分>,
>   "maturity": "<成熟度阶段>",
>   "suggestions": "<evaluator 的优化建议原文>"
> }
> ```
> 注意：scores 中仅包含已启用维度的分数。

### 步骤 2.5.1：按需 Agent 二次检测

注意：步骤 2.0.5 已在 raw_input 阶段做了首次检测。本步骤在 v2 文档中做二次检测，
因为 v2 可能包含 raw_input 中没有的新内容（由维度 Agent 补充）。

在基线评分完成后，扫描 v2 文档内容中的关键词，检测是否应建议启用按需 Agent：

1. 扫描文档，按以下规则检测：
   - 文档含"登录"、"密码"、"权限"、"认证"、"支付"、"加密"中任意一个 -> 建议 **security**
   - 文档含"并发"、"响应时间"、"QPS"、"可用性"、"性能"中任意一个 -> 建议 **performance**
   - 文档含"多语言"、"国际化"、"无障碍"、"屏幕阅读器"、"适配"中任意一个 -> 建议 **accessibility-i18n**
   - 文档中出现 3 个以上核心业务实体（如用户、订单、商品、账户等名词实体） -> 建议 **data**
   - 文档含"第三方"、"API"、"SDK"、"微信"、"支付宝"、"推送"、"短信"中任意一个 -> 建议 **dependency**

2. 过滤掉已在 `enabled_agents` 中的 Agent（避免重复建议）。

3. 如果有建议项，向用户提示：

```
检测到需求文档涉及以下领域，建议启用按需 Agent：
- {agent名}: 检测到关键词 "{匹配的关键词}"
- ...

请选择：
  Y — 全部启用
  N — 不启用
  或输入 Agent 名称选择性启用（如：security,data）
```

4. 根据用户回复更新 `enabled_agents`：
   - Y -> 将所有建议的 Agent 加入 `enabled_agents`
   - N -> 不做更改
   - 指定名称（如 `security,data`）-> 只将指定的 Agent 加入 `enabled_agents`

5. 更新 `state.json` 的 `enabled_agents` 字段。

### 步骤 2.6：向用户展示基线评分

向用户输出以下信息：

```
基线评分（广度扫描完成）

| 维度 | 分数 | 达标线 | 状态 |
|------|------|--------|------|
| 完整性 | {分数} | {target_score} | {>=达标线 ? 达标 : 未达标} |
| 一致性 | {分数} | {target_score} | {>=达标线 ? 达标 : 未达标} |
| 可行性 | {分数} | {target_score} | {>=达标线 ? 达标 : 未达标} |
| 用户旅程 | {分数} | {target_score} | {>=达标线 ? 达标 : 未达标} |
| 业务闭环 | {分数} | {target_score} | {>=达标线 ? 达标 : 未达标} |
{各按需维度同上，仅已启用的显示}

成熟度：{成熟度阶段}
平均分：{平均分}
最需改进：{最低分维度}

继续深度优化？(Y/N)
```

**评分校准**：如果用户对某个维度的评分提出异议：
1. 记录原始评分和用户调整方向
2. 追加到 `evolution/calibration/history.json`（如不存在则创建空数组）：
   ```json
   {
     "project": "{项目名}",
     "round": "baseline",
     "dimension": "{维度}",
     "agent_score": "{Agent分}",
     "user_adjusted": "{用户调整分}",
     "direction": "up/down",
     "date": "{日期}"
   }
   ```
3. 在当前项目中按用户调整值继续

**等待用户回复**：
- 用户回复 Y（或 yes、继续、好 等肯定词）-> 进入阶段三
- 用户回复 N（或 no、不了、够了 等否定词）-> 跳到阶段五（交付）
- 如果所有维度已经 >= 达标线 -> 向用户说明已达标，询问是否仍要继续优化

### 步骤 2.7：建立范围基线

从 v2 文档中提取所有功能点，创建 `scope-baseline.json`：

```json
{
  "version": "v2",
  "feature_count": <功能点总数>,
  "features": [
    "功能点 1 名称",
    "功能点 2 名称"
  ],
  "created_at": "{当前 ISO 时间戳}"
}
```

保存到 `.require-agent/projects/{项目名}/scope-baseline.json`。

> 这个基线在后续优化中用于检测范围蠕变——如果功能点数量增长超过基线的 50%，需要向用户发出警告。

同时初始化 state.json 中的 challenge_coverage：

从 v2 文档中提取所有功能点/模块名，为每个功能点创建三视角初始状态：
```json
{
  "challenge_coverage": {
    "{功能点/模块名}": {
      "恶意用户": { "status": "unchallenged" },
      "刁钻甲方": { "status": "unchallenged" },
      "需求质检员": { "status": "unchallenged" }
    }
  }
}
```

如果 Phase 2 的红队已审查了部分功能点，则将对应状态更新为审查结果。

### 步骤 2.8：更新状态

更新 `state.json`：

```json
{
  "phase": "deep_optimization",
  "current_round": 1,
  "scores": {
    "completeness": <分数>,
    "consistency": <分数>,
    "feasibility": <分数>,
    "user_journey": <分数>,
    "business_loop": <分数>
  },
  "updated_at": "{当前 ISO 时间戳}"
}
```

注意：scores 中按需维度仅在对应 Agent 已启用时包含。

完成后进入阶段三（加载 `modules/require-optimize.md`）。
