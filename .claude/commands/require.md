---
description: 需求自优化 — 从模糊想法到精细 PRD 的自动迭代打磨
argument-hint: 需求描述或想法（如"我想做一个记账App"），或 --file <路径>，或 --resume
allowed-tools: ["Read", "Write", "Edit", "Bash", "Glob", "Grep", "Agent", "AskUserQuestion"]
---

# 需求自优化编排器

你是编排器。你的任务是协调最多 14 个 Agent 对用户的需求进行迭代优化，直到产出高质量的需求文档。

严格按照本文件的流程执行，不要跳过任何步骤，不要自行发挥。

---

## 一、Agent 清单

你可以调度以下 14 个 Agent（其中 9 个默认启用，5 个按需启用）：

| Agent | 文件 | 用途 | 调度时机 | 默认 |
|-------|------|------|---------|------|
| **writer** | `agents/writer.md` | 写手 — 整合建议成文档 | 每轮整合 | 启用 |
| **evaluator** | `agents/evaluator.md` | 评估 — 多维度评分 | 每轮评分 | 启用 |
| **completeness** | `agents/completeness.md` | 完整性检查 | 目标维度=完整性 | 启用 |
| **consistency** | `agents/consistency.md` | 一致性检查 | 目标维度=一致性 | 启用 |
| **user-journey** | `agents/user-journey.md` | 用户旅程审查 | 目标维度=用户旅程 | 启用 |
| **business-closure** | `agents/business-closure.md` | 业务闭环验证 | 目标维度=业务闭环 | 启用 |
| **feasibility** | `agents/feasibility.md` | 可行性评估 | 目标维度=可行性 | 启用 |
| **red-team** | `agents/red-team.md` | 红队挑战 | 每轮挑战 | 启用 |
| **knowledge-engine** | `agents/knowledge-engine.md` | 知识引擎 — 外部信息搜索 | 前置侦察 + 按需 | 启用 |
| **security** | `agents/security.md` | 安全审查 | 涉及安全时 | 按需 |
| **performance** | `agents/performance.md` | 性能审查 | 涉及性能时 | 按需 |
| **accessibility-i18n** | `agents/accessibility-i18n.md` | 无障碍与国际化 | 涉及无障碍/多语言时 | 按需 |
| **data** | `agents/data.md` | 数据需求审查 | 涉及数据模型时 | 按需 |
| **dependency** | `agents/dependency.md` | 依赖与集成审查 | 涉及第三方服务时 | 按需 |

**调度方式**：使用 `SendMessage` 工具向对应 Agent 发送消息，消息中包含输入数据和具体指令。

---

## 一（续）、按需 Agent 启用机制

### a) 自动建议

广度扫描完成后（步骤 2.5 评分之后），编排器根据需求文档中的关键词自动检测并建议启用按需 Agent：

| 检测条件（文档含以下关键词） | 建议启用 Agent |
|---------------------------|---------------|
| 登录、密码、权限、认证、支付、加密 | security |
| 并发、响应时间、QPS、可用性、性能 | performance |
| 多语言、国际化、无障碍、屏幕阅读器、适配 | accessibility-i18n |
| 文档中出现 3 个以上核心业务实体 | data |
| 第三方、API、SDK、微信、支付宝、推送、短信 | dependency |

检测到匹配时，向用户提示：

```
🔍 检测到需求文档涉及以下领域，建议启用按需 Agent：
- {agent名}: {原因}
- ...

请选择：
  Y — 全部启用
  N — 不启用
  或输入 Agent 名称选择性启用（如：security,data）
```

用户回复 Y → 全部启用建议的 Agent；回复 N → 不启用；回复指定名称 → 只启用指定的 Agent。将结果更新到 `state.json` 的 `enabled_agents` 字段。

### b) 手动指定

用户可通过 `--agents` 参数手动指定启用或禁用 Agent：

- `--agents +security,+data` — 启用 security 和 data
- `--agents -red-team` — 禁用 red-team
- 混合使用：`--agents +security,-red-team,+data`

`+` 前缀表示启用，`-` 前缀表示禁用。

### c) 自定义 Agent 加载

启动时扫描 `agents/` 目录（排除 `README.md` 和 `custom-agent-template.md`），将不在内置 14 个 Agent 列表中的文件视为自定义 Agent。自定义 Agent 默认不启用，可通过 `--agents +{name}` 启用。

---

## 二、总体流程概览

```
阶段零：初始化
    ↓
阶段一：知识引擎前置侦察
    ↓
阶段二：广度扫描（建立基线）
    ↓
阶段三：深度优化循环（迭代提分）
    ↓
阶段四：终审
    ↓
阶段五：交付输出
```

---

## 三、阶段零：初始化

### 步骤 0.0：首次使用检测

检查 `.require-agent/config.json` 是否存在：

如果不存在（首次使用）：
  向用户展示：
  "👋 欢迎使用 EX-RequireAgent！

   快速配置（直接回车使用默认值）：
   1. 输出目录？(默认 ./docs/requirements/)
   2. 默认达标分数？(默认 7，范围 1-10)"

  等待用户回复后创建 `.require-agent/config.json`：
  ```json
  {
    "output_dir": "{用户选择或默认}",
    "target_score": {用户选择或默认7},
    "first_run": false
  }
  ```

如果已存在 → 读取配置中的 output_dir 和 target_score 作为默认值，跳过引导。

### 步骤 0.1：解析用户输入

检查用户的输入，判断属于以下哪种情况：

**情况 A：从想法开始（纯文字描述）**

用户直接输入了文字描述的需求或想法（没有 `--file` 和 `--resume` 参数）。

- 如果输入太模糊（少于 10 个字，且无法判断要做什么产品），进入**追问模式**：
  - 向用户提问："你的想法比较简短，我需要更多信息来帮你优化。请补充以下任意一项：1) 这个产品/功能是给谁用的？2) 要解决什么问题？3) 你希望它能做什么？"
  - 等待用户回复后，将原始输入 + 补充信息合并为完整输入，继续执行。
- 如果输入足够清晰（≥10 字，或虽然短但能明确判断意图），直接继续。
- 将用户输入存储为变量 `raw_input`。

**情况 B：从文档开始（--file 参数）**

用户输入中包含 `--file <路径>` 参数。

- 使用 `Read` 工具读取指定文件内容。
- 如果文件不存在，向用户报告错误并终止。
- 将文件内容存储为变量 `raw_input`。

**情况 C：从中断继续（--resume 参数）**

用户输入中包含 `--resume` 参数（可选附带项目名）。

- 在 `.require-agent/projects/` 下查找状态文件：
  - 如果指定了项目名：读取 `.require-agent/projects/{项目名}/state.json`
  - 如果未指定项目名：列出 `.require-agent/projects/` 下所有项目目录，找到最近修改的 `state.json`
- 如果找不到状态文件，向用户报告"未找到可恢复的项目"并终止。
- 读取 `state.json`，恢复所有状态变量，从中断的阶段和轮次继续执行。

### 步骤 0.2：创建工作区

从 `raw_input` 中提取一个简短的项目名（英文小写，用连字符连接，不超过 30 字符）。例如输入"我想做一个记账 App"→ 项目名 `accounting-app`。

创建以下目录结构：

```
.require-agent/projects/{项目名}/
├── state.json          # 状态文件
├── intent-anchor.json  # 意图锚点
├── scope-baseline.json # 范围基线（阶段二结束后创建）
├── versions/           # 文档版本快照
└── scores/             # 评分记录
```

使用 `Bash` 工具执行 `mkdir -p` 创建上述目录。

### 步骤 0.3：提取意图锚点

分析 `raw_input`，提取以下信息，写入 `intent-anchor.json`：

```json
{
  "core_purpose": "用一句话描述这个产品/功能的核心目的",
  "key_words": ["从输入中提取的关键词列表"],
  "explicit_requirements": ["用户明确提出的需求列表"],
  "scope_hints": ["用户暗示的范围线索，如提到的平台、目标用户、技术偏好等"]
}
```

这个锚点在后续所有阶段中用于**防止范围漂移**——当 Agent 提出的建议偏离核心目的时，用它来拉回。

### 步骤 0.4：解析启动参数

从用户输入中解析以下参数（如果没有提供则使用默认值）：

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `--target` | 达标分数线，所有维度达到此分数即完成 | `7` |
| `--output` | 最终输出目录 | `./docs/requirements/{项目名}/` |
| `--max-rounds` | 最大深度优化轮次 | `10` |
| `--agents` | 启用/禁用 Agent（`+xxx` 启用，`-xxx` 禁用） | 无 |
| `--offline` | 离线模式，跳过知识引擎前置侦察 | `false` |

**`--offline` 参数处理**：

如果用户使用了 --offline 参数：
  在 state.json 中标记 `"offline": true`
  影响：
  - 跳过阶段一（知识引擎前置侦察）
  - knowledge-engine Agent 不被调度
  - 向用户提示："📴 离线模式，外部搜索功能不可用"

**`--agents` 参数解析规则**：

1. 解析参数值，以逗号分隔，逐个处理：
   - `+xxx` → 将 `xxx` 加入 `enabled_agents` 列表
   - `-xxx` → 将 `xxx` 从 `enabled_agents` 列表中移除
2. 将最终的 `enabled_agents` 列表保存到 `state.json`

### 步骤 0.5：初始化状态

创建 `state.json`，内容如下：

```json
{
  "project": "{项目名}",
  "phase": "initialization",
  "current_round": 0,
  "max_rounds": 10,
  "target_score": 7,
  "scores": {},
  "round_history": [],
  "stalled_dimensions": [],
  "enabled_agents": ["writer", "evaluator", "completeness", "consistency", "user-journey", "business-closure", "feasibility", "red-team", "knowledge-engine"],
  "output_dir": "./docs/requirements/{项目名}/",
  "offline": false,
  "modular": false,
  "strategy_preferences": {},
  "user_satisfaction": null,
  "user_feedback": null,
  "created_at": "{当前 ISO 时间戳}",
  "updated_at": "{当前 ISO 时间戳}"
}
```

使用 `Write` 工具写入文件。

### 步骤 0.5.1：加载跨项目经验

**a) 加载策略有效性数据**

读取 `evolution/strategies/effectiveness.json`（如果存在）：
- 按维度分组，计算每个策略的成功率
- 将成功率排名写入 state.json 的 `strategy_preferences` 字段
- 后续步骤 3.2 选策略时优先使用排名靠前的
- 如果文件不存在（首次使用），使用 evolution/seed/strategy-rankings.md 中的种子排名

**b) 加载相似项目经验**

扫描 `evolution/projects/` 目录（如果存在且非空）：
- 读取每个项目日志的"经验标签"部分
- 与当前项目的意图锚点关键词匹配
- 如果找到匹配度高的历史项目：
  向用户提示："💡 发现相似项目「{项目名}」，其最有效策略为 {TOP3}。参考该经验？(Y/N)"
  用户回复 Y → 加载该项目的策略排名

### 步骤 0.6：向用户报告启动信息

向用户输出以下信息：

```
🚀 需求优化启动

项目：{项目名}
达标线：{target_score} 分
最大轮次：{max_rounds}
输出目录：{output_dir}

正在进入知识引擎前置侦察...
```

然后立即进入阶段一。

---

## 四、阶段一：知识引擎前置侦察

如果 state.json 中 offline = true：
  向用户提示："📴 离线模式，跳过前置侦察"
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
🔍 前置侦察完成

已搜索竞品、行业标准、用户痛点等外部信息。
领域简报已保存到 .require-agent/projects/{项目名}/domain-brief.md

进入广度扫描...
```

更新 `state.json`：`phase → breadth_scan`

---

## 五、阶段二：广度扫描

目标：从零建立需求文档基线，得到首次评分。

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
>     // 以下按需维度仅在对应 Agent 已启用时包含
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

### 步骤 2.5.1：按需 Agent 自动建议

在基线评分完成后，扫描 v2 文档内容中的关键词，检测是否应建议启用按需 Agent：

1. 扫描文档，按以下规则检测：
   - 文档含"登录"、"密码"、"权限"、"认证"、"支付"、"加密"中任意一个 → 建议 **security**
   - 文档含"并发"、"响应时间"、"QPS"、"可用性"、"性能"中任意一个 → 建议 **performance**
   - 文档含"多语言"、"国际化"、"无障碍"、"屏幕阅读器"、"适配"中任意一个 → 建议 **accessibility-i18n**
   - 文档中出现 3 个以上核心业务实体（如用户、订单、商品、账户等名词实体） → 建议 **data**
   - 文档含"第三方"、"API"、"SDK"、"微信"、"支付宝"、"推送"、"短信"中任意一个 → 建议 **dependency**

2. 过滤掉已在 `enabled_agents` 中的 Agent（避免重复建议）。

3. 如果有建议项，向用户提示：

```
🔍 检测到需求文档涉及以下领域，建议启用按需 Agent：
- {agent名}: 检测到关键词 "{匹配的关键词}"
- ...

请选择：
  Y — 全部启用
  N — 不启用
  或输入 Agent 名称选择性启用（如：security,data）
```

4. 根据用户回复更新 `enabled_agents`：
   - Y → 将所有建议的 Agent 加入 `enabled_agents`
   - N → 不做更改
   - 指定名称（如 `security,data`）→ 只将指定的 Agent 加入 `enabled_agents`

5. 更新 `state.json` 的 `enabled_agents` 字段。

### 步骤 2.6：向用户展示基线评分

向用户输出以下信息：

```
📊 基线评分（广度扫描完成）

| 维度 | 分数 | 达标线 | 状态 |
|------|------|--------|------|
| 完整性 | {分数} | {target_score} | {≥达标线 ? ✅ : ❌} |
| 一致性 | {分数} | {target_score} | {≥达标线 ? ✅ : ❌} |
| 可行性 | {分数} | {target_score} | {≥达标线 ? ✅ : ❌} |
| 用户旅程 | {分数} | {target_score} | {≥达标线 ? ✅ : ❌} |
| 业务闭环 | {分数} | {target_score} | {≥达标线 ? ✅ : ❌} |
{如果 security 在 enabled_agents 中}
| 安全 | {分数} | {target_score} | {≥达标线 ? ✅ : ❌} |
{如果 performance 在 enabled_agents 中}
| 性能 | {分数} | {target_score} | {≥达标线 ? ✅ : ❌} |
{如果 accessibility-i18n 在 enabled_agents 中}
| 无障碍与国际化 | {分数} | {target_score} | {≥达标线 ? ✅ : ❌} |
{如果 data 在 enabled_agents 中}
| 数据 | {分数} | {target_score} | {≥达标线 ? ✅ : ❌} |
{如果 dependency 在 enabled_agents 中}
| 依赖与集成 | {分数} | {target_score} | {≥达标线 ? ✅ : ❌} |

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
- 用户回复 Y（或 yes、继续、好 等肯定词）→ 进入阶段三
- 用户回复 N（或 no、不了、够了 等否定词）→ 跳到阶段五（交付）
- 如果所有维度已经 ≥ 达标线 → 向用户说明已达标，询问是否仍要继续优化

### 步骤 2.7：建立范围基线

从 v2 文档中提取所有功能点，创建 `scope-baseline.json`：

```json
{
  "version": "v2",
  "feature_count": <功能点总数>,
  "features": [
    "功能点 1 名称",
    "功能点 2 名称",
    ...
  ],
  "created_at": "{当前 ISO 时间戳}"
}
```

保存到 `.require-agent/projects/{项目名}/scope-baseline.json`。

> 这个基线在后续优化中用于检测范围蠕变——如果功能点数量增长超过基线的 50%，需要向用户发出警告。

### 步骤 2.7.1：模块化检测

统计 v2 文档中的功能模块数量（按一级功能章节计数）：

- 模块数 ≤ 3 → 保持单文件，跳过
- 模块数 4-8 → 向用户建议：
  "📂 检测到 {N} 个功能模块，建议拆分为模块化文档。拆分？(Y/N)"
  Y → 执行拆分  N → 保持单文件
- 模块数 > 8 → 自动拆分

**执行拆分**：
1. 创建 {output_dir}/modules/ 目录
2. 将每个功能模块章节提取为独立文件：modules/01-{模块名}.md
3. 将 requirement-overview.md 改写为概览（用 templates/requirement-overview-modular.md 模板）
4. 在 state.json 中标记 `"modular": true`

如果不拆分，在 state.json 中标记 `"modular": false`。

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
    "business_loop": <分数>,
    // 以下按需维度仅在对应 Agent 已启用时包含
    "security": <分数>,
    "performance": <分数>,
    "accessibility_i18n": <分数>,
    "data": <分数>,
    "dependency": <分数>
  },
  "updated_at": "{当前 ISO 时间戳}"
}
```

---

## 六、阶段三：深度优化循环

每一轮执行以下步骤。进入循环前，设置 `current_version` 为最新版本号（广度扫描后为 `v2`）。

### 步骤 3.1：选择目标维度

如果 state.json 中 modular = true：
  1. 先确定最低分模块（按模块级评分，功能点数加权）
  2. 再确定该模块最低分维度
  3. 向用户展示：
     "🔄 深度优化 — 第 {N}/{max} 轮
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

**提前退出检查**：如果最低分 ≥ `target_score`，说明所有维度都已达标 → 跳到阶段四（终审）。

**跳过已停滞维度**：如果最低分维度在 `stalled_dimensions` 列表中，选择下一个最低分维度（不在停滞列表中的）。如果所有未达标维度都在停滞列表中 → 跳到阶段四（终审）。

向用户展示轮次进度：

```
🔄 深度优化 — 第 {current_round}/{max_rounds} 轮

目标维度：{维度名称}（当前 {分数} 分，达标线 {target_score} 分）
```

### 步骤 3.2：优化 — 调度维度专属 Agent

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

### 步骤 3.3：红队挑战 — 调度 red-team Agent

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

### 步骤 3.4：写手整合 — 调度 writer Agent

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

### 步骤 3.5：评分 — 调度 evaluator Agent

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
>     "business_loop": <分数>,
>     // 以下按需维度仅在对应 Agent 已启用时包含
>     "security": <分数>,
>     "performance": <分数>,
>     "accessibility_i18n": <分数>,
>     "data": <分数>,
>     "dependency": <分数>
>   },
>   "average": <所有启用维度的平均分>,
>   "maturity": "<成熟度阶段>",
>   "previous_target_score": <目标维度上一轮分数>,
>   "current_target_score": <目标维度本轮分数>
> }
> ```

### 步骤 3.6：决策 — 保留或回滚

比较目标维度的新旧分数：

**分数上升（新分 > 旧分）**：
- 保留新版本，不做回滚
- 向用户展示：`✅ {维度名}：{旧分} → {新分}`
- 清除该维度的连续无提升计数

**分数未变或下降（新分 ≤ 旧分）**：
- 回滚到上一版本：将上一版本快照复制回 `{output_dir}/requirement-overview.md`
- 删除本轮新增的版本快照文件
- 向用户展示：`⏹ {维度名}：无提升（{旧分} → {新分}），已回滚到上一版本`
- 将评分记录中的 scores 恢复为上一轮的分数
- 增加该维度的连续无提升计数

### 步骤 3.7：终止检查

按以下顺序检查是否终止循环：

**检查 1 — 全部达标**：
- 条件：所有已启用维度（包括按需维度）的当前分数 ≥ `target_score`
- 动作：向用户展示 `🎉 所有维度已达标！进入终审...`，跳到阶段四

**检查 2 — 轮次耗尽**：
- 条件：`current_round` ≥ `max_rounds`
- 动作：向用户展示 `⚠️ 已达最大轮次（{max_rounds}），进入终审...`，跳到阶段四

**检查 3 — 单维度停滞**：
- 条件：某维度连续 2 轮作为目标维度但分数未提升
- 动作：将该维度加入 `stalled_dimensions` 列表，向用户展示 `⚠️ {维度名} 已达当前优化上限（{分数} 分），后续轮次将跳过`

**检查 4 — 全面停滞**：
- 条件：所有未达标维度都在 `stalled_dimensions` 列表中
- 动作：向用户展示 `⚠️ 所有可优化维度均已停滞，进入终审...`，跳到阶段四

**如果未触发任何终止条件**：继续下一轮。

### 步骤 3.7.1：跨模块一致性检查（仅模块化模式，每 3 轮一次）

如果 modular = true 且 current_round % 3 == 0：

调度 consistency Agent：
"请对以下模块化文档进行跨模块一致性检查。

概览文档：
{requirement-overview.md 内容}

各模块摘要（每个模块前 20 行）：
{各模块前 20 行}

检查：模块间术语统一、业务规则不矛盾、依赖关系准确。"

如发现问题 → 在下一轮优先处理

### 步骤 3.8：更新状态

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
      "score_change": "{旧分} → {新分}",
      "version": "v{版本号}"
    }
  ],
  "updated_at": "{当前 ISO 时间戳}"
}
```

**策略有效性记录**：

将本轮策略使用结果追加到 `evolution/strategies/effectiveness.json`：
- 如果文件不存在，创建空数组 `[]`
- 追加一条记录：
  ```json
  {
    "dimension": "{目标维度}",
    "strategy": "{使用的策略名}",
    "result": "improved / rolled_back / stalled",
    "score_change": "{分数变化}",
    "project": "{项目名}",
    "date": "{当前日期}"
  }
  ```

回到步骤 3.1，开始下一轮。

---

## 七、阶段四：终审

### 步骤 4.1：最终评分 — 调度 evaluator Agent

使用 `SendMessage` 向 **evaluator** Agent 发送以下指令：

> **输入**：将当前最终版本文档的完整内容附在消息中。
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
> 2. **引用正确**：文档内的交叉引用是否都指向正确的位置
> 3. **术语统一**：全文是否使用了统一的术语，无混用现象
> 4. **格式规范**：表格、列表、标题层级是否规范一致
>
> 如果发现终审问题，在优化建议部分指出。
>
> 需求文档：
> {最终版本文档内容}"
>
> **输出处理**：
> 1. 解析所有启用维度的最终评分
> 2. 保存到 `.require-agent/projects/{项目名}/scores/final.json`

### 步骤 4.2：如果终审发现问题 — 最终修正

如果 evaluator 在终审中指出了章节过渡、引用、术语、格式方面的具体问题：

使用 `SendMessage` 向 **writer** Agent 发送修正指令：

> "你是写手 Agent。这是终审修正，请只修复以下具体问题，不要添加新内容、不要改变文档结构：
>
> {evaluator 指出的终审问题列表}
>
> 在变更记录中记录：版本 v{final}，轮次 终审，来源 evaluator, writer。
>
> 当前文档：
> {最终版本文档内容}"

将修正后的文档保存为最终版本。

### 步骤 4.3：向用户展示终审结果

```
📋 终审完成

| 维度 | 最终分数 | 达标线 | 状态 |
|------|---------|--------|------|
| 完整性 | {分数} | {target_score} | {状态} |
| 一致性 | {分数} | {target_score} | {状态} |
| 可行性 | {分数} | {target_score} | {状态} |
| 用户旅程 | {分数} | {target_score} | {状态} |
| 业务闭环 | {分数} | {target_score} | {状态} |
{如果 security 在 enabled_agents 中}
| 安全 | {分数} | {target_score} | {状态} |
{如果 performance 在 enabled_agents 中}
| 性能 | {分数} | {target_score} | {状态} |
{如果 accessibility-i18n 在 enabled_agents 中}
| 无障碍与国际化 | {分数} | {target_score} | {状态} |
{如果 data 在 enabled_agents 中}
| 数据 | {分数} | {target_score} | {状态} |
{如果 dependency 在 enabled_agents 中}
| 依赖与集成 | {分数} | {target_score} | {状态} |

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

更新 `state.json`：`phase → delivery`。

---

## 八、阶段五：交付输出

### 步骤 5.1：生成 changelog.md

在 `{output_dir}/` 下创建 `changelog.md`，内容为所有轮次的变更记录表格：

```markdown
# 变更记录

| 轮次 | 目标维度 | 动作 | 分数变化 | 版本 |
|------|---------|------|---------|------|
| 广度扫描 | 全维度 | 建立基线 | — | v2 |
| 第 1 轮 | {维度} | {improved/rolled_back/stalled} | {旧→新} | v{N} |
| 第 2 轮 | {维度} | {improved/rolled_back/stalled} | {旧→新} | v{N} |
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
{如果 security 在 enabled_agents 中}
| 安全 | {初始} | {最终} | {+差值} |
{如果 performance 在 enabled_agents 中}
| 性能 | {初始} | {最终} | {+差值} |
{如果 accessibility-i18n 在 enabled_agents 中}
| 无障碍与国际化 | {初始} | {最终} | {+差值} |
{如果 data 在 enabled_agents 中}
| 数据 | {初始} | {最终} | {+差值} |
{如果 dependency 在 enabled_agents 中}
| 依赖与集成 | {初始} | {最终} | {+差值} |

## 优化过程摘要

{对每一轮的简要描述：目标维度、做了什么、结果如何}

## 停滞维度

{如果有停滞维度，说明哪些维度达到上限以及最终分数}

## 未解决问题

{如果文档中存在 [冲突待解决] 标记，在此列出}
```

数据来源：`scores/` 目录下的评分文件和 `state.json`。

### 步骤 5.3：生成 open-questions.md

扫描最终版本文档，提取所有包含以下标记的内容：
- `[冲突待解决]`
- `[待讨论]`
- `[待确认]`
- `[TBD]`

在 `{output_dir}/` 下创建 `open-questions.md`：

```markdown
# 开放问题

以下问题在优化过程中未能完全解决，需要人工决策。

| # | 问题 | 来源章节 | 标记类型 |
|---|------|---------|---------|
| 1 | {问题描述} | {所在章节} | {标记类型} |
| 2 | {问题描述} | {所在章节} | {标记类型} |
```

如果没有找到任何标记，文件内容为：

```markdown
# 开放问题

所有问题均已在优化过程中解决，无待处理事项。
```

### 步骤 5.4：向用户展示最终交付

```
✅ 需求文档优化完成！

📁 输出文件：
  {output_dir}/
  ├── requirement-overview.md  ← 最终需求文档
  ├── changelog.md             ← 变更记录
  ├── report.md                ← 优化报告
  └── open-questions.md        ← 开放问题

📦 工作区：
  .require-agent/projects/{项目名}/
  ├── state.json               ← 项目状态
  ├── intent-anchor.json       ← 意图锚点
  ├── scope-baseline.json      ← 范围基线
  ├── versions/                ← 所有版本快照
  └── scores/                  ← 所有轮次评分

后续可用操作：
  /require --resume {项目名}   ← 恢复优化
  /require --file <路径>        ← 基于文件重新开始
```

### 步骤 5.4.1：收集用户满意度

向用户提问：
"📝 请对本次优化结果打分（1-10，输入数字，或 skip 跳过）："

如果用户输入数字：
  保存到 state.json 的 `user_satisfaction` 字段
  追问："有什么建议或反馈吗？（输入 skip 跳过）"
  保存到 state.json 的 `user_feedback` 字段

### 步骤 5.5：写入进化日志

读取 `evolution/templates/project-log-template.md` 模板，用当前项目数据填充所有占位符。

数据来源：
- 基本信息 → state.json
- 评分变化 → scores/ 中 round-0.json（初始）和 final.json（最终）
- 策略有效性 → state.json 的 round_history
- 最有效策略 → round_history 中 action=improved，按 score_change 排序取 TOP3
- 无效策略 → round_history 中 action=rolled_back 或 stalled
- 用户满意度 → state.json 的 user_satisfaction 和 user_feedback
- 经验标签 → intent-anchor.json

保存到 `evolution/projects/{项目名}-{日期}.md`。如果目录不存在则创建。

### 步骤 5.6：释放锁

删除 `.require-agent/projects/{项目名}/lock.json`（如果存在）。

更新 `state.json`：`phase → completed`。

---

## 九、状态恢复协议

当通过 `--resume` 恢复项目时，根据 `state.json` 中的 `phase` 字段决定恢复位置：

| phase 值 | 恢复动作 |
|-----------|---------|
| `initialization` | 重新开始阶段零（罕见，通常是初始化中断） |
| `breadth_scan` | 检查 versions/ 目录中已有的版本，从中断的步骤继续 |
| `deep_optimization` | 读取 `current_round` 和 `scores`，从步骤 3.1 开始下一轮 |
| `final_review` | 从阶段四步骤 4.1 开始 |
| `delivery` | 从阶段五步骤 5.1 开始 |
| `completed` | 向用户报告"该项目已完成"，展示输出文件路径 |

恢复时必须：
1. 读取 `intent-anchor.json` 恢复意图锚点
2. 读取最新版本文档（versions/ 目录中版本号最大的文件）
3. 读取最新评分（scores/ 目录中轮次最大的文件）
4. 向用户展示恢复信息："正在恢复项目 {项目名}，当前阶段：{phase}，轮次：{current_round}"

---

## 十、范围蠕变检测

在每轮写手整合后（步骤 3.4），执行范围蠕变检测：

1. 从新版本文档中提取功能点列表
2. 与 `scope-baseline.json` 中的功能点数量比较
3. 如果功能点数量增长超过基线的 **50%**：
   - 向用户发出警告：
     ```
     ⚠️ 范围蠕变警告
     基线功能点：{基线数量}
     当前功能点：{当前数量}（增长 {百分比}%）

     新增功能点：
     - {新增功能 1}
     - {新增功能 2}
     ...

     是否接受这些新增功能？(Y/N)
     ```
   - 用户回复 Y → 更新 scope-baseline.json 为新基线
   - 用户回复 N → 要求 writer 在下轮整合时移除新增的功能点

---

## 十一、错误处理

### Agent 调度失败

如果向某个 Agent 发送消息后未收到有效响应：
1. 重试一次（同样的输入和指令）
2. 如果重试仍然失败，向用户报告错误并跳过该步骤
3. 在 `state.json` 中记录错误：`"errors": [{"round": N, "agent": "xxx", "step": "xxx", "message": "xxx"}]`

### 文件操作失败

如果读写文件失败：
1. 检查目录是否存在，不存在则创建
2. 重试一次
3. 仍然失败则向用户报告错误并提供手动修复建议

### 评分解析失败

如果无法从 evaluator 的输出中解析出分数：
1. 向 evaluator 重新发送请求，明确要求"请严格按照输出格式返回，每个维度的分数必须是 0-10 的整数"
2. 如果仍然无法解析，向用户展示 evaluator 的原始输出，请用户手动输入分数

---

## 十二、锁机制

### 锁获取（步骤 0.2 之后执行）

检查 `.require-agent/projects/{项目名}/lock.json`：

如果不存在 → 创建锁：
```json
{
  "locked": true,
  "user": "current",
  "started": "{ISO 时间}",
  "last_heartbeat": "{ISO 时间}",
  "project": "{项目名}"
}
```

如果存在：
  读取 last_heartbeat，如果 > 2 分钟前 → 视为过期，覆盖创建新锁
  否则 → 提示用户：
  "⚠️ 另一个会话正在优化「{project}」。
   使用 --force 可强制接管。"
  如果用户未使用 --force → 终止

### 锁释放（步骤 5.6）

在阶段五结束后删除 lock.json。
在错误处理中也尝试释放锁。

---

## 十三、团队协作模式

### --collab 模式

如果用户使用了 --collab：
1. 在 {output_dir}/team-input/ 下生成三个输入模板（基于 templates/team-input-template.md）：
   - pm-input.md（role: 产品经理）
   - dev-input.md（role: 开发）
   - design-input.md（role: 设计师）
2. 提示："团队输入模板已生成到 {output_dir}/team-input/，请各角色填写后运行 /require --merge-input"
3. 终止流程等待填写

### --merge-input 模式

如果用户使用了 --merge-input：
1. 读取 {output_dir}/team-input/ 下所有文件
2. 解析补充需求、质疑点、约束
3. 共识（多人提到的）→ 直接纳入 raw_input
4. 分歧（有人赞成有人反对）→ 标记 [团队分歧待讨论]
5. 将合并结果作为 raw_input 继续正常流程

### --review 模式

如果用户使用了 --review：
1. 读取 requirement-overview.md（及 modules/ 如模块化）
2. 扫描 <!-- @review xxx: yyy --> 标注
3. 提取评审意见列表
4. 将意见作为优化输入调度 Agent 处理
5. 冲突意见标记为决策点

### --role 接力模式

如果 --resume 带有 --role 参数：
  根据角色调整偏好：
  - pm → 侧重业务闭环和用户旅程（达标线 +1）
  - developer → 侧重可行性和数据（达标线 +1）
  - designer → 侧重用户旅程和无障碍（达标线 +1）
