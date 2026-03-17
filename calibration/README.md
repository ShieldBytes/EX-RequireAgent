# 评分校准记录

## 用途

校准记录用于追踪 Agent 评分与用户实际评分之间的偏差，帮助 Agent 逐步提高评分准确性。

当用户对 Agent 给出的分数进行调整时，系统会自动将校准记录保存为独立文件。通过分析校准历史，Agent 可以识别自身在特定维度上的评分偏向（偏高或偏低），并在后续评分中进行修正。

## 文件命名

每人每天生成一个独立的校准记录文件，文件名格式：
`{user_id}-{日期}.json`

示例：`wangwei-2026-03-15.json`

### 文件名设计原则

- 文件名 = 用户标识 + 日期 → 全球唯一
- 多人推送到同一个 git 仓库永远不会冲突（只有新增文件，不会修改同一文件）
- 同一用户同一天的多次校准追加到同一个文件中
- 汇总数据在本地 pull 后聚合计算，不存入 git

## 文件格式

每个文件为 JSON 对象，包含当天所有校准记录：

```json
{
  "format_version": "1.0",
  "user": "user_id",
  "date": "2026-03-15",
  "records": [
    {
      "project": "项目名",
      "round": 1,
      "dimension": "维度",
      "agent_score": 6,
      "user_adjusted": 8,
      "direction": "up",
      "reason": "理由",
      "timestamp": "2026-03-15T10:30:00"
    }
  ]
}
```

### 字段说明

| 字段 | 类型 | 说明 |
|------|------|------|
| `format_version` | string | 文件格式版本 |
| `user` | string | 用户标识 |
| `date` | string | 校准日期，格式 YYYY-MM-DD |
| `records` | array | 当天所有校准记录 |
| `records[].project` | string | 项目名称 |
| `records[].round` | number | 发生校准的轮次编号 |
| `records[].dimension` | string | 被校准的评分维度（如完整性、可行性等） |
| `records[].agent_score` | number | Agent 原始评分 |
| `records[].user_adjusted` | number | 用户调整后的评分 |
| `records[].direction` | string | 调整方向，`up` 表示用户调高，`down` 表示用户调低 |
| `records[].reason` | string | 用户给出的调整理由 |
| `records[].timestamp` | string | 校准时间戳，格式 ISO 8601 |

## 聚合规则

加载校准数据时，扫描本目录所有 .json 文件：
1. 解析每个文件的 records 数组
2. 按维度分组，统计 Agent 评分偏差的均值和方向
3. 识别系统性偏差模式（某维度持续偏高/偏低）
4. 应用时间衰减，近期校准权重更高

## 使用方式

1. 每次用户调整评分后，系统自动将记录保存到对应的 `{user_id}-{日期}.json` 文件
2. Agent 在评分前扫描所有校准文件，聚合识别偏差模式
3. 根据历史偏差对当前评分进行修正
