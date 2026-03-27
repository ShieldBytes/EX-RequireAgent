# 自定义 Agent 指南

## 如何创建自定义 Agent

1. 复制模板文件：
   ```bash
   cp agents/custom-agent-template.md agents/{your-agent-name}.md
   ```

2. 编辑文件，替换所有 `{xxx}` 占位符为实际内容

3. 确保以下必填项已填写：
   - `name`：小写字母+连字符，如 `regulation-compliance`
   - `description`：一句话描述用途，末尾加"自定义 Agent。"
   - 至少 2 个检查维度
   - 至少 1 个策略
   - 输出格式（必须与其他 Agent 风格一致）
   - 至少 2 个输出示例

## 如何启用

```bash
/require "需求描述" --agents +{your-agent-name}
```

例如：
```bash
/require "医疗挂号系统" --agents +regulation-compliance
```

## 命名规则

- 使用小写字母和连字符：`regulation-compliance`、`risk-control`
- 不要与内置 Agent 同名（completeness、consistency、user-journey、business-closure、feasibility、security、performance、accessibility-i18n、data、dependency、red-team、evaluator、writer、knowledge-engine）

## 输出格式要求

自定义 Agent 的输出**必须**与内置 Agent 格式一致：

```
[Agent名称] 严重程度：高/中/低
目标：xxx
发现：xxx
建议：xxx
```

这确保写手 Agent 能正确整合你的发现，评估 Agent 能正确评分。

## 内置 Agent 列表

| Agent | 说明 | 默认状态 |
|-------|------|---------|
| completeness | 完整性检查 | 默认启用 |
| consistency | 一致性检查 | 默认启用 |
| user-journey | 用户旅程审查 | 默认启用 |
| business-closure | 业务闭环验证 | 默认启用 |
| feasibility | 可行性评估 | 默认启用 |
| security | 安全审查 | 按需启用 |
| performance | 性能审查 | 按需启用 |
| accessibility-i18n | 无障碍与国际化 | 按需启用 |
| data | 数据需求审查 | 按需启用 |
| dependency | 依赖与集成审查 | 按需启用 |
| red-team | 红队挑战 | 默认启用 |
| evaluator | 评估裁判 | 默认启用 |
| writer | 写手 | 默认启用 |
| knowledge-engine | 知识引擎 | 默认启用 |
