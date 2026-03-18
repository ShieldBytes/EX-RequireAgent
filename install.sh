#!/bin/bash
# EX-RequireAgent 安装/更新/卸载脚本
#
# 安装：curl -sSL https://raw.githubusercontent.com/ShieldBytes/EX-RequireAgent/main/install.sh | bash
# 更新：curl -sSL https://raw.githubusercontent.com/ShieldBytes/EX-RequireAgent/main/install.sh | bash -s update
# 卸载：curl -sSL https://raw.githubusercontent.com/ShieldBytes/EX-RequireAgent/main/install.sh | bash -s uninstall

set -e

REPO="https://github.com/ShieldBytes/EX-RequireAgent.git"
INSTALL_DIR="$HOME/.claude/ex-require-agent"
COMMANDS_DIR="$HOME/.claude/commands"
ACTION="${1:-install}"

# ============ 卸载 ============
if [ "$ACTION" = "uninstall" ]; then
  echo "🗑  卸载 EX-RequireAgent..."

  # 删除全局命令文件
  rm -f "$COMMANDS_DIR"/require.md
  rm -f "$COMMANDS_DIR"/require-*.md
  echo "  ✅ 已删除全局命令文件"

  # 删除安装目录
  if [ -d "$INSTALL_DIR" ]; then
    rm -rf "$INSTALL_DIR"
    echo "  ✅ 已删除安装目录 $INSTALL_DIR"
  fi

  echo ""
  echo "✅ 卸载完成！"
  echo ""
  echo "注意：以下数据未删除（包含你的项目数据）："
  echo "  - 各项目目录下的 .require-agent/（运行时数据）"
  echo "  - 各项目目录下的 docs/requirements/（需求文档）"
  echo "  如需彻底清理，请手动删除这些目录。"
  exit 0
fi

# ============ 更新 ============
if [ "$ACTION" = "update" ]; then
  if [ ! -d "$INSTALL_DIR" ]; then
    echo "❌ 未安装 EX-RequireAgent，请先安装"
    exit 1
  fi

  echo "🔄 更新 EX-RequireAgent..."
  cd "$INSTALL_DIR"

  OLD_VERSION=$(git rev-parse --short HEAD)
  git pull --quiet
  NEW_VERSION=$(git rev-parse --short HEAD)

  if [ "$OLD_VERSION" = "$NEW_VERSION" ]; then
    echo "✅ 已是最新版本（$NEW_VERSION）"
    exit 0
  fi

  echo "  📦 $OLD_VERSION → $NEW_VERSION"
  # 继续执行下方的命令文件更新逻辑
fi

# ============ 安装 ============
if [ "$ACTION" = "install" ]; then
  echo "🚀 安装 EX-RequireAgent..."

  if [ -d "$INSTALL_DIR" ]; then
    echo "📦 已存在，更新中..."
    cd "$INSTALL_DIR" && git pull --quiet
  else
    echo "📦 下载插件..."
    git clone --quiet "$REPO" "$INSTALL_DIR"
  fi
fi

# 2. 创建命令目录（如果不存在）
mkdir -p "$COMMANDS_DIR"

# 3. 创建全局入口命令（单文件，引用全局路径）
cat > "$COMMANDS_DIR/require.md" << 'CMDEOF'
---
description: 需求自优化 — 从模糊想法到精细 PRD 的自动迭代打磨
argument-hint: 需求描述或想法，或 --file <路径>，或 --resume
allowed-tools: ["Read", "Write", "Edit", "Bash", "Glob", "Grep", "Agent", "AskUserQuestion"]
---

<!-- EX-RequireAgent 全局入口 -->
<!-- 安装路径：~/.claude/ex-require-agent -->

请使用 Read 工具读取以下文件，然后严格按照其中的指令执行：

`~/.claude/ex-require-agent/.claude/commands/require.md`

注意：该文件中引用的所有相对路径（如 skills/、agents/、templates/、evolution/）都相对于 `~/.claude/ex-require-agent/` 目录。在读取 skill 文件时使用完整路径，如 `~/.claude/ex-require-agent/skills/require-init.md`。
CMDEOF

# 4. 为所有辅助命令创建全局入口
for cmd in help status stop pause focus skip add preview versions diff rollback tag export list archive clean stats save-template lock unlock split sync feedback config profile mode diagnose trace; do
  SRC="$INSTALL_DIR/.claude/commands/require-${cmd}.md"
  if [ -f "$SRC" ]; then
    # 提取原文件的 frontmatter
    DESC=$(grep "^description:" "$SRC" | head -1 | sed 's/description: //')
    HINT=$(grep "^argument-hint:" "$SRC" | head -1 | sed 's/argument-hint: //')
    TOOLS=$(grep "^allowed-tools:" "$SRC" | head -1 | sed 's/allowed-tools: //')
    
    cat > "$COMMANDS_DIR/require-${cmd}.md" << SUBCMDEOF
---
description: ${DESC}
${HINT:+argument-hint: ${HINT}}
allowed-tools: ${TOOLS:-["Read", "Write", "Glob"]}
---

请使用 Read 工具读取以下文件，然后严格按照其中的指令执行：

\`~/.claude/ex-require-agent/.claude/commands/require-${cmd}.md\`

注意：所有相对路径都相对于 \`~/.claude/ex-require-agent/\` 目录。
SUBCMDEOF
  fi
done

CMD_COUNT=$(ls "$COMMANDS_DIR"/require*.md 2>/dev/null | wc -l | tr -d ' ')

echo ""
if [ "$ACTION" = "update" ]; then
  echo "✅ 更新完成！已更新 $CMD_COUNT 个命令。"
else
  echo "✅ 安装完成！"
fi
echo ""
echo "📁 安装位置：$INSTALL_DIR"
echo "📁 命令数量：$CMD_COUNT 个"
echo ""
echo "使用方法（在任意目录下）："
echo "  claude"
echo "  /model opus"
echo "  /require \"你的需求描述\""
echo ""
echo "管理命令："
echo "  更新：curl -sSL https://raw.githubusercontent.com/ShieldBytes/EX-RequireAgent/main/install.sh | bash -s update"
echo "  卸载：curl -sSL https://raw.githubusercontent.com/ShieldBytes/EX-RequireAgent/main/install.sh | bash -s uninstall"
