# 评分校准记录

## 用途

校准记录用于追踪 Agent 评分与用户实际评分之间的偏差，帮助 Agent 逐步提高评分准确性。

当用户对 Agent 给出的分数进行调整时，系统会自动将校准记录追加到 `history.json` 中。通过分析校准历史，Agent 可以识别自身在特定维度上的评分偏向（偏高或偏低），并在后续评分中进行修正。

## 文件格式

校准记录存储在 `history.json` 中，为 JSON 数组，每条记录格式如下：

```json
{
  "project": "项目名",
  "round": "轮次",
  "dimension": "维度",
  "agent_score": "Agent给的分",
  "user_adjusted": "用户调整后的分",
  "direction": "up/down",
  "reason": "理由",
  "date": "日期"
}
```

### 字段说明

| 字段 | 类型 | 说明 |
|------|------|------|
| `project` | string | 项目名称 |
| `round` | number | 发生校准的轮次编号 |
| `dimension` | string | 被校准的评分维度（如完整性、可行性等） |
| `agent_score` | number | Agent 原始评分 |
| `user_adjusted` | number | 用户调整后的评分 |
| `direction` | string | 调整方向，`up` 表示用户调高，`down` 表示用户调低 |
| `reason` | string | 用户给出的调整理由 |
| `date` | string | 校准日期，格式 YYYY-MM-DD |

## 使用方式

1. 每次用户调整评分后，系统自动追加一条记录到 `history.json`
2. Agent 在评分前读取校准历史，识别偏差模式
3. 根据历史偏差对当前评分进行修正
