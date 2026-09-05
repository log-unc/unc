import { readFileSync, writeFileSync, mkdirSync, readdirSync, copyFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { buildEntry } from "../src/parser.mjs";

const here = dirname(fileURLToPath(import.meta.url));
const siteRoot = resolve(here, "..");
const projectRoot = resolve(siteRoot, "..");

const loggersDir = join(siteRoot, "loggers");
const publicDir = join(siteRoot, "public");
const dataDir = join(publicDir, "data");
const vendorDir = join(publicDir, "vendor");

const scriptSource = join(projectRoot, "Log-Unc-V1.lua");
const scriptTarget = join(publicDir, "script.lua");

const failures = [];
const entries = [];

function readSubmissions() {
  let files;

  try {
    files = readdirSync(loggersDir).filter((file) => file.endsWith(".json"));
  } catch {
    return [];
  }

  return files.sort();
}

for (const file of readSubmissions()) {
  const path = join(loggersDir, file);
  const slug = file.replace(/\.json$/, "");

  let submission;

  try {
    submission = JSON.parse(readFileSync(path, "utf8"));
  } catch (error) {
    failures.push(`${file}: invalid JSON (${error.message})`);
    continue;
  }

  if (typeof submission.name !== "string" || submission.name.trim().length === 0) {
    failures.push(`${file}: "name" is required`);
    continue;
  }

  if (typeof submission.output !== "string" || submission.output.trim().length === 0) {
    failures.push(`${file}: "output" is required`);
    continue;
  }

  const entry = buildEntry({ ...submission, slug });

  if (entry.counts.total === 0) {
    failures.push(`${file}: no checks were recognised in "output"`);
    continue;
  }

  if (entries.some((existing) => existing.slug === entry.slug)) {
    failures.push(`${file}: duplicate slug "${entry.slug}"`);
    continue;
  }

  entries.push(entry);
}

entries.sort((first, second) => {
  if (second.score !== first.score) {
    return second.score - first.score;
  }

  if (second.counts.passed !== first.counts.passed) {
    return second.counts.passed - first.counts.passed;
  }

  return first.name.localeCompare(second.name);
});

mkdirSync(dataDir, { recursive: true });
mkdirSync(vendorDir, { recursive: true });

const index = entries.map((entry) => ({
  slug: entry.slug,
  name: entry.name,
  author: entry.author,
  url: entry.url,
  reference: entry.reference,
  submittedAt: entry.submittedAt,
  score: entry.score,
  counts: entry.counts,
  environment: entry.environment,
  executor: entry.executor
}));

writeFileSync(
  join(dataDir, "index.json"),
  `${JSON.stringify(index, null, 2)}\n`,
  "utf8"
);

for (const entry of entries) {
  writeFileSync(
    join(dataDir, `${entry.slug}.json`),
    `${JSON.stringify(entry, null, 2)}\n`,
    "utf8"
  );
}

copyFileSync(join(siteRoot, "src", "parser.mjs"), join(vendorDir, "parser.mjs"));

let scriptLines = 0;

try {
  const source = readFileSync(scriptSource, "utf8");

  writeFileSync(scriptTarget, source, "utf8");
  scriptLines = source.split("\n").length;
} catch (error) {
  failures.push(`Log-Unc-V1.lua: ${error.message}`);
}

const reference = entries.find((entry) => entry.reference) ?? entries[0] ?? null;

writeFileSync(
  join(dataDir, "meta.json"),
  `${JSON.stringify(
    {
      generatedAt: new Date().toISOString(),
      loggers: entries.length,
      scriptLines,
      referenceChecks: reference ? reference.counts.total : 0
    },
    null,
    2
  )}\n`,
  "utf8"
);

for (const entry of entries) {
  const label = `${entry.name} (${entry.slug})`;
  const line =
    `${label}: ${entry.score}% - ` +
    `${entry.counts.passed} passed, ${entry.counts.failed} failed, ` +
    `${entry.counts.skipped} skipped`;

  console.log(line);

  for (const warning of entry.warnings) {
    console.log(`  note: ${warning}`);
  }
}

console.log(
  `\n${entries.length} logger${entries.length === 1 ? "" : "s"}, ` +
    `${scriptLines} script lines`
);

if (failures.length > 0) {
  console.error(`\n${failures.length} problem${failures.length === 1 ? "" : "s"}:`);

  for (const failure of failures) {
    console.error(`  ${failure}`);
  }

  process.exit(1);
}
