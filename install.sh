#!/bin/bash
# ============================================================
# Requirements Visualization Skills - Installer
# https://github.com/Ackermangg/requirements-visualization
# ============================================================

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SOURCE="$REPO_DIR/.claude/skills"

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║       需求可视化 Skills 安装器                         ║"
echo "║  /图解  +  /流程图                                    ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""

# ── 选择 Agent 工具 ───────────────────────────────────────────
echo "请选择你使用的 AI Agent 工具："
echo "  1) Claude Code"
echo "  2) Cursor"
echo "  3) OpenAI Codex CLI"
echo "  4) 手动指定目录"
echo ""
read -rp "请输入 1-4 [默认: 1]: " TOOL_CHOICE
TOOL_CHOICE="${TOOL_CHOICE:-1}"

case "$TOOL_CHOICE" in
  1)
    TOOL_NAME="Claude Code"
    echo ""
    echo "安装位置："
    echo "  1) 全局 (~/.claude/skills/)  — 所有项目均可使用 [推荐]"
    echo "  2) 当前项目 (.claude/skills/)"
    echo ""
    read -rp "请输入 1 或 2 [默认: 1]: " SCOPE_CHOICE
    SCOPE_CHOICE="${SCOPE_CHOICE:-1}"
    if [ "$SCOPE_CHOICE" = "2" ]; then
      read -rp "请输入你的项目路径 [默认: $(pwd)]: " PROJECT_PATH
      PROJECT_PATH="${PROJECT_PATH:-$(pwd)}"
      TARGET_DIR="$PROJECT_PATH/.claude/skills"
    else
      TARGET_DIR="$HOME/.claude/skills"
    fi
    ;;
  2)
    TOOL_NAME="Cursor"
    echo ""
    echo "Cursor 的 Skills 安装在项目的 .cursor/commands/ 目录中。"
    read -rp "请输入你的项目路径 [默认: $(pwd)]: " PROJECT_PATH
    PROJECT_PATH="${PROJECT_PATH:-$(pwd)}"
    TARGET_DIR="$PROJECT_PATH/.cursor/commands"
    ;;
  3)
    TOOL_NAME="OpenAI Codex CLI"
    TARGET_DIR="$HOME/.codex/skills"
    ;;
  4)
    TOOL_NAME="自定义"
    read -rp "请输入目标目录路径: " TARGET_DIR
    if [ -z "$TARGET_DIR" ]; then
      echo "错误：未输入目录路径，退出。"
      exit 1
    fi
    ;;
  *)
    echo "无效选项，退出。"
    exit 1
    ;;
esac

echo ""
echo "→ 工具：$TOOL_NAME"
echo "→ 安装到：$TARGET_DIR"
echo ""

# ── 复制 Skills ───────────────────────────────────────────────
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
echo "[2/4] 检查 mermaid-cli（用于 /流程图 渲染 PNG）..."
if command -v mmdc &>/dev/null; then
  echo "  ✓ mermaid-cli 已安装"
else
  echo "  → 正在全局安装 @mermaid-js/mermaid-cli..."
  npm install -g @mermaid-js/mermaid-cli
  echo "  ✓ 安装完成"
fi

# ── 安装 MCP Server 依赖 ──────────────────────────────────────
echo ""
echo "[3/4] 安装 Gemini Image MCP Server 依赖（用于 /图解）..."
cd "$REPO_DIR/mcp-server"
npm install --silent
echo "  ✓ 依赖安装完成"
cd "$REPO_DIR"

# ── 配置 MCP Server ───────────────────────────────────────────
echo ""
echo "[4/4] 配置 Gemini Image MCP Server（用于 /图解）..."
echo "      （跳过则 /图解 的图片生成功能不可用，/流程图 不受影响）"
echo ""
read -rp "  是否现在配置 Gemini API？[Y/n]: " SETUP_MCP
SETUP_MCP="${SETUP_MCP:-Y}"

if [[ "$SETUP_MCP" =~ ^[Yy]$ ]]; then
  echo ""
  read -rp "  Gemini API Base URL（如 https://api.example.com/v1）: " API_BASE_URL
  read -rp "  Gemini API Key: " API_KEY
  read -rp "  Model ID [默认: google/gemini-3.1-flash-image-preview]: " MODEL_ID
  MODEL_ID="${MODEL_ID:-google/gemini-3.1-flash-image-preview}"

  MCP_SERVER_PATH="$REPO_DIR/mcp-server/index.mjs"

  echo ""
  case "$TOOL_CHOICE" in
    1)
      if command -v claude &>/dev/null; then
        claude mcp add gemini-image -s user \
          -e GEMINI_API_BASE_URL="$API_BASE_URL" \
          -e GEMINI_API_KEY="$API_KEY" \
          -e GEMINI_MODEL_ID="$MODEL_ID" \
          -- node "$MCP_SERVER_PATH"
        echo "  ✓ MCP Server 已注册到 Claude Code（gemini-image）"
      else
        echo "  ⚠ 未检测到 claude CLI，请手动执行："
        echo ""
        echo "  claude mcp add gemini-image -s user \\"
        echo "    -e GEMINI_API_BASE_URL=\"$API_BASE_URL\" \\"
        echo "    -e GEMINI_API_KEY=\"$API_KEY\" \\"
        echo "    -e GEMINI_MODEL_ID=\"$MODEL_ID\" \\"
        echo "    -- node \"$MCP_SERVER_PATH\""
      fi
      ;;
    2)
      echo "  Cursor 请在 Settings → MCP 中添加以下配置："
      echo ""
      echo '  {'
      echo '    "mcpServers": {'
      echo '      "gemini-image": {'
      echo "        \"command\": \"node\","
      echo "        \"args\": [\"$MCP_SERVER_PATH\"],"
      echo '        "env": {'
      echo "          \"GEMINI_API_BASE_URL\": \"$API_BASE_URL\","
      echo "          \"GEMINI_API_KEY\": \"$API_KEY\","
      echo "          \"GEMINI_MODEL_ID\": \"$MODEL_ID\""
      echo '        }'
      echo '      }'
      echo '    }'
      echo '  }'
      ;;
    3)
      echo "  Codex CLI 请在 ~/.codex/config.json 中添加 MCP Server 配置，"
      echo "  或参考：https://github.com/openai/codex-cli#mcp-servers"
      echo ""
      echo "  MCP Server 路径: $MCP_SERVER_PATH"
      echo "  环境变量: GEMINI_API_BASE_URL=$API_BASE_URL"
      ;;
    *)
      echo "  请参考你的 Agent 工具文档，注册以下 MCP Server："
      echo "  命令: node $MCP_SERVER_PATH"
      echo "  环境变量: GEMINI_API_BASE_URL / GEMINI_API_KEY / GEMINI_MODEL_ID"
      ;;
  esac
fi

# ── 完成 ──────────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║  ✓ 安装完成！重启 $TOOL_NAME 后生效              ║"
echo "╠══════════════════════════════════════════════════════╣"
echo "║  使用方法：                                            ║"
echo "║    /图解  [粘贴需求文本]   → 生成业务场景图解          ║"
echo "║    /流程图 [粘贴需求文本]  → 生成 Mermaid 逻辑流程图   ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""
