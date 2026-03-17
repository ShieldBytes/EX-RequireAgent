---
description: 锁定指定模块，Agent 不再修改
argument-hint: --module <模块名>
allowed-tools: ["Read", "Write"]
---

# 锁定模块

你需要锁定用户指定的模块，使后续优化轮次不再修改该模块的内容。

## 执行步骤

### 1. 解析参数

从用户输入 `$ARGUMENTS` 中解析 `--module` 后的模块名。

如果参数缺失，提示用户：
```
用法：/require-lock --module <模块名>
示例：/require-lock --module 用户管理
```

### 2. 定位当前项目

扫描 `.require-agent/projects/` 目录，找到最近修改的项目（按 state.json 的 `updated_at` 判断）。

如果没有项目，提示：
```
未找到任何需求优化项目。请先使用 /require 启动一个项目。
```

### 3. 锁定模块

读取 state.json：
- 将模块名追加到 `locked_modules` 数组中（如数组不存在则创建）
- 避免重复添加
- 更新 `updated_at`

如果模块已在锁定列表中：
```
模块 {模块名} 已处于锁定状态。
```

将更新后的 state.json 写回文件。

### 4. 展示结果

```
🔒 模块 {模块名} 已锁定

项目：{项目名}
已锁定模块：{locked_modules 列表}

锁定后该模块在后续优化中将被跳过。
如需解锁，使用 /require-unlock --module {模块名}
```
