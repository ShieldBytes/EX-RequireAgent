# 项目进化日志：{{project_name}}

## 元数据
```json
{
  "format_version": "1.0",
  "plugin_version": "1.0.0",
  "user": "{{user_id}}",
  "user_projects_count": {{user_projects_count}},
  "user_avg_satisfaction": {{user_avg_satisfaction}},
  "project_satisfaction": {{project_satisfaction}},
  "based_on": [{{loaded_experience_ids}}]
}
```

## 文件命名规则
本文件应保存为：`{项目名}-{日期}-{user_id}.md`
示例：`accounting-app-2026-03-15-wangwei.md`
→ 文件名全球唯一，多人推送永远不冲突。

## 基本信息
- 项目名：{{project_name}}
- 创建时间：{{created_at}}
- 完成时间：{{completed_at}}
- 总轮次：{{total_rounds}}
- 达标线：{{target_score}}
- 启用 Agent：{{enabled_agents}}

## 评分变化
| 维度 | 初始分 | 最终分 | 提升 |
|------|--------|--------|------|
{{score_rows}}

## 策略有效性
| 轮次 | 目标维度 | 使用策略 | 结果 | 分数变化 |
|------|---------|---------|------|---------|
{{strategy_rows}}

## 最有效策略 TOP3
{{top3_strategies}}

## 无效策略
{{ineffective_strategies}}

## 用户满意度
- 评分：{{user_score}}
- 反馈：{{user_feedback}}

## 经验标签
- 项目类型：{{project_type}}
- 关键词：{{keywords}}
