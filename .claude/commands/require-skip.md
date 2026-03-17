---
description: 跳过指定维度或模块，不再优化
argument-hint: <维度名> 或 --module <模块名>
allowed-tools: ["Read", "Write"]
---

# 跳过维度或模块

你需要将用户指定的维度或模块加入跳过列表，后续优化轮次不再处理。

## 执行步骤

### 1. 解析参数

从用户输入 `$ARGUMENTS` 中解析：
- **维度名**：如 `completeness`、`testability` 等
- **--module 模块名**：如 `--module 支付模块`

如果参数缺失，提示用户：
```
用法：/require-skip <维度名> 或 /require-skip --module <模块名>
示例：/require-skip testability
示例：/require-skip --module 支付模块
```

### 2. 定位当前项目

扫描 `.require-agent/projects/` 目录，找到最近修改的项目（按 state.json 的 `updated_at` 判断）。

如果没有进行中的项目，提示：
```
未找到进行中的项目。请先使用 /require 启动一个项目。
```

### 3. 更新跳过列表

读取 state.json：
- 如果指定的是维度：将维度名追加到 `skip_dimensions` 数组中（如数组不存在则创建）
- 如果指定的是模块：将模块名追加到 `skip_modules` 数组中（如数组不存在则创建）
- 避免重复添加

将更新后的 state.json 写回文件。

### 4. 展示结果

```
⏭ 已跳过 {目标}

项目：{项目名}
跳过的维度：{skip_dimensions 列表，或 "无"}
跳过的模块：{skip_modules 列表，或 "无"}

提示：如需恢复，请手动编辑 state.json 移除对应项。
```
