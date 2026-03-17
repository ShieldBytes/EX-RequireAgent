<!-- 本文件是 EX-RequireAgent 编排器的子模块，由主命令 .claude/commands/require.md 引用 -->
<!-- 不要直接运行本文件，它通过 Read 工具被加载 -->

# 评分系统：统一评分协议

本模块集中定义 evaluator 的调度指令模板、评分结果解析规则、评分保存格式和分数比较逻辑。
在广度扫描（2.5）、深度优化（3.5）、终审（4.1）三个阶段被引用。

---

## 一、Evaluator 调度指令模板

### 通用评分指令

向 **evaluator** Agent 发送评分请求时，使用以下模板：

```
你是评估 Agent。请对以下需求文档进行{评分类型}评估。

按照以下维度评分：完整性、一致性、可行性、用户旅程、业务闭环
{动态维度部分，根据 enabled_agents 动态追加}

对每个启用的维度按 0-10 分评分。判定成熟度阶段，并给出优化建议。

严格按照你定义的输出格式输出。

需求文档：
{文档内容}
```

### 动态维度生成规则

根据 `state.json` 的 `enabled_agents` 字段动态生成评分维度：

| enabled_agents 中包含 | 追加评分维度 |
|----------------------|------------|
| security | 安全 |
| performance | 性能 |
| accessibility-i18n | 无障碍与国际化 |
| data | 数据 |
| dependency | 依赖与集成 |

基础 5 个维度始终包含：完整性、一致性、可行性、用户旅程、业务闭环。

### 各阶段评分类型差异

| 阶段 | 评分类型 | 额外指令 |
|------|---------|---------|
| 广度扫描（2.5） | 全面评估 | 无 |
| 深度优化（3.5） | 全面评估 | 无 |
| 终审（4.1） | 全面终审评分 | 额外检查：章节过渡、引用正确、术语统一、格式规范 |

终审额外指令：
```
除了维度评分外，请额外检查以下终审项目：
1. 章节过渡：各章节之间的逻辑衔接是否自然
2. 引用正确：文档内的交叉引用是否都指向正确的位置
3. 术语统一：全文是否使用了统一的术语，无混用现象
4. 格式规范：表格、列表、标题层级是否规范一致

如果发现终审问题，在优化建议部分指出。
```

---

## 二、评分结果解析规则

从 evaluator 的输出中提取以下信息：

1. **维度分数**：解析每个维度的分数（0-10 整数）
   - 搜索格式：`维度名: X分` 或 `维度名: X/10` 或表格格式
   - 如果找不到明确分数，尝试从文本描述推断
   - 如果仍然无法解析 -> 触发错误处理（见 `skills/require-utils.md`）

2. **成熟度阶段**：解析成熟度判定
   - 可能的值：草稿阶段、结构化阶段、详细阶段、完善阶段、生产就绪

3. **优化建议**：提取 evaluator 给出的改进建议原文

4. **终审问题**（仅终审阶段）：提取章节过渡、引用、术语、格式方面的具体问题

---

## 三、评分保存格式

### 广度扫描评分（round-0.json）

```json
{
  "round": 0,
  "phase": "breadth_scan",
  "version": "v2",
  "scores": {
    "completeness": <分数>,
    "consistency": <分数>,
    "feasibility": <分数>,
    "user_journey": <分数>,
    "business_loop": <分数>
  },
  "average": <所有启用维度的平均分>,
  "maturity": "<成熟度阶段>",
  "suggestions": "<evaluator 的优化建议原文>"
}
```

注意：scores 对象中，按需维度仅在对应 Agent 已启用时包含。

### 深度优化评分（round-N.json）

```json
{
  "round": {current_round},
  "phase": "deep_optimization",
  "target_dimension": "{目标维度英文名}",
  "version": "v{N+1}",
  "scores": {
    "completeness": <分数>,
    "consistency": <分数>,
    "feasibility": <分数>,
    "user_journey": <分数>,
    "business_loop": <分数>
  },
  "average": <所有启用维度的平均分>,
  "maturity": "<成熟度阶段>",
  "previous_target_score": <目标维度上一轮分数>,
  "current_target_score": <目标维度本轮分数>
}
```

### 终审评分（final.json）

```json
{
  "round": "final",
  "phase": "final_review",
  "version": "v{final}",
  "scores": {
    "completeness": <分数>,
    "consistency": <分数>,
    "feasibility": <分数>,
    "user_journey": <分数>,
    "business_loop": <分数>
  },
  "average": <所有启用维度的平均分>,
  "maturity": "<成熟度阶段>",
  "review_issues": ["终审发现的问题列表"]
}
```

保存路径：`.require-agent/projects/{项目名}/scores/`

---

## 四、分数比较逻辑

### 新旧分数对比（步骤 3.6 使用）

```
输入：目标维度名、上一轮分数、本轮分数
逻辑：
  如果 本轮分数 > 上一轮分数：
    结果 = "improved"
    动作 = 保留新版本
  如果 本轮分数 <= 上一轮分数：
    结果 = "stalled" 或 "rolled_back"
    动作 = 回滚到上一版本
```

### 最低分查找（步骤 3.1 使用）

```
输入：scores 对象、stalled_dimensions 列表、enabled_agents 列表
逻辑：
  1. 过滤出已启用且未停滞的维度
  2. 找到分数最低的维度
  3. 如果有并列，按优先级排序：
     completeness > user_journey > business_loop > consistency > feasibility
     > security > performance > accessibility_i18n > data > dependency
  4. 如果最低分 >= target_score -> 返回"全部达标"
  5. 如果过滤后无可选维度 -> 返回"全面停滞"
```

### 达标检查

```
输入：scores 对象、target_score、enabled_agents 列表
逻辑：
  遍历所有已启用维度的分数：
    如果任何一个 < target_score -> 未达标
  所有维度都 >= target_score -> 达标
```

### 评分校准

当用户对评分提出异议时：
1. 记录原始 Agent 评分和用户调整方向
2. 追加到 `evolution/calibration/history.json`
3. 在当前项目中使用用户调整后的分数继续流程
4. 校准数据格式：
   ```json
   {
     "project": "{项目名}",
     "round": "{轮次标识}",
     "dimension": "{维度}",
     "agent_score": "{Agent分}",
     "user_adjusted": "{用户调整分}",
     "direction": "up/down",
     "date": "{日期}"
   }
   ```
