<!-- 本文件是 /require-eval 编排器的子模块，由主命令 .claude/commands/require-eval.md 引用 -->
<!-- 不要直接运行本文件，它通过 Read 工具被加载 -->

# 阶段二：需求评估 + 阶段三：输出与衔接

严格按照以下步骤顺序执行评估与输出流程。

---

## 步骤 2.1：调度 eval-judge Agent

### 准备输入

读取 `.require-agent/eval/{项目名}/project-profile.md` 的完整内容。

### 单需求评估（eval_mode = single）

使用 Agent 工具调度 eval-judge：

> "你是评估裁判 Agent。请使用 Read 工具读取 `{install_path}/agents/eval/eval-judge.md` 获取你的完整指令，然后按照指令评估以下新需求与现有项目的兼容性。
>
> 评估模式：single
>
> 项目画像：
> {project-profile.md 的完整内容}
>
> 新需求：
> {requirements[0] 的内容}
>
> {如果有 supplement → 补充说明：{supplement}}
>
> 评估报告模板：请使用 Read 工具读取 `{install_path}/templates/eval-report.md` 获取输出模板。
>
> 项目路径：{project_path}（用于 git 热度分析）"

### 批量需求评估（eval_mode = batch）

使用 Agent 工具调度 eval-judge：

> "你是评估裁判 Agent。请使用 Read 工具读取 `{install_path}/agents/eval/eval-judge.md` 获取你的完整指令，然后按照指令批量评估以下新需求与现有项目的兼容性。
>
> 评估模式：batch
>
> 项目画像：
> {project-profile.md 的完整内容}
>
> 需求列表：
> 1. {requirements[0]}
> 2. {requirements[1]}
> ...
>
> {如果有 supplement → 补充说明：{supplement}}
>
> 评估报告模板：请使用 Read 工具读取 `{install_path}/templates/eval-report.md` 获取输出模板。
>
> 项目路径：{project_path}（用于 git 热度分析）
>
> 注意：除了对每个需求单独评估外，还需要做需求间交叉分析（冲突检测、依赖关系、合并机会、优先级建议）。"

### 收集结果

存储 eval-judge 的输出为 `eval_result`。

---

## 步骤 2.2：保存评估报告

### 保存最新报告

使用 Write 工具将 `eval_result` 写入 `.require-agent/eval/{项目名}/eval-report.md`。

### 保存到历史

生成时间戳和需求摘要（从需求中提取前 20 个字符）：

使用 Write 工具将 `eval_result` 写入 `.require-agent/eval/{项目名}/history/{timestamp}-{需求摘要}.md`。

### 更新历史索引

读取 `.require-agent/eval/{项目名}/history/summary.json`（如不存在则创建空数组）。

追加一条记录：
```json
{
  "timestamp": "{ISO 时间戳}",
  "requirements": "{需求摘要}",
  "eval_mode": "{single / batch}",
  "verdict": "{推荐实施 / 有条件实施 / 不建议实施}",
  "weighted_score": {加权分},
  "file": "{timestamp}-{需求摘要}.md"
}
```

使用 Write 工具保存更新后的 `summary.json`。

---

## 步骤 3.1：展示评估报告摘要

向用户展示评估结果的摘要：

```
评估完成

{综合结论：[推荐实施] / [有条件实施] / [不建议实施]}
综合加权分：{score}/10

兼容度评分：
  业务契合度：{分}/10
  架构兼容度：{分}/10
  数据兼容度：{分}/10
  依赖兼容度：{分}/10
  实施复杂度：{分}/10

文件改动预估：
  修改：{N} 个文件
  新增：{N} 个文件
  受影响：{N} 个文件

{如果有前置条件 →
前置条件：
  1. {条件}
  2. {条件}
}

{如果有高风险项 →
风险提示：
  - {风险}
}

完整报告已保存到：.require-agent/eval/{项目名}/eval-report.md
```

---

## 步骤 3.2：后续衔接

向用户提示后续操作选项：

```
下一步：
  1. 确认实施 → 我将生成初始需求文档，衔接 /require 进行需求优化
  2. 调整需求 → 修改需求描述后重新评估
  3. 查看完整报告 → 我将展示 eval-report.md 的完整内容
  4. 放弃 → 结束评估
```

等待用户回复：

### 用户选择"确认实施"

1. 读取 `eval-report.md` 的内容
2. 检查当前项目是否已有通过 `/require` 创建的需求文档（扫描 `.require-agent/projects/` 目录）
   - **如果已有需求项目** → 向用户提示：
     ```
     检测到已有需求项目：{项目名}
     建议使用 /require-add "{需求描述}" 将新需求追加到已有项目。

     或者使用 /require --file .require-agent/eval/{项目名}/eval-report.md 从头创建新的需求文档。
     ```
   - **如果没有** → 向用户提示：
     ```
     建议使用 /require "{需求描述}" 启动需求优化流程。
     项目画像将作为上下文参考，帮助生成更贴合现有项目的需求文档。

     project-profile.md 路径：.require-agent/eval/{项目名}/project-profile.md
     ```

### 用户选择"调整需求"

1. 等待用户输入新的需求描述
2. 更新 `requirements` 变量
3. 回到步骤 2.1 重新评估

### 用户选择"查看完整报告"

1. 读取并展示 `eval-report.md` 的完整内容
2. 展示后回到后续衔接选项

### 用户选择"放弃"

向用户提示：
```
评估结束。报告已保存，后续可查看：
  /require-eval --skip-scan "{其他需求}"  — 使用已有 profile 评估其他需求
  历史记录：.require-agent/eval/{项目名}/history/
```
