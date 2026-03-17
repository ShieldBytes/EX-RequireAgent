# 策略有效性记录

## 文件格式

每个项目生成一个独立的策略记录文件，文件名格式：
`{项目名}-{日期}-{user_id}.json`

示例：`accounting-app-2026-03-15-wangwei.json`

## 文件内容格式

```json
{
  "format_version": "1.0",
  "project": "项目名",
  "user": "user_id",
  "user_projects_count": 20,
  "user_avg_satisfaction": 8.5,
  "project_satisfaction": 9,
  "date": "2026-03-15",
  "based_on": ["wangwei-记账App-2026-03-14"],
  "records": [
    {
      "round": 1,
      "dimension": "completeness",
      "strategy": "反向场景法",
      "result": "improved",
      "score_change": 2,
      "before": 3,
      "after": 5
    }
  ]
}
```

## 文件名设计原则

- 文件名 = 项目名 + 日期 + 用户标识 → 全球唯一
- 多人推送到同一个 git 仓库永远不会冲突（只有新增文件，不会修改同一文件）
- 汇总数据在本地 pull 后聚合计算，不存入 git

## 聚合规则

加载经验时，扫描本目录所有 .json 文件：
1. 解析 records 数组
2. 按维度分组，统计每个策略的成功率
3. 应用时间衰减（0-30天×1.0，31-90天×0.8，91-180天×0.5，>180天×0.3）
4. 应用质量加权（user_avg_satisfaction × project_satisfaction / 100）
5. 检测争议策略（同维度同策略标准差 > 1.5 = 争议）
