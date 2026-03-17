---
description: 同步团队进化数据（push 推送本地经验 / pull 拉取团队经验 / undo 撤销上次拉取 / ignore 屏蔽特定经验）
argument-hint: push / pull / undo / ignore <经验ID>
allowed-tools: ["Read", "Write", "Bash", "Glob"]
---

# 同步团队进化数据

你需要根据用户输入的子命令，执行相应的团队进化数据同步操作。

用户输入参数：`$ARGUMENTS`

---

## 1. 前置检查

读取 `.require-agent/config.json`，检查 `evolution_repo` 字段：

- **为空或不存在** → 输出以下提示后终止：
  ```
  ❌ 未配置共享仓库，请运行 /require 重新配置或手动编辑 .require-agent/config.json 的 evolution_repo 字段
  ```
- **不为空** → 同时记录以下配置值供后续使用：
  - `evolution_repo` — 共享仓库地址
  - `share_level` — 共享级别（full / anonymized / strategy_only）
  - `user_id` — 用户标识
  - `last_sync` — 上次同步时间戳
  - `sync_ignore_list` — 屏蔽列表（数组，可能不存在则视为空数组）

然后解析 `$ARGUMENTS`，确定子命令：
- 以 `push` 开头 → 执行 **子命令 push**
- 以 `pull` 开头 → 执行 **子命令 pull**
- 以 `undo` 开头 → 执行 **子命令 undo**
- 以 `ignore` 开头 → 执行 **子命令 ignore**，后续部分为经验 ID
- 为空或其他 → 执行 **无参数帮助**

---

## 2. 子命令 push

### 步骤 2.1 — 检查积压队列

检查 `.require-agent/sync-queue.json` 是否存在且非空数组：
- 存在且有内容 → 记录积压文件列表，后续一并推送
- 不存在或为空 → 跳过

### 步骤 2.2 — 创建临时目录

```bash
mkdir -p .require-agent/sync-tmp
```

### 步骤 2.3 — 克隆共享仓库

```bash
git clone --depth 1 {evolution_repo} .require-agent/sync-tmp/repo
```

如果克隆失败 → 提示"⚠️ 无法连接共享仓库，请检查网络和仓库地址"，清理临时目录后终止。

### 步骤 2.4 — 扫描本地新文件

以 `last_sync` 时间戳为基准（如果 last_sync 不存在则视为 epoch 0，即所有文件都是新的），扫描以下目录中在 last_sync 之后新增的文件：

- `evolution/projects/` 下的 `.md` 文件
- `evolution/strategies/` 下的 `.json` 文件
- `evolution/calibration/` 下的 `.json` 文件

使用 Bash 的 `find` 命令配合 `-newer` 或对比文件修改时间来筛选。

将积压队列中的文件也加入待推送列表。

如果没有新文件且没有积压 → 输出"没有新的进化数据需要推送"，清理临时目录后终止。

### 步骤 2.5 — 按 share_level 脱敏处理

根据 config.json 中的 `share_level` 对待推送文件进行不同级别的处理：

**full（完全共享）：**
- 直接复制文件，不做任何修改

**anonymized（匿名化）：**
- 复制文件时，将文件内容中的项目名替换为 `project-{hash前6位}`（hash 使用项目名的 MD5）
- 移除文件中所有 `intent-anchor` 相关的内容（包含 intent-anchor 的行或字段）

**strategy_only（仅策略）：**
- 只复制 `evolution/strategies/` 下的文件
- 且只保留每个 JSON 文件中 `records` 数组里每条记录的以下字段：
  - `dimension`
  - `strategy`
  - `result`
  - `score_change`
- 删除其他所有字段

### 步骤 2.6 — 复制到共享仓库

将处理后的文件复制到 `.require-agent/sync-tmp/repo/` 对应目录结构下：
- `evolution/projects/` → `repo/evolution/projects/`
- `evolution/strategies/` → `repo/evolution/strategies/`
- `evolution/calibration/` → `repo/evolution/calibration/`

确保目标目录存在（`mkdir -p`）。

### 步骤 2.7 — 写入审计日志

追加一行到 `.require-agent/sync-tmp/repo/sync-log.jsonl`：

```json
{"user":"{user_id}","action":"push","files":["文件路径1","文件路径2"],"timestamp":"{ISO时间}","share_level":"{share_level}"}
```

### 步骤 2.8 — 提交并推送

```bash
cd .require-agent/sync-tmp/repo
git add .
git commit -m "sync: push from {user_id} at {ISO时间}"
git push
```

**如果 git push 失败（权限/网络等原因）：**
1. 将待推送文件列表写入 `.require-agent/sync-queue.json`：
   ```json
   [{"file": "相对路径", "created": "ISO日期"}]
   ```
   如果已有积压队列，合并后写入（去重）。
2. 清理临时目录
3. 输出：
   ```
   ⚠️ 推送失败，数据已保存到待推送队列，下次 push 时自动重试
   队列中共 {N} 个文件待推送
   ```
4. 终止

### 步骤 2.9 — 清理临时目录

```bash
rm -rf .require-agent/sync-tmp
```

### 步骤 2.10 — 更新 last_sync

读取 config.json，将 `last_sync` 更新为当前 ISO 时间戳，写回文件。

### 步骤 2.11 — 清空积压队列

如果之前有积压且全部推送成功，删除 `.require-agent/sync-queue.json`。

### 步骤 2.12 — 展示结果

```
✅ 推送成功
推送了 {N} 个文件（共享级别：{share_level}）
- {文件1}
- {文件2}
...
```

如果包含积压文件，额外展示：
```
（其中 {M} 个为之前积压的文件）
```

---

## 3. 子命令 pull

### 步骤 3.1 — 备份当前本地进化数据

将 `evolution/` 目录打包备份：

```bash
mkdir -p .require-agent/evolution-backup
tar cf .require-agent/evolution-backup/backup-{ISO时间}.tar evolution/
```

如果 `evolution/` 目录不存在，跳过备份步骤。

### 步骤 3.2 — 克隆共享仓库

```bash
mkdir -p .require-agent/sync-tmp
git clone --depth 1 {evolution_repo} .require-agent/sync-tmp/repo
```

如果克隆失败 → 提示"⚠️ 无法连接共享仓库，请检查网络和仓库地址"，清理临时目录后终止。

### 步骤 3.3 — 增量同步

以 `last_sync` 时间戳为基准，只处理共享仓库中在 last_sync 之后新增或修改的文件。

遍历 `.require-agent/sync-tmp/repo/evolution/` 下的所有文件：
- `projects/*.md`
- `strategies/*.json`
- `calibration/*.json`

对每个文件：
1. 检查文件修改时间是否在 last_sync 之后（如果 last_sync 不存在则拉取全部）
2. 检查文件名/ID 是否在 `sync_ignore_list` 中，如果在则跳过
3. 通过以上检查的文件，复制到本地 `evolution/` 对应目录

统计：
- 新增项目经验数（projects/ 下的文件数）
- 新增策略记录数（strategies/ 下文件中的 records 条数总和）
- 来源成员数（根据文件名或内容中的 user 字段去重统计）

### 步骤 3.4 — 更新 last_sync

读取 config.json，将 `last_sync` 更新为当前 ISO 时间戳，写回文件。

### 步骤 3.5 — 清理临时目录

```bash
rm -rf .require-agent/sync-tmp
```

### 步骤 3.6 — 展示结果

如果有新内容：
```
📥 拉取完成
新增 {N} 个项目经验，{M} 条策略记录
来自 {K} 位团队成员
```

如果没有新内容：
```
已是最新，没有新的团队数据
```

---

## 4. 子命令 undo

### 步骤 4.1 — 查找最近的备份

使用 Glob 扫描 `.require-agent/evolution-backup/backup-*.tar`，按文件名排序取最新的一个。

如果没有找到任何备份文件：
```
没有可回滚的备份
```
终止。

### 步骤 4.2 — 展示备份信息

从文件名中提取备份时间（`backup-{ISO时间}.tar` 中的时间部分），展示：

```
找到备份：{备份时间}
回滚将恢复到此时间点的本地进化数据
确认？(Y/N)
```

等待用户回复。

### 步骤 4.3 — 执行回滚

用户确认 Y 后：

```bash
rm -rf evolution/
tar xf .require-agent/evolution-backup/backup-{ISO时间}.tar
```

### 步骤 4.4 — 展示结果

```
✅ 已回滚到 {备份时间}
```

---

## 5. 子命令 ignore

### 步骤 5.1 — 解析经验 ID

从 `$ARGUMENTS` 中提取 `ignore` 后面的经验 ID。

如果没有提供经验 ID：
```
请提供要屏蔽的经验 ID，例如：
/require-sync ignore wangwei-记账App-2026-03-15
```
终止。

### 步骤 5.2 — 更新屏蔽列表

读取 config.json：
- 如果 `sync_ignore_list` 不存在，创建为空数组
- 检查经验 ID 是否已在列表中，如果已存在 → 提示"该经验已在屏蔽列表中"，终止
- 将经验 ID 追加到 `sync_ignore_list` 数组
- 写回 config.json

### 步骤 5.3 — 检查并清理本地文件

在以下目录中搜索包含该经验 ID 的文件：
- `evolution/projects/`
- `evolution/strategies/`
- `evolution/calibration/`

如果找到匹配的文件，删除它们，并记录删除的文件列表。

### 步骤 5.4 — 展示结果

```
✅ 已屏蔽经验 {ID}，后续 pull 时将跳过
```

如果删除了本地文件，额外展示：
```
已清理本地文件：
- {文件1}
- {文件2}
```

---

## 6. 无参数时展示帮助

读取 config.json 获取配置信息，同时检查 `.require-agent/sync-queue.json` 获取积压数量，展示：

```
/require-sync 用法：

  /require-sync push          推送本地进化数据到团队共享仓库
  /require-sync pull          拉取团队最新进化数据
  /require-sync undo          撤销上次拉取，恢复到拉取前
  /require-sync ignore <ID>   屏蔽特定经验（本地不再加载）

配置：
  共享仓库：{evolution_repo 或 "未配置"}
  共享级别：{share_level}
  上次同步：{last_sync 或 "从未同步"}
  积压队列：{sync-queue.json 中的文件数量 或 0}
```
