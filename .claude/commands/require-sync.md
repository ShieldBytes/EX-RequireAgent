---
description: 同步团队进化数据（push 推送 / pull 拉取 / undo 撤销 / ignore 屏蔽）
argument-hint: push / pull / undo / ignore <经验ID>
allowed-tools: ["Read", "Write", "Bash", "Glob"]
---

# 同步团队进化数据

evolution 目录（`~/.claude/ex-require-agent/evolution/`）本身是一个独立的 git 仓库，关联了团队共享仓库。同步操作直接在该目录中执行 git 命令。

用户输入参数：`$ARGUMENTS`

---

## 1. 前置检查

读取 `.require-agent/config.json`，获取 `share_level` 和 `user_id`。

检查 evolution 目录是否已关联远程仓库：
```bash
cd ~/.claude/ex-require-agent/evolution && git remote -v
```
如果没有 remote → 提示"共享仓库未关联，请重新运行安装脚本"，终止。

解析 `$ARGUMENTS` 确定子命令：push / pull / undo / ignore / 空（帮助）。

---

## 2. 子命令 push

```bash
cd ~/.claude/ex-require-agent/evolution

# 检查是否有新内容
if git status --porcelain | grep -q .; then
  # 按 share_level 处理（如果是 strategy_only，先删除 projects/ 和 calibration/ 的未提交文件）
  git add -A
  git commit -m "sync: {user_id} push at {ISO时间}"
  git push origin main
else
  echo "没有新的进化数据需要推送"
fi
```

**share_level 处理：**
- full → `git add -A`（全部提交）
- anonymized → 提交前将 projects/*.md 中的项目名替换为 hash
- strategy_only → 只 `git add strategies/`，不提交 projects/ 和 calibration/

推送成功 → "✅ 推送成功"
推送失败 → "⚠️ 推送失败，请检查网络或权限。数据已保存在本地，下次重试。"

---

## 3. 子命令 pull

```bash
cd ~/.claude/ex-require-agent/evolution
git pull origin main --quiet
```

拉取成功 → 统计新增文件数，展示：
```
📥 拉取完成
新增 {N} 个文件
```

拉取失败 → "⚠️ 拉取失败，请检查网络"

无新内容 → "已是最新"

---

## 4. 子命令 undo

```bash
cd ~/.claude/ex-require-agent/evolution
# 查看最近一次 pull 的提交
git log --oneline -3
```

展示最近提交，询问用户确认回滚到哪个版本。

用户确认后：
```bash
git reset --hard HEAD~1
```

"✅ 已回滚"

---

## 5. 子命令 ignore

从参数中提取经验 ID。

读取 config.json，将 ID 追加到 `sync_ignore_list` 数组。

在 evolution/ 中搜索匹配文件并删除。

"✅ 已屏蔽 {ID}"

---

## 6. 无参数帮助

```
/require-sync 用法：

  /require-sync push     推送本地进化数据到团队
  /require-sync pull     拉取团队最新经验
  /require-sync undo     撤销上次拉取
  /require-sync ignore <ID>  屏蔽特定经验

当前状态：
  远程仓库：{git remote -v 的输出}
  本地变更：{git status --short 的输出}
```
