const TIMESTAMP = /^\s*\d{1,2}:\d{2}:\d{2}\s*--\s?/;
const PASS = /^\[PASS\]\s+(.+)$/;
const ENTRY = /^(\d+)\.\s+(.+?)\s+\|\s+(.*)$/;
const SUMMARY = /^(Score|Environment|Passed|Failed|Skipped|Coverage):\s*(.+)$/;
const METRIC = /^([A-Za-z][A-Za-z0-9_]*):\s*(.*)$/;
const SEPARATOR = /^[=-]{6,}$/;

const SUMMARY_KEYS = new Set([
  "Score",
  "Environment",
  "Passed",
  "Failed",
  "Skipped",
  "Coverage"
]);

function toNumber(value) {
  const parsed = Number.parseFloat(String(value).replace("%", ""));

  return Number.isFinite(parsed) ? parsed : null;
}

export function parseOutput(text) {
  const passed = [];
  const failed = [];
  const skipped = [];
  const metrics = {};
  const summary = {};
  const warnings = [];

  let section = "log";

  for (const rawLine of String(text).split(/\r?\n/)) {
    const line = rawLine.replace(TIMESTAMP, "").trim();

    if (line.length === 0 || SEPARATOR.test(line) || line === "None") {
      continue;
    }

    if (line === "FAILED TESTS") {
      section = "failed";
      continue;
    }

    if (line === "SKIPPED TESTS") {
      section = "skipped";
      continue;
    }

    if (line === "METRICS") {
      section = "metrics";
      continue;
    }

    const passMatch = line.match(PASS);

    if (passMatch) {
      passed.push(passMatch[1].trim());
      continue;
    }

    const summaryMatch = line.match(SUMMARY);

    if (summaryMatch && SUMMARY_KEYS.has(summaryMatch[1])) {
      summary[summaryMatch[1]] = summaryMatch[2].trim();
      continue;
    }

    if (section === "failed" || section === "skipped") {
      const entryMatch = line.match(ENTRY);

      if (entryMatch) {
        const entry = {
          name: entryMatch[2].trim(),
          reason: entryMatch[3].trim()
        };

        if (section === "failed") {
          failed.push(entry);
        } else {
          skipped.push(entry);
        }

        continue;
      }
    }

    if (section === "metrics") {
      const metricMatch = line.match(METRIC);

      if (metricMatch) {
        metrics[metricMatch[1]] = metricMatch[2].trim();
      }
    }
  }

  const declaredPassed = toNumber(summary.Passed);
  const declaredFailed = toNumber(summary.Failed);
  const declaredSkipped = toNumber(summary.Skipped);

  if (declaredPassed !== null && declaredPassed !== passed.length) {
    warnings.push(
      `summary reports ${declaredPassed} passed, ${passed.length} PASS lines were found`
    );
  }

  if (declaredFailed !== null && declaredFailed !== failed.length) {
    warnings.push(
      `summary reports ${declaredFailed} failed, ${failed.length} entries were listed`
    );
  }

  if (declaredSkipped !== null && declaredSkipped !== skipped.length) {
    warnings.push(
      `summary reports ${declaredSkipped} skipped, ${skipped.length} entries were listed`
    );
  }

  return {
    passed,
    failed,
    skipped,
    metrics,
    summary,
    warnings,
    environment: summary.Environment ?? metrics.Environment ?? null,
    executor: metrics.Executor ?? null,
    total: passed.length + failed.length + skipped.length
  };
}

export function slugify(value) {
  return String(value)
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 48);
}

export function toEntry(input) {
  const report = parseOutput(input.output ?? "");

  return {
    name: String(input.name ?? "").trim(),
    author: String(input.author ?? "").trim() || null,
    url: String(input.url ?? "").trim() || null,
    date: String(input.date ?? "").trim() || new Date().toISOString().slice(0, 10),
    environment: report.environment,
    executor: report.executor,
    total: report.total,
    failed: report.failed,
    skipped: report.skipped,
    metrics: report.metrics
  };
}

export function readEntry(entry) {
  const total = Number(entry.total) || 0;
  const failed = Array.isArray(entry.failed) ? entry.failed : [];
  const skipped = Array.isArray(entry.skipped) ? entry.skipped : [];
  const passed = Math.max(0, total - failed.length - skipped.length);
  const counted = passed + failed.length;

  return {
    ...entry,
    counts: {
      passed,
      failed: failed.length,
      skipped: skipped.length,
      total
    },
    score: counted > 0 ? Number(((passed / counted) * 100).toFixed(2)) : 0
  };
}

export function passedNames(entry, checks) {
  if (!Array.isArray(checks) || checks.length === 0) {
    return null;
  }

  const excluded = new Set();

  for (const item of entry.failed ?? []) {
    excluded.add(item.name);
  }

  for (const item of entry.skipped ?? []) {
    excluded.add(item.name);
  }

  return checks.filter((name) => !excluded.has(name));
}
