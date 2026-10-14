<#
.SYNOPSIS
    Backup folders to network share using rclone.
.DESCRIPTION
    Syncs source folders to \\10.31.0.5\Public\Backups, copying changed files
    and deleting destination files that no longer exist in the source.
#>

$ErrorActionPreference = "Stop"

$Dest = "\\10.31.0.5\Public\Backups"
$Failed = @()

$Sources = @(
    @{ Path = "$HOME\Zotero"; Name = "Zotero"; Exclude = @("*.bak", "*.tmp") }
    @{ Path = "$HOME\AppData\Roaming\Ulanzi\UlanziDeck\ProfilesV2"; Name = "UlanziDeck-ProfilesV2" }
)

foreach ($src in $Sources) {
    if (-not (Test-Path $src.Path)) {
        Write-Warning "Source not found, skipping: $($src.Path)"
        continue
    }

    $destPath = Join-Path $Dest $src.Name
    Write-Host "Syncing $($src.Path) -> $destPath" -ForegroundColor Cyan

    $rcloneArgs = @("sync", $src.Path, $destPath, "--progress")
    if ($src.Exclude) {
        foreach ($ex in $src.Exclude) {
            $rcloneArgs += "--exclude", $ex
        }
    }
    rclone @rcloneArgs
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "rclone sync failed for $($src.Path) (exit code $LASTEXITCODE)"
        $Failed += $src.Name
    }
}

if ($Failed) {
    Write-Warning "Backup finished with failures: $($Failed -join ', ')"
    exit 1
}
Write-Host "Backup complete." -ForegroundColor Green
