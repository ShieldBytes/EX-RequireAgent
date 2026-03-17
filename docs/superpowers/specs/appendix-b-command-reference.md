# 附录 B：命令参考手册

## 基础命令

| 命令 | 说明 | 示例 |
|---|---|---|
| `/require "描述"` | 从想法开始优化 | `/require "记账App"` |
| `/require --file path` | 从文档开始优化 | `/require --file ./prd.md` |
| `/require --resume` | 从中断处继续 | `/require --resume` |
| `/require --resume 项目名` | 恢复指定项目 | `/require --resume 记账App` |

## 启动参数

| 参数 | 说明 | 默认值 | 示例 |
|---|---|---|---|
| `--time N` | 时间预算（分钟） | 自动估算 | `--time 120` |
| `--rounds N` | 轮次上限 | 自动估算 | `--rounds 15` |
| `--target N` | 达标分数（1-10） | 7 | `--target 8` |
| `--market X` | 目标市场 | 全球 | `--market cn` |
| `--offline` | 离线模式 | 否 | `--offline` |
| `--budget X` | 成本预算 | medium | `--budget low` |
| `--template X` | 自定义模板路径 | 内置 | `--template ./tpl.md` |
| `--output X` | 输出目录 | `./docs/requirements/` | `--output ./docs/prd/` |
| `--dimensions` | 调整评分维度 | 默认 5 个 | `--dimensions +安全,-业务闭环` |
| `--agents` | 调整 Agent | 默认启用组 | `--agents +performance` |
| `--collab` | 团队协作模式 | 否 | `--collab` |
| `--explain` | 输出附来源注释 | 否 | `--explain` |
| `--project-template X` | 使用项目模板 | 无 | `--project-template ecommerce` |

## 过程控制

| 命令 | 说明 |
|---|---|
| `/require:status` | 查看当前进度和各维度评分 |
| `/require:focus 维度` | 下一轮优先优化指定维度 |
| `/require:focus --module X` | 下一轮优先优化指定模块 |
| `/require:skip 维度` | 跳过指定维度不再优化 |
| `/require:skip --module X` | 跳过指定模块 |
| `/require:lock --module X` | 锁定模块不再修改 |
| `/require:unlock --module X` | 解锁已锁定的模块 |
| `/require:pause` | 暂停优化，保存状态 |
| `/require:stop` | 终止优化，输出当前最优版本 |
| `/require:add "需求"` | 中途追加需求（不重置） |
| `/require:add "需求" --module X` | 追加需求到指定模块 |
| `/require:preview` | 预览下一轮会做什么（不实际执行） |

## 版本管理

| 命令 | 说明 |
|---|---|
| `/require:versions` | 查看所有版本列表 |
| `/require:diff v3 v7` | 对比两个版本 |
| `/require:diff v3 v7 --module X` | 对比指定模块的两个版本 |
| `/require:rollback v5` | 回滚到指定版本 |
| `/require:rollback "标签名"` | 回滚到指定标签的版本 |
| `/require:tag v5 "描述"` | 给版本打标签 |

## 导出

| 命令 | 说明 |
|---|---|
| `/require:export md` | 导出 Markdown（默认已生成） |
| `/require:export json` | 导出结构化 JSON |
| `/require:export csv` | 导出功能清单 CSV |

## 项目管理

| 命令 | 说明 |
|---|---|
| `/require:list` | 列出所有项目及状态 |
| `/require:archive 项目名` | 归档项目 |
| `/require:clean` | 清理过期工作区文件 |
| `/require:stats` | 全局统计（项目数、平均轮次、TOP 策略等） |
| `/require:save-template 项目名 --as 模板名` | 将项目保存为模板 |

## 团队协作

| 命令 | 说明 |
|---|---|
| `/require --collab` | 启动协作，生成团队输入模板 |
| `/require --merge-input` | 汇总团队输入 |
| `/require --review` | 读取文档中的 @review 标注继续优化 |
| `/require --resume --role X` | 以指定角色接力继续（developer/designer/pm） |
| `/require --force` | 强制接管被锁定的会话 |
| `/require:feedback 项目名 --issue "描述"` | 开发反馈回流 |

## 系统管理

| 命令 | 说明 |
|---|---|
| `/require:config` | 查看/修改配置 |
| `/require:profile` | 查看/修改用户画像 |
| `/require:profile --reset` | 重置用户画像 |
| `/require:diagnose` | 系统自诊断 |
| `/require:trace "关键词"` | 追踪某需求的完整生命线 |
| `/require:mode simple/standard/expert` | 切换体验模式 |
| `/require:split` | 手动触发文档模块化拆分 |
| `/require:help` | 显示帮助 |
