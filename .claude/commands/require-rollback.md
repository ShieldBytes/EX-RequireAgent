---
description: 回滚到指定版本，同步恢复评分和状态
argument-hint: <版本号> 或 "标签名"（如 v5 或 "客户演示版"）
allowed-tools: ["Read", "Write", "Bash", "Glob"]
---

# 版本回滚

你需要将需求文档回滚到指定版本，同步恢复对应的评分和状态。

## 执行步骤

### 1. 解析参数

从用户输入 `$ARGUMENTS` 中解析：
- **版本号**：格式为 `v{数字}`，如 `v5`
- **标签名**：引号中的文字，如 `"客户演示版"`

如果参数缺失，提示用户：
```
用法：/require-rollback <版本号> 或 /require-rollback "标签名"
示例：/require-rollback v5
示例：/require-rollback "客户演示版"
```

### 2. 定位项目和版本

扫描 `.require-agent/projects/` 目录，找到最近修改的项目。

读取 state.json：
- 如果参数是标签名：从 `version_tags` 中查找对应的版本号
- 如果标签名不存在，提示："未找到标签 {标签名}，可用标签：{列出所有标签}"

验证目标版本文件 `versions/v{N}.md` 存在。如不存在，提示：
```
版本 v{N} 不存在。可用版本：{列出 versions/ 下所有版本}
```

### 3. 恢复文档

读取 `versions/v{N}.md` 的内容，覆盖写入当前的 `requirement-overview.md`（即输出目录中的主文档）。

### 4. 恢复评分

在 `scores/` 目录中找到与目标版本对应轮次的评分文件（如 `round-{N}.json`），读取该评分作为当前评分。

### 5. 更新状态

更新 state.json：
- `current_round` 回退到目标版本对应的轮次
- 在 `round_history` 中，将目标版本之后的所有轮次记录标记为 `"status": "rolled_back"`
- 添加一条新的 round_history 记录，action 为 `"rollback"`，备注回滚来源
- 更新 `updated_at`

注意：后续版本文件和评分文件不删除，保留可追溯性。

### 6. 展示结果

```
↩️ 已回滚到 {版本号}

项目：{项目名}
目标版本：v{N}
恢复轮次：{对应轮次}

分数恢复为：
| 维度 | 分数 |
|------|------|
{每个启用维度一行}

⚠️ v{N} 之后的版本已标记为废弃但未删除，仍可查看。
```
