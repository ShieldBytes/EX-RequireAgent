---
description: 中途追加需求而不重置优化进度
argument-hint: "新增需求描述"
allowed-tools: ["Read", "Write", "Edit", "Agent"]
---

# 中途追加需求

你需要在不重置优化进度的情况下，将用户新增的需求注入到当前项目中。

**重要**：这个操作不会重置轮次计数和评分历史，但评分可能会因新需求的加入而变化。

## 执行步骤

### 1. 解析参数

从用户输入 `$ARGUMENTS` 中提取新需求描述。

如果参数为空，提示用户：
```
用法：/require-add "新增需求描述"
示例：/require-add "需要支持微信支付和支付宝支付"
```

### 2. 定位最近项目

扫描 `.require-agent/projects/*/state.json`，找到最近修改的项目。

如果没有找到项目，提示：
```
未找到任何需求优化项目。请先使用 /require 启动一个项目。
```

读取以下文件：
- `.require-agent/projects/{项目名}/state.json`
- `.require-agent/projects/{项目名}/intent-anchor.json`
- `.require-agent/projects/{项目名}/scope-baseline.json`（如果存在）

### 3. 检查项目状态

如果 `phase` 是 `completed`，提示：
```
项目 {项目名} 已完成。如需修改，请使用 /require --resume {项目名} 重新进入优化。
```

如果 `phase` 是 `initialization`，提示：
```
项目 {项目名} 尚未完成初始化，请等待初始化完成后再追加需求。
```

### 4. 更新意图锚点

读取 `intent-anchor.json`，将新需求追加到 `explicit_requirements` 数组末尾：

```json
{
  "explicit_requirements": [
    ...原有需求,
    "[追加] {新需求描述}"
  ]
}
```

使用 Edit 工具更新文件。

### 5. 更新范围基线

如果 `scope-baseline.json` 存在，读取并更新：

```json
{
  "user_expansions": [
    ...原有扩展记录（如果有）,
    {
      "description": "{新需求描述}",
      "added_at": "{当前 ISO 时间戳}",
      "source": "user_manual_add"
    }
  ]
}
```

标记为用户主动扩展（`source: user_manual_add`），这样范围蠕变检测时不会将其视为异常增长。

使用 Edit 工具更新文件。

### 6. 调度 writer Agent 整合新需求

使用 Agent 工具调度 writer，指令如下：

> "你是写手 Agent。用户中途追加了新需求，请将其整合到当前需求文档中。
>
> 整合规则：
> 1. 将新需求自然地融入到文档的合适位置（不是简单追加到末尾）
> 2. 保持文档结构的完整性和一致性
> 3. 在变更记录中标注：来源为「用户追加」
> 4. 不要删除或大幅修改已有内容
>
> 新增需求：{新需求描述}
>
> 意图锚点：{intent-anchor.json 内容}
>
> 当前文档：{读取当前最新版本的文档内容}"

将 writer 返回的文档保存为新版本：
1. 覆盖 `{output_dir}/requirement-overview.md`
2. 保存快照到 `.require-agent/projects/{项目名}/versions/v{N+1}.md`

### 7. 调度 evaluator Agent 快速评估

使用 Agent 工具调度 evaluator，指令如下：

> "你是评估 Agent。用户中途追加了新需求，请对更新后的需求文档进行快速评估。
>
> 重点关注：
> 1. 新需求是否与已有需求存在冲突
> 2. 新需求对各维度评分的影响预估
> 3. 是否需要启用新的按需 Agent（如新需求涉及安全、性能等）
>
> 新增需求：{新需求描述}
>
> 需求文档：{更新后的文档内容}"

### 8. 更新状态

更新 `state.json`：
- 在 `round_history` 中追加一条记录：
  ```json
  {
    "round": "inject",
    "action": "user_add_requirement",
    "description": "{新需求描述}",
    "version": "v{N+1}",
    "timestamp": "{当前 ISO 时间戳}"
  }
  ```
- 更新 `updated_at`

### 9. 展示结果

```
已注入新需求，评分可能变化。

项目：{项目名}
新需求：{新需求描述}
新版本：v{N+1}

影响评估：
{evaluator 的评估摘要}

下一步：
- 使用 /require --resume 继续优化（新需求将纳入后续优化轮次）
- 使用 /require-preview 预览下一轮计划
```
