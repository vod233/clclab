<#
  sync-articles.ps1
  ─────────────────
  Scan articles/ for .md files and sync metadata into registry.json.
  Supports optional YAML frontmatter at the top of each file.

  Usage:
    .\sync-articles.ps1             # scan + update registry + git add
    .\sync-articles.ps1 -Commit     # above + git commit
    .\sync-articles.ps1 -Push       # above + git push
    .\sync-articles.ps1 -DryRun     # preview only, no writes

  Frontmatter (optional):
    ---
    title: Article title
    date: 2026-06-20
    updated: 2026-06-21   (optional, defaults to date)
    excerpt: one-line summary
    tags: [build, Cloudflare]
    ---

  Publish flow:
    1. Drop a .md file into articles/
    2. Run: .\sync-articles.ps1 -Push
    OR
    1. Drop a .md file into articles/
    2. git add . && git commit -m "post: ..."
    3. git push   (pre-commit hook auto-runs this script)
#>

[CmdletBinding()]
param(
    [switch]$Commit,
    [switch]$Push,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

$articlesDir  = Join-Path $PSScriptRoot 'articles'
$registryPath = Join-Path $articlesDir  'registry.json'

# ── Helpers ──────────────────────────────────────────────────
# Quiet git: ignore stderr warnings like "LF will be replaced by CRLF"
function Git-Q {
    param([Parameter(ValueFromRemainingArguments=$true)]$Args)
    & git @Args 2>$null
    return $LASTEXITCODE
}

function Write-Banner {
    param([string]$Text, [string]$Color = 'Cyan')
    Write-Host ""
    Write-Host ("-- {0} --" -f $Text) -ForegroundColor $Color
}

function Parse-Frontmatter {
    param([string]$Content)
    if ($Content -notmatch '(?s)^---\r?\n(.+?)\r?\n---') { return @{} }
    $fm = @{}
    foreach ($line in $matches[1] -split "`r?`n") {
        if ($line -match '^\s*(\w+)\s*:\s*(.*?)\s*$') {
            $key   = $matches[1]
            $value = $matches[2]
            if ($value -match '^([^#]+?)(?:\s+#.*)?$') { $value = $matches[1].Trim() }
            if ($value -match '^\[(.*)\]$') {
                $fm[$key] = @($matches[1] -split ',' | ForEach-Object { $_.Trim().Trim('"', "'") } | Where-Object { $_ })
            } else {
                $fm[$key] = $value.Trim('"', "'")
            }
        }
    }
    return $fm
}

function Get-Excerpt {
    param([string]$Content, [int]$MaxLen = 120)
    $body = $Content -replace '(?s)^---.+?---\s*', ''
    $body = $body -replace '(?m)^#\s+.+?$', ''
    $body = $body -replace '(?m)^>\s*.+?$', ''
    $para = ($body -split "`r?`n`r?`n" |
        Where-Object { $_.Trim() -and -not $_.Trim().StartsWith('#') -and -not $_.Trim().StartsWith('```') } |
        Select-Object -First 1)
    if (-not $para) { return '' }
    $text = ($para -replace '\s+', ' ').Trim()
    if ($text.Length -gt $MaxLen) { $text = $text.Substring(0, $MaxLen).TrimEnd() + '...' }
    return $text
}

# ── Load registry ────────────────────────────────────────────
if (Test-Path $registryPath) {
    try {
        $registry = Get-Content $registryPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $existing = @($registry.articles)
    } catch {
        Write-Warning "registry.json parse failed, backing up and rebuilding"
        Move-Item $registryPath "$registryPath.bak" -Force
        $existing = @()
    }
} else {
    $existing = @()
}

# ── Scan articles/ ───────────────────────────────────────────
Write-Banner "Scanning articles/"

# Note: -Filter '*.md' is unreliable on PS5 with non-ASCII in working dir.
# Use -Include with -Recurse on the directory instead.
$mdFiles = @(Get-ChildItem -Path $articlesDir -File -Recurse |
    Where-Object { $_.Extension -eq '.md' })
$merged   = @($existing)
$changes  = @{ added = @(); updated = @(); unchanged = 0 }

foreach ($file in $mdFiles) {
    $slug    = $file.BaseName
    $content = Get-Content $file.FullName -Raw -Encoding UTF8
    $fm      = Parse-Frontmatter $content
    $old     = $existing | Where-Object { $_.slug -eq $slug } | Select-Object -First 1

    # title: frontmatter > H1 > existing > slug
    $title = if     ($fm['title'])                  { $fm['title'] }
             elseif ($content -match '(?m)^#\s+(.+?)$') { $matches[1].Trim() }
             elseif ($old -and $old.title)          { $old.title }
             else                                   { $slug }

    # date: frontmatter > existing > file mtime
    $date = if     ($fm['date'])                    { $fm['date'] }
            elseif ($old -and $old.date)            { $old.date }
            else                                    { $file.LastWriteTime.ToString('yyyy-MM-dd') }

    # excerpt: frontmatter > existing > body extraction
    $excerpt = if     ($fm['excerpt'])              { $fm['excerpt'] }
               elseif ($old -and $old.excerpt)      { $old.excerpt }
               else                                 { Get-Excerpt $content }

    # tags: frontmatter > existing > empty
    $tags = if     ($fm['tags'])                    { @($fm['tags']) }
            elseif ($old -and $old.tags)            { @($old.tags) }
            else                                    { @() }

    # updated: frontmatter > existing > date
    $updated = if     ($fm['updated'])              { $fm['updated'] }
               elseif ($old -and $old.updated)      { $old.updated }
               else                                 { $date }

    $entry = [ordered]@{
        slug    = $slug
        title   = $title
        date    = $date
        updated = $updated
        excerpt = $excerpt
        tags    = @($tags)
    }

    $isNew   = -not $old
    $changed = $isNew -or $old.title -ne $title -or $old.date -ne $date -or
               $old.excerpt -ne $excerpt -or
               (($old.tags | ConvertTo-Json -Compress) -ne (@($tags) | ConvertTo-Json -Compress))

    if ($changed) {
        if ($isNew) { $changes.added   += $entry } else { $changes.updated += $entry }
        $idx = -1
        for ($i = 0; $i -lt $merged.Count; $i++) { if ($merged[$i].slug -eq $slug) { $idx = $i; break } }
        if ($idx -ge 0) { $merged[$idx] = $entry } else { $merged += $entry }
        $action = if ($isNew) { '+ Added'   } else { '~ Updated' }
        $color  = if ($isNew) { 'Green'     } else { 'Yellow' }
        if ($DryRun) {
            if ($isNew) { $action = '+ Would add' } else { $action = '~ Would update' }
        }
        Write-Host ("  {0,-14} {1}" -f $action, $slug) -ForegroundColor $color
    } else {
        $changes.unchanged++
        if (-not $DryRun) { Write-Host ("  . Unchanged   {0}" -f $slug) -ForegroundColor DarkGray }
    }
}

# ── Save registry ────────────────────────────────────────────
$hasChanges = $changes.added.Count -gt 0 -or $changes.updated.Count -gt 0

if ($hasChanges -and -not $DryRun) {
    $sorted = $merged | Sort-Object { $_.date } -Descending
    $output = [ordered]@{ articles = @($sorted) }
    # Use 2-space indent to match project style
    $json = $output | ConvertTo-Json -Depth 10
    $json = $json -replace '(?m)^    ', '  '
    Set-Content -Path $registryPath -Value $json -Encoding UTF8 -NoNewline

    Write-Banner "registry.json updated"
    Write-Host ("  New:       {0}" -f $changes.added.Count)   -ForegroundColor Green
    Write-Host ("  Updated:   {0}" -f $changes.updated.Count) -ForegroundColor Yellow
    Write-Host ("  Unchanged: {0}" -f $changes.unchanged)     -ForegroundColor DarkGray
    Write-Host ("  Total:     {0}" -f @($merged).Count)       -ForegroundColor Cyan
}

if ($DryRun) {
    Write-Banner "Dry run complete - no changes made" 'Yellow'
    exit 0
}

if (-not $hasChanges) {
    Write-Host ""
    Write-Host "  No changes needed." -ForegroundColor DarkGray
    exit 0
}

# ── Git operations ───────────────────────────────────────────
Write-Banner "Staging files"
Git-Q add $registryPath | Out-Null
Get-ChildItem -Path $articlesDir -File -Recurse |
    Where-Object { $_.Extension -eq '.md' } |
    ForEach-Object { Git-Q add $_.FullName | Out-Null }
Write-Host "  Staged registry.json and all .md files" -ForegroundColor DarkGray

if ($Commit -or $Push) {
    Write-Banner "Committing"
    $msg = if     ($changes.added.Count -eq 1) { "post: $($changes.added[0].title)" }
           elseif ($changes.added.Count -gt 1) { "posts: $($changes.added.Count) new articles" }
           else                                { "chore: update articles registry" }
    Git-Q commit -m $msg | Out-Null
    Write-Host ("  {0}" -f $msg) -ForegroundColor Green
}

if ($Push) {
    Write-Banner "Pushing"
    Git-Q push | Out-Null
    Write-Host "  Pushed. Cloudflare Pages will deploy in ~30s." -ForegroundColor Green
} else {
    Write-Banner "Next step"
    Write-Host "  git commit -m 'post: ...'" -ForegroundColor Yellow
    Write-Host "  git push"                 -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Tip: the pre-commit hook will auto-run this script." -ForegroundColor DarkGray
}
