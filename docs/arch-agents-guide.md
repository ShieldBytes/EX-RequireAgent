# 架构 Agent 指南

## 架构 Agent 列表

| Agent | 文件 | 说明 | 默认状态 |
|-------|------|------|---------|
| arch-structure | `structure.md` | 结构设计 — 部署形态+模块划分+通信方式+演进路径 | 默认启用 |
| arch-platform | `platform.md` | 平台设计 — 技术栈+DevOps+监控+基础设施 | 默认启用 |
| arch-interface | `interface.md` | 接口设计 — API+认证+版本策略+错误码 | 默认启用 |
| arch-storage | `storage.md` | 存储设计 — 数据库+缓存+分库分表 | 默认启用 |
| arch-challenger | `challenger.md` | 架构挑战者 — 四视角全量系统性挑战 | 默认启用 |
| arch-coverage | `coverage.md` | 覆盖验证 — 双向验证架构与需求的对齐关系 | 按需启用 |
| arch-writer | `writer.md` | 架构写手 — 整合设计产出为渐进式披露结构文档 | 默认启用 |
| arch-evaluator | `evaluator.md` | 架构评估 — 8 维度评分+成熟度判定+约束合规 | 默认启用 |
| arch-knowledge-engine | `knowledge-engine.md` | 技术侦察 — 搜索技术选型、架构模式、开源方案、成本基准 | 默认启用 |

**编排器**：`.claude/commands/arch.md`（不在本目录，在命令目录下）

## 与 /require Agent 的关系

架构 Agent 与 /require Agent **完全独立，不交叉调用**：

- /require Agent 负责需求优化，产出需求文档
- /arch Agent 负责架构设计，产出架构文档
- 两者通过文件（需求文档、架构反馈文档）进行间接通信，不直接互相调用
- 数据存储隔离：/require 使用 `.require-agent/`，/arch 使用 `.arch-agent/`
- 进化系统隔离：/require 使用 `evolution/strategies/`，/arch 使用 `evolution/arch-strategies/`

## 目录结构说明

架构 Agent 的文件放在 `agents/arch/` 子目录下，与 /require 的 Agent 文件（`agents/*.md`）分离。这样做的目的是：

1. **避免误识别**：/require 的 Agent 发现机制扫描 `agents/*.md`，不会进入子目录，避免将架构 Agent 误识别为需求 Agent
2. **职责清晰**：目录结构直观反映两个系统的独立性
3. **独立演进**：架构 Agent 和需求 Agent 可以各自独立迭代，互不影响

## 如何使用

```bash
# 从 /require 产出直接生成架构
/arch --from-require 项目名

# 从外部文档生成
/arch --file ./prd.md

# 指定达标分
/arch --file ./prd.md --target 8

# 离线模式（跳过技术侦察）
/arch --file ./prd.md --offline

# 恢复中断的架构生成
/arch --resume 项目名
```
