#!/usr/bin/env node

import {
  formatShanghaiTime,
  normalizeWhitespace,
  parseArgs,
  requireArg,
  writeTextFile
} from "./lib/workflow-utils.mjs";

const args = parseArgs(process.argv.slice(2));

if (args.help) {
  printHelp();
  process.exit(0);
}

try {
  const mode = requireArg(args, "mode");
  const output = render(mode, args);

  if (args.output) {
    writeTextFile(args.output, output + "\n");
  }

  process.stdout.write(output + "\n");
} catch (error) {
  console.error(`生成失败：${error.message}`);
  process.exit(1);
}

function printHelp() {
  console.log(`用法：
  node scripts/render-workflow-message.mjs --mode confirm --details "..."
  node scripts/render-workflow-message.mjs --mode result --task "..." --details "..." --result "..." [--confirm "..."]
`);
}

function render(mode, args) {
  if (mode === "confirm") {
    const details = requireArg(args, "details");
    const consequence = normalizeWhitespace(args.consequence || "");
    return [
      "即将执行以下操作：",
      details,
      consequence ? `可能影响：${consequence}` : "",
      '是否确认执行？（回复"确认"执行，回复其他内容取消）'
    ]
      .filter(Boolean)
      .join("\n");
  }

  if (mode === "result") {
    const task = requireArg(args, "task");
    const details = requireArg(args, "details");
    const result = requireArg(args, "result");
    const confirm = normalizeWhitespace(args.confirm || "无");
    const time = normalizeWhitespace(args.time || formatShanghaiTime());

    return [
      "【工作流执行结果】",
      `任务：${task}`,
      `执行时间：${time}`,
      `处理内容：${details}`,
      `结果：${result}`,
      `确认：${confirm}`
    ].join("\n");
  }

  throw new Error(`不支持的 mode：${mode}`);
}
