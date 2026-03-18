# EX-RequireAgent

需求自优化智能体 — 从模糊想法到精细 PRD 的自动迭代打磨。

灵感来源于 [Karpathy/AutoResearch](https://github.com/karpathy/autoresearch) 的自主进化循环机制：输入一个想法或需求文档，14 个 AI Agent 协作多轮迭代优化，自动输出结构化的需求文档。

## 特性

- **14 个专业 Agent 协作**：完整性、一致性、用户旅程、业务闭环、可行性、安全、性能、无障碍、数据、依赖、红队、评估、知识引擎、写手
- **自适应进化引擎**：评分+轮次+时间三重约束动态协作，自动保留/回滚
- **知识引擎**：全球范围搜索竞品、行业实践、用户痛点，为优化提供情报支持
- **跨项目进化**：积累策略有效性经验，越用越聪明
- **模块化文档**：大需求自动拆分为模块，独立管理和优化
- **团队协作**：接力/并行/评审三种模式，锁机制防冲突
- **29 个命令**：覆盖从优化到版本管理、项目管理、团队同步的完整工作流

## 安装

### 一键安装（推荐）

```bash
curl -sSL https://raw.githubusercontent.com/ShieldBytes/EX-RequireAgent/main/install.sh | bash
```

安装后在**任意目录**使用：

```bash
cd your-project
claude
/model opus
/require "我想做一个记账App，能记录每天的收支"
```

### 更新

```bash
curl -sSL https://raw.githubusercontent.com/ShieldBytes/EX-RequireAgent/main/install.sh | bash -s update
```

### 卸载

```bash
curl -sSL https://raw.githubusercontent.com/ShieldBytes/EX-RequireAgent/main/install.sh | bash -s uninstall
```

### 其他安装方式

<details>
<summary>方式二：直接克隆使用</summary>

```bash
git clone git@github.com:ShieldBytes/EX-RequireAgent.git
cd EX-RequireAgent
claude
/model opus
/require "你的需求描述"
```

仅在仓库目录内可用。
</details>

<details>
<summary>方式三：集成到已有项目</summary>

```bash
cp -r /path/to/EX-RequireAgent/.claude your-project/
cp -r /path/to/EX-RequireAgent/skills your-project/
cp -r /path/to/EX-RequireAgent/agents your-project/
cp -r /path/to/EX-RequireAgent/templates your-project/
cp -r /path/to/EX-RequireAgent/evolution your-project/
```

```bash
cd your-project && claude
/require "你的需求描述"
```
</details>

## 工作流程

```
/require "你的想法"
    │
    ▼
初始化 → 知识引擎搜索竞品和行业信息
    │
    ▼
广度扫描 → 5+ 个 Agent 并行分析需求
    │
    ▼
基线评分 → 5 维度评分（0-10），确认后继续
    │
    ▼
深度优化循环 → 按最低分维度调度专属 Agent 迭代
    │            分数上升→保留，下降→回滚
    ▼
终审 → 一致性/格式/引用最终检查
    │
    ▼
交付 → requirement-overview.md + changelog + report
```

## 常用命令

| 命令 | 说明 |
|------|------|
| `/require "描述"` | 从想法开始优化 |
| `/require --file ./prd.md` | 从已有文档开始 |
| `/require --resume` | 从中断处继续 |
| `/require-status` | 查看进度和评分 |
| `/require-stop` | 终止并输出当前最优版本 |
| `/require-add "新需求"` | 中途追加需求 |
| `/require-help` | 查看全部 29 个命令 |

### 启动参数

```bash
/require "描述" --target 8          # 达标分数（默认7）
/require "描述" --offline           # 离线模式
/require "描述" --agents +security  # 额外启用安全 Agent
/require "描述" --private           # 私有项目（不同步）
```

## 输出文件

```
docs/requirements/{项目名}/
├── requirement-overview.md   ← 最终需求文档
├── changelog.md              ← 变更记录
├── report.md                 ← 优化报告
└── open-questions.md         ← 待解决问题
```

## Agent 架构

| 类别 | Agent | 默认 |
|------|-------|------|
| 基础维度 | completeness, consistency, user-journey, business-closure, feasibility | 启用 |
| 防护 | security | 按需 |
| 质量 | performance, accessibility-i18n | 按需 |
| 架构 | data, dependency | 按需 |
| 系统 | red-team, evaluator, knowledge-engine, writer | 启用 |

按需 Agent 根据需求内容自动建议启用，也可手动：`--agents +security,+data`

## 自定义 Agent

```bash
cp agents/custom-agent-template.md agents/my-agent.md
# 编辑后启用
/require "需求" --agents +my-agent
```

详见 [agents/README.md](agents/README.md)

## 团队协作

安装时自动关联共享仓库，进化数据**全自动同步**：

```
项目开始 → 自动拉取团队最新经验
项目结束 → 自动推送本次经验
```

手动同步和其他协作命令：

```bash
/require-sync push     # 手动推送
/require-sync pull     # 手动拉取
/require --collab      # 启动团队输入模式
/require --review      # 读取文档中的评审标注
/require-stats --team  # 团队统计看板
```

## 项目结构

```
EX-RequireAgent/
├── .claude/commands/     ← 29 个命令
├── skills/               ← 11 个编排器子模块
├── agents/               ← 14 个 Agent + 自定义模板
├── templates/            ← 输出模板
├── evolution/            ← 进化系统
└── docs/                 ← 设计文档
```

## 设计文档

- [设计规格](docs/superpowers/specs/2026-03-15-ex-require-agent-design.md)
- [Agent 详细定义](docs/superpowers/specs/appendix-a-agent-details.md)
- [命令参考手册](docs/superpowers/specs/appendix-b-command-reference.md)

## License

MIT
