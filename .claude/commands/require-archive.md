---
description: 归档已完成的项目
argument-hint: <项目名>
allowed-tools: ["Read", "Write", "Bash"]
---

# 归档项目

你需要将已完成的项目归档，从活跃项目列表中移出。

## 执行步骤

### 1. 解析参数

从用户输入 `$ARGUMENTS` 中解析项目名。

如果参数缺失，扫描 `.require-agent/projects/` 列出所有已完成项目供选择：
```
用法：/require-archive <项目名>

可归档项目（phase = completed）：
{列出所有已完成项目名}
```

### 2. 验证项目

检查 `.require-agent/projects/{项目名}/` 目录是否存在。
读取 state.json，确认 phase 为 `completed`。

如果项目不存在：
```
未找到项目 {项目名}。可用项目：{列出所有项目}
```

如果项目未完成：
```
项目 {项目名} 尚未完成（当前阶段：{phase}），请先完成或终止后再归档。
```

### 3. 执行归档

1. 确保 `.require-agent/archive/` 目录存在（不存在则创建）
2. 将 `.require-agent/projects/{项目名}/` 整个目录移动到 `.require-agent/archive/{项目名}/`
3. 更新归档后的 state.json：
   - 将 `phase` 改为 `"archived"`
   - 添加 `archived_at` 为当前 ISO 时间戳
   - 更新 `updated_at`

### 4. 展示结果

```
📦 项目 {项目名} 已归档

归档位置：.require-agent/archive/{项目名}/
归档时间：{archived_at}

归档项目不会出现在 /require-list 的活跃列表中。
如需恢复，可手动将目录移回 projects/。
```
