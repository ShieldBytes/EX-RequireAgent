<!-- 本文件是 EX-RequireAgent 编排器的子模块，由主命令 .claude/commands/require.md 引用 -->
<!-- 不要直接运行本文件，它通过 Read 工具被加载 -->

# 阶段零：初始化

严格按照以下步骤顺序执行初始化流程。

---

## 步骤 0.0：首次使用检测

检查 `.require-agent/config.json` 是否存在：

如果不存在（首次使用）：
  向用户展示：
  "欢迎使用 EX-RequireAgent！

   快速配置（直接回车使用默认值）：
   1. 输出目录？(默认 ./docs/requirements/)
   2. 默认达标分数？(默认 7，范围 1-10)
   3. 你的标识？(用于团队协作中区分成员，建议英文名或工号，默认读取 git config user.name)
   4. 共享级别？(full=完整/anonymized=匿名/strategy_only=仅策略/none=不共享，默认 full)"

  等待用户回复后创建 `.require-agent/config.json`：
  ```json
  {
    "output_dir": "{用户选择或默认 ./docs/requirements/}",
    "target_score": {用户选择或默认 7},
    "user_id": "{用户输入或 git config user.name 或 anonymous-xxxx}",
    "share_level": "{full/anonymized/strategy_only/none，默认 full}",
    "auto_sync": {share_level 不是 none 则 true，否则 false},
    "last_sync": null,
    "sync_ignore_list": [],
    "first_run": false
  }
  ```

  注意：共享仓库地址不再需要用户配置，安装脚本已在 `~/.claude/ex-require-agent/evolution/` 中自动关联了默认共享仓库。

如果已存在 -> 读取配置。如果缺少以下字段，用默认值补全：
  - user_id：默认从 git config user.name 获取，或 "anonymous"
  - evolution_repo：默认 ""（不共享）
  - share_level：默认 "full"
  - auto_sync：默认 false
  - public_knowledge：默认 false
  - last_sync：默认 null
  - sync_ignore_list：默认 []

---

## 步骤 0.1：解析用户输入

检查用户的输入，判断属于以下哪种情况：

### 情况 A：从想法开始（纯文字描述）

用户直接输入了文字描述的需求或想法（没有 `--file` 和 `--resume` 参数）。

- 如果输入太模糊（少于 10 个字，且无法判断要做什么产品），进入**追问模式**：
  - 向用户提问："你的想法比较简短，我需要更多信息来帮你优化。请补充以下任意一项：1) 这个产品/功能是给谁用的？2) 要解决什么问题？3) 你希望它能做什么？"
  - 等待用户回复后，将原始输入 + 补充信息合并为完整输入，继续执行。
- 如果输入足够清晰（>=10 字，或虽然短但能明确判断意图），直接继续。
- 将用户输入存储为变量 `raw_input`。

### 情况 B：从文档开始（--file 参数）

用户输入中包含 `--file <路径>` 参数。

- 使用 `Read` 工具读取指定文件内容。
- 如果文件不存在，向用户报告错误并终止。
- 将文件内容存储为变量 `raw_input`。

### 情况 C：从中断继续（--resume 参数）

用户输入中包含 `--resume` 参数（可选附带项目名）。

- 在 `.require-agent/projects/` 下查找状态文件：
  - 如果指定了项目名：读取 `.require-agent/projects/{项目名}/state.json`
  - 如果未指定项目名：列出 `.require-agent/projects/` 下所有项目目录，找到最近修改的 `state.json`
- 如果找不到状态文件，向用户报告"未找到可恢复的项目"并终止。
- 读取 `state.json`，恢复所有状态变量，从中断的阶段和轮次继续执行。

**--module 参数（可选）**：

如果用户输入包含 `--module <模块名>`（如 `--resume 项目名 --module 用户管理`）：

1. 确认项目处于模块化模式（`state.json` 中 `modular: true`）
2. 确认指定模块存在于 `{output_dir}/modules/` 目录中
3. 在 `state.json` 中设置 `focus_module` 为指定模块名
4. 向用户提示：
   ```
   已锁定聚焦模块：{模块名}
   后续所有优化轮次将只针对此模块，直到该模块所有维度达标。
   解除锁定：/require-focus --unlock
   ```
5. 如果项目不是模块化模式或模块不存在，向用户报告错误并忽略该参数，正常恢复

**用户补充说明（可选）**：

用户输入中除了 `--resume`、`--module` 等参数之外的自由文字，作为本次恢复的补充说明。

示例：
```
/require --resume 记账app --module 用户管理 "登录流程的异常处理不够细，需要补充第三方登录失败的场景"
```

处理方式：
1. 提取参数之外的自由文字部分，存储为变量 `resume_instruction`
2. 如果 `resume_instruction` 不为空：
   - 在 `state.json` 中设置 `resume_instruction` 字段为该文字
   - 向用户展示确认：`收到补充说明："{resume_instruction}"，将在下一轮优化中优先处理。`
3. 进入深度优化循环时，步骤 3.2 调度维度 Agent 时，将 `resume_instruction` 作为额外上下文附在 Agent 指令中：
   > "用户补充说明：{resume_instruction}
   > 请在优化建议中优先关注用户提出的问题。"
4. `resume_instruction` 仅影响恢复后的第一轮优化，使用后从 `state.json` 中清除（设为 null）

---

## 步骤 0.2：创建工作区

从 `raw_input` 中提取一个简短的项目名（英文小写，用连字符连接，不超过 30 字符）。例如输入"我想做一个记账 App"-> 项目名 `accounting-app`。

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

### 进化数据软链接

进化数据统一存储在全局目录 `~/.claude/ex-require-agent/evolution/`，在当前项目目录创建软链接方便查看：

```bash
# 确保全局进化目录存在
mkdir -p ~/.claude/ex-require-agent/evolution/projects
mkdir -p ~/.claude/ex-require-agent/evolution/strategies
mkdir -p ~/.claude/ex-require-agent/evolution/calibration

# 在当前项目目录创建软链接（如果不存在）
if [ ! -e "./evolution" ]; then
  ln -s ~/.claude/ex-require-agent/evolution ./evolution
fi
```

这样：
- 数据实际只存一份（全局目录）
- 任何项目目录下 `./evolution/` 都能访问全部经验
- 团队同步只操作全局目录

---

## 步骤 0.3：提取意图锚点

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

---

## 步骤 0.4：解析启动参数

从用户输入中解析以下参数（如果没有提供则使用默认值）：

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `--target` | 达标分数线，所有维度达到此分数即完成 | `7` |
| `--output` | 最终输出目录 | `./docs/requirements/{项目名}/` |
| `--max-rounds` | 最大深度优化轮次 | `10` |
| `--agents` | 启用/禁用 Agent（`+xxx` 启用，`-xxx` 禁用） | 无 |
| `--offline` | 离线模式，跳过知识引擎前置侦察 | `false` |
| `--private` | 私有项目，进化数据不推送到共享仓库 | `false` |

### `--offline` 参数处理

如果用户使用了 --offline 参数：
  在 state.json 中标记 `"offline": true`
  影响：
  - 跳过阶段一（知识引擎前置侦察）
  - knowledge-engine Agent 不被调度
  - 向用户提示："离线模式，外部搜索功能不可用"

### `--private` 参数处理

如果用户使用了 --private 参数：
  在 state.json 中标记 `"sync": false`
  向用户提示："私有模式，进化数据不会推送到团队共享仓库"

### `--agents` 参数解析规则

1. 解析参数值，以逗号分隔，逐个处理：
   - `+xxx` -> 将 `xxx` 加入 `enabled_agents` 列表
   - `-xxx` -> 将 `xxx` 从 `enabled_agents` 列表中移除
2. 将最终的 `enabled_agents` 列表保存到 `state.json`

---

## 步骤 0.5：初始化状态

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
  "focus_module": null,
  "strategy_preferences": {},
  "user_satisfaction": null,
  "user_feedback": null,
  "sync": true,
  "loaded_experience": [],
  "created_at": "{当前 ISO 时间戳}",
  "updated_at": "{当前 ISO 时间戳}"
}
```

使用 `Write` 工具写入文件。

---

## 步骤 0.6：向用户报告启动信息

向用户输出以下信息：

```
需求优化启动

项目：{项目名}
达标线：{target_score} 分
最大轮次：{max_rounds}
输出目录：{output_dir}

正在进入知识引擎前置侦察...
```

然后立即进入阶段一（加载 `modules/require-evolution.md` 中的步骤 0.5.1 智能经验加载，然后进入 `modules/require-scan.md`）。
