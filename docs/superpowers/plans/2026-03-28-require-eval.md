# `/require-eval` Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现 `/require-eval` 命令 — 扫描已有代码库，反向提取业务逻辑与技术架构，评估新需求的兼容性并给出文件级落地建议。

**Architecture:** 新增 4 个 Agent（business-scanner、arch-scanner、dependency-scanner、eval-judge）+ 3 个编排器子模块 skill（init、scan、assess）+ 1 个命令入口。遵循现有 `/require` 的架构模式：命令入口加载子模块 skill，skill 调度 Agent。

**Tech Stack:** Claude Code Skills（Markdown prompt engineering），遵循 EX-RequireAgent 现有 Agent/Skill/Command 三层架构。

**Spec:** `docs/superpowers/specs/2026-03-28-require-eval-design.md`

---

## File Structure

### 新增文件（9 个）

| 文件 | 职责 |
|------|------|
| `agents/eval/business-scanner.md` | 业务扫描 Agent — 从业务视角扫描代码库 |
| `agents/eval/arch-scanner.md` | 架构扫描 Agent — 从技术架构视角扫描代码库 |
| `agents/eval/dependency-scanner.md` | 依赖扫描 Agent — 从外部依赖与接口视角扫描代码库 |
| `agents/eval/eval-judge.md` | 评估裁判 Agent — 评估新需求与现有项目的兼容性 |
| `skills/require-eval-init.md` | 初始化子模块 — 参数解析、项目类型识别、工作区创建 |
| `skills/require-eval-scan.md` | 扫描子模块 — 四层扫描体系、profile 生成 |
| `skills/require-eval-assess.md` | 评估子模块 — 需求评估、报告生成、后续衔接 |
| `.claude/commands/require-eval.md` | 命令入口 — 编排器主文件 |
| `templates/eval-report.md` | 评估报告模板 |

### 修改文件（1 个）

| 文件 | 改动 |
|------|------|
| `install.sh` | 在命令注册循环中追加 `eval`，并为 `/require-eval` 创建全局入口 |

---

### Task 1: 创建 business-scanner Agent

**Files:**
- Create: `agents/eval/business-scanner.md`

- [ ] **Step 1: 创建 agents/eval/ 目录**

Run: `mkdir -p ~/.claude/ex-require-agent/agents/eval` (if developing locally, use project path)

```bash
mkdir -p agents/eval
```

- [ ] **Step 2: 编写 business-scanner Agent**

Create `agents/eval/business-scanner.md`:

```markdown
---
name: business-scanner
description: 业务扫描 Agent — 从业务视角扫描代码库，识别功能模块、用户角色、业务流程和业务规则，输出业务层面的项目画像。
tools:
  - Read
  - Glob
  - Grep
  - Bash
---

# 业务扫描 Agent

## 核心职责

从业务视角全面扫描代码库，识别所有功能模块、用户角色、业务流程链路和业务规则。你只关注"这个项目在业务上做了什么"，不关注技术实现细节。

---

## 输入

编排器会传入以下信息：

- `project_path`：项目根目录路径
- `project_type`：项目类型（如 `react-spa`、`nestjs-backend`、`flutter-app`、`monorepo`）
- `framework`：框架信息（如 `NestJS 10 + Prisma`）
- `language`：编程语言
- `scan_scope`：扫描范围（`full` 全量 / `incremental` 增量 / `targeted` 定向补扫）
- `incremental_files`：（增量模式）变更文件列表
- `targeted_files`：（定向补扫模式）需要补扫的文件列表

---

## 扫描策略

### 通用框架（适用所有项目类型）

无论项目类型如何，按以下五步执行：

**第一步：入口点与路由扫描**

识别所有用户可触达的功能入口：
- 使用 Glob 搜索路由定义文件（如 `**/router*`、`**/routes*`、`**/*controller*`、`**/*Controller*`、`**/pages/**`、`**/screens/**`、`**/views/**`）
- 使用 Grep 搜索路由注册模式（如 `@Get`、`@Post`、`router.get`、`app.use`、`path:`、`Route`、`Navigator`）
- 对每个入口点记录：路径、HTTP 方法（如适用）、关联的处理函数

**第二步：服务层与业务逻辑扫描**

识别核心业务逻辑：
- 使用 Glob 搜索服务文件（如 `**/*service*`、`**/*Service*`、`**/*usecase*`、`**/*UseCase*`、`**/*interactor*`、`**/*manager*`、`**/*handler*`）
- 读取每个服务文件，识别其中的公开方法和业务操作
- 特别关注：条件判断、状态变更、数据验证、业务规则

**第三步：状态与枚举扫描**

识别业务状态流转：
- 使用 Grep 搜索枚举定义（如 `enum`、`Enum`、`Status`、`State`、`Type`）
- 使用 Grep 搜索状态机模式（如 `transition`、`status`、`state`、`phase`、`step`）
- 梳理每个业务对象的状态集合和转换关系

**第四步：测试文件扫描**

从测试中提取功能描述：
- 使用 Glob 搜索测试文件（如 `**/*test*`、`**/*spec*`、`**/*Test*`、`**/test/**`、`**/tests/**`、`**/__tests__/**`）
- 读取测试用例的描述（`describe`、`it`、`test`、`@Test`），这些是功能的最佳文档
- 从测试中补充主代码扫描可能遗漏的功能点

**第五步：文档与注释扫描**

提取业务上下文：
- 读取 `README.md`、`docs/` 目录下的文档
- 使用 Grep 搜索 API 文档文件（如 `**/swagger*`、`**/openapi*`、`**/*.yaml`、`**/*.yml`）
- 使用 Bash 执行 `git log --oneline -50` 获取近期提交历史，识别业务演进脉络
- 读取 `CHANGELOG.md`（如存在）

### 类型上下文提示

根据编排器传入的 `project_type`，调整扫描重点：

- **后端项目**（NestJS/Express/Spring/Django/Go/Rust/PHP/Ruby/.NET）：重点扫描 Controller→Service→Repository 层级、中间件、数据模型
- **前端 Web**（React/Vue/Angular/Svelte/Next.js/Nuxt）：重点扫描页面路由、组件结构、状态管理（Redux/Vuex/Pinia/Zustand）、API 调用层
- **移动端**（iOS/Android/Flutter/RN/鸿蒙）：重点扫描 ViewController/Activity/Screen、导航结构、本地存储、原生桥接
- **小程序**（微信/支付宝/Taro/uni-app）：重点扫描页面配置（app.json/pages）、生命周期、API 调用
- **桌面端**（Electron/Tauri）：重点扫描主进程/渲染进程、IPC 通信、菜单/窗口管理
- **CLI 工具**：重点扫描命令定义、参数解析、子命令注册
- **SDK/Library**：重点扫描导出的公共 API、类型定义
- **游戏**（Unity/Unreal/Godot/Cocos）：重点扫描场景管理、游戏状态、输入处理、UI 系统
- **数据/AI/ML**：重点扫描数据管道、模型定义、训练/推理入口、配置
- **DevOps/基础设施**：重点扫描资源定义、部署流程、环境配置
- **浏览器扩展**：重点扫描 manifest.json、content script、background script、popup
- **嵌入式/IoT**：重点扫描主循环、中断处理、传感器驱动、通信协议
- **区块链/Web3**：重点扫描合约定义、交易处理、事件监听

如果 `project_type` 不在上述列表中，仅使用通用框架执行扫描。

---

## 活跃度标记

对每个识别到的模块，通过 git 历史判断活跃度：

```bash
# 检查模块最后修改时间
git log -1 --format="%ci" -- <模块目录>
```

- **active**：最近 6 个月内有变更
- **inactive**：超过 6 个月无变更
- **deprecated**：代码中包含 `@deprecated`、`@Deprecated`、`// deprecated`、`# deprecated`、`TODO: remove`、`FIXME: 废弃` 等标记

---

## 输出格式

输出一份结构化的业务扫描报告，格式如下：

```markdown
# 业务扫描报告

## 功能模块清单

### 1. [active] {模块名}
- **职责**：{一句话描述模块做什么}
- **入口**：{用户触达这个模块的方式（路由/页面/命令等）}
- **核心文件**：
  - `{文件路径}` — {文件职责}
  - ...
- **关键业务逻辑**：{简述核心业务规则}

### 2. [inactive] {模块名}
...

### 3. [deprecated] {模块名}
...

## 用户角色清单

| 角色 | 描述 | 可访问的功能 |
|------|------|------------|
| {角色名} | {描述} | {功能列表} |

## 业务流程链路

### 链路 1：{流程名}（如：用户下单流程）
```
{步骤 A} → {步骤 B} → {步骤 C} → ...
```
- 涉及模块：{模块列表}
- 关键状态变更：{状态流转}

### 链路 2：...

## 业务规则清单

| 规则 | 所属模块 | 描述 |
|------|---------|------|
| {规则名} | {模块} | {具体规则内容} |

## 文件归属映射

{列出每个已扫描文件归属到哪个模块，格式：}
- `{文件路径}` → {模块名}
```

---

## 工作规则

1. **只关注业务层面**：不输出技术架构细节（那是 arch-scanner 的职责）
2. **具体到文件**：每个模块必须列出核心文件路径
3. **不遗漏**：宁可多列也不要漏掉，后续有交叉验证补漏
4. **文件归属必填**：输出的每个功能模块必须附带文件归属映射，用于后续覆盖率计算
5. **增量模式**：如果 `scan_scope` 是 `incremental`，只扫描 `incremental_files` 中的文件及其关联模块
6. **定向补扫**：如果 `scan_scope` 是 `targeted`，只扫描 `targeted_files` 中的文件，输出它们的业务归属
```

- [ ] **Step 3: 验证文件格式**

Run: `head -5 agents/eval/business-scanner.md`

确认 frontmatter 格式正确（`---` 开头和结尾，包含 name、description、tools）。

- [ ] **Step 4: Commit**

```bash
git add agents/eval/business-scanner.md
git commit -m "feat: 新增 business-scanner Agent — 业务视角扫描代码库"
```

---

### Task 2: 创建 arch-scanner Agent

**Files:**
- Create: `agents/eval/arch-scanner.md`

- [ ] **Step 1: 编写 arch-scanner Agent**

Create `agents/eval/arch-scanner.md`:

```markdown
---
name: arch-scanner
description: 架构扫描 Agent — 从技术架构视角扫描代码库，识别技术栈、分层结构、模块依赖、数据模型和基础设施，输出技术架构层面的项目画像。
tools:
  - Read
  - Glob
  - Grep
  - Bash
---

# 架构扫描 Agent

## 核心职责

从技术架构视角全面扫描代码库，识别技术栈、分层结构、模块间依赖关系、数据模型和基础设施。你只关注"这个项目在技术上是怎么构建的"，不关注业务逻辑。

---

## 输入

编排器会传入以下信息：

- `project_path`：项目根目录路径
- `project_type`：项目类型
- `framework`：框架信息
- `language`：编程语言
- `scan_scope`：扫描范围（`full` / `incremental` / `targeted`）
- `incremental_files`：（增量模式）变更文件列表
- `targeted_files`：（定向补扫模式）需要补扫的文件列表

---

## 扫描策略

### 通用框架（适用所有项目类型）

**第一步：技术栈识别**

从包管理和配置文件中提取技术栈：
- 使用 Glob 搜索包管理文件（`package.json`、`go.mod`、`Cargo.toml`、`Podfile`、`pubspec.yaml`、`build.gradle`、`pom.xml`、`requirements.txt`、`Gemfile`、`*.csproj`、`composer.json`）
- 读取文件内容，提取：
  - 编程语言及版本
  - 框架及版本
  - 核心依赖库（按用途分类：HTTP、数据库、缓存、队列、测试、构建工具等）
- 使用 Glob 搜索配置文件（`tsconfig.json`、`babel.config.*`、`webpack.config.*`、`vite.config.*`、`.eslintrc*`、`Dockerfile`、`docker-compose.*`）

**第二步：目录结构与分层分析**

识别项目的分层模式：
- 使用 Bash 执行 `find . -type d -maxdepth 3` 获取目录结构（排除 node_modules/.git 等）
- 分析目录命名模式，识别分层架构：
  - MVC：controllers/ models/ views/
  - 分层架构：presentation/ domain/ data/ 或 api/ service/ repository/
  - 特性分组：features/ modules/ 或按业务域分目录
  - 组件化：components/ hooks/ utils/ services/
- 记录每一层的职责和包含的目录

**第三步：模块依赖关系分析**

构建模块间的依赖图：
- 使用 Grep 搜索导入语句（`import`、`require`、`from`、`use`、`include`、`using`）
- 分析每个模块（目录）导入了哪些其他模块
- 识别：
  - 单向依赖：A→B（正常）
  - 双向依赖：A↔B（耦合风险）
  - 循环依赖：A→B→C→A（架构问题）
  - 核心模块：被多数模块依赖的模块
  - 孤岛模块：没有被其他模块依赖的模块

**第四步：数据模型扫描**

识别核心数据结构：
- 使用 Glob 搜索数据模型文件（`**/model*`、`**/entity*`、`**/schema*`、`**/migration*`、`**/*.prisma`、`**/*.graphql`、`**/types*`、`**/interface*`）
- 读取文件内容，提取：
  - 实体/模型名称
  - 核心字段和类型
  - 实体间关系（一对多、多对多等）
  - 数据库注释（如有）
- 使用 Grep 搜索数据库连接配置，识别数据库类型

**第五步：基础设施扫描**

识别项目使用的基础设施组件：
- 使用 Grep 搜索中间件注册（`middleware`、`interceptor`、`filter`、`guard`、`pipe`）
- 使用 Grep 搜索缓存使用（`cache`、`redis`、`memcached`）
- 使用 Grep 搜索队列使用（`queue`、`bull`、`rabbitmq`、`kafka`、`sqs`）
- 使用 Grep 搜索日志配置（`logger`、`winston`、`pino`、`log4j`）
- 使用 Glob 搜索部署配置（`Dockerfile`、`docker-compose*`、`k8s/`、`.github/workflows/`、`Jenkinsfile`、`*.tf`）

### 类型上下文提示

根据 `project_type` 调整关注点：

- **后端项目**：重点扫描数据库模型、中间件链、微服务通信模式
- **前端 Web**：重点扫描组件树结构、状态管理架构、构建配置、资产管理
- **移动端**：重点扫描导航架构、本地存储方案、原生模块桥接
- **小程序**：重点扫描页面配置、分包策略、自定义组件结构
- **桌面端**：重点扫描进程模型、IPC 架构、原生 API 使用
- **CLI 工具**：重点扫描命令注册、插件架构
- **游戏**：重点扫描场景管理、ECS 架构、资源管理
- **数据/AI/ML**：重点扫描数据流水线架构、模型服务部署
- **DevOps**：重点扫描资源拓扑、环境分层、密钥管理

---

## 输出格式

```markdown
# 架构扫描报告

## 技术栈清单

| 类别 | 技术 | 版本 | 用途 |
|------|------|------|------|
| 语言 | {语言名} | {版本} | — |
| 框架 | {框架名} | {版本} | {用途} |
| 数据库 | {数据库} | {版本} | {用途} |
| 缓存 | {缓存方案} | {版本} | {用途} |
| ... | ... | ... | ... |

## 分层结构

```
{项目目录结构}
├── {层级1}/    ← {职责说明}
├── {层级2}/    ← {职责说明}
└── {层级3}/    ← {职责说明}
```

**架构模式**：{MVC / 分层 / 特性分组 / 组件化 / 其他}

## 模块依赖关系

### 依赖图
```
{模块A} → {模块B} → {模块C}
{模块D} → {模块B}
{模块E}（孤岛）
```

### 耦合度分析
| 模块 | 被依赖次数 | 依赖次数 | 耦合度评级 |
|------|-----------|---------|-----------|
| {模块名} | {N} | {M} | {低/中/高} |

### 风险标记
- 双向依赖：{模块A} ↔ {模块B}
- 循环依赖：{A} → {B} → {C} → {A}

## 数据模型清单

### {实体名}
- **核心字段**：{字段名}: {类型}, ...
- **关系**：{与其他实体的关系}
- **所在文件**：`{文件路径}`

## 基础设施清单

| 组件 | 类型 | 配置位置 |
|------|------|---------|
| {组件名} | {中间件/缓存/队列/日志/...} | `{文件路径}` |

## 文件归属映射

- `{文件路径}` → {分层/模块名}
```

---

## 工作规则

1. **只关注技术架构**：不分析业务逻辑（那是 business-scanner 的职责）
2. **具体到文件**：每个数据模型、基础设施组件都要标注文件路径
3. **依赖关系要精确**：基于实际的 import/require 分析，不猜测
4. **文件归属必填**：用于后续覆盖率计算
5. **增量/定向模式**：同 business-scanner 的规则
```

- [ ] **Step 2: 验证文件格式**

Run: `head -5 agents/eval/arch-scanner.md`

确认 frontmatter 格式正确。

- [ ] **Step 3: Commit**

```bash
git add agents/eval/arch-scanner.md
git commit -m "feat: 新增 arch-scanner Agent — 技术架构视角扫描代码库"
```

---

### Task 3: 创建 dependency-scanner Agent

**Files:**
- Create: `agents/eval/dependency-scanner.md`

- [ ] **Step 1: 编写 dependency-scanner Agent**

Create `agents/eval/dependency-scanner.md`:

```markdown
---
name: dependency-scanner
description: 依赖扫描 Agent — 从外部依赖与接口视角扫描代码库，识别 API 端点、第三方服务集成、全局行为和环境变量，输出对外接口与外部依赖层面的项目画像。
tools:
  - Read
  - Glob
  - Grep
  - Bash
---

# 依赖扫描 Agent

## 核心职责

从外部接口和依赖视角全面扫描代码库，识别对外暴露的 API、消费的外部 API、第三方服务集成、全局行为（中间件/拦截器）和环境变量。你只关注"这个项目和外部世界怎么交互的"。

---

## 输入

编排器会传入以下信息：

- `project_path`：项目根目录路径
- `project_type`：项目类型
- `framework`：框架信息
- `language`：编程语言
- `scan_scope`：扫描范围（`full` / `incremental` / `targeted`）
- `incremental_files`：（增量模式）变更文件列表
- `targeted_files`：（定向补扫模式）需要补扫的文件列表

---

## 扫描策略

### 通用框架（适用所有项目类型）

**第一步：API 端点全量扫描**

识别所有对外暴露的接口：
- 使用 Grep 搜索 HTTP 方法注解/定义（`@Get`、`@Post`、`@Put`、`@Delete`、`@Patch`、`router.get`、`router.post`、`app.get`、`app.post`、`@RequestMapping`、`@api_view`、`func.*Handle`）
- 使用 Glob 搜索 API 文档（`**/swagger*`、`**/openapi*`、`**/*.swagger.*`、`**/api-docs*`）
- 如果存在 OpenAPI/Swagger 文件，优先解析其内容（比代码注解更完整、语义更清晰）
- 对每个端点记录：路径、HTTP 方法、简要说明、所在文件

**第二步：外部 API 调用扫描**

识别项目消费的外部服务：
- 使用 Grep 搜索 HTTP 客户端使用（`axios`、`fetch`、`http.get`、`HttpClient`、`RestTemplate`、`requests.get`、`http.NewRequest`、`reqwest`）
- 使用 Grep 搜索 SDK 初始化（`new.*Client`、`createClient`、`SDK`、`initialize`）
- 对每个外部调用记录：目标服务、调用方式、所在文件

**第三步：第三方服务集成扫描**

识别所有第三方服务集成：
- 使用 Grep 搜索常见第三方服务关键词：
  - 支付：`wechat`、`alipay`、`stripe`、`paypal`
  - 推送：`firebase`、`apns`、`jpush`、`getui`
  - 存储：`oss`、`s3`、`cos`、`minio`
  - 短信：`twilio`、`sms`、`aliyun.*sms`
  - 邮件：`sendgrid`、`ses`、`nodemailer`
  - 社交：`oauth`、`wechat`、`weibo`、`github`、`google`
  - 监控：`sentry`、`datadog`、`prometheus`、`grafana`
  - 搜索：`elasticsearch`、`algolia`、`meilisearch`
- 对每个集成记录：服务名、用途、SDK 版本（从包管理文件获取）、所在文件

**第四步：全局行为扫描**

识别中间件、拦截器等全局行为：
- 使用 Grep 搜索中间件注册（`app.use`、`@Middleware`、`@UseGuards`、`@UseInterceptors`、`@UseFilters`、`before_action`、`middleware`）
- 使用 Grep 搜索全局拦截模式（`interceptor`、`filter`、`guard`、`pipe`、`hook`、`beforeEach`、`afterEach`）
- 对每个全局行为记录：名称、类型（鉴权/限流/日志/CORS/错误处理等）、所在文件

**第五步：环境变量与配置扫描**

识别所有配置项：
- 使用 Grep 搜索环境变量读取（`process.env`、`os.environ`、`os.Getenv`、`env::`、`@Value`、`ConfigService`）
- 使用 Glob 搜索配置文件（`.env*`、`config/*`、`**/config.*`、`application*.yml`、`settings.*`）
- 读取 `.env.example` 或 `.env.template`（如存在），这通常是环境变量的完整清单
- 对每个配置项记录：变量名、用途推测、是否有默认值
- 使用 Glob 搜索部署配置（`Dockerfile`、`docker-compose*`、`.github/workflows/*`、`Jenkinsfile`、`*.tf`、`k8s/`、`helm/`）

### 类型上下文提示

根据 `project_type` 调整关注点：

- **后端项目**：重点扫描 API 端点、数据库连接、消息队列、微服务间通信
- **前端 Web**：重点扫描 API 调用层（axios/fetch 封装）、第三方 JS SDK、CDN 配置
- **移动端**：重点扫描原生桥接、推送服务、应用市场配置、深度链接
- **小程序**：重点扫描小程序 API 调用、云函数、插件引用
- **桌面端**：重点扫描系统 API 调用、自动更新、本地文件系统访问
- **CLI 工具**：重点扫描外部命令调用、API 集成
- **游戏**：重点扫描网络通信、资源 CDN、广告 SDK、数据上报
- **DevOps**：重点扫描云服务 API、密钥管理、服务发现

---

## 输出格式

```markdown
# 依赖扫描报告

## 对外暴露的 API 清单

| 路径 | 方法 | 说明 | 所在文件 |
|------|------|------|---------|
| {路径} | {GET/POST/...} | {说明} | `{文件路径}` |

## 对内消费的 API 清单

| 目标服务 | 调用方式 | 用途 | 所在文件 |
|---------|---------|------|---------|
| {服务名/URL} | {SDK/HTTP} | {用途} | `{文件路径}` |

## 第三方服务清单

| 服务名 | 用途 | SDK/版本 | 所在文件 |
|--------|------|---------|---------|
| {服务名} | {用途} | {SDK@版本} | `{文件路径}` |

## 全局行为清单

| 名称 | 类型 | 说明 | 所在文件 |
|------|------|------|---------|
| {名称} | {鉴权/限流/日志/CORS/...} | {说明} | `{文件路径}` |

## 环境变量清单

| 变量名 | 用途 | 默认值 | 所在文件 |
|--------|------|--------|---------|
| {变量名} | {用途} | {默认值或无} | `{文件路径}` |

## 部署配置

| 配置 | 类型 | 所在文件 |
|------|------|---------|
| {配置名} | {Docker/CI/K8s/...} | `{文件路径}` |

## 文件归属映射

- `{文件路径}` → {API/第三方集成/中间件/配置}
```

---

## 工作规则

1. **只关注对外交互**：不分析内部业务逻辑或技术架构
2. **具体到文件**：每条记录必须标注所在文件路径
3. **不扫描敏感值**：只记录变量名和用途，不输出实际密钥值
4. **文件归属必填**：用于后续覆盖率计算
5. **增量/定向模式**：同其他 scanner 的规则
```

- [ ] **Step 2: 验证文件格式**

Run: `head -5 agents/eval/dependency-scanner.md`

- [ ] **Step 3: Commit**

```bash
git add agents/eval/dependency-scanner.md
git commit -m "feat: 新增 dependency-scanner Agent — 外部依赖与接口视角扫描代码库"
```

---

### Task 4: 创建 eval-judge Agent

**Files:**
- Create: `agents/eval/eval-judge.md`

- [ ] **Step 1: 编写 eval-judge Agent**

Create `agents/eval/eval-judge.md`:

```markdown
---
name: eval-judge
description: 评估裁判 Agent — 基于项目画像评估新需求的兼容性，从五个维度打分，输出文件级落地建议和风险分析。
tools:
  - Read
  - Glob
  - Grep
  - Bash
---

# 评估裁判 Agent

## 核心职责

基于项目画像（project-profile.md），评估新需求与现有项目的兼容性。从五个维度打分，给出文件级落地建议和风险分析，最终给出三档判定结论。

---

## 输入

编排器会传入以下信息：

- `project_profile`：项目画像内容（project-profile.md 的完整内容）
- `new_requirements`：新需求描述（可能是文字、文件内容、或多个需求的列表）
- `requirement_type`：`single`（单个需求）/ `batch`（批量需求）
- `project_path`：项目根目录路径（用于 git 热度分析）

---

## 评估流程

### 步骤一：需求理解

1. 解析新需求的核心意图：
   - 要做什么？（功能描述）
   - 为谁做？（目标用户）
   - 解决什么问题？（价值主张）
2. 如果输入是文件内容，提取功能点清单
3. 如果是多个需求（`requirement_type: batch`），逐个解析并标记需求间的潜在关系

### 步骤二：兼容性评估（五维度打分）

对每个需求，从以下五个维度打分（每个维度 0-10 分）：

**维度一：业务契合度（权重 25%）**

评估标准：
- 新需求是否与现有业务方向一致？
- 是否能融入现有的业务闭环？
- 是否为现有用户角色服务？
- 是否会打破已有的业务流程？

打分参考：
- 9-10：完全契合，是现有业务的自然延伸
- 7-8：高度契合，有少量需要调整的地方
- 5-6：部分契合，需要一些适配工作
- 3-4：勉强相关，需要较大的业务调整
- 0-2：不相关或冲突

**维度二：架构兼容度（权重 25%）**

评估标准：
- 现有分层架构能否承载新需求？
- 需要新增模块还是修改现有模块？
- 是否会引入架构层面的技术债务？
- 模块间耦合度是否会因此升高？

打分参考：
- 9-10：现有架构完全支持，几乎无需调整
- 7-8：小幅扩展即可，新增一个模块或少量文件
- 5-6：需要中等规模改动，可能涉及多个现有模块
- 3-4：需要大幅重构某些模块
- 0-2：与现有架构冲突，需要底层改动

**维度三：数据兼容度（权重 20%）**

评估标准：
- 现有数据模型是否能支撑新需求？
- 需要新增表/实体还是修改现有的？
- 数据迁移的复杂度如何？
- 是否影响现有数据的一致性？

打分参考：
- 9-10：完全兼容，现有数据模型已覆盖
- 7-8：需要新增少量字段或表，不影响现有数据
- 5-6：需要新增实体和关系，可能需要数据迁移
- 3-4：需要修改现有表结构，数据迁移复杂
- 0-2：数据模型冲突严重，需要大规模重构

**维度四：依赖兼容度（权重 15%）**

评估标准：
- 是否需要引入新的外部依赖？
- 新依赖与现有依赖是否有版本冲突？
- 是否需要对接新的第三方服务？
- 对运维复杂度的影响？

打分参考：
- 9-10：不需要新增任何依赖
- 7-8：新增少量依赖，无冲突风险
- 5-6：新增较多依赖或需对接新的第三方服务
- 3-4：新依赖与现有依赖有潜在冲突
- 0-2：严重依赖冲突或需要替换现有依赖

**维度五：实施复杂度（权重 15%）**

评估标准：
- 需要改动多少个文件？
- 改动是否集中在一个模块还是分散在多处？
- 改动是否涉及核心/稳定代码？
- 回归测试的范围有多大？

打分参考（分数越高越简单）：
- 9-10：改动极少（< 5 个文件），集中在一个模块
- 7-8：改动较少（5-15 个文件），主要在 1-2 个模块
- 5-6：中等改动（15-30 个文件），涉及多个模块
- 3-4：大量改动（30-50 个文件），涉及核心代码
- 0-2：超大范围改动（> 50 个文件），系统性变更

### 步骤三：落地建议

基于评估结果，给出具体的实施建议：

1. **推荐实现方案**：简述怎么做（2-3 句话）
2. **涉及模块**：列出需要改动的模块及改动原因
3. **文件级改动清单**：
   - 通过 Glob 和 Grep 在项目中定位具体文件
   - 分三类列出：需要修改的文件 + 需要新增的文件 + 可能受影响的文件
   - 每个文件附带简要说明
4. **依赖变更**：需要新增/升级/移除哪些依赖
5. **Monorepo 额外输出**：如果 profile 中包含多个子项目，列出影响哪些子项目、跨端实施顺序建议

### 步骤四：风险分析

1. **技术风险**：性能瓶颈、数据迁移、兼容性等
2. **业务风险**：对现有功能的影响
3. **实施风险**：工期、依赖、团队能力要求
4. **git 热度分析**：
   - 使用 Bash 执行 `git log --since="30 days ago" --name-only --pretty=format:""` 获取近 30 天改动的文件
   - 统计每个文件的改动次数，找出热文件
   - 使用 Bash 执行 `git log --since="180 days ago" --name-only --pretty=format:""` 找出长期未改动的稳定文件
   - 使用 Bash 执行 `git shortlog -sn -- {模块路径}` 分析贡献者集中度
   - 对落地建议中涉及的文件，标注热度和风险

### 步骤五：综合结论

计算综合加权分：
```
综合分 = 业务契合度 × 0.25 + 架构兼容度 × 0.25 + 数据兼容度 × 0.20 + 依赖兼容度 × 0.15 + 实施复杂度 × 0.15
```

三档判定：
- **[推荐实施]**：综合加权分 ≥ 7.0
- **[有条件实施]**：综合加权分 4.0 ~ 6.9，列出需要先解决的前置条件
- **[不建议实施]**：综合加权分 < 4.0，说明主要冲突点

### 步骤六：批量评估交叉分析（仅 batch 模式）

当评估多个需求时，在所有单个评估完成后追加：

1. **冲突检测**：A 和 B 是否改同一个模块的同一处逻辑
2. **依赖关系**：A 是否是 B 的前置条件
3. **合并机会**：A 和 B 改的文件重叠多，合并实现更高效
4. **优先级建议**：综合兼容度和依赖关系，建议实施顺序

---

## 输出格式

按照编排器传入的评估报告模板（templates/eval-report.md）格式输出。

如果没有模板，使用以下默认格式：

```markdown
# 需求评估报告

## 评估概要
- 项目：{项目名}
- 新需求：{需求描述}
- 综合结论：{[推荐实施] / [有条件实施] / [不建议实施]}
- 综合加权分：{分数}/10
- 评估时间：{ISO 时间戳}

## 兼容度评分
| 维度 | 分数 | 权重 | 说明 |
|------|------|------|------|
| 业务契合度 | {分}/10 | 25% | {一句话说明} |
| 架构兼容度 | {分}/10 | 25% | {一句话说明} |
| 数据兼容度 | {分}/10 | 20% | {一句话说明} |
| 依赖兼容度 | {分}/10 | 15% | {一句话说明} |
| 实施复杂度 | {分}/10 | 15% | {一句话说明} |

## 落地建议

### 推荐方案
{方案描述}

### 文件级改动清单

**需要修改（{N} 个）：**
- `{文件路径}` — {改动说明}

**需要新增（{N} 个）：**
- `{文件路径}` — {职责说明}

**可能受影响（{N} 个）：**
- `{文件路径}` — {影响原因}

### 依赖变更
- 新增：{依赖@版本}
- 升级：{依赖 旧版本 → 新版本}

## 风险分析

### 前置条件
{如有}

### 技术风险
{列出}

### git 热度分析
- `{文件名}` 近 30 天改动 {N} 次 → {风险评估}

## 实施优先级
{建议}
```

---

## 工作规则

1. **基于 profile 评估**：所有判断必须基于 project-profile.md 中的实际数据，不猜测
2. **文件级精度**：落地建议必须精确到文件路径
3. **git 数据支撑**：风险分析中的热度分析必须基于实际 git 数据
4. **量化打分**：每个维度必须给出 0-10 的分数和理由
5. **批量模式**：多需求时必须做交叉分析
```

- [ ] **Step 2: 验证文件格式**

Run: `head -5 agents/eval/eval-judge.md`

- [ ] **Step 3: Commit**

```bash
git add agents/eval/eval-judge.md
git commit -m "feat: 新增 eval-judge Agent — 需求兼容性评估裁判"
```

---

### Task 5: 创建评估报告模板

**Files:**
- Create: `templates/eval-report.md`

- [ ] **Step 1: 编写评估报告模板**

Create `templates/eval-report.md`:

```markdown
# 需求评估报告

## 评估概要
- **项目**：{project_name}
- **项目类型**：{project_type}
- **新需求**：{requirement_summary}
- **综合结论**：{verdict: [推荐实施] / [有条件实施] / [不建议实施]}
- **综合加权分**：{weighted_score}/10
- **评估时间**：{timestamp}

---

## 兼容度评分

| 维度 | 分数 | 权重 | 说明 |
|------|------|------|------|
| 业务契合度 | {business_fit}/10 | 25% | {business_fit_reason} |
| 架构兼容度 | {arch_compat}/10 | 25% | {arch_compat_reason} |
| 数据兼容度 | {data_compat}/10 | 20% | {data_compat_reason} |
| 依赖兼容度 | {dep_compat}/10 | 15% | {dep_compat_reason} |
| 实施复杂度 | {impl_complexity}/10 | 15% | {impl_complexity_reason} |

---

## 落地建议

### 推荐方案

{recommended_approach}

### 文件级改动清单

**需要修改（{modify_count} 个）：**
{modify_list}

**需要新增（{create_count} 个）：**
{create_list}

**可能受影响（{affect_count} 个）：**
{affect_list}

### 依赖变更

{dependency_changes}

---

## 风险分析

### 前置条件

{prerequisites}

### 技术风险

{tech_risks}

### 业务风险

{business_risks}

### git 热度分析

{git_heat_analysis}

---

## 实施优先级

{implementation_priority}
```

- [ ] **Step 2: Commit**

```bash
git add templates/eval-report.md
git commit -m "feat: 新增评估报告模板 eval-report.md"
```

---

### Task 6: 创建 require-eval-init 子模块

**Files:**
- Create: `skills/require-eval-init.md`

- [ ] **Step 1: 编写初始化子模块**

Create `skills/require-eval-init.md`:

```markdown
<!-- 本文件是 /require-eval 编排器的子模块，由主命令 .claude/commands/require-eval.md 引用 -->
<!-- 不要直接运行本文件，它通过 Read 工具被加载 -->

# 阶段零：初始化

严格按照以下步骤顺序执行初始化流程。

---

## 步骤 0.1：解析用户输入

检查用户的输入 `$ARGUMENTS`，解析以下信息：

### 提取标志位

| 标志位 | 说明 | 默认值 |
|--------|------|--------|
| `--file <路径>` | 从文件读取需求（可多次使用） | 无 |
| `--scan-only` | 只扫描不评估 | false |
| `--skip-scan` | 跳过扫描，直接使用已有 profile | false |
| `--rescan` | 强制重新全量扫描 | false |
| `--offline` | 离线模式 | false |

### 提取需求内容

按以下优先级解析输入类型：

1. 如果包含 `--scan-only` → 设置 `eval_mode = "scan_only"`，无需求内容
2. 如果包含 `--file` 参数 → 使用 Read 工具读取文件内容
   - 单个 `--file` → 设置 `eval_mode = "single"`
   - 多个 `--file` → 设置 `eval_mode = "batch"`
   - 如果同时有文字描述 → 文件为主体，文字作为 `supplement`（补充说明）
3. 如果有多段文字（用引号分隔的多个需求）→ 设置 `eval_mode = "batch"`
4. 如果只有一段文字 → 设置 `eval_mode = "single"`
5. 如果既无文件也无文字且无 `--scan-only` → 提示用户：
   ```
   用法：
     /require-eval "需求描述"
     /require-eval --file ./docs/feature.md
     /require-eval --scan-only

   示例：
     /require-eval "新增社交分享功能"
     /require-eval --file ./docs/share-feature.md "另外需要支持微信小程序"
     /require-eval "社交分享" "消息推送" "积分系统"
   ```

将解析结果存储为变量：
- `eval_mode`：`scan_only` / `single` / `batch`
- `requirements`：需求内容列表
- `supplement`：补充说明（可为空）
- `flags`：标志位集合

---

## 步骤 0.2：检测当前工作目录

验证当前目录是否为有效的代码项目：

1. 使用 Glob 搜索以下标志文件（任一存在即可）：
   - `package.json`、`go.mod`、`Cargo.toml`、`Podfile`、`pubspec.yaml`、`build.gradle`、`build.gradle.kts`、`pom.xml`、`requirements.txt`、`setup.py`、`pyproject.toml`、`Gemfile`、`*.csproj`、`*.sln`、`composer.json`、`Makefile`、`CMakeLists.txt`、`*.xcodeproj`、`*.xcworkspace`、`app.json`、`manifest.json`

2. 如果没有找到任何标志文件，检查是否至少有 `.git/` 目录

3. 如果都没有，向用户提示：
   ```
   当前目录不像是一个代码项目（未找到包管理文件或 .git 目录）。
   请在项目根目录下执行 /require-eval。
   ```
   终止执行。

---

## 步骤 0.3：项目类型识别

### 单体 vs Monorepo 判断

首先判断是单体项目还是 Monorepo：

**Monorepo 特征检测**（满足任一即为 Monorepo）：
- 根目录存在 `turborepo.json`、`nx.json`、`pnpm-workspace.yaml`、`lerna.json`
- 根目录 `package.json` 中包含 `workspaces` 字段
- 有多个子目录各自包含独立的包管理文件（如 `frontend/package.json` + `backend/package.json`）

如果是 Monorepo：
1. 识别所有子项目目录及其类型
2. 将结果存储为：
   ```json
   {
     "project_type": "monorepo",
     "sub_projects": [
       { "path": "frontend", "type": "react-spa", "framework": "React 18", "language": "TypeScript" },
       { "path": "backend", "type": "nestjs-api", "framework": "NestJS + Prisma", "language": "TypeScript" }
     ]
   }
   ```

### 单体项目类型识别

读取包管理文件内容，根据依赖和配置推断项目类型：

- 读取 `package.json`：看 dependencies 中是否有 `react`、`vue`、`angular`、`svelte`、`next`、`nuxt`、`express`、`nestjs`、`electron`、`react-native`
- 读取 `pubspec.yaml`：Flutter 项目
- 读取 `Podfile`：iOS 项目
- 读取 `build.gradle`：Android 或 Java 后端
- 读取 `go.mod`：Go 项目
- 读取 `Cargo.toml`：Rust 项目
- 读取 `requirements.txt` / `pyproject.toml`：Python 项目
- 读取 `Gemfile`：Ruby 项目
- 读取 `*.csproj`：.NET 项目
- 读取 `composer.json`：PHP 项目

将结果存储为：
```json
{
  "project_type": "{类型}",
  "framework": "{框架}",
  "language": "{语言}"
}
```

---

## 步骤 0.4：检查已有 Profile

### 提取项目名

从当前目录名提取项目名（如 `/path/to/my-project` → `my-project`）。

### 检查 profile 是否存在

读取 `.require-agent/eval/{项目名}/profile-meta.json`：

**情况 A：不存在 或 `--rescan`**
→ 设置 `scan_mode = "full"`

**情况 B：存在且未指定 `--rescan`**
→ 读取 `scan_time` 字段，使用 Bash 计算自 scan_time 以来的 commit 数：

```bash
git rev-list --count --since="{scan_time}" HEAD
```

根据 commit 数给出建议：
- < 10 个 commit → 向用户提示："profile 基本有效，将进行增量更新"
  → 设置 `scan_mode = "incremental"`
- 10~50 个 commit → 向用户提示："profile 可能有偏差，建议使用 --rescan 重新扫描"
  → 设置 `scan_mode = "incremental"`（用户可忽略建议）
- \> 50 个 commit → 向用户提示："profile 已过期，强烈建议使用 --rescan"
  → 设置 `scan_mode = "incremental"`（用户可忽略建议）

**情况 C：指定了 `--skip-scan`**
→ 如果 profile 不存在，报错："未找到已有的项目画像，无法跳过扫描。请先执行 /require-eval --scan-only"
→ 如果 profile 存在，设置 `scan_mode = "skip"`

### 增量扫描准备

如果 `scan_mode = "incremental"`：
- 使用 Bash 获取变更文件列表：
  ```bash
  git diff --name-only --diff-filter=ACMR "{scan_time_commit}..HEAD"
  ```
- 使用 Bash 获取删除的文件列表：
  ```bash
  git diff --name-only --diff-filter=D "{scan_time_commit}..HEAD"
  ```
- 存储为 `incremental_files`（变更文件）和 `deleted_files`（删除文件）

---

## 步骤 0.5：创建工作区

如果工作区不存在，创建目录结构：

```bash
mkdir -p .require-agent/eval/{项目名}/history
```

---

## 步骤 0.6：加载排除规则

1. 如果 `.require-agent/eval/{项目名}/eval-ignore` 存在 → 读取自定义排除规则
2. 否则使用默认排除规则：
   ```
   .env*
   credentials*
   secrets*
   *.key
   *.pem
   node_modules/
   vendor/
   .git/
   dist/
   build/
   __pycache__/
   *.pyc
   *.jpg
   *.jpeg
   *.png
   *.gif
   *.svg
   *.ico
   *.woff
   *.woff2
   *.ttf
   *.eot
   *.mp3
   *.mp4
   *.zip
   *.tar.gz
   *.jar
   *.class
   *.o
   *.so
   *.dylib
   package-lock.json
   yarn.lock
   pnpm-lock.yaml
   Podfile.lock
   pubspec.lock
   Cargo.lock
   go.sum
   Gemfile.lock
   composer.lock
   ```

存储为 `exclude_rules`。

---

## 步骤 0.7：向用户报告启动信息

```
需求评估启动

项目：{项目名}
项目类型：{project_type}（{framework}）
{如果是 Monorepo → "子项目：{列出子项目}"}
扫描模式：{full 全量 / incremental 增量 / skip 跳过}
评估模式：{scan_only 纯扫描 / single 单需求 / batch 批量需求}

{如果是增量模式 → "变更文件：{N} 个"}
{如果是全量模式 → "正在进入全量扫描..."}
{如果是跳过模式 → "使用已有 profile，直接进入评估..."}
```

然后进入下一阶段：
- 如果 `scan_mode` 不是 `skip` → 进入阶段一（加载 `skills/require-eval-scan.md`）
- 如果 `scan_mode` 是 `skip` → 直接进入阶段二（加载 `skills/require-eval-assess.md`）
```

- [ ] **Step 2: 验证文件格式**

Run: `head -3 skills/require-eval-init.md`

确认以 HTML 注释开头，说明是子模块。

- [ ] **Step 3: Commit**

```bash
git add skills/require-eval-init.md
git commit -m "feat: 新增 require-eval-init 子模块 — 参数解析与项目类型识别"
```

---

### Task 7: 创建 require-eval-scan 子模块

**Files:**
- Create: `skills/require-eval-scan.md`

- [ ] **Step 1: 编写扫描子模块**

Create `skills/require-eval-scan.md`:

```markdown
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
```

- [ ] **Step 2: 验证文件格式**

Run: `head -3 skills/require-eval-scan.md`

- [ ] **Step 3: Commit**

```bash
git add skills/require-eval-scan.md
git commit -m "feat: 新增 require-eval-scan 子模块 — 四层扫描体系"
```

---

### Task 8: 创建 require-eval-assess 子模块

**Files:**
- Create: `skills/require-eval-assess.md`

- [ ] **Step 1: 编写评估子模块**

Create `skills/require-eval-assess.md`:

```markdown
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
```

- [ ] **Step 2: 验证文件格式**

Run: `head -3 skills/require-eval-assess.md`

- [ ] **Step 3: Commit**

```bash
git add skills/require-eval-assess.md
git commit -m "feat: 新增 require-eval-assess 子模块 — 需求评估与报告输出"
```

---

### Task 9: 创建命令入口

**Files:**
- Create: `.claude/commands/require-eval.md`

- [ ] **Step 1: 编写命令入口**

Create `.claude/commands/require-eval.md`:

```markdown
---
description: 项目扫描与需求评估 — 扫描已有代码库，评估新需求的兼容性并给出文件级落地建议
argument-hint: "需求描述"，或 --file <路径>，或 --scan-only
allowed-tools: ["Read", "Write", "Edit", "Bash", "Glob", "Grep", "Agent", "AskUserQuestion"]
---

# 项目扫描与需求评估编排器

你是编排器。你的任务是扫描当前项目代码库，生成项目画像，并评估用户提出的新需求与现有项目的兼容性。

严格按照本文件的流程执行，不要跳过任何步骤，不要自行发挥。

---

## 一、Agent 清单

你可以调度以下 4 个 Agent：

| Agent | 文件 | 用途 | 调度时机 |
|-------|------|------|---------|
| **business-scanner** | `agents/eval/business-scanner.md` | 业务视角扫描 | 阶段一 |
| **arch-scanner** | `agents/eval/arch-scanner.md` | 架构视角扫描 | 阶段一 |
| **dependency-scanner** | `agents/eval/dependency-scanner.md` | 依赖视角扫描 | 阶段一 |
| **eval-judge** | `agents/eval/eval-judge.md` | 需求兼容性评估 | 阶段二 |

**调度方式**：使用 Agent 工具调度，消息中包含输入数据和具体指令。

---

## 二、总体流程概览

```
阶段零：初始化（参数解析、项目类型识别、profile 状态检查）
    ↓
阶段一：四层扫描（正向扫描 → 覆盖验证 → 入口追踪 → 用户确认）
    ↓
阶段二：需求评估（eval-judge 评估 → 生成报告）
    ↓
阶段三：输出与衔接（展示摘要 → 后续操作）
```

---

## 三、阶段零：初始化

使用 Read 工具读取 `skills/require-eval-init.md` 的内容，严格按照其中定义的步骤执行初始化流程。

包含：解析用户输入（0.1）、检测工作目录（0.2）、项目类型识别（0.3）、检查已有 Profile（0.4）、创建工作区（0.5）、加载排除规则（0.6）、报告启动信息（0.7）。

---

## 四、阶段一：四层扫描

使用 Read 工具读取 `skills/require-eval-scan.md` 的内容，严格按照其中定义的步骤执行扫描流程。

包含：
- 步骤 1.1：三 Agent 并行正向扫描
- 步骤 1.2：逆向文件覆盖验证
- 步骤 1.3：入口追踪补漏
- 步骤 1.4：交叉验证
- 步骤 1.5：Monorepo 跨项目关联分析（仅 Monorepo）
- 步骤 1.6：废弃代码标记
- 步骤 1.7：汇总生成 project-profile.md
- 步骤 1.8：展示摘要，用户确认

如果 `scan_mode` 是 `skip` → 跳过本阶段，直接进入阶段二。
如果 `eval_mode` 是 `scan_only` → 步骤 1.8 完成后终止。

---

## 五、阶段二 + 阶段三：评估与输出

使用 Read 工具读取 `skills/require-eval-assess.md` 的内容，严格按照其中定义的步骤执行评估与输出流程。

包含：
- 步骤 2.1：调度 eval-judge Agent
- 步骤 2.2：保存评估报告
- 步骤 3.1：展示评估报告摘要
- 步骤 3.2：后续衔接（确认实施 / 调整需求 / 查看报告 / 放弃）

---

## Skill 文件索引

| 文件 | 用途 | 加载时机 |
|------|------|---------|
| `skills/require-eval-init.md` | 初始化流程 | 阶段零 |
| `skills/require-eval-scan.md` | 四层扫描体系 | 阶段一 |
| `skills/require-eval-assess.md` | 评估与输出 | 阶段二+三 |
```

- [ ] **Step 2: 验证文件格式**

Run: `head -5 .claude/commands/require-eval.md`

确认 frontmatter 包含 description、argument-hint、allowed-tools。

- [ ] **Step 3: Commit**

```bash
git add .claude/commands/require-eval.md
git commit -m "feat: 新增 /require-eval 命令入口 — 编排器主文件"
```

---

### Task 10: 更新 install.sh

**Files:**
- Modify: `install.sh:144`

- [ ] **Step 1: 在命令注册循环中追加 eval**

在 `install.sh` 第 144 行的命令列表中追加 `eval`：

将：
```bash
for cmd in help status stop pause focus skip add preview versions diff rollback tag export list archive clean stats save-template lock unlock split sync feedback config profile mode diagnose trace; do
```

改为：
```bash
for cmd in help status stop pause focus skip add preview versions diff rollback tag export list archive clean stats save-template lock unlock split sync feedback config profile mode diagnose trace eval; do
```

- [ ] **Step 2: 验证修改**

Run: `grep "eval;" install.sh`

确认 `eval` 出现在命令列表中。

- [ ] **Step 3: Commit**

```bash
git add install.sh
git commit -m "fix: install.sh 注册 /require-eval 命令入口"
```

---

## Summary

| Task | 文件 | 说明 |
|------|------|------|
| 1 | `agents/eval/business-scanner.md` | 业务扫描 Agent |
| 2 | `agents/eval/arch-scanner.md` | 架构扫描 Agent |
| 3 | `agents/eval/dependency-scanner.md` | 依赖扫描 Agent |
| 4 | `agents/eval/eval-judge.md` | 评估裁判 Agent |
| 5 | `templates/eval-report.md` | 评估报告模板 |
| 6 | `skills/require-eval-init.md` | 初始化子模块 |
| 7 | `skills/require-eval-scan.md` | 扫描子模块 |
| 8 | `skills/require-eval-assess.md` | 评估子模块 |
| 9 | `.claude/commands/require-eval.md` | 命令入口 |
| 10 | `install.sh` | 命令注册 |
