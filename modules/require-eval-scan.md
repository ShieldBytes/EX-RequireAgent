<!-- 本文件是 /require-eval 编排器的子模块，由主命令 .claude/commands/require-eval.md 引用 -->
<!-- 不要直接运行本文件，它通过 Read 工具被加载 -->

# 阶段一：四层扫描体系

严格按照以下步骤顺序执行扫描流程，生成 project-profile.md。

---

## 步骤 1.1：第一层 — 三 Agent 并行正向扫描

### 准备 Agent 输入

为三个 scanner Agent 构造统一的输入上下文：

```json
{
  "project_path": "{当前工作目录}",
  "project_type": "{project_type}",
  "framework": "{framework}",
  "language": "{language}",
  "scan_scope": "{scan_mode: full / incremental / targeted}",
  "incremental_files": "{如增量模式，变更文件列表}",
  "targeted_files": "{如定向补扫，目标文件列表}"
}
```

### 调度三个 Agent（并行）

使用 Agent 工具并行调度三个 scanner：

**调度 business-scanner Agent：**

> "你是业务扫描 Agent。请使用 Read 工具读取 `{install_path}/agents/eval/business-scanner.md` 获取你的完整指令，然后按照指令对以下项目进行业务层面的扫描。
>
> 项目路径：{project_path}
> 项目类型：{project_type}
> 框架：{framework}
> 语言：{language}
> 扫描范围：{scan_scope}
> {如果增量模式 → 变更文件列表：{incremental_files}}
> {如果定向补扫 → 目标文件列表：{targeted_files}}"

**调度 arch-scanner Agent：**

> "你是架构扫描 Agent。请使用 Read 工具读取 `{install_path}/agents/eval/arch-scanner.md` 获取你的完整指令，然后按照指令对以下项目进行技术架构层面的扫描。
>
> {同上参数}"

**调度 dependency-scanner Agent：**

> "你是依赖扫描 Agent。请使用 Read 工具读取 `{install_path}/agents/eval/dependency-scanner.md` 获取你的完整指令，然后按照指令对以下项目进行外部依赖与接口层面的扫描。
>
> {同上参数}"

### Monorepo 场景

如果 `project_type` 是 `monorepo`：

对每个子项目分别调度三个 scanner Agent（所有子项目的 Agent 并行调度），传入各子项目的 `project_type`、`framework`、`language`。

### 收集结果

等待三个（或 Monorepo 场景下更多）Agent 全部返回结果。

存储为：
- `business_scan`：business-scanner 的输出
- `arch_scan`：arch-scanner 的输出
- `dependency_scan`：dependency-scanner 的输出

---

## 步骤 1.2：第二层 — 逆向文件覆盖验证

编排器自己执行，不调度 Agent。

### 获取项目全部源码文件

使用 Glob 搜索所有源码文件（排除 `exclude_rules` 中的模式），获取文件列表 `all_files`。

### 提取已归属文件

从三份扫描结果的"文件归属映射"部分，提取所有已归属的文件路径，合并为 `covered_files`。

### 计算覆盖率

```
total = all_files 的数量
covered = covered_files 的数量
coverage = covered / total
uncovered_files = all_files - covered_files
```

### 处理未归属文件

如果 `uncovered_files` 不为空：

1. 向用户报告："{uncovered_files 数量} 个文件未被归类，正在定向补扫..."
2. 对 `uncovered_files` 调度三个 scanner Agent 进行定向补扫（`scan_scope: targeted`，`targeted_files: uncovered_files`）
3. 将补扫结果合并到 `business_scan`、`arch_scan`、`dependency_scan` 中
4. 重新计算覆盖率

### 保存覆盖率数据

将覆盖率信息存储为 `scan_coverage`，后续写入 `scan-coverage.json`。

---

## 步骤 1.3：第三层 — 入口追踪补漏

编排器自己执行，不调度 Agent。

### 识别所有入口点

从三份扫描结果中提取已识别的入口点，与以下 Grep 搜索结果交叉比对：

使用 Grep 搜索各类入口点模式：
- HTTP 路由/API：`@Get|@Post|@Put|@Delete|router\.|app\.(get|post|put|delete)|@RequestMapping|@api_view`
- 定时任务：`@Cron|@Scheduled|cron\.|schedule\.|setInterval|node-cron`
- 消息队列：`@MessagePattern|@EventPattern|consumer|subscriber|@RabbitListener|@KafkaListener`
- CLI 命令：`command\(|program\.|yargs|commander|@Command|cobra`
- WebSocket：`@WebSocketGateway|@SubscribeMessage|ws\.|socket\.|io\.on`
- 事件监听：`@OnEvent|@EventHandler|addEventListener|on\(.*event|EventEmitter`

### 追踪调用链

对于每个入口点：
1. 读取入口文件
2. 追踪其调用链（通过 import 和函数调用关系）
3. 将调用链上的文件和函数与第一层扫描结果的模块清单对比

### 标记隐性功能

如果发现调用链中的某段逻辑没有被第一层扫描识别为功能：
- 标记为"隐性功能"
- 补录到 business_scan 中
- 特别关注跨模块调用链和中间件/拦截器逻辑

---

## 步骤 1.4：交叉验证

编排器自己执行，不调度 Agent。

### 三方对比

比对三份扫描结果：

1. **模块一致性**：business-scanner 识别的模块是否都在 arch-scanner 的依赖图中出现？
2. **接口一致性**：dependency-scanner 识别的 API 端点是否都能对应到 business-scanner 识别的功能？
3. **文件一致性**：三份结果中同一个文件的归属是否一致？

### 差异处理

如果发现差异：
1. 记录差异点
2. 对差异涉及的文件进行定向补扫（调度对应的 scanner Agent）
3. 以补扫结果更新扫描数据

---

## 步骤 1.5：Monorepo 跨项目关联分析

仅当 `project_type` 是 `monorepo` 时执行。

编排器自己分析：

1. **接口对接关系**：
   - 从各子项目的 dependency_scan 中提取"对内消费的 API 清单"
   - 与其他子项目的"对外暴露的 API 清单"匹配
   - 建立子项目间的 API 对接关系图

2. **共享依赖**：
   - 检查是否有 `shared/` 或 `common/` 类的子项目
   - 哪些子项目引用了共享代码
   - 共享代码的版本是否一致

3. **数据一致性**：
   - 比对各子项目中相同业务实体的定义（如 User、Order）
   - 标记定义不一致的地方

4. **跨端业务链路**：
   - 从 business_scan 中提取业务流程链路
   - 分析哪些链路跨越了多个子项目
   - 记录完整的跨端链路

---

## 步骤 1.6：废弃代码标记

编排器自己执行。

从 business_scan 中已标记的模块活跃度（active/inactive/deprecated），汇总废弃和不活跃的模块列表。

---

## 步骤 1.7：汇总生成 project-profile.md

将所有扫描结果汇总为一份统一的项目画像文档，使用 Write 工具写入 `.require-agent/eval/{项目名}/project-profile.md`：

```markdown
# 项目画像：{项目名}

> 扫描时间：{ISO 时间戳}
> 项目类型：{project_type}（{framework}）
> 文件覆盖率：{coverage}%

---

## 技术栈
{来自 arch_scan}

## 项目结构
{来自 arch_scan 的分层结构}

## 功能模块清单
{来自 business_scan，按活跃度分组}

## 业务流程链路
{来自 business_scan}

## 业务规则
{来自 business_scan}

## 用户角色
{来自 business_scan}

## 数据模型
{来自 arch_scan}

## 模块依赖关系
{来自 arch_scan}

## API 接口清单
{来自 dependency_scan}

## 第三方服务集成
{来自 dependency_scan}

## 全局行为
{来自 dependency_scan}

## 环境变量
{来自 dependency_scan}

{如果是 Monorepo → }
## 子项目关联
### 接口对接关系
{来自步骤 1.5}
### 共享依赖
{来自步骤 1.5}
### 跨端业务链路
{来自步骤 1.5}

## 废弃/不活跃模块
{来自步骤 1.6}
```

### 写入元数据

使用 Write 工具写入 `.require-agent/eval/{项目名}/profile-meta.json`：

```json
{
  "project_name": "{项目名}",
  "project_type": "{project_type}",
  "framework": "{framework}",
  "language": "{language}",
  "scan_time": "{ISO 时间戳}",
  "scan_mode": "{full / incremental}",
  "file_coverage": {覆盖率数值，如 0.972},
  "total_files": {总文件数},
  "covered_files": {已覆盖文件数},
  "modules_count": {模块数量},
  "entry_points_count": {入口点数量},
  "user_confirmed": false,
  "user_supplements": []
}
```

### 写入覆盖率详情

使用 Write 工具写入 `.require-agent/eval/{项目名}/scan-coverage.json`：

```json
{
  "total_files": {总文件数},
  "covered_files": [{已覆盖文件路径列表}],
  "uncovered_files": [{未覆盖文件路径列表}],
  "coverage": {覆盖率}
}
```

### 增量模式：处理删除的文件

如果 `scan_mode` 是 `incremental` 且有 `deleted_files`：
- 从已有 profile 中移除这些文件的归属记录
- 如果移除后某个模块没有任何文件了，标记该模块为 `deprecated`

---

## 步骤 1.8：第四层 — 展示 profile 摘要，用户确认

向用户展示扫描结果摘要：

```
项目扫描完成

项目类型：{project_type}（{framework}）
{如果 Monorepo → "子项目：{子项目数} 个"}
业务模块：{modules_count} 个（{active_count} 活跃 / {inactive_count} 不活跃 / {deprecated_count} 已废弃）
API 端点：{api_count} 个
外部依赖：{dependency_count} 个
业务流程：{flow_count} 条完整链路
文件覆盖率：{coverage}%（{uncovered_count} 个文件未归属）

模块清单：
  1. [active] {模块名} — {职责}
  2. [active] {模块名} — {职责}
  3. [inactive] {模块名} — {职责}
  ...

{如果有未归属文件 →
未归属文件：
  - {文件路径}
  - ...
}

是否有遗漏？你可以补充说明，或输入"确认"继续。
```

等待用户回复：

- 如果用户回复"确认"或类似确认语 → 更新 `profile-meta.json` 的 `user_confirmed: true`
- 如果用户补充了信息 →
  1. 将补充信息追加到 `profile-meta.json` 的 `user_supplements` 数组
  2. 基于补充信息更新 profile（由编排器直接修改 project-profile.md）
  3. 重新展示摘要，再次等待确认
- 如果 `eval_mode` 是 `scan_only` → 扫描完成，向用户报告，终止执行
- 否则 → 进入阶段二（加载 `skills/require-eval-assess.md`）
