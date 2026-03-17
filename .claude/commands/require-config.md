---
description: 查看或修改插件配置
argument-hint: "[set <key> <value>]"
allowed-tools: ["Read", "Write"]
---

# 配置管理

你需要查看或修改 Require Agent 插件的配置。

## 执行步骤

### 1. 解析参数

从用户输入 `$ARGUMENTS` 中解析操作类型：
- 无参数：查看当前配置
- `set <key> <value>`：修改指定配置项
- `--reset`：重置为默认配置

### 2. 定位配置文件

配置文件路径：`.require-agent/config.json`

如果配置文件不存在，使用默认配置：
```json
{
  "current_mode": "standard",
  "target_score": 8.5,
  "max_rounds": 10,
  "enabled_dimensions": ["completeness", "clarity", "consistency", "feasibility", "testability"],
  "auto_split_threshold": 5000,
  "output_format": "md",
  "language": "zh-CN"
}
```

### 3. 执行操作

#### 查看配置（无参数）

读取 config.json，格式化展示：
```
⚙️ 当前配置

| 配置项 | 值 | 说明 |
|--------|-----|------|
| current_mode | {值} | 体验模式 |
| target_score | {值} | 达标分数线 |
| max_rounds | {值} | 最大优化轮次 |
| enabled_dimensions | {值} | 启用的评分维度 |
| auto_split_threshold | {值} | 自动拆分阈值（字数） |
| output_format | {值} | 默认输出格式 |
| language | {值} | 语言 |
```

#### 修改配置（set）

验证 key 是否为合法配置项。如果不是，提示：
```
未知配置项 {key}。可用配置项：{列出所有合法 key}
```

验证 value 类型和范围是否合法（如 target_score 应为 0-10 的数字）。

更新 config.json 中对应字段，写回文件。

展示：
```
✅ 已更新配置

{key}: {旧值} → {新值}
```

#### 重置配置（--reset）

用默认配置覆盖 config.json。展示：
```
🔄 配置已重置为默认值。
```
