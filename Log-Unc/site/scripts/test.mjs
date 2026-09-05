import { parseReport, slugify, buildEntry, publicMetrics } from "../src/parser.mjs";

let failures = 0;

function check(label, condition) {
  if (condition) {
    console.log(`ok    ${label}`);
    return;
  }

  failures += 1;
  console.error(`FAIL  ${label}`);
}

function equal(label, actual, expected) {
  const same = JSON.stringify(actual) === JSON.stringify(expected);

  if (!same) {
    console.error(`      expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`);
  }

  check(label, same);
}

const sample = [
  "16:53:30 -- [PASS] game is DataModel",
  "16:53:30 -- [PASS] Service Workspace",
  "16:53:30 -- [PASS] buffer bit access",
  "16:53:31 -- some stray logger noise",
  "16:53:35 -- ========================================================",
  "16:53:35 -- Log-Unc diagnostic completed",
  "16:53:35 -- Score: 75.00%",
  "16:53:35 -- Environment: ENV",
  "16:53:35 -- Passed: 3",
  "16:53:35 -- Failed: 1",
  "16:53:35 -- Skipped: 2",
  "16:53:35 -- Coverage: 4/6",
  "16:53:35 -- ========================================================",
  "16:53:35 -- FAILED TESTS",
  "16:53:35 -- 1. Instance property assignment type checking | Size from number accepted",
  "16:53:35 -- --------------------------------------------------------",
  "16:53:35 -- SKIPPED TESTS",
  "16:53:35 -- 1. Service FlagStandService | returned false",
  "16:53:35 -- 2. Buffer read and write | buffer unavailable",
  "16:53:35 -- --------------------------------------------------------",
  "16:53:35 -- METRICS",
  "16:53:35 -- Environment: ENV",
  "16:53:35 -- Executor: TestRunner",
  "16:53:35 -- UserId: 10427484875",
  "16:53:35 -- DisplayName: someone",
  "16:53:35 -- ClientId: abcd...wxyz (len 36)",
  "16:53:35 -- HeartbeatFPS: 59.9",
  "16:53:35 -- ========================================================"
].join("\n");

const report = parseReport(sample);

equal("passed names", report.passed, [
  "game is DataModel",
  "Service Workspace",
  "buffer bit access"
]);

equal("failed entries", report.failed, [
  {
    name: "Instance property assignment type checking",
    reason: "Size from number accepted"
  }
]);

equal("skipped entries", report.skipped, [
  { name: "Service FlagStandService", reason: "returned false" },
  { name: "Buffer read and write", reason: "buffer unavailable" }
]);

equal("counts", report.counts, { passed: 3, failed: 1, skipped: 2, total: 6 });
equal("score", report.score, 75);
equal("reported score", report.reportedScore, 75);
equal("environment", report.environment, "ENV");
equal("executor", report.executor, "TestRunner");
equal("metric value", report.metrics.HeartbeatFPS, "59.9");
check("no warnings on a consistent report", report.warnings.length === 0);

const stripped = publicMetrics(report.metrics);

check("UserId is stripped", stripped.UserId === undefined);
check("DisplayName is stripped", stripped.DisplayName === undefined);
check("ClientId is stripped", stripped.ClientId === undefined);
check("Executor survives", stripped.Executor === "TestRunner");
check("HeartbeatFPS survives", stripped.HeartbeatFPS === "59.9");

const unprefixed = parseReport(
  ["[PASS] first check", "[PASS] second check", "Passed: 2", "Failed: 0"].join("\n")
);

equal("works without timestamps", unprefixed.counts, {
  passed: 2,
  failed: 0,
  skipped: 0,
  total: 2
});

equal("perfect score", unprefixed.score, 100);

const mismatched = parseReport(
  ["[PASS] only one", "Passed: 900", "Failed: 0", "Skipped: 0"].join("\n")
);

check("mismatch produces a warning", mismatched.warnings.length === 1);
equal("mismatch trusts counted lines", mismatched.counts.passed, 1);

const empty = parseReport("");

equal("empty input", empty.counts, { passed: 0, failed: 0, skipped: 0, total: 0 });
equal("empty score", empty.score, 0);

equal("slug from a plain name", slugify("NyxLogger"), "nyxlogger");
equal("slug strips symbols", slugify("Void Nine 9!"), "void-nine-9");
equal("slug trims dashes", slugify("--edge--"), "edge");

const entry = buildEntry({
  name: "  Test Logger  ",
  author: "  someone  ",
  url: "",
  slug: "test-logger",
  submittedAt: "2026-01-01",
  output: sample
});

equal("entry slug", entry.slug, "test-logger");
equal("entry name is trimmed", entry.name, "Test Logger");
equal("entry author is trimmed", entry.author, "someone");
equal("empty url becomes null", entry.url, null);
equal("entry score", entry.score, 75);
check("entry metrics are sanitised", entry.metrics.UserId === undefined);
check("entry keeps failure reasons", entry.failed[0].reason === "Size from number accepted");

const noChecks = buildEntry({ name: "Broken", output: "nothing useful here" });

equal("output without checks", noChecks.counts.total, 0);

console.log("");

if (failures > 0) {
  console.error(`${failures} check${failures === 1 ? "" : "s"} failed`);
  process.exit(1);
}

console.log("all checks passed");
