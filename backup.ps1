<#
.SYNOPSIS
    Backup folders to network share using rclone.
.DESCRIPTION
    Syncs source folders to \\10.31.0.5\Public\Backups, copying changed files
    and deleting destination files that no longer exist in the source.
#>

$ErrorActionPreference = "Stop"

$Dest = "\\10.31.0.5\Public\Backups"

$Sources = @(
    @{ Path = "$HOME\Zotero";                    Name = "Zotero" }
    @{ Path = "$HOME\Documents\Inventory";       Name = "Inventory" }
    @{ Path = "$HOME\AppData\Roaming\krita";     Name = "krita" }
)

foreach ($src in $Sources) {
    if (-not (Test-Path $src.Path)) {
        Write-Warning "Source not found, skipping: $($src.Path)"
        continue
    }

    $destPath = Join-Path $Dest $src.Name
    Write-Host "Syncing $($src.Path) -> $destPath" -ForegroundColor Cyan

    rclone sync $src.Path $destPath --progress
    if ($LASTEXITCODE -ne 0) {
        Write-Error "rclone sync failed for $($src.Path) (exit code $LASTEXITCODE)"
    }
}

Write-Host "Backup complete." -ForegroundColor Green
