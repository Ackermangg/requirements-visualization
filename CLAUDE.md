# 需求可视化工具

## 可用命令

- `/图解` - 分析复杂业务需求，生成直观的信息图解图片（通过 Nano Banana Pro / Gemini 3 Pro Image）
  - 用法：`/图解 [粘贴需求文本]` 或先发截图再输入 `/图解 请分析上面的截图`
  - 输出：需求分析摘要 + 图解图片

- `/流程图` - 分析业务需求逻辑，自动选择最合适的图表类型（流程图/时序图/状态图等），生成 Mermaid 代码并渲染为图片
  - 用法：`/流程图 [粘贴需求文本]` 或先发截图再输入 `/流程图 请分析上面的截图`
  - 输出：Mermaid 代码 + 渲染图片

## 输出目录

- `output/infographics/` - 图解图片
- `output/diagrams/` - 流程图（.mmd 源码 + .png 图片）

## MCP 工具

- `gemini-image`: 自定义 Gemini Image MCP Server
  - 支持自定义 API 地址、Key、模型 ID（通过环境变量配置）
  - 工具：`generate_image`（生成图片）、`edit_image`（编辑图片）

## 技术约定

- 图解图片默认 16:9 宽高比，信息密集时用 4:3
- Mermaid 节点 ID 用英文，标签用中文（避免渲染兼容性问题）
- 流程图渲染使用 mermaid-cli，3 倍缩放确保高清
