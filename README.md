# EX-RequireAgent

需求自优化智能体 — 从模糊想法到精细 PRD，再到完整技术架构的自动迭代打磨。

灵感来源于 [Karpathy/AutoResearch](https://github.com/karpathy/autoresearch) 的自主进化循环机制：输入一个想法或需求文档，AI Agent 协作多轮迭代优化，自动输出结构化的需求文档和技术架构方案。

## 三大核心能力

| 能力 | 命令 | Agent 数 | 输入 | 输出 |
|------|------|---------|------|------|
| **需求优化** | `/require` | 14 个 | 模糊想法 / 需求文档 | 结构化 PRD |
| **架构生成** | `/arch` | 9 个 | PRD / 需求文档 | 完整技术架构方案 |
| **项目评估** | `/require-eval` | 4 个 | 已有代码库 + 新需求 | 兼容性评估报告 + 文件级落地建议 |

三个能力可串联使用：`/require-eval` 评估通过 → `/require` 优化需求 → `/arch` 生成架构，形成 **评估→需求→架构** 的完整闭环。

## 特性

- **27 个专业 Agent 协作**：14 个需求 Agent + 9 个架构 Agent + 4 个评估 Agent，各司其职
- **自适应进化引擎**：评分+轮次+时间三重约束动态协作，自动保留/回滚
- **知识引擎**：全球范围搜索竞品、行业实践、技术选型参考
- **跨项目进化**：积累策略有效性和架构模式经验，越用越聪明
- **渐进式披露文档**：overview 看全貌，modules/ 按需深入
- **需求→架构双向追溯**：每个架构决策可追溯到需求，每个需求可定位到架构
- **四视角架构挑战**：最优解、灵活性、落地现实、需求对齐，全量系统性挑战
- **团队协作**：接力/并行/评审三种模式，锁机制防冲突

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

### /require 需求优化

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

### /arch 架构生成

```
/arch --from-require 项目名（或 --file ./prd.md）
    │
    ▼
初始化 → 约束收集（团队/预算/时间/基础设施）
    │
    ▼
技术侦察 → 搜索技术选型、架构模式、开源方案
    │
    ▼
需求分解 → 提取功能域、用户故事、数据实体
    │
    ▼
分层生成 → Layer 1 结构 → 用户确认方向
           Layer 2 平台
           Layer 3 接口 + 存储（并行）
    │
    ▼
基线评分 → 8 维度评分 + 约束合规检查
    │
    ▼
挑战循环 → 四视角全量挑战 → 分级追问 → 级联传播
    │        分数上升→保留，下降→回滚
    ▼
终审 → 追溯矩阵终检 + 一致性检查
    │
    ▼
交付 → architecture-overview.md + modules/ + decisions/ + 需求反馈
```

### /require-eval 项目评估

```
/require-eval "新增社交分享功能"
    │
    ▼
初始化 → 检测项目类型（单体/Monorepo），检查已有画像
    │
    ▼
四层扫描 → 三 Agent 并行正向扫描（业务+架构+依赖）
    │        逆向文件覆盖验证（确保无遗漏）
    │        入口追踪补漏（发现隐性功能）
    │        用户确认（展示摘要，可补充修正）
    ▼
需求评估 → 5 维度兼容性评分 + 文件级落地建议
    │        git 热度分析 + 风险评估
    ▼
输出报告 → eval-report.md + 三档判定（推荐/有条件/不建议）
    │
    ▼
衔接 → 确认实施 → /require 或 /require-add
```

### 串联使用

```
/require-eval "新增社交分享" → 评估通过
                                    │
/require "社交分享功能"     ←────┘  →  PRD 产出
                                    │
/arch --from-require 项目名  ←────┘  →  技术架构
                                    │
requirement-feedback.md  ←─────────┘  →  反馈回需求侧
```

## 常用命令

### 需求优化

| 命令 | 说明 |
|------|------|
| `/require "描述"` | 从想法开始优化 |
| `/require --file ./prd.md` | 从已有文档开始 |
| `/require --resume` | 从中断处继续 |
| `/require-status` | 查看进度和评分 |
| `/require-stop` | 终止并输出当前最优版本 |
| `/require-add "新需求"` | 中途追加需求 |
| `/require-help` | 查看全部命令 |

### 项目评估

| 命令 | 说明 |
|------|------|
| `/require-eval "需求描述"` | 扫描项目 + 评估新需求 |
| `/require-eval --file ./feature.md` | 从需求文件评估 |
| `/require-eval "需求A" "需求B"` | 批量评估多个需求 |
| `/require-eval --scan-only` | 只扫描项目，不评估 |
| `/require-eval "需求" --skip-scan` | 跳过扫描，复用已有画像 |
| `/require-eval "需求" --rescan` | 强制重新全量扫描 |

### 架构生成

| 命令 | 说明 |
|------|------|
| `/arch --from-require 项目名` | 从 /require 产出直接生成架构 |
| `/arch --file ./prd.md` | 从外部需求文档生成 |
| `/arch --resume` | 从中断处继续 |
| `/arch --file ./prd.md --target 8` | 指定达标分（默认7） |
| `/arch --file ./prd.md --offline` | 离线模式（跳过技术侦察） |

### 启动参数

```bash
# 需求优化
/require "描述" --target 8          # 达标分数（默认7）
/require "描述" --offline           # 离线模式
/require "描述" --agents +security  # 额外启用安全 Agent
/require "描述" --private           # 私有项目（不同步）

# 架构生成
/arch --from-require 记账App        # 串联：需求产出 → 架构
/arch --file ./prd.md --target 8    # 从外部文档，达标分8
/arch --file ./prd.md --offline     # 离线模式
```

## 输出文件

### 需求文档

```
docs/requirements/{项目名}/
├── requirement-overview.md   ← 最终需求文档
├── modules/                  ← 模块详情
├── changelog.md              ← 变更记录
├── report.md                 ← 优化报告
└── open-questions.md         ← 待解决问题
```

### 架构文档

```
docs/architecture/{项目名}/
├── architecture-overview.md  ← 架构总览（L0 摘要 + L1 全景）
├── modules/                  ← 模块架构详情（L2：API + 表结构 + 组件图）
│   ├── 01-用户模块.md
│   └── ...
├── decisions/                ← 架构决策记录（ADR）
│   ├── 001-部署形态.md
│   └── ...
├── challenge-report.md       ← 挑战报告
├── requirement-feedback.md   ← 需求反馈（闭环回 /require）
└── report.md                 ← 优化报告
```

## Agent 架构

### 需求 Agent（14 个，服务 /require）

| 类别 | Agent | 默认 |
|------|-------|------|
| 基础维度 | completeness, consistency, user-journey, business-closure, feasibility | 启用 |
| 防护 | security | 按需 |
| 质量 | performance, accessibility-i18n | 按需 |
| 数据与集成 | data, dependency | 按需 |
| 系统 | red-team, evaluator, knowledge-engine, writer | 启用 |

### 架构 Agent（9 个，服务 /arch）

| 类别 | Agent | 说明 |
|------|-------|------|
| 生成 | arch-structure, arch-platform, arch-interface, arch-storage | 分层设计：结构→平台→接口+存储 |
| 挑战 | arch-challenger | 四视角全量系统性挑战 |
| 验证 | arch-coverage | 双向需求覆盖验证（按需） |
| 系统 | arch-writer, arch-evaluator, arch-knowledge-engine | 整合、8 维度评分、技术侦察 |

### 评估 Agent（4 个，服务 /require-eval）

| 类别 | Agent | 说明 |
|------|-------|------|
| 扫描 | business-scanner, arch-scanner, dependency-scanner | 三维度并行扫描：业务+架构+依赖 |
| 评估 | eval-judge | 5 维度兼容性评分 + 文件级落地建议 |

三套 Agent 完全独立，数据隔离，互不影响。按需 Agent 根据内容自动建议启用。

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
├── .claude/commands/     ← 命令（require.md + arch.md + 其他）
├── modules/               ← 编排器子模块（require-* + arch-*）
├── agents/               ← 需求 Agent（14 个 + 自定义模板）
│   ├── arch/             ← 架构 Agent（9 个，独立子目录）
│   └── eval/             ← 评估 Agent（4 个，独立子目录）
├── templates/            ← 输出模板（需求模板 + 架构模板）
├── evolution/            ← 进化系统（需求经验 + 架构经验，隔离存储）
└── docs/                 ← 设计文档
```

### 评估数据

```
.require-agent/eval/{项目名}/
├── project-profile.md       ← 项目画像（持久化，可复用）
├── profile-meta.json         ← 扫描元数据
├── eval-report.md            ← 最新评估报告
├── scan-coverage.json        ← 文件覆盖率详情
└── history/                  ← 历史评估记录
```

## 设计文档

- [设计规格](docs/superpowers/specs/2026-03-15-ex-require-agent-design.md)
- [/require-eval 设计](docs/superpowers/specs/2026-03-28-require-eval-design.md)
- [Agent 详细定义](docs/superpowers/specs/appendix-a-agent-details.md)
- [命令参考手册](docs/superpowers/specs/appendix-b-command-reference.md)

## License

MIT
