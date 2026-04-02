# export-pdf.ps1 — Export an HTML presentation to PDF
#
# Usage:
#   .\export-pdf.ps1 <path-to-html> [output.pdf]
#   .\export-pdf.ps1 <path-to-html> [output.pdf] -Compact
#
# Examples:
#   .\export-pdf.ps1 .\my-deck\index.html
#   .\export-pdf.ps1 .\presentation.html .\slides.pdf
#   .\export-pdf.ps1 .\presentation.html -Compact   # smaller file size
#
# Requirements:
#   - Node.js (https://nodejs.org)
#   - Playwright (`npm install playwright` will be auto-triggered)
#
# What this does:
#   1. Starts a local server to serve the HTML (fonts and assets need HTTP)
#   2. Uses Playwright to screenshot each slide at 1920x1080
#   3. Combines all screenshots into a single PDF
#
# Note: Animations are not preserved (static export).

param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$InputHtml,

    [Parameter(Position=1)]
    [string]$OutputPdf,

    [switch]$Compact    # 1280x720 instead of 1920x1080 for smaller files
)

$ErrorActionPreference = "Stop"

# ─── Viewport ──────────────────────────────────────────
$ViewportW = if ($Compact) { 1280 } else { 1920 }
$ViewportH = if ($Compact) { 720 } else { 1080 }

# ─── Colors ─────────────────────────────────────────────
function Info  ($msg) { Write-Host "ℹ  $msg" -ForegroundColor Cyan }
function Ok    ($msg) { Write-Host "✓  $msg" -ForegroundColor Green }
function Warn  ($msg) { Write-Host "⚠  $msg" -ForegroundColor Yellow }
function Err   ($msg) { Write-Host "✗  $msg" -ForegroundColor Red }

# ─── Input validation ───────────────────────────────────
if (-not (Test-Path $InputHtml)) {
    Err "File not found: $InputHtml"
    exit 1
}

$InputHtml = (Resolve-Path $InputHtml).Path
$HtmlDir   = Split-Path $InputHtml -Parent
$HtmlName  = Split-Path $InputHtml -Leaf

if (-not $OutputPdf) {
    $OutputPdf = Join-Path $HtmlDir ([System.IO.Path]::GetFileNameWithoutExtension($InputHtml) + ".pdf")
}

# Resolve to absolute
$OutputPdf = (Resolve-Path (Split-Path $OutputPdf -Parent) -ErrorAction SilentlyContinue).Path
if (-not $OutputPdf) {
    $OutputPdf = $OutputPdf
}
else {
    $OutputPdf = Join-Path (Split-Path $OutputPdf -Parent) (Split-Path $OutputPdf -Leaf)
}
New-Item -ItemType Directory -Path (Split-Path $OutputPdf -Parent) -Force | Out-Null

Write-Host ""
Write-Host "╔══════════════════════════════════════╗" -ForegroundColor White
Write-Host "║       Export Slides to PDF            ║" -ForegroundColor White
Write-Host "╚══════════════════════════════════════╝" -ForegroundColor White
Write-Host ""

# ─── Step 1: Check Node.js ─────────────────────────────
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Err "Node.js is required but not installed."
    Write-Host "Install Node.js: https://nodejs.org" -ForegroundColor Cyan
    exit 1
}
Ok "Node.js found"

# ─── Step 2: Setup temp workspace ─────────────────────
$TempDir = [System.IO.Path]::GetTempFileName() -replace "\.tmp$", ""
Remove-Item $TempDir -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $TempDir | Out-Null

$ExportScript = Join-Path $TempDir "export-slides.mjs"
$TempScreenshots = Join-Path $TempDir "screenshots"
New-Item -ItemType Directory -Path $TempScreenshots | Out-Null

# ─── Step 3: Write Playwright script ───────────────────
$playwrightScript = @"
// export-slides.mjs — Playwright script to export HTML slides to PDF

import { chromium } from 'playwright';
import { createServer } from 'http';
import { readFileSync, existsSync, mkdirSync, unlinkSync } from 'fs';
import { join, extname } from 'path';

const SERVE_DIR   = process.argv[2];
const HTML_FILE   = process.argv[3];
const OUTPUT_PDF  = process.argv[4];
const SCREENSHOT_DIR = process.argv[5];
const VP_WIDTH    = parseInt(process.argv[6]) || 1920;
const VP_HEIGHT   = parseInt(process.argv[7]) || 1080;

const MIME_TYPES = {
  '.html': 'text/html', '.css': 'text/css', '.js': 'application/javascript',
  '.json': 'application/json', '.png': 'image/png', '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg', '.gif': 'image/gif', '.svg': 'image/svg+xml',
  '.webp': 'image/webp', '.woff': 'font/woff', '.woff2': 'font/woff2',
  '.ttf': 'font/ttf',
};

const server = createServer((req, res) => {
  const decodedUrl = decodeURIComponent(req.url);
  let filePath = join(SERVE_DIR, decodedUrl === '/' ? HTML_FILE : decodedUrl);
  try {
    const content = readFileSync(filePath);
    const ext = extname(filePath).toLowerCase();
    res.writeHead(200, { 'Content-Type': MIME_TYPES[ext] || 'application/octet-stream' });
    res.end(content);
  } catch {
    res.writeHead(404);
    res.end('Not found');
  }
});

const port = await new Promise(r => server.listen(0, () => r(server.address().port)));
console.log(`  Server running on port ${port}`);

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: VP_WIDTH, height: VP_HEIGHT } });

await page.goto(`http://localhost:${port}/`, { waitUntil: 'networkidle' });
await page.evaluate(() => document.fonts.ready);
await page.waitForTimeout(1500);

const slideCount = await page.evaluate(() => document.querySelectorAll('.slide').length);
console.log(`  Found ${slideCount} slides`);

if (slideCount === 0) {
  console.error('  ERROR: No .slide elements found.');
  await browser.close();
  server.close();
  process.exit(1);
}

mkdirSync(SCREENSHOT_DIR, { recursive: true });
const screenshotPaths = [];

for (let i = 0; i < slideCount; i++) {
  await page.evaluate((idx) => {
    const slides = document.querySelectorAll('.slide');
    slides.forEach((slide, sidx) => {
      if (sidx === idx) {
        slide.style.display = '';
        slide.style.opacity = '1';
        slide.style.visibility = 'visible';
        slide.style.position = 'relative';
        slide.classList.add('active');
      } else {
        slide.style.display = 'none';
        slide.classList.remove('active');
      }
    });
    if (window.presentation && typeof window.presentation.goToSlide === 'function') {
      window.presentation.goToSlide(idx);
    }
  }, i);

  await page.waitForTimeout(300);
  await page.evaluate((idx) => {
    const slides = document.querySelectorAll('.slide');
    const current = slides[idx];
    if (current) {
      current.querySelectorAll('.reveal').forEach(el => {
        el.style.opacity = '1';
        el.style.transform = 'none';
      });
    }
  }, i);
  await page.waitForTimeout(100);

  const shotPath = join(SCREENSHOT_DIR, `slide-${String(i + 1).padStart(3, '0')}.png`);
  await page.screenshot({ path: shotPath, fullPage: false });
  screenshotPaths.push(shotPath);
  console.log(`  Captured slide ${i + 1}/${slideCount}`);
}

await browser.close();
server.close();

// ─── Combine into PDF ─────────────────────────────────
console.log('  Assembling PDF...');
const browser2 = await chromium.launch();
const pdfPage = await browser2.newPage();

const imagesHtml = screenshotPaths.map(p => {
  const data = readFileSync(p).toString('base64');
  return `<div class="page"><img src="data:image/png;base64,${data}" /></div>`;
}).join('\n');

const pdfHtml = `<!DOCTYPE html><html><head><style>
  * { margin: 0; padding: 0; }
  @page { size: ${VP_WIDTH}px ${VP_HEIGHT}px; margin: 0; }
  .page { width: ${VP_WIDTH}px; height: ${VP_HEIGHT}px; page-break-after: always; overflow: hidden; }
  .page:last-child { page-break-after: auto; }
  img { width: ${VP_WIDTH}px; height: ${VP_HEIGHT}px; display: block; object-fit: contain; }
</style></head><body>${imagesHtml}</body></html>`;

await pdfPage.setContent(pdfHtml, { waitUntil: 'load' });
await pdfPage.pdf({
  path: OUTPUT_PDF,
  width: `${VP_WIDTH}px`,
  height: `${VP_HEIGHT}px`,
  printBackground: true,
  margin: { top: 0, right: 0, bottom: 0, left: 0 },
});

await browser2.close();
screenshotPaths.forEach(p => unlinkSync(p));
console.log(`  PDF saved to: ${OUTPUT_PDF}`);
"@

Set-Content -Path $ExportScript -Value $playwrightScript -Encoding UTF8

# ─── Step 4: Install Playwright ─────────────────────────
Info "Setting up Playwright..."
Write-Host ""

$PlaywrightDir = Join-Path $TempDir "node_modules"
$pkgJson = Join-Path $TempDir "package.json"
Set-Content -Path $pkgJson -Value '{"name":"slide-export","private":true,"type":"module"}' -Encoding UTF8

Push-Location $TempDir
try {
    npm install playwright --silent 2>$null
    if (-not (Test-Path $PlaywrightDir)) {
        throw "npm install playwright failed"
    }
    Ok "Playwright installed"
    Write-Host ""

    # Install Chromium
    Info "Installing Chromium browser (one-time download, ~150MB)..."
    npx playwright install chromium 2>&1 | Out-Null
    Ok "Chromium ready"
    Write-Host ""
}
catch {
    Err "Failed to setup Playwright: $_"
    Pop-Location
    Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    exit 1
}
Pop-Location

# ─── Step 5: Run export ────────────────────────────────
if ($Compact) { Info "Using compact mode (1280×720)" }

Info "Exporting slides..."
Write-Host ""

node $ExportScript $HtmlDir $HtmlName $OutputPdf $TempScreenshots $ViewportW $ViewportH
if ($LASTEXITCODE -ne 0) {
    Err "PDF export failed."
    Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    exit 1
}

# ─── Step 6: Cleanup and success ───────────────────────
Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue

$fileSize = (Get-Item $OutputPdf).Length / 1MB
$fileSizeStr = "{0:N1} MB" -f $fileSize

Write-Host ""
Write-Host "════════════════════════════════════════" -ForegroundColor White
Ok "PDF exported successfully!"
Write-Host ""
Write-Host "  File:  $OutputPdf" -ForegroundColor White
Write-Host "  Size:  $fileSizeStr"
Write-Host ""
Write-Host "  Works everywhere — email, Slack, Notion, print." -ForegroundColor Gray
Write-Host "  Note: Animations are not preserved (static export)." -ForegroundColor Gray
Write-Host "════════════════════════════════════════" -ForegroundColor White
Write-Host ""

# Auto-open
try {
    Start-Process $OutputPdf -ErrorAction SilentlyContinue
}
catch { }
