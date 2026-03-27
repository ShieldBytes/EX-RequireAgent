# `/require-eval` 设计文档 — 项目扫描与需求评估

> 从已有代码库反向提取业务逻辑与技术架构，评估新需求的兼容性并给出文件级落地建议。

---

## 一、命令接口

```bash
# 场景一：直接描述需求
/require-eval "新增社交分享功能"

# 场景二：从文件输入需求
/require-eval --file ./docs/share-feature.md
/require-eval --file ./docs/requirements/社交分享/prd.md

# 场景三：多个需求批量评估
/require-eval "社交分享" "消息推送" "积分系统"
/require-eval --file ./feat1.md --file ./feat2.md

# 场景四：只扫描不评估
/require-eval --scan-only

# 场景五：已有 profile，跳过扫描
/require-eval "新增社交分享功能" --skip-scan

# 场景六：强制重新扫描
/require-eval "新增社交分享功能" --rescan

# 场景七：离线模式
/require-eval "新增社交分享功能" --offline

# 场景八：混合输入
/require-eval --file ./share-feature.md "另外还需要支持分享到微信小程序"
```

### 输入解析逻辑

```
用户输入
  ↓
解析输入类型：
  ├─ 纯文字描述 → 当作需求概述
  ├─ --file 单文件 → 读取文件内容作为需求
  ├─ --file 多文件 → 读取所有文件，标记为多需求批量评估
  ├─ 多段文字 → 标记为多需求批量评估
  ├─ 文件 + 文字 → 文件为主体，文字为补充说明
  └─ --scan-only → 无需求输入，纯扫描模式
```

---

## 二、整体流程

```
用户输入 /require-eval
    ↓
[阶段零] 初始化
  ├─ 检测当前工作目录是否为有效项目
  ├─ 项目类型识别（单体 / Monorepo / 多项目）
  ├─ 检查是否已有 project-profile.md
  │   ├─ 有且未过期 → 基于 git diff 增量更新
  │   ├─ 有但已过期 → 提示建议重扫，用户可忽略
  │   └─ 无 或 --rescan → 全量扫描
  └─ 创建工作区 .require-agent/eval/{项目名}/
    ↓
[阶段一] 四层扫描（生成 project-profile.md）
  ├─ 第一层：三 Agent 并行正向扫描
  ├─ 第二层：逆向文件覆盖验证
  ├─ 第三层：入口追踪补漏
  └─ 第四层：展示 profile 摘要，用户确认
    ↓
[阶段二] 需求评估（生成 eval-report.md）
  └─ eval-judge Agent 综合评估
    ↓
[阶段三] 输出报告
  ├─ 兼容度评分
  ├─ 落地建议（文件级）
  ├─ 风险提示
  └─ 保存到 history/
    ↓
[阶段四] 后续衔接
  ├─ "确认实施" → 自动生成初始需求文档，携带 profile 上下文，衔接 /require 或 /require-add
  ├─ "调整需求" → 修改需求后重新评估
  └─ "放弃" → 结束
```

---

## 三、工作区结构

```
.require-agent/eval/{项目名}/
  ├─ project-profile.md       # 项目画像（持久化，可复用）
  ├─ profile-meta.json         # 扫描元数据（时间、覆盖率、版本）
  ├─ scan-coverage.json        # 文件覆盖率详情
  ├─ eval-report.md            # 最新评估报告
  ├─ eval-ignore               # 排除规则（类似 .gitignore 语法）
  └─ history/                  # 历史评估记录
      ├─ summary.json          # 历史索引（快速对比用）
      └─ {timestamp}-{需求摘要}.md
```

---

## 四、阶段零 — 初始化与项目类型识别

### 项目类型识别逻辑

```
扫描根目录 →

[单体项目]
  识别标志文件：package.json / go.mod / Cargo.toml / Podfile / pubspec.yaml /
  build.gradle / pom.xml / requirements.txt / Gemfile / *.csproj ...
  识别框架特征：目录结构 + 依赖声明
  输出：
    project_type: "nestjs-backend"
    framework: "NestJS 10 + Prisma + MySQL"
    language: "TypeScript"

[Monorepo / 多项目目录]
  识别特征：
    ├─ 根目录有 turborepo.json / nx.json / pnpm-workspace.yaml / lerna.json
    ├─ 或有多个子目录各自包含独立的包管理文件
    └─ 或目录名暗示多端（frontend/ backend/ mobile/ admin/ shared/）
  输出：
    project_type: "monorepo"
    sub_projects:
      - { path: "frontend", type: "react-spa", framework: "React 18 + Zustand", language: "TypeScript" }
      - { path: "backend", type: "nestjs-api", framework: "NestJS + Prisma", language: "TypeScript" }
      - { path: "mobile", type: "flutter-app", framework: "Flutter + Riverpod", language: "Dart" }
      - ...
```

### 完整项目类型覆盖

| 大类 | 子类 | 典型技术栈 |
|------|------|----------|
| **前端 Web** | SPA 单页应用 | React / Vue / Angular / Svelte |
| | SSR/SSG | Next.js / Nuxt / Astro / Remix |
| | 静态站点/博客 | Hugo / Hexo / Jekyll / VitePress |
| | 小程序 | 微信/支付宝/抖音小程序、Taro、uni-app |
| **后端服务** | Node.js | NestJS / Express / Koa / Fastify / Hono |
| | Java | Spring Boot / Spring Cloud |
| | Python | Django / FastAPI / Flask |
| | Go | Gin / Echo / Fiber |
| | Rust | Actix / Axum |
| | PHP | Laravel / ThinkPHP |
| | Ruby | Rails |
| | .NET | ASP.NET Core |
| **移动端** | iOS 原生 | Swift / SwiftUI / ObjC |
| | Android 原生 | Kotlin / Java / Compose |
| | Flutter | Dart |
| | React Native | TypeScript |
| | 鸿蒙 | ArkTS / ArkUI |
| | KMP | Kotlin Multiplatform |
| **桌面端** | Electron | Electron + React/Vue |
| | Tauri | Tauri + Rust + 前端 |
| | 原生桌面 | SwiftUI(macOS) / WPF / Qt |
| **CLI 工具** | | Node.js / Go / Rust / Python |
| **SDK / Library** | | 各语言 |
| **游戏** | | Unity(C#) / Unreal(C++) / Godot / Cocos |
| **数据/AI/ML** | | Python + PyTorch/TF / Jupyter / 数据管道 |
| **DevOps/基础设施** | | Terraform / Ansible / Helm / GitHub Actions |
| **浏览器扩展** | | Chrome Extension / Firefox Addon |
| **嵌入式/IoT** | | C / C++ / MicroPython / Arduino |
| **区块链/Web3** | | Solidity / Move / Rust(Solana) |
| **全栈 / Monorepo** | | Turborepo / Nx / pnpm workspace |

### 扫描策略生成方式

不为每种类型写死扫描逻辑，而是 **通用框架 + 类型上下文**：

```
通用框架（适用所有项目）：
  1. 入口点识别 → 所有项目都有入口（main/index/路由/命令）
  2. 模块边界识别 → 所有项目都有模块划分（目录/包/namespace）
  3. 依赖关系识别 → 所有项目都有 import/require/include
  4. 数据结构识别 → 所有项目都有核心数据定义
  5. 配置识别 → 所有项目都有配置文件

类型上下文（告诉 Agent 重点关注什么）：
  根据识别到的 project_type + framework，生成扫描重点提示。
  比如 Flutter 项目 → "入口在 lib/main.dart，路由看 GoRouter/Navigator，
  状态管理看 Provider/Bloc/Riverpod，UI 结构看 Widget 组合树"

  即使遇到未知项目类型，通用框架也能保底扫出基本结构。
```

### profile 过期判断

```
每次执行 /require-eval 时：
  ├─ 读取 profile-meta.json 的 scan_time
  ├─ 计算 scan_time 至今的 commit 数量
  │   ├─ < 10 个 commit → "profile 基本有效，将增量更新"
  │   ├─ 10~50 个 commit → "profile 可能有偏差，建议 --rescan"
  │   └─ > 50 个 commit → "profile 已过期，强烈建议 --rescan"
  └─ 用户可忽略提醒，继续使用旧 profile
```

### 增量扫描逻辑

```
当已有 profile 且未过期时：
  ├─ git diff --name-only {scan_time}..HEAD → 获取变更文件列表
  ├─ 变更文件归属到已有模块 → 该模块定向重扫
  ├─ 新增文件未归属 → 走逆向覆盖验证补录
  ├─ 删除的文件 → 从 profile 中移除对应条目
  └─ 增量扫描后更新 profile-meta.json
```

### 敏感文件排除

```
默认排除：
  ├─ .env* / credentials* / secrets* / *.key / *.pem
  ├─ node_modules / vendor / .git / dist / build / __pycache__
  ├─ 二进制文件（图片/字体/编译产物）
  └─ 锁文件（package-lock.json / yarn.lock 等，只读不深入分析）

可配置：.require-agent/eval/{项目名}/eval-ignore（类似 .gitignore 语法）
```

---

## 五、阶段一 — 四层扫描体系

### 第一层：三 Agent 并行正向扫描

**business-scanner Agent：**

```
扫描目标：业务层面
扫描策略：
  1. 路由/控制器/页面扫描 → 识别所有用户可触达的功能
  2. 服务层/逻辑层扫描 → 识别业务逻辑和规则
  3. 状态机/枚举扫描 → 识别业务状态流转
  4. 测试文件扫描 → 测试用例往往是功能的最佳文档
  5. 文档/注释扫描 → README、API 文档、内联注释中的业务上下文
  6. CHANGELOG / git 关键节点 → 业务演进脉络

输出 business-scan.md：
  ├─ 功能模块清单（每个模块的职责、入口、核心文件）
  ├─ 用户角色清单（有哪些用户类型，各自能做什么）
  ├─ 业务流程链路（完整闭环）
  ├─ 业务规则清单（限额、校验、状态机、审批流）
  └─ 模块活跃度标记：
      - active（活跃）
      - inactive（最近 6 个月无变更）
      - deprecated（代码中有明确废弃标记）
```

**arch-scanner Agent：**

```
扫描目标：技术架构层面
扫描策略：
  1. 包管理文件扫描 → 识别技术栈
  2. 目录结构分析 → 识别分层模式
  3. 导入关系分析 → 构建模块依赖图
  4. 数据模型扫描 → ORM 实体/Schema/迁移文件/数据库注释
  5. 配置文件扫描 → 中间件、缓存、队列等基础设施

输出 arch-scan.md：
  ├─ 技术栈清单
  ├─ 分层结构说明
  ├─ 模块依赖关系图（谁依赖谁，耦合度高低）
  ├─ 数据模型清单（实体、关系、核心字段）
  └─ 基础设施清单
```

**dependency-scanner Agent：**

```
扫描目标：外部依赖与接口
扫描策略：
  1. API 端点全量扫描 → 路由定义、参数、返回值
  2. API 文档扫描 → Swagger/OpenAPI spec（比代码更清晰的接口语义）
  3. 第三方 SDK 调用扫描 → 识别外部服务集成
  4. 环境变量/配置扫描 → 功能开关、服务地址
  5. 中间件/拦截器扫描 → 全局行为（鉴权、限流、日志）
  6. 部署配置扫描 → Docker/CI/CD/K8s

输出 dependency-scan.md：
  ├─ 对外暴露的 API/接口清单（路径、方法、说明）
  ├─ 对内消费的 API/接口清单
  ├─ 第三方服务清单（服务名、用途、SDK 版本）
  ├─ 全局行为清单（中间件、拦截器）
  └─ 环境变量清单
```

**Monorepo 场景下的扫描：**

```
第一轮：子项目独立扫描（并行）
  ├─ frontend  → 三个 scanner 扫 → frontend-profile
  ├─ backend   → 三个 scanner 扫 → backend-profile
  ├─ mobile    → 三个 scanner 扫 → mobile-profile
  └─ ...每个子项目都完整走三 Agent 扫描

第二轮：跨项目关联分析（编排器做）
  ├─ 接口对接关系 — frontend 调了 backend 哪些 API？mobile 呢？
  ├─ 共享依赖 — shared 被谁引用了？各端依赖是否一致？
  ├─ 数据一致性 — 同一实体在各端的定义是否对齐？
  └─ 业务流程跨端链路 — "下单"横跨 mobile → backend → admin
```

### 第二层：逆向文件覆盖验证

```
编排器执行：
  1. 遍历项目所有源码文件（按排除规则过滤）
  2. 对照第一层三份扫描结果，检查每个文件是否已归属到某个模块
  3. 生成覆盖率报告：
     ├─ 已归属文件列表
     ├─ 未归属文件列表
     └─ 覆盖率 = 已归属 / 总文件数
  4. 未归属文件 → 交给三个 scanner 定向补扫
  5. 目标：覆盖率 ≥ 95%（剩余的通常是配置文件、脚本等）
```

### 第三层：入口追踪补漏

```
编排器执行：
  1. 识别所有入口点：
     ├─ HTTP 路由 / API 端点
     ├─ 定时任务 / Cron Job
     ├─ 消息队列消费者
     ├─ CLI 命令
     ├─ WebSocket 监听
     ├─ 事件订阅 / Hook
     └─ 页面路由 / 导航入口（前端/客户端）
  2. 从每个入口点正向追踪调用链
  3. 将追踪到的功能链路与第一层的模块清单对比：
     ├─ 已覆盖 → 跳过
     └─ 未覆盖 → 标记为"隐性功能"，补录到 profile
  4. 特别关注：
     ├─ 跨模块调用链（A→B→C，可能是一个未被识别的完整业务流程）
     └─ 中间件/拦截器逻辑（权限校验、日志、限流等全局行为）
```

### 第四层：用户确认

```
展示给用户：
  ┌─────────────────────────────────────────┐
  │ 项目扫描结果摘要                           │
  ├─────────────────────────────────────────┤
  │ 项目类型：Monorepo（3 个子项目）            │
  │ 技术栈：TypeScript + NestJS / React / Flutter │
  │ 业务模块：12 个                            │
  │ API 端点：47 个                            │
  │ 外部依赖：8 个                             │
  │ 业务流程：5 条完整链路                      │
  │ 文件覆盖率：97.2%（9 个文件未归属）          │
  ├─────────────────────────────────────────┤
  │ 子项目：                                   │
  │  1. backend（NestJS）— 用户/订单/支付/...   │
  │  2. frontend（React）— 商城/个人中心/...    │
  │  3. mobile（Flutter）— 首页/购物车/...      │
  ├─────────────────────────────────────────┤
  │ 模块清单：                                 │
  │  1. [active] 用户模块 — 注册/登录/权限       │
  │  2. [active] 订单模块 — 下单/取消/状态流转    │
  │  3. [inactive] 活动模块 — 抽奖/优惠券        │
  │  4. [deprecated] 旧支付模块 — 已标记废弃     │
  │  ...                                      │
  ├─────────────────────────────────────────┤
  │ 跨端链路：                                 │
  │  1. 下单流程：mobile → backend → admin      │
  │  2. 支付流程：mobile → backend → 微信/支付宝  │
  │  ...                                      │
  ├─────────────────────────────────────────┤
  │ 未归属文件：                                │
  │  - src/utils/rate-limiter.ts               │
  │  - src/jobs/cleanup.ts                     │
  │  ...                                      │
  ├─────────────────────────────────────────┤
  │ 是否有遗漏？你可以补充说明，                 │
  │ 或输入 "确认" 继续评估                      │
  └─────────────────────────────────────────┘

用户可以：
  - 直接确认 → 进入评估阶段
  - 补充信息 → 增量更新 profile，重新展示
  - 修正错误 → 比如"订单模块还包含售后功能"
```

---

## 六、阶段二 — 需求评估体系

### eval-judge Agent 评估流程

```
输入：project-profile.md + 用户新需求
  ↓
[步骤一] 需求理解
  ├─ 解析新需求的核心意图（要做什么、为谁做、解决什么问题）
  ├─ 如果输入是文件 → 提取功能点清单
  └─ 如果是多个需求 → 逐个解析 + 标记需求间关系
  ↓
[步骤二] 兼容性评估（5 个维度打分，每个 0-10）
  ├─ 业务契合度 — 新需求是否符合现有业务方向和闭环逻辑
  ├─ 架构兼容度 — 现有架构能否承载新需求，需要多大改动
  ├─ 数据兼容度 — 现有数据模型是否支持，需不需要加表改表
  ├─ 依赖兼容度 — 需不需要引入新的外部依赖，和现有依赖是否冲突
  └─ 实施复杂度 — 改动范围有多大，风险有多高（分数越高越简单）
  ↓
[步骤三] 落地建议
  ├─ 推荐实现方案（简述怎么做）
  ├─ 涉及模块 — 需要改哪些模块，为什么
  ├─ 文件级改动清单：
  │   ├─ 需要修改的文件 + 改动说明
  │   ├─ 需要新增的文件 + 职责说明
  │   └─ 可能受影响的文件 + 影响原因
  ├─ 依赖变更 — 需要新增/升级/移除哪些依赖
  └─ Monorepo 场景额外输出：
      ├─ 影响哪些子项目的哪些文件
      └─ 跨端实施顺序建议
  ↓
[步骤四] 风险分析
  ├─ 技术风险 — 性能瓶颈、数据迁移、兼容性
  ├─ 业务风险 — 对现有功能的影响
  ├─ 实施风险 — 工期、依赖、团队能力要求
  └─ git 热度增强分析：
      ├─ 热文件（最近频繁改动） → 改这些文件冲突概率更高
      ├─ 稳定文件（长期未改动） → 回归风险更高，可能缺测试
      └─ 贡献者集中度 → 某模块只有一个人改过，知识集中风险
  ↓
[步骤五] 综合结论
  └─ 三档判定：
     ├─ [推荐实施] — 综合加权分 ≥ 7.0，兼容度高，改动可控
     ├─ [有条件实施] — 综合加权分 4.0~6.9，需要先解决某些前置问题
     └─ [不建议实施] — 综合加权分 < 4.0，和现有项目冲突严重，或投入产出比太低

评分权重：
  - 业务契合度：25%
  - 架构兼容度：25%
  - 数据兼容度：20%
  - 依赖兼容度：15%
  - 实施复杂度：15%
```

### 批量评估时的额外步骤

```
当输入多个需求时，在单个评估完成后追加：
  ↓
[步骤六] 需求间交叉分析
  ├─ 冲突检测 — A 和 B 是否改同一个模块的同一处逻辑
  ├─ 依赖关系 — A 是否是 B 的前置条件
  ├─ 合并机会 — A 和 B 改的文件重叠多，合并实现更高效
  └─ 优先级建议 — 综合兼容度和依赖关系，建议实施顺序
```

### eval-report.md 输出示例

```markdown
# 需求评估报告

## 评估概要
- 项目：my-project（Monorepo）
- 新需求：新增社交分享功能
- 综合结论：⚠️ 有条件实施
- 评估时间：2026-03-27

## 兼容度评分
| 维度 | 分数 | 说明 |
|------|------|------|
| 业务契合度 | 8/10 | 社交分享符合用户增长方向 |
| 架构兼容度 | 6/10 | 需要新增分享服务层，现有架构可扩展 |
| 数据兼容度 | 7/10 | 需新增分享记录表，不影响现有表 |
| 依赖兼容度 | 5/10 | 需引入微信/微博 SDK，有版本兼容风险 |
| 实施复杂度 | 6/10 | 中等规模改动，约 15 个文件 |

## 落地建议
### 推荐方案
新增独立的 share 模块，通过事件机制与订单模块解耦...

### 文件级改动清单

**backend — 需要修改（6 个）：**
- `backend/src/order/order.service.ts` — 订单完成后触发分享事件
- `backend/src/common/events.ts` — 新增 ShareEvent 类型
- ...

**backend — 需要新增（5 个）：**
- `backend/src/share/share.module.ts` — 分享模块定义
- `backend/src/share/share.service.ts` — 分享核心逻辑
- ...

**mobile — 需要新增（4 个）：**
- `mobile/lib/pages/share/share_page.dart` — 分享页面
- `mobile/lib/services/share_service.dart` — 分享服务
- ...

**frontend — 需要修改（2 个）：**
- `frontend/src/components/ShareButton.tsx` — 新增分享按钮组件
- ...

**可能受影响（4 个）：**
- `backend/src/user/user.service.ts` — 分享需读取用户信息，需确认接口权限
- ...

### 依赖变更
- backend 新增：wechat-sdk@^2.0.0
- mobile 新增：share_plus: ^7.0.0

### 跨端实施顺序
建议：backend → shared → frontend + mobile 并行 → admin

## 风险分析
### 前置条件
1. 微信开放平台需先申请应用 AppID
2. 现有 event bus 只支持同步，需改为异步

### 技术风险
- 微信 SDK 版本和 Node 18 兼容性需验证

### git 热度分析
- `order.service.ts` 近 30 天改动 12 次 → 冲突概率高，建议协调排期
- `user.service.ts` 近 6 个月无改动 → 回归风险中等，建议补充测试

## 实施优先级
建议先完成前置条件（event bus 异步化），再实施分享功能。
```

---

## 七、新增 Agent 清单

```
agents/
  └─ eval/
      ├─ business-scanner.md    # 业务扫描 Agent
      ├─ arch-scanner.md        # 架构扫描 Agent
      ├─ dependency-scanner.md  # 依赖扫描 Agent
      └─ eval-judge.md          # 评估裁判 Agent
```

---

## 八、编排器核心逻辑

```
require-eval 编排器职责：

  ├─ 参数解析与路由
  │   ├─ 解析输入类型（文字/文件/混合/多需求）
  │   ├─ 解析标志位（--skip-scan / --rescan / --scan-only / --offline）
  │   └─ 决定走哪条路径
  │
  ├─ 阶段零：初始化
  │   ├─ 项目类型识别
  │   ├─ profile 状态检查与过期判断
  │   ├─ 增量 or 全量决策
  │   └─ 排除规则加载
  │
  ├─ 阶段一：扫描编排
  │   ├─ 并行调度三个 scanner Agent（传入 project_type 上下文）
  │   ├─ Monorepo 场景：对每个子项目并行扫描 + 跨项目关联分析
  │   ├─ 收集三份扫描结果
  │   ├─ 执行逆向文件覆盖验证（编排器自己做）
  │   ├─ 执行入口追踪补漏（编排器自己做）
  │   ├─ 交叉验证三份结果（差异区域定向补扫）
  │   ├─ 废弃代码识别与标记
  │   ├─ 汇总生成 project-profile.md + profile-meta.json + scan-coverage.json
  │   └─ 展示摘要，等用户确认
  │
  ├─ 阶段二：评估编排
  │   ├─ 调度 eval-judge Agent（传入 profile + 新需求）
  │   ├─ 多需求场景：逐个评估 + 交叉分析
  │   └─ 生成 eval-report.md
  │
  ├─ 阶段三：输出
  │   ├─ 展示评估报告摘要
  │   ├─ 保存到 history/ + 更新 summary.json
  │   └─ 提示后续操作
  │
  └─ 阶段四：衔接
      ├─ "确认实施" → 自动生成初始需求文档，携带 profile 上下文
      │   ├─ → /require（从头创建完整 PRD）
      │   └─ → /require-add（追加到已有项目的需求文档）
      ├─ "调整需求" → 修改需求后重新评估
      └─ "放弃" → 结束
```

---

## 九、与现有系统的集成

```
/require-eval 与现有命令的关系：

  /require-eval --scan-only
       ↓ 生成 project-profile.md
       ↓ 可被后续所有命令引用

  /require-eval "新需求"
       ↓ 评估通过，用户选择实施
       ├→ /require --file eval-report.md     从头创建完整 PRD
       └→ /require-add "新需求"              追加到已有项目

  profile 复用：
       ├→ /require 可读取 profile 作为上下文参考
       ├→ /arch 可读取 profile 了解现有架构
       └→ 后续 /require-eval 可直接复用，增量更新

  评估历史对比：
       ├→ 多次评估结果存在 history/
       └→ summary.json 支持快速查看历史评估、跨评估对比
```
