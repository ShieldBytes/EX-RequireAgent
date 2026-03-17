---
description: 切换体验模式（极简/标准/专家）
argument-hint: simple / standard / expert
allowed-tools: ["Read", "Write"]
---

# 切换体验模式

你需要切换 Require Agent 的体验模式，不同模式下的交互详细程度和可用命令不同。

## 执行步骤

### 1. 解析参数

从用户输入 `$ARGUMENTS` 中解析目标模式：
- `simple`：极简模式
- `standard`：标准模式（默认）
- `expert`：专家模式

如果参数缺失或不合法，提示：
```
用法：/require-mode <模式>
可选模式：
  simple   — 极简模式：精简输出，自动决策，最少交互
  standard — 标准模式：平衡输出与交互，适合大多数用户
  expert   — 专家模式：详细输出，完整控制，所有高级命令可用
```

### 2. 读取配置

读取 `.require-agent/config.json`（如不存在则使用默认配置）。

### 3. 更新模式

将 `current_mode` 字段修改为目标模式，写回 config.json。

### 4. 展示结果

模式说明：

**simple 极简模式**：
- 可用命令：5 个核心命令（require, require-status, require-stop, require-list, require-help）
- 优化过程自动执行，减少中间确认
- 输出精简，只展示关键信息

**standard 标准模式**：
- 可用命令：15 个常用命令
- 每轮优化展示变更和评分
- 关键决策点请求确认

**expert 专家模式**：
- 可用命令：全部命令
- 展示完整评分细节和分析推理
- 支持手动干预每个步骤

```
🔄 模式已切换

{旧模式} → {新模式}
可用命令数：{对应命令数}

当前模式：{模式名称} — {模式描述}
```
