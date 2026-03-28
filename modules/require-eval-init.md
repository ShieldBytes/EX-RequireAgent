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
- 如果 `scan_mode` 不是 `skip` → 进入阶段一（加载 `modules/require-eval-scan.md`）
- 如果 `scan_mode` 是 `skip` → 直接进入阶段二（加载 `modules/require-eval-assess.md`）
