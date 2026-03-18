#!/bin/bash
# EX-RequireAgent 一键安装脚本
# 用法：curl -sSL https://raw.githubusercontent.com/ShieldBytes/EX-RequireAgent/main/install.sh | bash

set -e

REPO="https://github.com/ShieldBytes/EX-RequireAgent.git"
INSTALL_DIR="$HOME/.claude/ex-require-agent"
COMMANDS_DIR="$HOME/.claude/commands"

echo "🚀 安装 EX-RequireAgent..."

# 1. 克隆或更新仓库到全局目录
if [ -d "$INSTALL_DIR" ]; then
  echo "📦 更新已有安装..."
  cd "$INSTALL_DIR" && git pull --quiet
else
  echo "📦 下载插件..."
  git clone --quiet "$REPO" "$INSTALL_DIR"
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

echo ""
echo "✅ 安装完成！"
echo ""
echo "📁 安装位置：$INSTALL_DIR"
echo "📁 命令位置：$COMMANDS_DIR/require*.md"
echo ""
echo "使用方法（在任意目录下）："
echo "  claude"
echo "  /model opus"
echo "  /require \"你的需求描述\""
echo ""
echo "更新方法："
echo "  重新运行本脚本即可"
