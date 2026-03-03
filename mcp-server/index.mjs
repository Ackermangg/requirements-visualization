import { GoogleGenAI } from "@google/genai";
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";
import fs from "fs";
import path from "path";

const API_KEY = process.env.GEMINI_API_KEY;
const BASE_URL = process.env.GEMINI_API_BASE_URL;
const MODEL_ID = process.env.GEMINI_MODEL_ID || "gemini-3-pro-image-preview";

if (!API_KEY) {
  console.error("Error: GEMINI_API_KEY environment variable is required");
  process.exit(1);
}

const aiConfig = { apiKey: API_KEY };
if (BASE_URL) {
  aiConfig.httpOptions = { baseUrl: BASE_URL };
}

const ai = new GoogleGenAI(aiConfig);

const server = new McpServer({
  name: "gemini-image",
  version: "1.0.0",
});

server.tool(
  "generate_image",
  "Generate an image using Gemini (Nano Banana Pro). Provide a detailed English prompt with Chinese text in quotes for text rendering.",
  {
    prompt: z.string().describe("Image generation prompt (English recommended, Chinese text in quotes)"),
    outputPath: z.string().describe("Absolute file path to save the generated image (e.g., /path/to/output.png)"),
    aspectRatio: z
      .enum(["1:1", "3:4", "4:3", "9:16", "16:9"])
      .default("16:9")
      .describe("Aspect ratio of the generated image"),
  },
  async ({ prompt, outputPath, aspectRatio }) => {
    try {
      const outputDir = path.dirname(outputPath);
      if (!fs.existsSync(outputDir)) {
        fs.mkdirSync(outputDir, { recursive: true });
      }

      const response = await ai.models.generateContent({
        model: MODEL_ID,
        contents: [{ role: "user", parts: [{ text: prompt }] }],
        config: {
          responseModalities: ["IMAGE", "TEXT"],
          imageGenerationConfig: {
            aspectRatio: aspectRatio,
          },
        },
      });

      const candidates = response.candidates;
      if (!candidates || candidates.length === 0) {
        return {
          content: [{ type: "text", text: "Error: No candidates in response" }],
          isError: true,
        };
      }

      const parts = candidates[0].content.parts;
      let imageFound = false;
      let textResponse = "";

      for (const part of parts) {
        if (part.inlineData && part.inlineData.mimeType?.startsWith("image/")) {
          const imageBuffer = Buffer.from(part.inlineData.data, "base64");
          fs.writeFileSync(outputPath, imageBuffer);
          imageFound = true;
        }
        if (part.text) {
          textResponse += part.text;
        }
      }

      if (!imageFound) {
        return {
          content: [
            {
              type: "text",
              text: `Error: No image data in response. Model response: ${textResponse || "(empty)"}`,
            },
          ],
          isError: true,
        };
      }

      const stats = fs.statSync(outputPath);
      const sizeKB = Math.round(stats.size / 1024);

      return {
        content: [
          {
            type: "text",
            text: `Image generated successfully!\nPath: ${outputPath}\nSize: ${sizeKB} KB\nAspect Ratio: ${aspectRatio}\nModel: ${MODEL_ID}${textResponse ? `\nModel notes: ${textResponse}` : ""}`,
          },
        ],
      };
    } catch (error) {
      return {
        content: [
          {
            type: "text",
            text: `Error generating image: ${error.message}`,
          },
        ],
        isError: true,
      };
    }
  }
);

server.tool(
  "edit_image",
  "Edit an existing image using Gemini. Provide the source image and editing instructions.",
  {
    prompt: z.string().describe("Editing instructions for the image"),
    sourceImagePath: z.string().describe("Absolute path to the source image file"),
    outputPath: z.string().describe("Absolute path to save the edited image"),
  },
  async ({ prompt, sourceImagePath, outputPath }) => {
    try {
      if (!fs.existsSync(sourceImagePath)) {
        return {
          content: [{ type: "text", text: `Error: Source image not found: ${sourceImagePath}` }],
          isError: true,
        };
      }

      const outputDir = path.dirname(outputPath);
      if (!fs.existsSync(outputDir)) {
        fs.mkdirSync(outputDir, { recursive: true });
      }

      const imageData = fs.readFileSync(sourceImagePath);
      const base64Image = imageData.toString("base64");
      const ext = path.extname(sourceImagePath).toLowerCase();
      const mimeType = ext === ".png" ? "image/png" : ext === ".webp" ? "image/webp" : "image/jpeg";

      const response = await ai.models.generateContent({
        model: MODEL_ID,
        contents: [
          {
            role: "user",
            parts: [
              { inlineData: { mimeType, data: base64Image } },
              { text: prompt },
            ],
          },
        ],
        config: {
          responseModalities: ["IMAGE", "TEXT"],
        },
      });

      const candidates = response.candidates;
      if (!candidates || candidates.length === 0) {
        return {
          content: [{ type: "text", text: "Error: No candidates in response" }],
          isError: true,
        };
      }

      const parts = candidates[0].content.parts;
      let imageFound = false;
      let textResponse = "";

      for (const part of parts) {
        if (part.inlineData && part.inlineData.mimeType?.startsWith("image/")) {
          const imageBuffer = Buffer.from(part.inlineData.data, "base64");
          fs.writeFileSync(outputPath, imageBuffer);
          imageFound = true;
        }
        if (part.text) {
          textResponse += part.text;
        }
      }

      if (!imageFound) {
        return {
          content: [
            {
              type: "text",
              text: `Error: No image data in response. Model response: ${textResponse || "(empty)"}`,
            },
          ],
          isError: true,
        };
      }

      const stats = fs.statSync(outputPath);
      const sizeKB = Math.round(stats.size / 1024);

      return {
        content: [
          {
            type: "text",
            text: `Image edited successfully!\nPath: ${outputPath}\nSize: ${sizeKB} KB\nModel: ${MODEL_ID}${textResponse ? `\nModel notes: ${textResponse}` : ""}`,
          },
        ],
      };
    } catch (error) {
      return {
        content: [{ type: "text", text: `Error editing image: ${error.message}` }],
        isError: true,
      };
    }
  }
);

async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
}

main().catch((error) => {
  console.error("Fatal error:", error);
  process.exit(1);
});
