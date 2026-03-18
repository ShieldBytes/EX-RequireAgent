<!-- 本文件是 EX-RequireAgent 编排器的子模块，由主命令 .claude/commands/require.md 引用 -->
<!-- 不要直接运行本文件，它通过 Read 工具被加载 -->

# 进化系统：经验加载与反馈

本模块包含智能经验加载、用户满意度收集、进化日志写入和自动推送功能。

**重要路径约定：** 所有 `evolution/` 路径实际指向全局目录 `~/.claude/ex-require-agent/evolution/`。项目目录下的 `./evolution/` 是指向全局目录的软链接，读写效果相同。

---

## 步骤 0.5.1：智能经验加载

在初始化状态（步骤 0.5）完成后执行。

如果 config.json 中 auto_sync = true 且 evolution_repo 不为空：
  使用 Bash 执行静默 pull：
  ```
  mkdir -p .require-agent/sync-tmp
  git clone --depth 1 {evolution_repo} .require-agent/sync-tmp/repo 2>/dev/null
  ```
  如果克隆成功 -> 将新文件复制到本地 evolution/ 对应目录，更新 last_sync
  如果克隆失败 -> 提示 "无法同步团队经验，使用本地数据"，继续
  清理临时目录

### a) 按相关性过滤加载

扫描 `evolution/strategies/` 下所有 .json 文件和 `evolution/projects/` 下所有 .md 文件。

不全量加载，而是：
1. 读取每个文件的项目名和关键词
2. 与当前项目的意图锚点（intent-anchor.json）关键词匹配
3. 按相关性分类：
   - 高相关：项目类型相同或有 2+ 共同关键词
   - 中相关：有 1 个共同关键词
   - 低相关：无交集
4. 只加载高相关和中相关的文件
5. 检查 config.json 的 sync_ignore_list，跳过被屏蔽的经验

向用户展示："加载团队经验：共 {总数} 个项目，{加载数} 个相关，已加载"

### b) 多因子推荐排序

对加载的策略记录按以下公式计算推荐分：

```
策略推荐分 = 成功率 * 0.3 + 平均提升分归一化 * 0.25 + 时间衰减 * 0.15 + 质量权重 * 0.15 + 验证次数归一化 * 0.1 + 争议度惩罚 * 0.05

时间衰减：0-30天=1.0，31-90天=0.8，91-180天=0.5，>180天=0.3
质量权重：user_avg_satisfaction * project_satisfaction / 100
争议度：同维度同策略的标准差 > 1.5 则为争议策略，惩罚系数 0.5
```

按维度输出策略推荐排名，写入 state.json 的 strategy_preferences 字段。

### c) 争议策略检测

如果某策略在同维度下标准差 > 1.5：
标记为争议策略，加载时不自动应用，而是展示给用户：
"争议策略：{策略名} 在 {维度} 中存在分歧
 {用户A}({N次}) 认为有效，{用户B}({M次}) 认为无效
 是否在本项目中尝试？(Y/N)"

### d) 新发现通知

如果本次 pull 有新增内容（last_sync 之后）：
扫描新文件中的高分策略（推荐分 > 0.8）：
"团队新发现（上次同步后新增 {N} 个项目经验）：
 - {策略名} 在 {维度} 中成功率 {X}%（{N}个项目验证）
 已自动纳入策略优先级。"

无新内容 -> 静默不打扰

### e) 预测分析

如果找到 3+ 个相似历史项目：
"基于团队 {N} 个相似项目经验：
 预计轮次：{min}-{max} 轮
 最难维度：{维度名}（历史平均最终分 {分数}）
 建议重点：前 3 轮集中攻 {最有效维度}"

记录加载了哪些经验到 state.json 的 loaded_experience 字段（经验文件 ID 列表）。

### f) 自动策略生成

如果某维度在 evolution/strategies/ 中积累了 >= 20 条策略记录：

1. 分析该维度所有成功记录（result=improved）的模式：
   - 哪些策略组合经常连续成功
   - 哪些项目类型下哪些策略效果最好

2. 如果发现明确模式（如"电商项目先用功能遍历法再用角色扮演法，比反过来好"）：
   生成实验性策略，保存到 `evolution/strategies/generated/` 目录：
   ```json
   {
     "name": "{自动生成的策略名}",
     "generated_from": "{基于 N 个项目的成功模式}",
     "applicable_types": ["{适用的项目类型}"],
     "dimension": "{适用维度}",
     "steps": ["{策略步骤1}", "{策略步骤2}"],
     "expected_improvement": "+{预期提升} 分",
     "confidence": "低/中/高（基于样本量）",
     "status": "experimental",
     "created_at": "{日期}",
     "usage_count": 0,
     "success_count": 0
   }
   ```

3. 向用户通知：
   "基于团队数据发现新策略模式：
    {策略名}（适用于{项目类型}的{维度}维度）
    预期提升：+{分数} 分
    标记为实验性，使用后自动追踪效果。"

4. 在步骤 3.2 选策略时：
   如果有 experimental 状态的生成策略适用于当前维度和项目类型：
   提示用户："有一个实验性策略可用：{策略名}。尝试？(Y/N)"
   用户选 Y -> 使用，结果记录到生成策略的 usage_count 和 success_count
   usage_count >= 3 且 success_count/usage_count >= 0.7 -> 升级为正式策略（status: "proven"）

---

## 步骤 5.4.1：收集用户满意度

在交付输出展示完成后（步骤 5.4 之后）执行。

向用户提问：
"请对本次优化结果打分（1-10，输入数字，或 skip 跳过）："

如果用户输入数字：
  保存到 state.json 的 `user_satisfaction` 字段
  追问："有什么建议或反馈吗？（输入 skip 跳过）"
  保存到 state.json 的 `user_feedback` 字段

---

## 步骤 5.5：写入进化日志

读取 `evolution/templates/project-log-template.md` 模板，用当前项目数据填充所有占位符。

数据来源：
- 基本信息 -> state.json
- 评分变化 -> scores/ 中 round-0.json（初始）和 final.json（最终）
- 策略有效性 -> state.json 的 round_history
- 最有效策略 -> round_history 中 action=improved，按 score_change 排序取 TOP3
- 无效策略 -> round_history 中 action=rolled_back 或 stalled
- 用户满意度 -> state.json 的 user_satisfaction 和 user_feedback
- 经验标签 -> intent-anchor.json

保存到 `evolution/projects/{项目名}-{日期}-{user_id}.md`（user_id 从 config.json 读取）。如果目录不存在则创建。

策略记录也用零冲突格式：`{项目名}-{日期}-{user_id}.json`，保存到 `evolution/strategies/`。

记录中包含经验反馈回路数据：
```
对比 state.json 的 loaded_experience 列表：
对每条加载的经验，记录：
- 该经验推荐了什么策略
- 本项目实际是否使用了该策略
- 使用结果如何（improved/stalled/rolled_back）
将反馈写入进化日志的 "经验反馈" 部分
```

---

## 步骤 5.5.1：自动推送进化数据

读取 config.json：
- 如果 auto_sync = false 或 evolution_repo 为空 -> 跳过
- 如果 state.json 中 sync = false（--private 项目）->
  向用户提问："本项目为私有模式。是否推送脱敏后的策略数据？(Y/N)"
  Y -> 只推送 strategy_only 级别数据
  N -> 跳过

执行推送：
1. 创建临时目录，克隆共享仓库（浅克隆）
2. 按 share_level 脱敏处理本次新生成的进化文件
3. 复制到仓库对应目录
4. 追加审计日志到 sync-log.jsonl
5. git add + commit + push
6. 清理临时目录
7. 更新 last_sync

推送成功 -> "进化数据已同步到团队（{N} 个文件）"
推送失败 -> 写入 .require-agent/sync-queue.json，提示 "自动推送失败，已存入队列，可用 /require-sync push 手动重试"

---

## 策略有效性记录（步骤 3.8 调用）

每轮深度优化结束后（步骤 3.8），将本轮策略使用结果追加到 `evolution/strategies/effectiveness.json`：
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
