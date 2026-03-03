#!/bin/bash
# ============================================================
# Requirements Visualization Skills - Installer
# https://github.com/[YOUR_USERNAME]/requirements-visualization
# ============================================================

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SOURCE="$REPO_DIR/.claude/skills"

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║       需求可视化 Skills 安装器                         ║"
echo "║  /图解  +  /流程图  for Claude Code                   ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""

# ── 安装位置选择 ─────────────────────────────────────────────
echo "请选择安装位置："
echo "  1) 全局安装 (~/.claude/skills/)  — 所有项目均可使用 [推荐]"
echo "  2) 仅当前项目 (.claude/skills/)  — 仅当前目录可用"
echo ""
read -rp "请输入 1 或 2 [默认: 1]: " INSTALL_CHOICE
INSTALL_CHOICE="${INSTALL_CHOICE:-1}"

if [ "$INSTALL_CHOICE" = "2" ]; then
  TARGET_DIR="$(pwd)/.claude/skills"
  echo "→ 安装到当前项目: $TARGET_DIR"
else
  TARGET_DIR="$HOME/.claude/skills"
  echo "→ 安装到全局: $TARGET_DIR"
fi

# ── 复制 Skills ───────────────────────────────────────────────
echo ""
echo "[1/4] 复制 Skills 文件..."
mkdir -p "$TARGET_DIR"

for skill in 图解 流程图; do
  if [ -d "$SKILLS_SOURCE/$skill" ]; then
    cp -r "$SKILLS_SOURCE/$skill" "$TARGET_DIR/"
    echo "  ✓ $skill"
  else
    echo "  ✗ $skill (源文件不存在，跳过)"
  fi
done

# ── 安装 mermaid-cli ──────────────────────────────────────────
echo ""
echo "[2/4] 检查 mermaid-cli (用于 /流程图 渲染 PNG)..."
if command -v mmdc &>/dev/null; then
  echo "  ✓ mermaid-cli 已安装 ($(mmdc --version 2>/dev/null || echo 'ok'))"
else
  echo "  → 正在全局安装 @mermaid-js/mermaid-cli..."
  npm install -g @mermaid-js/mermaid-cli
  echo "  ✓ mermaid-cli 安装完成"
fi

# ── 安装 MCP Server 依赖 ──────────────────────────────────────
echo ""
echo "[3/4] 安装 Gemini Image MCP Server 依赖..."
cd "$REPO_DIR/mcp-server"
npm install --silent
echo "  ✓ MCP Server 依赖安装完成"
cd "$REPO_DIR"

# ── 配置 MCP Server ───────────────────────────────────────────
echo ""
echo "[4/4] 配置 Gemini Image MCP Server (用于 /图解)..."
echo ""
echo "  需要 Gemini API 访问信息（支持第三方兼容 API）："
echo ""
read -rp "  请输入 Gemini API Base URL (如 https://api.example.com/v1): " API_BASE_URL
read -rp "  请输入 Gemini API Key: " API_KEY
read -rp "  请输入 Model ID [默认: google/gemini-3.1-flash-image-preview]: " MODEL_ID
MODEL_ID="${MODEL_ID:-google/gemini-3.1-flash-image-preview}"

MCP_SERVER_PATH="$REPO_DIR/mcp-server/index.mjs"

if command -v claude &>/dev/null; then
  echo ""
  echo "  → 注册 MCP Server..."
  claude mcp add gemini-image -s user \
    -e GEMINI_API_BASE_URL="$API_BASE_URL" \
    -e GEMINI_API_KEY="$API_KEY" \
    -e GEMINI_MODEL_ID="$MODEL_ID" \
    -- node "$MCP_SERVER_PATH"
  echo "  ✓ MCP Server 注册完成 (gemini-image)"
else
  echo ""
  echo "  ⚠ 未检测到 claude CLI，请手动执行以下命令："
  echo ""
  echo "  claude mcp add gemini-image -s user \\"
  echo "    -e GEMINI_API_BASE_URL=\"$API_BASE_URL\" \\"
  echo "    -e GEMINI_API_KEY=\"$API_KEY\" \\"
  echo "    -e GEMINI_MODEL_ID=\"$MODEL_ID\" \\"
  echo "    -- node \"$MCP_SERVER_PATH\""
fi

# ── 完成 ──────────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║  ✓ 安装完成！                                         ║"
echo "╠══════════════════════════════════════════════════════╣"
echo "║  使用方法：                                            ║"
echo "║    /图解  [粘贴需求文本]    → 生成业务场景图解          ║"
echo "║    /流程图 [粘贴需求文本]   → 生成 Mermaid 逻辑流程图   ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""
