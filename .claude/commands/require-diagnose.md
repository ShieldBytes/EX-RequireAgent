---
description: 系统自诊断
allowed-tools: ["Read", "Glob", "Bash"]
---

# 系统自诊断

你需要对 Require Agent 系统进行全面的健康检查和自诊断。

## 执行步骤

### 1. 文件完整性检查

使用 Glob 扫描以下关键文件是否存在：

**Agent 文件**（`.claude/agents/`）：
- require-orchestrator.md
- 其他 agent 文件

**Skill 文件**（`.claude/skills/`）：
- 所有 skill 文件

**Command 文件**（`.claude/commands/`）：
- 所有 require-*.md 命令文件

**模板文件**（`evolution/`）：
- scoring-dimensions.json
- project-templates/ 目录
- 其他配置文件

统计：存在/缺失的文件数量。

### 2. 环境检查

检查核心工具可用性：
- Read：文件读取能力
- Write：文件写入能力
- Glob：文件搜索能力
- Bash：命令执行能力
- Grep：内容搜索能力

### 3. 进化数据检查

扫描 `evolution/` 目录：
- evolution-log.json 是否存在及记录数
- scoring-dimensions.json 是否存在及维度数
- user-profile.json 是否存在
- project-templates/ 下的模板数

### 4. 工作区检查

扫描 `.require-agent/` 目录：
- config.json 是否存在及配置完整性
- projects/ 下各项目状态：
  - 项目名
  - phase 状态
  - state.json 完整性
  - versions/ 中版本数
  - scores/ 中评分文件数
- archive/ 下已归档项目数

### 5. 存储统计

使用 Bash 命令计算各目录占用空间：
- `.claude/` 总大小
- `.require-agent/` 总大小
- `evolution/` 总大小
- `docs/requirements/` 总大小

### 6. 汇总展示

```
🔍 Require Agent 系统诊断报告

📁 文件完整性
  Agent 文件：{N}/{总数} ✅/❌
  Skill 文件：{N}/{总数} ✅/❌
  Command 文件：{N}/{总数} ✅/❌
  模板文件：{N}/{总数} ✅/❌

🔧 环境状态
  核心工具：全部可用 ✅ / {不可用列表} ❌

📊 进化数据
  进化日志：{记录数} 条
  评分维度：{维度数} 个
  用户画像：{存在/不存在}
  项目模板：{模板数} 个

📂 工作区
  活跃项目：{N} 个
  已归档项目：{N} 个
  各项目状态：
  {每个项目一行：项目名 — phase — 版本数 — 评分数}

💾 存储占用
  .claude/：{大小}
  .require-agent/：{大小}
  evolution/：{大小}
  docs/requirements/：{大小}
  总计：{总大小}

{如有问题，列出具体问题和建议修复方式}
```
