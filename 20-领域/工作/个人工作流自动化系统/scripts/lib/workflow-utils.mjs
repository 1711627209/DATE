import fs from "node:fs";
import path from "node:path";

const shanghaiFormatter = new Intl.DateTimeFormat("sv-SE", {
  timeZone: "Asia/Shanghai",
  year: "numeric",
  month: "2-digit",
  day: "2-digit",
  hour: "2-digit",
  minute: "2-digit",
  second: "2-digit",
  hour12: false
});

export function parseArgs(argv) {
  const args = {};

  for (let index = 0; index < argv.length; index += 1) {
    const token = argv[index];

    if (!token.startsWith("--")) {
      if (!args._) {
        args._ = [];
      }
      args._.push(token);
      continue;
    }

    const key = token.slice(2);
    const next = argv[index + 1];

    if (!next || next.startsWith("--")) {
      args[key] = true;
      continue;
    }

    args[key] = next;
    index += 1;
  }

  return args;
}

export function requireArg(args, name) {
  if (!args[name]) {
    throw new Error(`缺少必要参数 --${name}`);
  }
  return args[name];
}

export function readTextFile(filePath) {
  return fs.readFileSync(filePath, "utf8").replace(/^\uFEFF/, "");
}

export function readJsonFile(filePath) {
  return JSON.parse(readTextFile(filePath));
}

export function ensureParentDir(filePath) {
  fs.mkdirSync(path.dirname(path.resolve(filePath)), { recursive: true });
}

export function writeTextFile(filePath, content) {
  ensureParentDir(filePath);
  fs.writeFileSync(filePath, content, "utf8");
}

export function replaceExtension(filePath, nextExtension) {
  const parsed = path.parse(path.resolve(filePath));
  return path.join(parsed.dir, `${parsed.name}${nextExtension}`);
}

export function formatShanghaiTime(value = new Date()) {
  const date = value instanceof Date ? value : new Date(value);
  const parts = Object.fromEntries(
    shanghaiFormatter
      .formatToParts(date)
      .filter((part) => part.type !== "literal")
      .map((part) => [part.type, part.value])
  );

  return `${parts.year}-${parts.month}-${parts.day} ${parts.hour}:${parts.minute}:${parts.second}`;
}

export function normalizeWhitespace(value) {
  return String(value || "")
    .replace(/\r\n/g, "\n")
    .replace(/\u00a0/g, " ")
    .replace(/[ \t]+/g, " ")
    .replace(/\n{3,}/g, "\n\n")
    .trim();
}

export function toArray(value) {
  if (Array.isArray(value)) {
    return value;
  }
  if (value === undefined || value === null) {
    return [];
  }
  return [value];
}
