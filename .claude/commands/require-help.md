---
description: 显示 EX-RequireAgent 的完整帮助信息
allowed-tools: []
---

# EX-RequireAgent 帮助手册

请向用户输出以下完整的命令列表和参数说明。使用格式化的表格和分组展示，确保清晰易读。

---

## 基础命令

| 命令 | 说明 | 示例 |
|------|------|------|
| `/require "描述"` | 从文字描述启动需求优化 | `/require "我想做一个记账App"` |
| `/require --file <路径>` | 从已有文档启动需求优化 | `/require --file ./docs/draft.md` |
| `/require --resume [项目名]` | 恢复中断的优化项目 | `/require --resume accounting-app` |

## 启动参数

以下参数可与基础命令组合使用：

| 参数 | 说明 | 默认值 | 示例 |
|------|------|--------|------|
| `--target <分数>` | 达标分数线（所有维度达到此分数即完成） | `7` | `--target 8` |
| `--max-rounds <轮次>` | 最大深度优化轮次 | `10` | `--max-rounds 5` |
| `--output <目录>` | 最终输出目录 | `./docs/requirements/{项目名}/` | `--output ./output/` |
| `--agents <列表>` | 启用/禁用 Agent（`+`启用，`-`禁用） | 默认9个 | `--agents +security,-red-team` |

## 过程控制命令

| 命令 | 说明 |
|------|------|
| `/require-status` | 查看当前优化进度（阶段、轮次、各维度评分） |
| `/require-add "新需求"` | 中途追加需求而不重置优化进度 |
| `/require-preview` | 预览下一轮优化计划（不实际执行） |

## 版本管理命令

| 命令 | 说明 | 示例 |
|------|------|------|
| `/require-tag <版本号> "描述"` | 给需求文档版本打标签 | `/require-tag v5 "客户演示版"` |
| `/require-diff <版本1> <版本2>` | 对比两个版本差异 | `/require-diff v3 v7` |

## 项目管理命令

| 命令 | 说明 |
|------|------|
| `/require-list` | 列出所有需求优化项目及状态 |
| `/require-clean` | 清理已完成或废弃的项目工作区 |
| `/require-stats` | 显示全局优化统计 |

## 模块管理命令

| 命令 | 说明 |
|------|------|
| `/require:lock <模块>` | 锁定指定模块，优化时不修改 |
| `/require:unlock <模块>` | 解锁已锁定的模块 |
| `/require:split <模块列表>` | 将需求文档拆分为独立子模块 |

## Agent 列表

### 默认启用（9个）

| Agent | 用途 |
|-------|------|
| writer | 写手 — 整合建议成文档 |
| evaluator | 评估 — 多维度评分 |
| completeness | 完整性检查 |
| consistency | 一致性检查 |
| user-journey | 用户旅程审查 |
| business-closure | 业务闭环验证 |
| feasibility | 可行性评估 |
| red-team | 红队挑战 |
| knowledge-engine | 知识引擎 — 外部信息搜索 |

### 按需启用（5个）

| Agent | 用途 | 触发关键词 |
|-------|------|-----------|
| security | 安全审查 | 登录、密码、权限、认证、支付、加密 |
| performance | 性能审查 | 并发、响应时间、QPS、可用性 |
| accessibility-i18n | 无障碍与国际化 | 多语言、国际化、无障碍、适配 |
| data | 数据需求审查 | 3个以上核心业务实体 |
| dependency | 依赖与集成审查 | 第三方、API、SDK、微信、支付宝 |

## 工作目录结构

```
.require-agent/projects/{项目名}/
├── state.json          # 项目状态
├── intent-anchor.json  # 意图锚点
├── scope-baseline.json # 范围基线
├── versions/           # 文档版本快照
└── scores/             # 评分记录
```

## 同步命令
  /require-sync push       推送本地进化数据到团队共享仓库
  /require-sync pull       拉取团队最新进化数据
  /require-sync undo       撤销上次拉取
  /require-sync ignore <ID> 屏蔽特定经验

## 新增参数
  --private                私有项目，进化数据不推送
  --team（用于 /require-stats） 显示团队统计看板

## 共享配置
  首次使用时引导配置，或手动编辑 .require-agent/config.json：
  - evolution_repo: 共享仓库地址
  - share_level: full / anonymized / strategy_only
  - auto_sync: true / false
