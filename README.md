# 需求可视化 Skills for Claude Code

将复杂业务需求文档瞬间转化为**图解**和**逻辑流程图**的 Claude Code Skills。

## 包含的 Skills

### `/图解` — 业务场景图解

把抽象的需求规则放回真实业务场景中，让开发人员一眼看懂"这个需求要做什么、为什么这样设计"。

- 输入：需求文本或截图
- 输出：包含规则标注的场景示意图（PNG），由 Gemini Image 生成
- 支持 1-4 张分镜图（按需求复杂度自动规划）

### `/流程图` — 逻辑流程图

将需求逻辑转化为严谨的 Mermaid 图表，供开发人员按逻辑编写代码。

- 输入：需求文本或截图
- 输出：Mermaid 源码 + 渲染 PNG
- 自动选择图表类型：流程图 / 时序图 / 状态图 / ER 图 / 思维导图
- 支持多图分层（主流程 + 字段取值 + 状态生命周期）

## 快速安装

```bash
git clone https://github.com/[YOUR_USERNAME]/requirements-visualization
cd requirements-visualization
chmod +x install.sh
./install.sh
```

安装脚本会：
1. 复制 Skills 到 `~/.claude/skills/`（全局）或 `.claude/skills/`（当前项目）
2. 检查并安装 `mermaid-cli`（用于 `/流程图` PNG 渲染）
3. 安装 MCP Server 依赖
4. 引导配置 Gemini API（支持第三方兼容 API 地址）

## 手动安装

### 1. 安装 `/流程图`（无需 API Key）

```bash
# 全局安装
mkdir -p ~/.claude/skills
cp -r .claude/skills/流程图 ~/.claude/skills/

# 安装 mermaid-cli
npm install -g @mermaid-js/mermaid-cli
```

### 2. 安装 `/图解`（需要 Gemini Image API）

```bash
# 复制 Skill
cp -r .claude/skills/图解 ~/.claude/skills/

# 安装 MCP Server 依赖
cd mcp-server && npm install && cd ..

# 注册 MCP Server（支持第三方 Gemini 兼容 API）
claude mcp add gemini-image -s user \
  -e GEMINI_API_BASE_URL="https://your-api-endpoint/v1" \
  -e GEMINI_API_KEY="your-api-key" \
  -e GEMINI_MODEL_ID="google/gemini-3.1-flash-image-preview" \
  -- node "$(pwd)/mcp-server/index.mjs"
```

## 使用方法

重启 Claude Code 后，在任意项目中使用：

```
/图解 [粘贴需求文本]
```

```
/流程图 [粘贴需求文本]
```

也可以先发截图，再输入：

```
/图解 请分析上面的截图
```

## 兼容性

| 工具 | `/图解` | `/流程图` | 说明 |
|------|--------|---------|------|
| **Claude Code** | ✅ | ✅ | 完整支持，含 MCP |
| **VS Code Copilot** | ⚠️ | ✅ | 图解需 MCP 配置；流程图完整支持 |
| **OpenAI Codex CLI** | ⚠️ | ✅ | 同上 |
| **Cursor** | ❌ | ✅ | Cursor 使用 `.cursor/commands/` 格式，Skills 需手动适配 |

## 技术架构

```
用户输入需求文本/截图
       ↓
  Claude Code Skill
       ↓
  Claude 深度分析需求
       ↓
  ┌──────────────┬──────────────────┐
  │  /图解        │  /流程图           │
  │  构建图片提示词│  生成 Mermaid 代码 │
  │       ↓       │       ↓           │
  │  Gemini Image │  mermaid-cli      │
  │  MCP Server   │  渲染 PNG         │
  └──────────────┴──────────────────┘
```

### MCP Server

`mcp-server/index.mjs` 是支持自定义 API 地址的轻量级 Gemini Image MCP Server：

- 使用 `@google/genai` SDK（官方 Node.js SDK）
- 通过 `httpOptions.baseUrl` 支持第三方 Gemini 兼容 API
- 提供 `generate_image` 和 `edit_image` 两个 MCP 工具

### 配置项

| 环境变量 | 说明 | 默认值 |
|---------|------|--------|
| `GEMINI_API_BASE_URL` | API 地址（支持第三方） | - |
| `GEMINI_API_KEY` | API Key | - |
| `GEMINI_MODEL_ID` | 模型 ID | `google/gemini-3.1-flash-image-preview` |

## 输出目录

Skills 执行时会在项目目录下创建：

```
output/
├── infographics/   # /图解 输出的 PNG 图片
└── diagrams/       # /流程图 输出的 .mmd 源码 + .png 图片
```

## License

MIT
