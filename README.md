# 需求可视化 Skills

将复杂业务需求文档瞬间转化为**图解**和**逻辑流程图**的跨平台 AI Agent Skills。

> **Skills 是模型无关的**：每个 Skill 是一份 prompt 指令集，由宿主工具的 AI 模型来理解和执行——Claude Code 用 Claude，Cursor 用 Cursor 内置模型，Codex CLI 用 OpenAI 模型，以此类推。`/图解` 调用 Gemini 的只是图片生成那一步（通过 MCP 工具），需求分析和 prompt 构建由宿主模型完成。

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
git clone https://github.com/Ackermangg/requirements-visualization
cd requirements-visualization
chmod +x install.sh
./install.sh
```

安装脚本会询问你使用的 Agent 工具，并将 Skills 复制到对应目录：

| 工具 | Skills 目录 |
|------|------------|
| Claude Code（全局） | `~/.claude/skills/` |
| Claude Code（当前项目） | `{project}/.claude/skills/` |
| Cursor | `{project}/.cursor/commands/` |
| OpenAI Codex CLI | `~/.codex/skills/` |

此外还会：
- 检查并安装 `mermaid-cli`（用于 `/流程图` PNG 渲染）
- 安装 MCP Server 依赖，并引导配置 Gemini API

## 手动安装

### 第一步：复制 Skills 到对应工具目录

**Claude Code（全局，推荐）**
```bash
mkdir -p ~/.claude/skills
cp -r .claude/skills/图解 ~/.claude/skills/
cp -r .claude/skills/流程图 ~/.claude/skills/
```

**Cursor**
```bash
mkdir -p /your-project/.cursor/commands
cp -r .claude/skills/图解 /your-project/.cursor/commands/
cp -r .claude/skills/流程图 /your-project/.cursor/commands/
```

**OpenAI Codex CLI**
```bash
mkdir -p ~/.codex/skills
cp -r .claude/skills/图解 ~/.codex/skills/
cp -r .claude/skills/流程图 ~/.codex/skills/
```

### 第二步：安装 mermaid-cli（`/流程图` 必需）

```bash
npm install -g @mermaid-js/mermaid-cli
```

### 第三步：配置 Gemini Image MCP Server（`/图解` 必需）

```bash
cd mcp-server && npm install && cd ..
```

**Claude Code**
```bash
claude mcp add gemini-image -s user \
  -e GEMINI_API_BASE_URL="https://your-api-endpoint/v1" \
  -e GEMINI_API_KEY="your-api-key" \
  -e GEMINI_MODEL_ID="google/gemini-3.1-flash-image-preview" \
  -- node "$(pwd)/mcp-server/index.mjs"
```

**Cursor**：Settings → MCP → 添加：
```json
{
  "mcpServers": {
    "gemini-image": {
      "command": "node",
      "args": ["/path/to/mcp-server/index.mjs"],
      "env": {
        "GEMINI_API_BASE_URL": "https://your-api-endpoint/v1",
        "GEMINI_API_KEY": "your-api-key",
        "GEMINI_MODEL_ID": "google/gemini-3.1-flash-image-preview"
      }
    }
  }
}
```

**Codex CLI / 其他工具**：参考各工具的 MCP Server 配置文档。

## 使用方法

安装后重启 agent 工具，在任意项目中使用：

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

两个 Skill 均为模型无关的 prompt 指令集，可运行在任何支持 SKILL.md 格式的 agent 工具上。

| 工具 | `/图解` | `/流程图` | 说明 |
|------|--------|---------|------|
| **Claude Code** | ✅ | ✅ | 完整支持，含 MCP；推荐使用 |
| **VS Code Copilot** | ✅ | ✅ | 需在 VS Code 中配置 `gemini-image` MCP Server |
| **OpenAI Codex CLI** | ✅ | ✅ | 需配置 MCP Server；`mermaid-cli` 需全局安装 |
| **Cursor** | ✅ | ✅ | 将 SKILL.md 内容复制到 `.cursor/rules/` 或 `.cursor/commands/` 中即可 |

> **`/图解` 的前提**：需要在宿主工具中注册 `gemini-image` MCP Server，图片生成才能工作。注册方式见下方"手动安装"。

## 技术架构

```
用户输入需求文本/截图
       ↓
  Agent Skill（prompt 指令集，由宿主模型执行）
       ↓
  宿主 AI 模型深度分析需求
  （Claude / GPT-4 / Cursor AI / 任意模型）
       ↓
  ┌──────────────────┬──────────────────┐
  │  /图解            │  /流程图           │
  │  宿主模型构建      │  宿主模型生成       │
  │  图片生成 prompt  │  Mermaid 代码      │
  │       ↓           │       ↓           │
  │  gemini-image     │  mermaid-cli      │
  │  MCP Server       │  渲染 PNG         │
  │  （图片生成工具，  │                   │
  │   与宿主模型无关） │                   │
  └──────────────────┴──────────────────┘
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
