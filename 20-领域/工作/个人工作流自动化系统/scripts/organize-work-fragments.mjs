#!/usr/bin/env node

import path from "node:path";
import {
  formatShanghaiTime,
  normalizeWhitespace,
  parseArgs,
  readJsonFile,
  readTextFile,
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
  const title = args.title || path.parse(inputPath).name;
  const fragments = loadFragments(inputPath);

  if (!fragments.length) {
    throw new Error("没有识别到可整理的工作碎片。");
  }

  const grouped = groupFragments(fragments);
  const markdown = renderMarkdown({ inputPath, outputPath, title, fragments, grouped });

  writeTextFile(outputPath, markdown);
  console.log(`已生成整理结果：${outputPath}`);
} catch (error) {
  console.error(`整理失败：${error.message}`);
  process.exit(1);
}

function printHelp() {
  console.log(`用法：
  node scripts/organize-work-fragments.mjs --input <txt/json文件> [--output <md文件>] [--title <标题>]
`);
}

function loadFragments(filePath) {
  if (filePath.toLowerCase().endsWith(".json")) {
    return normalizeFragmentList(extractFragmentsFromJson(readJsonFile(filePath)));
  }

  return normalizeFragmentList(extractFragmentsFromText(readTextFile(filePath)));
}

function extractFragmentsFromJson(root) {
  if (Array.isArray(root)) {
    return root.flatMap((item) => extractFragmentsFromJson(item));
  }

  if (typeof root === "string") {
    return [root];
  }

  if (!root || typeof root !== "object") {
    return [];
  }

  const directKeys = ["fragments", "items", "messages", "content", "text", "summary"];
  for (const key of directKeys) {
    if (key in root) {
      const extracted = extractFragmentsFromJson(root[key]);
      if (extracted.length) {
        return extracted;
      }
    }
  }

  return Object.values(root).flatMap((value) => extractFragmentsFromJson(value));
}

function extractFragmentsFromText(text) {
  return text
    .replace(/\r\n/g, "\n")
    .split("\n")
    .map((line) => line.replace(/^\s*(?:[-*•]|\d+[.)]|[A-Z][.)])\s*/, "").trim())
    .filter(Boolean);
}

function normalizeFragmentList(fragments) {
  const unique = new Set();

  return fragments
    .map((fragment) => normalizeWhitespace(fragment))
    .filter(Boolean)
    .filter((fragment) => {
      const key = fragment.toLowerCase();
      if (unique.has(key)) {
        return false;
      }
      unique.add(key);
      return true;
    });
}

function groupFragments(fragments) {
  const grouped = {
    todo: [],
    confirm: [],
    risk: [],
    idea: [],
    reference: [],
    note: []
  };

  fragments.forEach((fragment) => {
    grouped[detectBucket(fragment)].push(fragment);
  });

  return grouped;
}

function detectBucket(fragment) {
  const text = fragment.toLowerCase();

  if (/\[(待确认|确认|question)\]/i.test(fragment) || /是否|待确认|确认下|确认是否|\?/.test(fragment)) {
    return "confirm";
  }

  if (/\[(风险|问题|阻塞|risk)\]/i.test(fragment) || /风险|问题|bug|异常|阻塞|延期|卡住|失败/.test(fragment)) {
    return "risk";
  }

  if (/\[(待办|todo)\]/i.test(fragment) || /^(需要|待|跟进|安排|确认|补充|提交|推进|完成|更新)/.test(fragment)) {
    return "todo";
  }

  if (/\[(想法|灵感|idea)\]/i.test(fragment) || /想法|灵感|方案|机会|可以考虑|尝试|试试/.test(fragment)) {
    return "idea";
  }

  if (/\[(资料|参考|reference)\]/i.test(fragment) || /资料|链接|文档|参考|附件|录屏|会议纪要|截图/.test(fragment)) {
    return "reference";
  }

  return "note";
}

function renderMarkdown({ inputPath, title, fragments, grouped }) {
  const counts = [
    `待办 ${grouped.todo.length}`,
    `待确认 ${grouped.confirm.length}`,
    `风险 ${grouped.risk.length}`,
    `想法 ${grouped.idea.length}`,
    `资料 ${grouped.reference.length}`,
    `备注 ${grouped.note.length}`
  ].join("，");

  const lines = [
    `# ${title}`,
    "",
    `- Source: \`${path.basename(inputPath)}\``,
    `- Generated at: ${formatShanghaiTime()}`,
    `- Total fragments: ${fragments.length}`,
    "",
    "## 一句话摘要",
    "",
    `本次共整理 ${fragments.length} 条工作碎片：${counts}。`,
    ""
  ];

  appendSection(lines, "待办事项", grouped.todo, (item) => `- [ ] ${item}`);
  appendSection(lines, "待确认事项", grouped.confirm, (item) => `- ${item}`);
  appendSection(lines, "风险与问题", grouped.risk, (item) => `- ${item}`);
  appendSection(lines, "想法与机会", grouped.idea, (item) => `- ${item}`);
  appendSection(lines, "资料与背景", grouped.reference, (item) => `- ${item}`);
  appendSection(lines, "补充备注", grouped.note, (item) => `- ${item}`);

  lines.push("## 建议下一步");
  lines.push("");
  buildNextSteps(grouped).forEach((step) => lines.push(`- ${step}`));
  lines.push("");
  lines.push("## 原始碎片归档");
  lines.push("");
  fragments.forEach((fragment, index) => lines.push(`${index + 1}. ${fragment}`));
  lines.push("");

  return lines.join("\n").trimEnd() + "\n";
}

function appendSection(lines, title, items, formatter) {
  if (!items.length) {
    return;
  }

  lines.push(`## ${title}`);
  lines.push("");
  items.forEach((item) => lines.push(formatter(item)));
  lines.push("");
}

function buildNextSteps(grouped) {
  const steps = [];

  if (grouped.todo.length) {
    steps.push("先从“待办事项”里挑 1-3 项设为本周优先动作。");
  }

  if (grouped.confirm.length) {
    steps.push("把“待确认事项”发回 QCLAW 或相关对象做下一轮确认。");
  }

  if (grouped.risk.length) {
    steps.push("为“风险与问题”补上负责人、截止时间或兜底方案。");
  }

  if (grouped.reference.length) {
    steps.push("把“资料与背景”里的条目补上明确链接或存放位置。");
  }

  if (grouped.idea.length) {
    steps.push("把值得保留的灵感移动到“💡灵感记录”或后续专题文档中。");
  }

  if (!steps.length) {
    steps.push("当前碎片以备注为主，可以先保留，等待下次合并整理。");
  }

  return steps;
}
