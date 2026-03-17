---
description: 解锁已锁定的模块
argument-hint: --module <模块名>
allowed-tools: ["Read", "Write"]
---

# 解锁模块

你需要解锁用户指定的已锁定模块，使其恢复可被优化的状态。

## 执行步骤

### 1. 解析参数

从用户输入 `$ARGUMENTS` 中解析 `--module` 后的模块名。

如果参数缺失，提示用户：
```
用法：/require-unlock --module <模块名>
示例：/require-unlock --module 用户管理
```

### 2. 定位当前项目

扫描 `.require-agent/projects/` 目录，找到最近修改的项目（按 state.json 的 `updated_at` 判断）。

如果没有项目，提示：
```
未找到任何需求优化项目。请先使用 /require 启动一个项目。
```

### 3. 解锁模块

读取 state.json：
- 检查 `locked_modules` 数组中是否存在该模块
- 如果不存在，提示："模块 {模块名} 未被锁定。当前锁定模块：{locked_modules 列表或 '无'}"
- 如果存在，从 `locked_modules` 数组中移除该模块
- 更新 `updated_at`

将更新后的 state.json 写回文件。

### 4. 展示结果

```
🔓 模块 {模块名} 已解锁

项目：{项目名}
剩余锁定模块：{locked_modules 列表，或 "无"}

该模块将在后续优化中恢复参与。
```
