import { parseReport, slugify, buildSubmissionFile } from "/vendor/parser.mjs";

const nameInput = document.getElementById("submitName");
const authorInput = document.getElementById("submitAuthor");
const urlInput = document.getElementById("submitUrl");
const outputInput = document.getElementById("submitOutput");

const downloadButton = document.getElementById("downloadButton");
const copyJsonButton = document.getElementById("copyJsonButton");
const status = document.getElementById("submitStatus");

const preview = document.getElementById("submitPreview");
const previewGrid = document.getElementById("previewGrid");
const previewWarnings = document.getElementById("previewWarnings");
const previewPath = document.getElementById("previewPath");

function setStatus(message, kind = "") {
  status.className = `status ${kind}`.trim();
  status.textContent = message;
}

function currentSlug() {
  return slugify(nameInput.value) || "logger";
}

function renderPreview() {
  const output = outputInput.value;

  if (output.trim().length === 0) {
    preview.hidden = true;
    setStatus("Paste your output to preview it.");
    return null;
  }

  const report = parseReport(output);

  const items = [
    ["Score", `${report.score}%`],
    ["Passed", report.counts.passed],
    ["Failed", report.counts.failed],
    ["Skipped", report.counts.skipped],
    ["Total", report.counts.total],
    ["Environment", report.environment ?? "unknown"],
    ["Executor", report.executor ?? "none"],
    ["Metrics", Object.keys(report.metrics).length]
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

  previewPath.textContent = `site/loggers/${currentSlug()}.json`;
  preview.hidden = false;

  if (report.counts.total === 0) {
    setStatus("No checks were recognised in that output.", "bad");
    return null;
  }

  setStatus(`Parsed ${report.counts.total} checks at ${report.score}%.`, "ok");

  return report;
}

function buildFile() {
  const name = nameInput.value.trim();

  if (name.length === 0) {
    setStatus("Logger name is required.", "bad");
    return null;
  }

  const report = renderPreview();

  if (report === null) {
    return null;
  }

  const file = buildSubmissionFile({
    name,
    author: authorInput.value,
    url: urlInput.value,
    output: outputInput.value
  });

  return { file, text: `${JSON.stringify(file, null, 2)}\n` };
}

outputInput.addEventListener("input", renderPreview);
nameInput.addEventListener("input", () => {
  if (!preview.hidden) {
    previewPath.textContent = `site/loggers/${currentSlug()}.json`;
  }
});

downloadButton.addEventListener("click", () => {
  const built = buildFile();

  if (built === null) {
    return;
  }

  const blob = new Blob([built.text], { type: "application/json" });
  const link = document.createElement("a");

  link.href = URL.createObjectURL(blob);
  link.download = `${currentSlug()}.json`;

  document.body.appendChild(link);
  link.click();
  link.remove();

  URL.revokeObjectURL(link.href);

  setStatus(`Saved ${currentSlug()}.json. Add it to site/loggers/ in a pull request.`, "ok");
});

copyJsonButton.addEventListener("click", async () => {
  const built = buildFile();

  if (built === null) {
    return;
  }

  try {
    await navigator.clipboard.writeText(built.text);
  } catch {
    const textArea = document.createElement("textarea");

    textArea.value = built.text;
    textArea.setAttribute("readonly", "readonly");
    textArea.style.position = "fixed";
    textArea.style.opacity = "0";

    document.body.appendChild(textArea);
    textArea.select();
    document.execCommand("copy");
    textArea.remove();
  }

  copyJsonButton.textContent = "Copied";

  setTimeout(() => {
    copyJsonButton.textContent = "Copy JSON";
  }, 1400);
});
