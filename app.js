import { parseOutput, toEntry, readEntry, passedNames, slugify } from "./tools/parse.mjs";

const PAGE_SIZE = 150;
const PREVIEW_LIMIT = 40000;

const state = {
  loggers: [],
  slug: null,
  filter: "all",
  query: "",
  limit: PAGE_SIZE,
  checks: null,
  source: "",
  script: null
};

const el = (id) => document.getElementById(id);

const navButtons = document.querySelectorAll(".nav-button");
const panels = document.querySelectorAll(".panel");
const openTabButtons = document.querySelectorAll("[data-open-tab]");
const totalChecksLabels = document.querySelectorAll("[data-total-checks]");

const leaderboardList = el("leaderboardList");
const leaderboardRows = el("leaderboardRows");
const loggerStatistics = el("loggerStatistics");
const backButton = el("backButton");

const loggerName = el("loggerName");
const loggerMeta = el("loggerMeta");
const loggerScore = el("loggerScore");
const scoreBar = el("scoreBar");
const passedCount = el("passedCount");
const failedCount = el("failedCount");
const skippedCount = el("skippedCount");
const totalCount = el("totalCount");

const filterGroup = el("filterGroup");
const searchInput = el("searchInput");
const testList = el("testList");
const listSummary = el("listSummary");
const metricsBlock = el("metricsBlock");
const metricsGrid = el("metricsGrid");

const loaderCode = el("loaderCode");
const scriptCode = el("scriptCode");
const scriptName = el("scriptName");
const rawLink = el("rawLink");
const copyButton = el("copyButton");
const copyLoaderButton = el("copyLoaderButton");

const submitName = el("submitName");
const submitAuthor = el("submitAuthor");
const submitUrl = el("submitUrl");
const submitOutput = el("submitOutput");
const downloadButton = el("downloadButton");
const copyJsonButton = el("copyJsonButton");
const submitStatus = el("submitStatus");
const submitPreview = el("submitPreview");
const previewGrid = el("previewGrid");
const previewWarnings = el("previewWarnings");
const previewJson = el("previewJson");

function formatScore(value) {
  const score = Number(value);

  if (!Number.isFinite(score)) {
    return "0";
  }

  return Number.isInteger(score) ? String(score) : score.toFixed(2);
}

async function loadJson(path) {
  const response = await fetch(path, { cache: "no-cache" });

  if (!response.ok) {
    throw new Error(`${path} responded with ${response.status}`);
  }

  return response.json();
}

function openTab(name) {
  navButtons.forEach((button) => {
    button.classList.toggle("active", button.dataset.tab === name);
  });

  panels.forEach((panel) => {
    panel.classList.toggle("active", panel.id === name);
  });

  if (name === "leaderboard" && state.slug === null) {
    showLeaderboard();
  }

  history.replaceState(null, "", `#${name}`);
}

function renderLeaderboard() {
  leaderboardRows.replaceChildren();

  if (state.loggers.length === 0) {
    const empty = document.createElement("div");

    empty.className = "empty-state";
    empty.textContent = "No results published yet.";

    leaderboardRows.appendChild(empty);
    return;
  }

  state.loggers.forEach((logger, position) => {
    const row = document.createElement("button");

    row.className = "leaderboard-row player-row";
    row.type = "button";

    const rank = document.createElement("span");

    rank.className = "rank";
    rank.textContent = String(position + 1).padStart(2, "0");

    const player = document.createElement("span");

    player.className = "player";

    const name = document.createElement("span");

    name.className = "player-name";
    name.textContent = logger.name;
    player.appendChild(name);

    if (logger.environment === "ROBLOX") {
      const badge = document.createElement("span");

      badge.className = "badge";
      badge.textContent = "reference";
      player.appendChild(badge);
    }

    const arrow = document.createElement("span");

    arrow.className = "player-arrow";
    arrow.textContent = "\u2192";
    player.appendChild(arrow);

    const tests = document.createElement("span");

    tests.className = "row-tests";

    const ok = document.createElement("i");
    const bad = document.createElement("i");
    const skip = document.createElement("i");

    ok.className = "ok";
    ok.textContent = String(logger.counts.passed);
    bad.className = "bad";
    bad.textContent = String(logger.counts.failed);
    skip.className = "skip";
    skip.textContent = String(logger.counts.skipped);

    tests.append(ok, document.createTextNode(" / "), bad, document.createTextNode(" / "), skip);

    const score = document.createElement("span");

    score.className = "row-score";
    score.textContent = `${formatScore(logger.score)}%`;

    row.append(rank, player, tests, score);
    row.addEventListener("click", () => {
      selectLogger(logger.slug);
    });

    leaderboardRows.appendChild(row);
  });
}

function currentLogger() {
  return state.loggers.find((logger) => logger.slug === state.slug) ?? null;
}

function collectRows(logger) {
  const rows = [];

  for (const entry of logger.failed ?? []) {
    rows.push({ status: "failed", name: entry.name, reason: entry.reason });
  }

  for (const entry of logger.skipped ?? []) {
    rows.push({ status: "skipped", name: entry.name, reason: entry.reason });
  }

  const names = passedNames(logger, state.checks);

  if (names) {
    for (const name of names) {
      rows.push({ status: "passed", name, reason: "" });
    }
  }

  return rows;
}

function statusGlyph(status) {
  if (status === "passed") {
    return "\u2713";
  }

  return status === "failed" ? "\u00d7" : "!";
}

function createTestItem(row) {
  const item = document.createElement("li");
  const icon = document.createElement("span");
  const body = document.createElement("div");
  const name = document.createElement("div");

  icon.className = `test-status ${row.status}`;
  icon.textContent = statusGlyph(row.status);

  body.className = "test-body";
  name.textContent = row.name;
  body.appendChild(name);

  if (row.reason) {
    const reason = document.createElement("div");

    reason.className = "test-reason";
    reason.textContent = row.reason;
    body.appendChild(reason);
  }

  item.append(icon, body);

  return item;
}

function renderTests() {
  const logger = currentLogger();

  if (!logger) {
    return;
  }

  const hasNames = Array.isArray(state.checks) && state.checks.length > 0;

  filterGroup.querySelectorAll(".filter-button").forEach((button) => {
    button.disabled = button.dataset.filter === "passed" && !hasNames;
  });

  const query = state.query.trim().toLowerCase();
  const filtered = collectRows(logger).filter((row) => {
    if (state.filter !== "all" && row.status !== state.filter) {
      return false;
    }

    if (query.length === 0) {
      return true;
    }

    return (
      row.name.toLowerCase().includes(query) ||
      row.reason.toLowerCase().includes(query)
    );
  });

  const visible = filtered.slice(0, state.limit);

  testList.replaceChildren();

  if (visible.length === 0) {
    const empty = document.createElement("li");

    empty.textContent =
      logger.counts.failed === 0 && logger.counts.skipped === 0 && !hasNames
        ? "Every check passed."
        : "No checks match this filter.";

    testList.appendChild(empty);
  } else {
    for (const row of visible) {
      testList.appendChild(createTestItem(row));
    }
  }

  listSummary.replaceChildren(
    document.createTextNode(`Showing ${visible.length} of ${filtered.length} checks`)
  );

  if (filtered.length > visible.length) {
    const remaining = Math.min(PAGE_SIZE, filtered.length - visible.length);
    const more = document.createElement("button");

    more.type = "button";
    more.textContent = `Show ${remaining} more`;
    more.addEventListener("click", () => {
      state.limit += PAGE_SIZE;
      renderTests();
    });

    listSummary.append(document.createTextNode(" \u00b7 "), more);
  }
}

function renderMetrics(logger) {
  const entries = Object.entries(logger.metrics ?? {});

  metricsGrid.replaceChildren();
  metricsBlock.hidden = entries.length === 0;

  entries.sort(([first], [second]) => first.localeCompare(second));

  for (const [key, value] of entries) {
    const metric = document.createElement("div");
    const label = document.createElement("span");
    const content = document.createElement("strong");

    metric.className = "metric";
    label.textContent = key;
    content.textContent = String(value);

    metric.append(label, content);
    metricsGrid.appendChild(metric);
  }
}

function renderMeta(logger) {
  loggerMeta.replaceChildren();

  const tags = [];

  if (logger.environment) {
    tags.push([logger.environment, logger.environment === "ROBLOX"]);
  }

  if (logger.executor) {
    tags.push([`Executor: ${logger.executor}`, false]);
  }

  if (logger.author) {
    tags.push([`by ${logger.author}`, false]);
  }

  if (logger.date) {
    tags.push([logger.date, false]);
  }

  for (const [text, accent] of tags) {
    const tag = document.createElement("span");

    tag.className = accent ? "tag accent" : "tag";
    tag.textContent = text;

    loggerMeta.appendChild(tag);
  }

  if (logger.url) {
    const link = document.createElement("a");

    link.className = "tag";
    link.href = logger.url;
    link.rel = "noreferrer noopener";
    link.target = "_blank";
    link.textContent = "Source";

    loggerMeta.appendChild(link);
  }
}

function selectLogger(slug) {
  state.slug = slug;
  state.filter = "all";
  state.query = "";
  state.limit = PAGE_SIZE;

  const logger = currentLogger();

  if (!logger) {
    showLeaderboard();
    return;
  }

  searchInput.value = "";

  filterGroup.querySelectorAll(".filter-button").forEach((button) => {
    button.classList.toggle("active", button.dataset.filter === "all");
  });

  loggerName.textContent = logger.name;
  loggerScore.textContent = formatScore(logger.score);
  scoreBar.style.width = `${Math.max(0, Math.min(100, Number(logger.score) || 0))}%`;

  passedCount.textContent = String(logger.counts.passed);
  failedCount.textContent = String(logger.counts.failed);
  skippedCount.textContent = String(logger.counts.skipped);
  totalCount.textContent = String(logger.counts.total);

  renderMeta(logger);
  renderMetrics(logger);
  renderTests();

  leaderboardList.hidden = true;
  loggerStatistics.hidden = false;

  history.replaceState(null, "", `#logger/${encodeURIComponent(slug)}`);
  window.scrollTo({ top: 0, behavior: "smooth" });
}

function showLeaderboard() {
  state.slug = null;
  loggerStatistics.hidden = true;
  leaderboardList.hidden = false;
}

navButtons.forEach((button) => {
  button.addEventListener("click", () => {
    if (button.dataset.tab === "leaderboard") {
      showLeaderboard();
    }

    openTab(button.dataset.tab);
  });
});

openTabButtons.forEach((button) => {
  button.addEventListener("click", () => {
    openTab(button.dataset.openTab);
  });
});

backButton.addEventListener("click", () => {
  showLeaderboard();
  history.replaceState(null, "", "#leaderboard");
});

filterGroup.addEventListener("click", (event) => {
  const button = event.target.closest(".filter-button");

  if (!button || button.disabled) {
    return;
  }

  state.filter = button.dataset.filter;
  state.limit = PAGE_SIZE;

  filterGroup.querySelectorAll(".filter-button").forEach((item) => {
    item.classList.toggle("active", item === button);
  });

  renderTests();
});

searchInput.addEventListener("input", () => {
  state.query = searchInput.value;
  state.limit = PAGE_SIZE;
  renderTests();
});

async function copyText(button, text, label) {
  try {
    await navigator.clipboard.writeText(text);
  } catch {
    const area = document.createElement("textarea");

    area.value = text;
    area.setAttribute("readonly", "readonly");
    area.style.position = "fixed";
    area.style.opacity = "0";

    document.body.appendChild(area);
    area.select();
    document.execCommand("copy");
    area.remove();
  }

  button.textContent = "Copied";

  setTimeout(() => {
    button.textContent = label;
  }, 1400);
}

copyButton.addEventListener("click", () => {
  if (state.source.length === 0) {
    return;
  }

  copyText(copyButton, state.source, "Copy source");
});

copyLoaderButton.addEventListener("click", () => {
  if (!state.script) {
    return;
  }

  copyText(copyLoaderButton, state.script.loadstring, "Copy loadstring");
});

function renderSubmitPreview() {
  const output = submitOutput.value;

  if (output.trim().length === 0) {
    submitPreview.hidden = true;
    submitStatus.className = "status";
    submitStatus.textContent = "Paste your output to preview it.";
    return null;
  }

  const report = parseOutput(output);
  const entry = toEntry({
    name: submitName.value,
    author: submitAuthor.value,
    url: submitUrl.value,
    output
  });

  const text = `${JSON.stringify(entry, null, 2)}\n`;
  const passed = report.total - report.failed.length - report.skipped.length;
  const before = new TextEncoder().encode(output).length;
  const after = new TextEncoder().encode(text).length;

  const items = [
    ["Passed", passed],
    ["Failed", report.failed.length],
    ["Skipped", report.skipped.length],
    ["Total", report.total],
    ["Environment", report.environment ?? "unknown"],
    ["Executor", report.executor ?? "none"],
    ["Metrics", Object.keys(report.metrics).length],
    ["File size", `${(after / 1024).toFixed(1)} KB`],
    ["Saved", `${(100 - (after / Math.max(before, 1)) * 100).toFixed(0)}%`]
  ];

  previewGrid.replaceChildren();

  for (const [label, value] of items) {
    const item = document.createElement("div");
    const title = document.createElement("span");
    const content = document.createElement("strong");

    item.className = "preview-item";
    title.textContent = label;
    content.textContent = String(value);

    item.append(title, content);
    previewGrid.appendChild(item);
  }

  previewWarnings.hidden = report.warnings.length === 0;
  previewWarnings.textContent = report.warnings.join(" \u00b7 ");
  previewJson.textContent = text;
  submitPreview.hidden = false;

  if (report.total === 0) {
    submitStatus.className = "status bad";
    submitStatus.textContent = "No checks were recognised in that output.";
    return null;
  }

  submitStatus.className = "status ok";
  submitStatus.textContent = `Parsed ${report.total} checks, ${passed} passed.`;

  return text;
}

function buildFile() {
  if (submitName.value.trim().length === 0) {
    submitStatus.className = "status bad";
    submitStatus.textContent = "Logger name is required.";
    return null;
  }

  return renderSubmitPreview();
}

submitOutput.addEventListener("input", renderSubmitPreview);

[submitName, submitAuthor, submitUrl].forEach((input) => {
  input.addEventListener("input", () => {
    if (!submitPreview.hidden) {
      renderSubmitPreview();
    }
  });
});

downloadButton.addEventListener("click", () => {
  const text = buildFile();

  if (text === null) {
    return;
  }

  const slug = slugify(submitName.value) || "logger";
  const blob = new Blob([text], { type: "application/json" });
  const link = document.createElement("a");

  link.href = URL.createObjectURL(blob);
  link.download = `${slug}.json`;

  document.body.appendChild(link);
  link.click();
  link.remove();

  URL.revokeObjectURL(link.href);

  submitStatus.className = "status ok";
  submitStatus.textContent = `Saved ${slug}.json. Add it to loggers/ and list it in loggers/index.json.`;
});

copyJsonButton.addEventListener("click", () => {
  const text = buildFile();

  if (text === null) {
    return;
  }

  copyText(copyJsonButton, text, "Copy JSON");
});

function applyHash() {
  const hash = decodeURIComponent(location.hash.slice(1));

  if (hash.startsWith("logger/")) {
    const slug = hash.slice("logger/".length);

    openTab("leaderboard");

    if (state.loggers.some((logger) => logger.slug === slug)) {
      selectLogger(slug);
    } else {
      showLeaderboard();
    }

    return;
  }

  if (document.getElementById(hash)) {
    openTab(hash);
  }
}

async function loadLoggers() {
  let files = [];

  try {
    const index = await loadJson("loggers/index.json");

    files = Array.isArray(index) ? index : index.files ?? [];
  } catch {
    files = [];
  }

  const loaded = await Promise.all(
    files.map(async (file) => {
      try {
        const entry = await loadJson(`loggers/${file}`);

        return readEntry({ ...entry, slug: file.replace(/\.json$/i, "") });
      } catch {
        return null;
      }
    })
  );

  state.loggers = loaded.filter((entry) => entry !== null && entry.counts.total > 0);

  state.loggers.sort((first, second) => {
    if (second.score !== first.score) {
      return second.score - first.score;
    }

    if (second.counts.passed !== first.counts.passed) {
      return second.counts.passed - first.counts.passed;
    }

    return first.name.localeCompare(second.name);
  });

  renderLeaderboard();

  const reference =
    state.loggers.find((logger) => logger.environment === "ROBLOX") ?? state.loggers[0];

  if (reference) {
    totalChecksLabels.forEach((element) => {
      element.textContent = reference.counts.total.toLocaleString("en-US");
    });
  }

  applyHash();
}

async function loadChecks() {
  try {
    const data = await loadJson("script/checks.json");

    state.checks = Array.isArray(data) ? data : data.checks ?? null;
  } catch {
    state.checks = null;
  }

  if (state.slug !== null) {
    renderTests();
  }
}

async function loadScript() {
  try {
    state.script = await loadJson("script/script.json");
  } catch {
    loaderCode.textContent = "-- script/script.json is missing";
    scriptCode.textContent = "-- script/script.json is missing";
    return;
  }

  loaderCode.textContent = state.script.loadstring ?? "";

  if (state.script.raw) {
    rawLink.href = state.script.raw;
  } else {
    rawLink.hidden = true;
  }

  const path = state.script.file ?? "script/Log-Unc-V1.lua";

  try {
    const response = await fetch(path, { cache: "no-cache" });

    if (!response.ok) {
      throw new Error(String(response.status));
    }

    state.source = await response.text();

    const lines = state.source.split("\n").length;

    scriptName.textContent =
      `${state.script.name ?? path} \u00b7 ${lines.toLocaleString("en-US")} lines`;

    scriptCode.textContent = state.source.slice(0, PREVIEW_LIMIT);

    if (state.source.length > PREVIEW_LIMIT) {
      scriptCode.textContent += "\n\n-- preview truncated, use Copy source for the full file";
    }
  } catch {
    scriptCode.textContent = `-- could not read ${path}`;
  }
}

loadLoggers();
loadChecks();
loadScript();
