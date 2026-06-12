<#
  sync-articles.ps1 (wrapper)
  ───────────────────────────
  Thin wrapper that delegates to the root-level sync-articles.ps1.
  Allows running the script from any directory inside the project.
#>

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$main = Join-Path $root 'sync-articles.ps1'

if (-not (Test-Path $main)) {
    Write-Error "Cannot find main script at: $main"
    exit 1
}

# Forward all arguments (DryRun, Commit, Push, etc.)
& $main @args
