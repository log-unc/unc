import { readFileSync, writeFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { parseOutput, toEntry, slugify } from "./parse.mjs";

const here = dirname(fileURLToPath(import.meta.url));
const root = resolve(here, "..");

const args = process.argv.slice(2);

if (args.length === 0) {
  console.error("usage: node tools/convert.mjs <output.txt> [--name X] [--author Y] [--url Z] [--date YYYY-MM-DD]");
  process.exit(1);
}

const options = { name: "", author: "", url: "", date: "" };
const source = args[0];

for (let index = 1; index < args.length; index += 1) {
  const flag = args[index].replace(/^--/, "");

  if (Object.prototype.hasOwnProperty.call(options, flag)) {
    options[flag] = args[index + 1] ?? "";
    index += 1;
  }
}

const output = readFileSync(resolve(process.cwd(), source), "utf8");
const report = parseOutput(output);

if (report.total === 0) {
  console.error("no checks were recognised in that output");
  process.exit(1);
}

if (options.name.length === 0) {
  console.error("--name is required");
  process.exit(1);
}

const entry = toEntry({ ...options, output });
const slug = slugify(options.name);
const target = resolve(root, "loggers", `${slug}.json`);

writeFileSync(target, `${JSON.stringify(entry, null, 2)}\n`, "utf8");

const indexPath = resolve(root, "loggers", "index.json");
let files = [];

try {
  const parsed = JSON.parse(readFileSync(indexPath, "utf8"));

  files = Array.isArray(parsed.files) ? parsed.files : [];
} catch {
  files = [];
}

if (!files.includes(`${slug}.json`)) {
  files.push(`${slug}.json`);
  files.sort();

  writeFileSync(indexPath, `${JSON.stringify({ files }, null, 2)}\n`, "utf8");
}

const passed = report.total - report.failed.length - report.skipped.length;
const before = new TextEncoder().encode(output).length;
const after = new TextEncoder().encode(JSON.stringify(entry)).length;

console.log(`loggers/${slug}.json`);
console.log(`  ${passed} passed, ${report.failed.length} failed, ${report.skipped.length} skipped of ${report.total}`);
console.log(`  ${(before / 1024).toFixed(1)} KB output -> ${(after / 1024).toFixed(1)} KB entry`);

for (const warning of report.warnings) {
  console.log(`  note: ${warning}`);
}
