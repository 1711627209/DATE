#!/usr/bin/env node

import path from "node:path";
import {
  formatShanghaiTime,
  normalizeWhitespace,
  parseArgs,
  readJsonFile,
  replaceExtension,
  requireArg,
  writeTextFile
} from "./lib/workflow-utils.mjs";

const args = parseArgs(process.argv.slice(2));

if (args.help) {
  printHelp();
  process.exit(0);
}

try {
  const inputPath = requireArg(args, "input");
  const outputPath = args.output || replaceExtension(inputPath, ".md");
  const fallbackTitle = args.title || path.parse(inputPath).name;
  const root = readJsonFile(inputPath);
  const conversations = extractConversations(root, fallbackTitle);

  if (!conversations.length) {
    throw new Error("未识别到可转换的对话消息，请先用一份真实导出样本补充解析规则。");
  }

  const markdown = renderMarkdown({
    inputPath,
    documentTitle: fallbackTitle,
    conversations
  });

  writeTextFile(outputPath, markdown);
  console.log(`已生成 Markdown：${outputPath}`);
} catch (error) {
  console.error(`转换失败：${error.message}`);
  process.exit(1);
}

function printHelp() {
  console.log(`用法：
  node scripts/convert-ai-chat.mjs --input <json文件> [--output <md文件>] [--title <标题>]
`);
}

function renderMarkdown({ inputPath, documentTitle, conversations }) {
  const lines = [
    `# ${documentTitle}`,
    "",
    `- Source: \`${path.basename(inputPath)}\``,
    `- Converted at: ${formatShanghaiTime()}`,
    `- Conversations: ${conversations.length}`,
    ""
  ];

  conversations.forEach((conversation, conversationIndex) => {
    const title = conversation.title || `对话 ${conversationIndex + 1}`;
    lines.push(`## ${title}`);
    lines.push("");

    if (!conversation.messages.length) {
      lines.push("_无可识别消息_");
      lines.push("");
      return;
    }

    conversation.messages.forEach((message, messageIndex) => {
      const order = String(messageIndex + 1).padStart(2, "0");
      const label = toDisplayRole(message.role);
      const timeLabel = message.timestamp ? ` | ${message.timestamp}` : "";
      lines.push(`### ${order}. ${label}${timeLabel}`);
      lines.push("");
      lines.push(message.content);
      lines.push("");
    });
  });

  return lines.join("\n").trimEnd() + "\n";
}

function toDisplayRole(role) {
  const map = {
    user: "用户",
    assistant: "AI",
    system: "系统",
    tool: "工具",
    developer: "开发者",
    unknown: "未知角色"
  };
  return map[String(role || "unknown").toLowerCase()] || String(role || "未知角色");
}

function extractConversations(root, fallbackTitle) {
  if (Array.isArray(root)) {
    if (root.some(isMessageLike)) {
      return [{ title: fallbackTitle, messages: normalizeMessageList(root) }];
    }

    return root.flatMap((item, index) => {
      const itemTitle = item?.title || `${fallbackTitle} ${index + 1}`;
      return extractConversations(item, itemTitle);
    });
  }

  if (!root || typeof root !== "object") {
    return [];
  }

  if (Array.isArray(root.messages)) {
    return [{ title: root.title || fallbackTitle, messages: normalizeMessageList(root.messages) }];
  }

  if (Array.isArray(root.items) && root.items.some(isMessageLike)) {
    return [{ title: root.title || fallbackTitle, messages: normalizeMessageList(root.items) }];
  }

  if (Array.isArray(root.conversations)) {
    return root.conversations.flatMap((item, index) => {
      const itemTitle = item?.title || `${fallbackTitle} ${index + 1}`;
      return extractConversations(item, itemTitle);
    });
  }

  if (root.mapping && typeof root.mapping === "object") {
    const messages = extractMessagesFromMapping(root.mapping);
    if (messages.length) {
      return [{ title: root.title || fallbackTitle, messages }];
    }
  }

  const fallbackArrays = [];
  collectMessageArrays(root, fallbackArrays, new Set(), 0);
  return fallbackArrays.map((messages, index) => ({
    title: index === 0 ? fallbackTitle : `${fallbackTitle} ${index + 1}`,
    messages: normalizeMessageList(messages)
  }));
}

function collectMessageArrays(node, results, seen, depth) {
  if (!node || typeof node !== "object" || seen.has(node) || depth > 6) {
    return;
  }

  seen.add(node);

  if (Array.isArray(node)) {
    if (node.some(isMessageLike)) {
      results.push(node);
      return;
    }

    node.forEach((item) => collectMessageArrays(item, results, seen, depth + 1));
    return;
  }

  Object.values(node).forEach((value) => collectMessageArrays(value, results, seen, depth + 1));
}

function normalizeMessageList(messages) {
  return messages
    .map((message, index) => normalizeMessage(message, index))
    .filter(Boolean)
    .sort((left, right) => (left.sortKey || Number.MAX_SAFE_INTEGER) - (right.sortKey || Number.MAX_SAFE_INTEGER));
}

function normalizeMessage(entry, index) {
  const raw = entry?.message && typeof entry.message === "object" ? entry.message : entry;
  const role = extractRole(raw) || extractRole(entry) || "unknown";
  const content = extractMessageContent(raw) || extractMessageContent(entry);

  if (!content) {
    return null;
  }

  const sortKey = extractSortKey(raw) ?? extractSortKey(entry) ?? index;
  const timestamp = normalizeTimestamp(raw?.create_time ?? raw?.created_at ?? raw?.timestamp ?? entry?.create_time ?? entry?.created_at ?? entry?.timestamp);

  return {
    role,
    content,
    timestamp,
    sortKey
  };
}

function isMessageLike(value) {
  if (!value || typeof value !== "object") {
    return false;
  }

  const raw = value?.message && typeof value.message === "object" ? value.message : value;
  return Boolean(extractRole(raw) || extractMessageContent(raw));
}

function extractRole(value) {
  if (!value || typeof value !== "object") {
    return "";
  }

  const candidates = [
    value.role,
    value.author?.role,
    value.author,
    value.message?.author?.role,
    value.message?.role,
    value.type
  ];

  return candidates.find((candidate) => typeof candidate === "string" && candidate.trim()) || "";
}

function extractMessageContent(value) {
  if (!value || typeof value !== "object") {
    return typeof value === "string" ? normalizeWhitespace(value) : "";
  }

  const candidates = [
    value.content,
    value.parts,
    value.text,
    value.body,
    value.value,
    value.output_text,
    value.transcript,
    value.message,
    value.data?.content,
    value.data?.text
  ];

  for (const candidate of candidates) {
    const text = extractText(candidate);
    if (text) {
      return text;
    }
  }

  return "";
}

function extractText(value) {
  if (typeof value === "string") {
    return normalizeWhitespace(value);
  }

  if (Array.isArray(value)) {
    return normalizeWhitespace(value.map((item) => extractText(item)).filter(Boolean).join("\n\n"));
  }

  if (!value || typeof value !== "object") {
    return "";
  }

  const orderedKeys = ["parts", "text", "content", "body", "value", "markdown", "output_text", "transcript", "message"];

  for (const key of orderedKeys) {
    if (key in value) {
      const text = extractText(value[key]);
      if (text) {
        return text;
      }
    }
  }

  if (Array.isArray(value.items)) {
    const text = extractText(value.items);
    if (text) {
      return text;
    }
  }

  return "";
}

function extractSortKey(value) {
  const rawValue = value?.create_time ?? value?.created_at ?? value?.timestamp ?? value?.updated_at;

  if (typeof rawValue === "number") {
    return rawValue > 10_000_000_000 ? rawValue : rawValue * 1000;
  }

  if (typeof rawValue === "string") {
    const numeric = Number(rawValue);
    if (!Number.isNaN(numeric)) {
      return numeric > 10_000_000_000 ? numeric : numeric * 1000;
    }

    const parsed = Date.parse(rawValue);
    if (!Number.isNaN(parsed)) {
      return parsed;
    }
  }

  return undefined;
}

function normalizeTimestamp(value) {
  if (value === undefined || value === null || value === "") {
    return "";
  }

  if (typeof value === "number") {
    const normalized = value > 10_000_000_000 ? value : value * 1000;
    return formatShanghaiTime(new Date(normalized));
  }

  if (typeof value === "string") {
    const numeric = Number(value);
    if (!Number.isNaN(numeric)) {
      const normalized = numeric > 10_000_000_000 ? numeric : numeric * 1000;
      return formatShanghaiTime(new Date(normalized));
    }

    const parsed = Date.parse(value);
    if (!Number.isNaN(parsed)) {
      return formatShanghaiTime(new Date(parsed));
    }
  }

  return "";
}

function extractMessagesFromMapping(mapping) {
  return Object.values(mapping)
    .map((node) => normalizeMessage(node, 0))
    .filter(Boolean)
    .sort((left, right) => (left.sortKey || Number.MAX_SAFE_INTEGER) - (right.sortKey || Number.MAX_SAFE_INTEGER));
}
