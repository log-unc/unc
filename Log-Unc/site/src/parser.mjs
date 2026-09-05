const TIMESTAMP = /^\s*\d{1,2}:\d{2}:\d{2}\s*--\s?/;
const PASS = /^\[PASS\]\s+(.+)$/;
const ENTRY = /^(\d+)\.\s+(.+?)\s+\|\s+(.*)$/;
const SUMMARY = /^(Score|Environment|Passed|Failed|Skipped|Coverage):\s*(.+)$/;
const METRIC = /^([A-Za-z][A-Za-z0-9_]*):\s*(.*)$/;
const SEPARATOR = /^[=-]{6,}$/;

const SECTION_LOG = "log";
const SECTION_FAILED = "failed";
const SECTION_SKIPPED = "skipped";
const SECTION_METRICS = "metrics";

const SUMMARY_KEYS = new Set([
  "Score",
  "Environment",
  "Passed",
  "Failed",
  "Skipped",
  "Coverage"
]);

const PRIVATE_METRICS = new Set([
  "AccountAge",
  "ClientId",
  "DisplayName",
  "ExecutorHwid",
  "Player",
  "RootPosition",
  "RootVelocity",
  "SystemLocale",
  "UserId"
]);

function stripPrefix(line) {
  return line.replace(TIMESTAMP, "").trim();
}

function toNumber(value) {
  const parsed = Number.parseFloat(String(value).replace("%", ""));

  return Number.isFinite(parsed) ? parsed : null;
}

export function parseReport(text) {
  const passed = [];
  const failed = [];
  const skipped = [];
  const metrics = {};
  const summary = {};
  const warnings = [];

  let section = SECTION_LOG;

  for (const rawLine of String(text).split(/\r?\n/)) {
    const line = stripPrefix(rawLine);

    if (line.length === 0 || SEPARATOR.test(line) || line === "None") {
      continue;
    }

    if (line === "FAILED TESTS") {
      section = SECTION_FAILED;
      continue;
    }

    if (line === "SKIPPED TESTS") {
      section = SECTION_SKIPPED;
      continue;
    }

    if (line === "METRICS") {
      section = SECTION_METRICS;
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

    if (section === SECTION_FAILED || section === SECTION_SKIPPED) {
      const entryMatch = line.match(ENTRY);

      if (entryMatch) {
        const entry = {
          name: entryMatch[2].trim(),
          reason: entryMatch[3].trim()
        };

        if (section === SECTION_FAILED) {
          failed.push(entry);
        } else {
          skipped.push(entry);
        }

        continue;
      }
    }

    if (section === SECTION_METRICS) {
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
      `summary reports ${declaredPassed} passed but ${passed.length} PASS lines were found`
    );
  }

  if (declaredFailed !== null && declaredFailed !== failed.length) {
    warnings.push(
      `summary reports ${declaredFailed} failed but ${failed.length} entries were listed`
    );
  }

  if (declaredSkipped !== null && declaredSkipped !== skipped.length) {
    warnings.push(
      `summary reports ${declaredSkipped} skipped but ${skipped.length} entries were listed`
    );
  }

  const passedCount = passed.length > 0 ? passed.length : declaredPassed ?? 0;
  const failedCount = failed.length > 0 ? failed.length : declaredFailed ?? 0;
  const skippedCount = skipped.length > 0 ? skipped.length : declaredSkipped ?? 0;
  const counted = passedCount + failedCount;

  const score = counted > 0
    ? Number(((passedCount / counted) * 100).toFixed(2))
    : 0;

  return {
    passed,
    failed,
    skipped,
    metrics,
    summary,
    score,
    reportedScore: toNumber(summary.Score),
    counts: {
      passed: passedCount,
      failed: failedCount,
      skipped: skippedCount,
      total: counted + skippedCount
    },
    environment: summary.Environment ?? metrics.Environment ?? null,
    executor: metrics.Executor ?? null,
    warnings
  };
}

export function publicMetrics(metrics) {
  const safe = {};

  for (const [key, value] of Object.entries(metrics ?? {})) {
    if (!PRIVATE_METRICS.has(key)) {
      safe[key] = value;
    }
  }

  return safe;
}

export function slugify(value) {
  return String(value)
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 48);
}

export function buildEntry(submission) {
  const report = parseReport(submission.output ?? "");

  return {
    slug: slugify(submission.slug || submission.name || ""),
    name: String(submission.name ?? "").trim(),
    author: String(submission.author ?? "").trim() || null,
    url: String(submission.url ?? "").trim() || null,
    reference: submission.reference === true,
    submittedAt: String(submission.submittedAt ?? "").trim() || null,
    score: report.score,
    counts: report.counts,
    environment: report.environment,
    executor: report.executor,
    passed: report.passed,
    failed: report.failed,
    skipped: report.skipped,
    metrics: publicMetrics(report.metrics),
    warnings: report.warnings
  };
}

export function buildSubmissionFile(input) {
  return {
    name: String(input.name ?? "").trim(),
    author: String(input.author ?? "").trim() || null,
    url: String(input.url ?? "").trim() || null,
    submittedAt: new Date().toISOString().slice(0, 10),
    output: String(input.output ?? "").replace(/\r\n/g, "\n").trimEnd()
  };
}
