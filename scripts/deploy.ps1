# deploy.ps1 — Deploy a slide deck to Vercel for instant sharing
#
# Usage:
#   .\deploy.ps1 <path-to-slide-folder-or-html>
#
# Examples:
#   .\deploy.ps1 .\my-pitch-deck\
#   .\deploy.ps1 .\presentation.html
#
# Requirements:
#   - Node.js (https://nodejs.org)
#   - Vercel account (https://vercel.com/signup, free)
#
# What this does:
#   1. Checks if Vercel CLI is installed (installs if not)
#   2. Checks if user is logged in (guides through login if not)
#   3. Deploys the slide deck to a public URL
#   4. Prints the live URL

param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$InputPath
)

$ErrorActionPreference = "Stop"

# ─── Colors ────────────────────────────────────────────────
function Info  ($msg) { Write-Host "ℹ  $msg" -ForegroundColor Cyan }
function Ok    ($msg) { Write-Host "✓  $msg" -ForegroundColor Green }
function Warn  ($msg) { Write-Host "⚠  $msg" -ForegroundColor Yellow }
function Err   ($msg) { Write-Host "✗  $msg" -ForegroundColor Red }

# ─── Input validation ─────────────────────────────────────
if (-not (Test-Path $InputPath)) {
    Err "Path not found: $InputPath"
    exit 1
}

$InputPath = (Resolve-Path $InputPath).Path

Write-Host ""
Write-Host "╔══════════════════════════════════════╗" -ForegroundColor White
Write-Host "║       Deploy Slides to Vercel        ║" -ForegroundColor White
Write-Host "╚══════════════════════════════════════╝" -ForegroundColor White
Write-Host ""

# If input is a single HTML file, copy it to a temp folder as index.html
$isTempDir = $false
if ((Test-Path $InputPath -PathType Leaf) -and $InputPath -match "\.html$") {
    $tempDir = [System.IO.Path]::GetTempFileName() -replace "\.tmp$", ""
    Remove-Item $InputPath -Force -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Path $tempDir | Out-Null
    Copy-Item $InputPath "$tempDir\index.html"

    $parentDir = Split-Path $InputPath -Parent

    # Parse HTML for local file references and copy them
    $htmlContent = Get-Content "$tempDir\index.html" -Raw -Encoding UTF8
    $refs = [regex]::Matches($htmlContent, '(?:src|href|url\s*\()["'']?([^"'')>)]+)') | ForEach-Object { $_.Groups[1].Value }
    foreach ($ref in $refs) {
        $cleanRef = $ref -replace "^src=", "" -replace "^href=", "" -replace "^url\(", "" -replace '["'']', ""
        if ($cleanRef -match "^http" -or $cleanRef -match "^data:" -or $cleanRef -match "^#" -or $cleanRef -match "^/") { continue }
        $sourceFile = Join-Path $parentDir $cleanRef
        if (Test-Path $sourceFile -PathType Leaf) {
            $targetDir = Join-Path $tempDir (Split-Path $cleanRef)
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
            Copy-Item $sourceFile $targetDir -Force
        }
    }

    # Also copy assets/ folder if it exists
    $assetsSrc = Join-Path $parentDir "assets"
    if (Test-Path $assetsSrc -PathType Container) {
        Copy-Item $assetsSrc "$tempDir\assets" -Recurse -Force
    }

    $DeployDir = $tempDir
    $isTempDir = $true
    $deckName = [System.IO.Path]::GetFileNameWithoutExtension($InputPath)
    Info "Single HTML file detected — preparing for deployment..."
}
elseif (Test-Path $InputPath -PathType Container) {
    if (-not (Test-Path (Join-Path $InputPath "index.html"))) {
        Err "Folder '$InputPath' does not contain an index.html file."
        exit 1
    }
    $DeployDir = $InputPath
    $isTempDir = $false
    $deckName = Split-Path $InputPath -Leaf
}
else {
    Err "'$InputPath' is not a valid HTML file or directory."
    exit 1
}

# Sanitize project name for Vercel
$deckName = $deckName -replace '[^a-zA-Z0-9._-]', '-' -replace '-+', '-' -replace '^-|-$', ''
if ($deckName.Length -gt 100) { $deckName = $deckName.Substring(0, 100) }

# ─── Step 1: Check Node.js ───────────────────────────────
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Err "Node.js is required but not installed."
    Write-Host ""
    Write-Host "Install Node.js: https://nodejs.org" -ForegroundColor Cyan
    exit 1
}
Ok "Node.js found"

# ─── Step 2: Check/Install Vercel CLI ───────────────────
Info "Checking Vercel CLI..."

$vercelCmd = $null
if (Get-Command vercel -ErrorAction SilentlyContinue) {
    $vercelCmd = "vercel"
    Ok "Vercel CLI found"
}
else {
    try {
        Info "Installing Vercel CLI..."
        npm install -g vercel --silent 2>$null
        $vercelCmd = "vercel"
        Ok "Vercel CLI installed"
    }
    catch {
        Err "Failed to install Vercel CLI. Try: npm install -g vercel"
        exit 1
    }
}

# ─── Step 3: Check login status ─────────────────────────
Info "Checking Vercel login status..."

try {
    $whoami = & vercel whoami 2>&1
    $vercelUser = ($whoami | Out-String).Trim()
    if ($vercelUser -and $vercelUser -notmatch "^not") {
        Ok "Logged in as: $vercelUser"
    }
    else { $vercelUser = $null }
}
catch { $vercelUser = $null }

if (-not $vercelUser) {
    Write-Host ""
    Warn "You're not logged in to Vercel yet."
    Write-Host ""
    Write-Host "  1. Go to https://vercel.com/signup" -ForegroundColor White
    Write-Host "  2. Sign up with GitHub, Google, or email" -ForegroundColor White
    Write-Host "  3. Run: vercel login" -ForegroundColor White
    Write-Host "  4. Then re-run this deploy script" -ForegroundColor White
    Write-Host ""

    # Try interactive login
    Write-Host "Attempting interactive login..." -ForegroundColor Yellow
    try {
        & vercel login 2>&1 | Out-Null
        $whoami = & vercel whoami 2>&1
        $vercelUser = ($whoami | Out-String).Trim()
        if ($vercelUser) { Ok "Logged in as: $vercelUser" }
        else {
            Err "Login failed. Please run 'vercel login' manually."
            exit 1
        }
    }
    catch {
        Err "Login failed. Please run 'vercel login' manually."
        exit 1
    }
}

# ─── Step 4: Deploy ───────────────────────────────────
Write-Host ""
Info "Deploying slides..."
Write-Host ""

# Rename temp deploy dir to sanitized deck name
if ($isTempDir) {
    $renamedDir = Join-Path (Split-Path $tempDir -Parent) $deckName
    Move-Item $tempDir $renamedDir -Force
    $DeployDir = $renamedDir
}

try {
    $deployOutput = & vercel deploy $DeployDir --yes --prod 2>&1 | Out-String
}
catch {
    Err "Deployment failed: $_"
    exit 1
}

# Extract URL
$deployUrl = [regex]::Match($deployOutput, 'https://[^\s<>"'']+').Value | Select-Object -Last 1

if (-not $deployUrl) {
    Err "Deployment succeeded but couldn't find URL in output."
    Write-Host $deployOutput
    exit 1
}

# ─── Step 5: Success ───────────────────────────────────
Write-Host ""
Write-Host "════════════════════════════════════════" -ForegroundColor White
Ok "Slides deployed successfully!"
Write-Host ""
Write-Host "  Live URL:  $deployUrl" -ForegroundColor White
Write-Host ""
Write-Host "  Works on any device — phones, tablets, laptops." -ForegroundColor Gray
Write-Host "  Share via Slack, email, text, or anywhere." -ForegroundColor Gray
Write-Host ""
Write-Host "  Tip: To take it down, visit https://vercel.com/dashboard" -ForegroundColor Cyan
Write-Host "       and delete the project '$deckName'." -ForegroundColor Cyan
Write-Host "════════════════════════════════════════" -ForegroundColor White
Write-Host ""

# ─── Cleanup ──────────────────────────────────────────
if ($isTempDir) {
    Remove-Item $DeployDir -Recurse -Force -ErrorAction SilentlyContinue
}
