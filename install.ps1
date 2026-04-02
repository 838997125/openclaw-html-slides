# install.ps1 — 一键安装 HTML Slides 技能到 OpenClaw
#
# 用法：在 PowerShell 中运行
#   .\install.ps1
#
# 或一行命令：
#   irm https://raw.githubusercontent.com/838997125/openclaw-html-slides/main/install.ps1 | iex

param(
    [string]$SkillDest = "$HOME\.openclaw\workspace\skills\html-slides"
)

$ErrorActionPreference = "Stop"
$RepoUrl = "https://github.com/838997125/openclaw-html-slides"
$Branch = "main"

function Info ($msg) { Write-Host "ℹ  $msg" -ForegroundColor Cyan }
function Ok   ($msg) { Write-Host "✓  $msg" -ForegroundColor Green }
function Err  ($msg) { Write-Host "✗  $msg" -ForegroundColor Red }

Write-Host ""
Write-Host "╔══════════════════════════════════════╗" -ForegroundColor White
Write-Host "║   HTML Slides · OpenClaw 安装程序     ║" -ForegroundColor White
Write-Host "╚══════════════════════════════════════╝" -ForegroundColor White
Write-Host ""

# ─── 检查 OpenClaw workspace ───────────────────────────
$workspace = $HOME + "\.openclaw\workspace"
if (-not (Test-Path $workspace)) {
    Err "OpenClaw workspace 不存在：$workspace"
    Write-Host "请先安装 OpenClaw：https://docs.openclaw.ai" -ForegroundColor Cyan
    exit 1
}
Ok "OpenClaw workspace 存在"

# ─── 创建 skills 目录 ──────────────────────────────────
$skillDir = $SkillDest
if (-not (Test-Path $skillDir)) {
    New-Item -ItemType Directory -Path $skillDir -Force | Out-Null
}
Info "安装目录：$skillDir"

# ─── 下载仓库 ──────────────────────────────────────────
$tmpZip = [System.IO.Path]::GetTempFileName() + ".zip"
$tmpDir = [System.IO.Path]::GetTempFileName()

Info "正在下载仓库..."
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri "$RepoUrl/archive/refs/heads/$Branch.zip" -OutFile $tmpZip -TimeoutSec 30
    Ok "下载完成"
}
catch {
    Err "下载失败：$_"
    Remove-Item $tmpZip -Force -ErrorAction SilentlyContinue
    exit 1
}

# ─── 解压 ───────────────────────────────────────────────
Info "正在解压..."
Expand-Archive -Path $tmpZip -DestinationPath $tmpDir -Force
$extractedDir = (Get-ChildItem $tmpDir | Where-Object { $_.PSIsContainer })[0].FullName

# ─── 复制文件到 skill 目录 ──────────────────────────────
Info "正在安装技能..."
Get-ChildItem $extractedDir | ForEach-Object {
    Copy-Item $_.FullName "$skillDir\" -Recurse -Force
}
Ok "技能文件已安装到：$skillDir"

# ─── 清理 ──────────────────────────────────────────────
Remove-Item $tmpZip -Force -ErrorAction SilentlyContinue
Remove-Item $tmpDir -Recurse -Force -ErrorAction SilentlyContinue

# ─── 完成 ──────────────────────────────────────────────
Write-Host ""
Write-Host "════════════════════════════════════════" -ForegroundColor Green
Ok "安装成功！" -ForegroundColor Green
Write-Host ""
Write-Host "  安装路径：$skillDir" -ForegroundColor White
Write-Host ""
Write-Host "  使用方法（在 OpenClaw 中对小小说）：" -ForegroundColor Gray
Write-Host "  ""帮我做个 PPT""  /  ""做个路演幻灯片""" -ForegroundColor White
Write-Host "  ""做网页版自我介绍""  /  ""把 PPT 转成网页""" -ForegroundColor White
Write-Host ""
Write-Host "════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
