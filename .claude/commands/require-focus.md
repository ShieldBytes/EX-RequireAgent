---
description: 指定下一轮优化的目标维度或模块
argument-hint: <维度名> 或 --module <模块名> [--lock]
allowed-tools: ["Read", "Write"]
---

# 指定优化焦点

你需要让用户指定优化的目标维度或模块，覆盖自动选择逻辑。

## 执行步骤

### 1. 解析参数

从用户输入 `$ARGUMENTS` 中解析：
- **维度名**：如 `completeness`、`consistency` 等
- **--module 模块名**：如 `--module 用户管理`
- **--lock**：持续聚焦模式，锁定只优化指定模块，直到该模块所有维度达标或手动解除
- **--unlock**：解除持续聚焦，恢复自动选择

如果参数缺失，提示用户：
```
用法：
  /require-focus <维度名>                        指定下一轮目标维度（仅一轮）
  /require-focus --module <模块名>               指定下一轮目标模块（仅一轮）
  /require-focus --module <模块名> --lock        锁定只优化指定模块（持续生效）
  /require-focus --unlock                        解除模块锁定，恢复自动选择

示例：
  /require-focus completeness
  /require-focus --module 用户管理
  /require-focus --module 用户管理 --lock
  /require-focus --unlock
```

### 2. 定位当前项目

扫描 `.require-agent/projects/` 目录，找到最近修改的项目（按 state.json 的 `updated_at` 判断）。

如果没有进行中的项目，提示：
```
未找到进行中的项目。请先使用 /require 启动一个项目。
```

### 3. 处理 --unlock

如果参数包含 `--unlock`：
1. 清除 state.json 中的 `focus_module` 字段（设为 `null`）
2. 清除 `next_target_module` 字段（设为 `null`）
3. 展示结果并返回：
```
✅ 已解除模块锁定

项目：{项目名}
后续优化将恢复自动选择最低分模块。
```

### 4. 验证目标有效性

读取 state.json，检查：
- 如果指定的是维度：确认该维度在 `enabled_dimensions` 中且不在 `skip_dimensions` 中
- 如果指定的是模块：确认该模块存在于 modules/ 目录中且不在 `locked_modules` 中

### 5. 设置优化焦点

在 state.json 中：

**不带 --lock（仅下一轮）**：
- 设置 `next_target_override` 字段为指定的维度名
- 如有 `--module` 参数，设置 `next_target_module` 字段为模块名

**带 --lock（持续聚焦）**：
- 设置 `focus_module` 字段为模块名（持续生效，直到 --unlock 或该模块达标）
- 同时设置 `next_target_module` 字段为模块名

将更新后的 state.json 写回文件。

### 6. 展示结果

**不带 --lock**：
```
✅ 下一轮将优先优化 {目标}

项目：{项目名}
当前轮次：{current_round}
指定目标：{维度名或模块名}

注意：此设置仅影响下一轮，之后恢复自动选择。
```

**带 --lock**：
```
✅ 已锁定聚焦模块：{模块名}

项目：{项目名}
当前轮次：{current_round}
聚焦模块：{模块名}

后续所有优化轮次将只针对此模块，直到该模块所有维度达标。
解除锁定：/require-focus --unlock
```
