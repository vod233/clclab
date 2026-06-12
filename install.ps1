<#
  install.ps1
  ───────────
  一次性配置：
    1. 告诉 git 使用 .githooks/ 作为 hooks 目录
    2. 执行一次 sync-articles.ps1 确保 registry.json 同步
    3. 打印使用说明
#>

$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

Write-Host ""
Write-Host "── CLCLab articles automation setup ──" -ForegroundColor Cyan

# Configure git hooks path
$existing = git config core.hooksPath
if ($existing -ne '.githooks') {
    git config core.hooksPath .githooks
    Write-Host "  + git config core.hooksPath = .githooks" -ForegroundColor Green
} else {
    Write-Host "  · core.hooksPath already set" -ForegroundColor DarkGray
}

# Initial sync
Write-Host ""
Write-Host "── Running initial sync ──" -ForegroundColor Cyan
& "$PSScriptRoot\sync-articles.ps1"

Write-Host ""
Write-Host "── Setup complete ──" -ForegroundColor Green
Write-Host ""
Write-Host "  以后发布新文章："
Write-Host "    1. 把 .md 文件丢进 articles/"
Write-Host "    2. git add . && git commit -m 'post: 文章标题'"
Write-Host "    3. git push"
Write-Host ""
Write-Host "  pre-commit 钩子会自动跑 sync-articles.ps1 更新 registry.json" -ForegroundColor DarkGray
Write-Host "  或者一次性搞定：.\sync-articles.ps1 -Push" -ForegroundColor DarkGray
Write-Host ""
