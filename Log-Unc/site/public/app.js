const navButtons = document.querySelectorAll(".nav-button");
const panels = document.querySelectorAll(".panel");
const openTabButtons = document.querySelectorAll("[data-open-tab]");

const leaderboardList = document.getElementById("leaderboardList");
const leaderboardRows = document.getElementById("leaderboardRows");
const loggerStatistics = document.getElementById("loggerStatistics");
const backButton = document.getElementById("backButton");

const loggerName = document.getElementById("loggerName");
const loggerMeta = document.getElementById("loggerMeta");
const loggerScore = document.getElementById("loggerScore");
const scoreBar = document.getElementById("scoreBar");
const passedCount = document.getElementById("passedCount");
const failedCount = document.getElementById("failedCount");
const skippedCount = document.getElementById("skippedCount");
const totalCount = document.getElementById("totalCount");

const filterGroup = document.getElementById("filterGroup");
const searchInput = document.getElementById("searchInput");
const testList = document.getElementById("testList");
const listSummary = document.getElementById("listSummary");
const metricsBlock = document.getElementById("metricsBlock");
const metricsGrid = document.getElementById("metricsGrid");

const scriptCode = document.getElementById("scriptCode");
const scriptName = document.getElementById("scriptName");
const copyButton = document.getElementById("copyButton");
const copyLoaderButton = document.getElementById("copyLoaderButton");
const referenceChecks = document.querySelectorAll("[data-reference-checks]");

const PAGE_SIZE = 150;
const DISPLAY_LIMIT = 40000;

const state = {
  index: [],
  detail: new Map(),
  slug: null,
  filter: "all",
  query: "",
  limit: PAGE_SIZE,
  source: ""
};

function formatScore(value) {
  const score = Number(value);

  if (!Number.isFinite(score)) {
    return "0";
  }

  return Number.isInteger(score) ? String(score) : score.toFixed(2);
}

function openTab(tabName) {
  navButtons.forEach((button) => {
    button.classList.toggle("active", button.dataset.tab === tabName);
  });

  panels.forEach((panel) => {
    panel.classList.toggle("active", panel.id === tabName);
  });

  if (tabName === "leaderboard" && state.slug === null) {
    showLeaderboard();
  }

  history.replaceState(null, "", `#${tabName}`);
}

function renderLeaderboard() {
  leaderboardRows.replaceChildren();

  if (state.index.length === 0) {
    const empty = document.createElement("div");

    empty.className = "empty-state";
    empty.textContent = "No results published yet.";

    leaderboardRows.appendChild(empty);
    return;
  }

  state.index.forEach((logger, position) => {
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

    if (logger.reference) {
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

    tests.append(
      ok,
      document.createTextNode(" / "),
      bad,
      document.createTextNode(" / "),
      skip
    );

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

function collectRows(logger) {
  const rows = [];

  for (const entry of logger.failed ?? []) {
    rows.push({ status: "failed", name: entry.name, reason: entry.reason });
  }

  for (const entry of logger.skipped ?? []) {
    rows.push({ status: "skipped", name: entry.name, reason: entry.reason });
  }

  for (const name of logger.passed ?? []) {
    rows.push({ status: "passed", name, reason: "" });
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
  const logger = state.detail.get(state.slug);

  if (!logger) {
    return;
  }

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

    empty.textContent = "No checks match this filter.";
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
    tags.push({
      text: logger.environment,
      accent: logger.environment === "ROBLOX"
    });
  }

  if (logger.executor) {
    tags.push({ text: `Executor: ${logger.executor}`, accent: false });
  }

  if (logger.author) {
    tags.push({ text: `by ${logger.author}`, accent: false });
  }

  if (logger.submittedAt) {
    tags.push({ text: logger.submittedAt, accent: false });
  }

  for (const tag of tags) {
    const element = document.createElement("span");

    element.className = tag.accent ? "tag accent" : "tag";
    element.textContent = tag.text;

    loggerMeta.appendChild(element);
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

function renderDetail(logger) {
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
}

async function loadDetail(slug) {
  if (state.detail.has(slug)) {
    return state.detail.get(slug);
  }

  const response = await fetch(`/data/${encodeURIComponent(slug)}.json`);

  if (!response.ok) {
    throw new Error(`request failed with ${response.status}`);
  }

  const logger = await response.json();

  state.detail.set(slug, logger);

  return logger;
}

async function selectLogger(slug) {
  state.slug = slug;
  state.filter = "all";
  state.query = "";
  state.limit = PAGE_SIZE;

  searchInput.value = "";

  filterGroup.querySelectorAll(".filter-button").forEach((button) => {
    button.classList.toggle("active", button.dataset.filter === "all");
  });

  history.replaceState(null, "", `#logger/${encodeURIComponent(slug)}`);
  window.scrollTo({ top: 0, behavior: "smooth" });

  try {
    renderDetail(await loadDetail(slug));
  } catch {
    state.slug = null;
    showLeaderboard();
  }
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

  if (!button) {
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
    const textArea = document.createElement("textarea");

    textArea.value = text;
    textArea.setAttribute("readonly", "readonly");
    textArea.style.position = "fixed";
    textArea.style.opacity = "0";

    document.body.appendChild(textArea);
    textArea.select();
    document.execCommand("copy");
    textArea.remove();
  }

  button.textContent = "Copied";

  setTimeout(() => {
    button.textContent = label;
  }, 1400);
}

copyButton.addEventListener("click", () => {
  copyText(copyButton, state.source, "Copy source");
});

copyLoaderButton.addEventListener("click", () => {
  const loader = `loadstring(game:HttpGet("${location.origin}/script.lua"))()`;

  copyText(copyLoaderButton, loader, "Copy loadstring");
});

function applyHash() {
  const hash = decodeURIComponent(location.hash.slice(1));

  if (hash.startsWith("logger/")) {
    const slug = hash.slice("logger/".length);

    openTab("leaderboard");

    if (state.index.some((logger) => logger.slug === slug)) {
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

async function loadIndex() {
  try {
    const response = await fetch("/data/index.json");

    if (!response.ok) {
      throw new Error(`request failed with ${response.status}`);
    }

    state.index = await response.json();
  } catch {
    state.index = [];
  }

  renderLeaderboard();
  applyHash();
}

async function loadMeta() {
  try {
    const response = await fetch("/data/meta.json");

    if (!response.ok) {
      return;
    }

    const meta = await response.json();

    if (meta.referenceChecks) {
      referenceChecks.forEach((element) => {
        element.textContent = meta.referenceChecks.toLocaleString("en-US");
      });
    }
  } catch {
    return;
  }
}

async function loadScript() {
  try {
    const response = await fetch("/script.lua");

    if (!response.ok) {
      throw new Error(`request failed with ${response.status}`);
    }

    state.source = await response.text();

    const lines = state.source.split("\n").length;

    scriptName.textContent = `Log-Unc-V1.lua \u00b7 ${lines.toLocaleString("en-US")} lines`;
    scriptCode.textContent = state.source.slice(0, DISPLAY_LIMIT);

    if (state.source.length > DISPLAY_LIMIT) {
      scriptCode.textContent +=
        "\n\n-- preview truncated, use Copy source for the full file";
    }
  } catch {
    scriptCode.textContent = "-- Failed to load the script. Try reloading the page.";
  }
}

loadMeta();
loadIndex();
loadScript();
