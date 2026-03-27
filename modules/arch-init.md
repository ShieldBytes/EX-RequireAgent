<!-- 本文件是 EX-RequireAgent 架构编排器的子模块，由主命令 .claude/commands/arch.md 引用 -->
<!-- 不要直接运行本文件，它通过 Read 工具被加载 -->

# 阶段零：初始化

严格按照以下步骤顺序执行初始化流程。

---

## 步骤 0.0：首次使用检测

检查 `.arch-agent/config.json` 是否存在：

如果不存在（首次使用）：
  向用户展示：
  "欢迎使用 EX-RequireAgent 架构设计模块！

   快速配置（直接回车使用默认值）：
   1. 输出目录？(默认 ./docs/architecture/)
   2. 默认达标分数？(默认 7，范围 1-10)
   3. 你的标识？(用于团队协作中区分成员，建议英文名或工号，默认读取 git config user.name)"

  等待用户回复后创建 `.arch-agent/config.json`：
  ```json
  {
    "output_dir": "{用户选择或默认 ./docs/architecture/}",
    "target_score": {用户选择或默认 7},
    "user_id": "{用户输入或 git config user.name 或 anonymous-xxxx}",
    "first_run": false
  }
  ```

如果已存在 -> 读取配置。如果缺少以下字段，用默认值补全：
  - user_id：默认从 git config user.name 获取，或 "anonymous"
  - target_score：默认 7
  - output_dir：默认 "./docs/architecture/"

---

## 步骤 0.1：解析用户输入

检查用户的输入，判断属于以下哪种情况：

### 情况 A：从需求文档导入（--from-require 参数）

用户输入中包含 `--from-require {项目名}` 参数。

- 读取 `.require-agent/projects/{项目名}/versions/` 目录，找到最新版本快照文件（按版本号排序取最大）。
- 将最新版本快照复制到 `.arch-agent/projects/{项目名}/requirement-snapshot.md`。
- 读取 `.require-agent/projects/{项目名}/scores/` 目录下的终版评分文件 `final.json`：
  - 计算所有维度的平均分
  - 如果平均分 < 5：向用户发出警告：
    ```
    ⚠ 警告：需求文档评分较低（平均分 {平均分}），架构设计质量可能受限。
    建议先使用 /require 将需求文档优化到达标水平后再进行架构设计。

    是否仍要继续？(Y/N)
    ```
  - 等待用户确认后继续，用户选择 N 则终止。
- 如果 `final.json` 不存在，向用户提示："未找到终版评分，将直接使用最新版本快照"。
- 将快照内容存储为变量 `requirement_input`。

### 情况 B：从外部文件导入（--file 参数）

用户输入中包含 `--file <路径>` 参数。

- 使用 `Read` 工具读取指定文件内容。
- 如果文件不存在，向用户报告错误并终止。
- 将文件内容存储为变量 `requirement_input`。

### 情况 C：从中断继续（--resume 参数）

用户输入中包含 `--resume` 参数（可选附带项目名）。

- 在 `.arch-agent/projects/` 下查找状态文件：
  - 如果指定了项目名：读取 `.arch-agent/projects/{项目名}/state.json`
  - 如果未指定项目名：列出 `.arch-agent/projects/` 下所有项目目录，找到最近修改的 `state.json`
- 如果找不到状态文件，向用户报告"未找到可恢复的架构项目"并终止。
- 读取 `state.json`，恢复所有状态变量，从中断的阶段和轮次继续执行。

**用户补充说明（可选）**：

用户输入中除了 `--resume` 等参数之外的自由文字，作为本次恢复的补充说明。

示例：
```
/arch --resume 电商平台 "支付模块需要考虑多渠道对账的场景"
```

处理方式：
1. 提取参数之外的自由文字部分，存储为变量 `resume_instruction`
2. 如果 `resume_instruction` 不为空：
   - 在 `state.json` 中设置 `resume_instruction` 字段为该文字
   - 向用户展示确认：`收到补充说明："{resume_instruction}"，将在下一轮优化中优先处理。`
3. 进入挑战循环时，将 `resume_instruction` 作为额外上下文附在 Agent 指令中：
   > "用户补充说明：{resume_instruction}
   > 请在改进建议中优先关注用户提出的问题。"
4. `resume_instruction` 仅影响恢复后的第一轮优化，使用后从 `state.json` 中清除（设为 null）

---

## 步骤 0.2：输入质量门槛检查

从 `requirement_input` 中检测以下指标：

| 指标 | 检测方式 |
|------|---------|
| 功能模块数量 | 统计文档中独立的功能域/模块/子系统 |
| 核心实体数量 | 统计文档中出现的业务实体（如用户、订单、商品等） |
| 用户角色数量 | 统计文档中提及的用户角色/类型 |

**判定规则**：

- 功能模块 >= 3 且核心实体 >= 2 → **通过**，继续执行。
- 功能模块 1-2 且核心实体 >= 1 → **警告**：
  ```
  ⚠ 需求文档信息量偏少（功能模块 {N} 个，核心实体 {M} 个）。
  架构设计可能不够充分，建议补充更多功能细节。

  是否仍要继续？(Y/N)
  ```
  等待用户确认后继续。
- 功能模块 = 0 或核心实体 = 0 → **阻断**：
  ```
  ✗ 需求文档信息不足，无法进行架构设计。

  检测结果：功能模块 {N} 个，核心实体 {M} 个
  建议先使用 /require 完善需求文档后再进行架构设计。
  ```
  终止流程。

---

## 步骤 0.3：约束收集

向用户收集项目约束条件：

```
快速配置项目约束（直接回车跳过）：
  1. 团队规模？（如：3 后端 + 2 前端 + 1 运维）
  2. 团队技术偏好？（如：Go、React、已有 Java 经验）
  3. 现有基础设施？（如：阿里云 ECS、已有 MySQL 8.0 集群）
  4. 预算范围？（如：服务器月预算 5000 元）
  5. 上线时间要求？（如：3 个月内 MVP）
  6. 合规要求？（如：等保三级、GDPR）
  7. 预期用户规模？（如：首年 10 万注册，日活 5000）
```

等待用户回复后，将约束写入 `.arch-agent/projects/{项目名}/constraints.json`：

```json
{
  "team_size": "{用户输入或 null}",
  "tech_preference": "{用户输入或 null}",
  "existing_infra": "{用户输入或 null}",
  "budget": "{用户输入或 null}",
  "timeline": "{用户输入或 null}",
  "compliance": "{用户输入或 null}",
  "expected_scale": "{用户输入或 null}",
  "collected_at": "{当前 ISO 时间戳}"
}
```

---

## 步骤 0.4：创建工作区

从 `requirement_input` 或用户参数中确定项目名（英文小写，用连字符连接，不超过 30 字符）。

创建以下目录结构：

```
.arch-agent/projects/{项目名}/
├── state.json                      # 状态文件
├── constraints.json                # 约束条件
├── requirement-snapshot.md         # 需求文档快照
├── requirement-decomposition.json  # Phase 1.5 生成：需求分解
├── tech-brief.md                   # Phase 1 生成：技术简报
├── versions/                       # 架构文档版本快照
├── scores/                         # 评分记录
└── decisions/                      # 架构决策记录（ADR）
```

使用 `Bash` 工具执行 `mkdir -p` 创建上述目录。

### 进化数据目录

进化数据统一存储在全局目录，与 /require 的进化数据隔离：

```bash
# 确保架构进化全局目录存在
mkdir -p ~/.claude/ex-require-agent/evolution/arch-strategies
mkdir -p ~/.claude/ex-require-agent/evolution/arch-projects
mkdir -p ~/.claude/ex-require-agent/evolution/arch-calibration
```

---

## 步骤 0.5：提取意图锚点

分析 `requirement_input`，提取以下信息，写入 `.arch-agent/projects/{项目名}/intent-anchor.json`：

```json
{
  "core_purpose": "用一句话描述这个系统的核心目的",
  "key_words": ["从需求文档中提取的关键业务词列表"],
  "tech_key_words": ["从需求文档中提取的技术关键词列表，如提到的技术栈、协议、平台等"],
  "explicit_requirements": ["需求文档中明确提出的架构相关需求，如高可用、低延迟等"],
  "scope_hints": ["需求文档中暗示的架构范围线索，如目标用户量、部署区域等"]
}
```

这个锚点在后续所有阶段中用于**防止架构过度设计或设计偏离**——当 Agent 提出的方案偏离核心目的时，用它来拉回。

---

## 步骤 0.6：解析启动参数

从用户输入中解析以下参数（如果没有提供则使用默认值）：

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `--target` | 达标分数线，所有维度达到此分数即完成 | `7` |
| `--output` | 最终输出目录 | `./docs/architecture/{项目名}/` |
| `--max-rounds` | 最大挑战轮次 | `8` |
| `--offline` | 离线模式，跳过技术侦察中的外部搜索 | `false` |
| `--private` | 私有项目，进化数据不推送到共享仓库 | `false` |

### `--offline` 参数处理

如果用户使用了 --offline 参数：
  在 state.json 中标记 `"offline": true`
  影响：
  - 技术侦察阶段不使用外部搜索
  - 向用户提示："离线模式，外部搜索功能不可用"

### `--private` 参数处理

如果用户使用了 --private 参数：
  在 state.json 中标记 `"sync": false`
  向用户提示："私有模式，进化数据不会推送到团队共享仓库"

---

## 步骤 0.7：初始化状态

创建 `.arch-agent/projects/{项目名}/state.json`，内容如下：

```json
{
  "project": "{项目名}",
  "phase": "initialization",
  "current_round": 0,
  "max_rounds": 8,
  "target_score": 7,
  "scores": {},
  "round_history": [],
  "stalled_dimensions": [],
  "enabled_agents": ["arch-structure", "arch-platform", "arch-interface", "arch-storage", "arch-writer", "arch-evaluator", "arch-coverage", "arch-challenger"],
  "output_dir": "./docs/architecture/{项目名}/",
  "offline": false,
  "sync": true,
  "strategy_preferences": {},
  "user_satisfaction": null,
  "user_feedback": null,
  "resume_instruction": null,
  "loaded_experience": [],
  "created_at": "{当前 ISO 时间戳}",
  "updated_at": "{当前 ISO 时间戳}"
}
```

使用 `Write` 工具写入文件。

---

## 步骤 0.8：向用户报告启动信息

向用户输出以下信息：

```
架构设计启动

项目：{项目名}
达标线：{target_score} 分
最大轮次：{max_rounds}
输出目录：{output_dir}
约束摘要：团队 {team_size}，时间 {timeline}，预算 {budget}

正在进入技术侦察与需求分解...
```

然后立即进入 Phase 1（技术侦察）和 Phase 1.5（需求分解），加载 `modules/arch-generate.md`。
