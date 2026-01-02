#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Upload files to R2 bucket via rclone with date-based organization
.DESCRIPTION
    Uploads files to r2:blog/uploads with a prefix format: YYYYMM/random_hex/filename
    Prints the public URL after successful upload
.PARAMETER Files
    One or more file paths to upload
.EXAMPLE
    .\r2upload.ps1 image.png
.EXAMPLE
    .\r2upload.ps1 file1.png file2.jpg file3.pdf
#>

param(
    [Parameter(Mandatory=$true, ValueFromRemainingArguments=$true)]
    [string[]]$Files
)

function Get-RandomHex {
    param([int]$Length = 6)

    $bytes = New-Object byte[] ($Length / 2)
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    $rng.GetBytes($bytes)
    $rng.Dispose()

    return ($bytes | ForEach-Object { $_.ToString("x2") }) -join ''
}

function Upload-ToR2 {
    param(
        [string]$FilePath
    )

    # Check if file exists
    if (-not (Test-Path $FilePath)) {
        Write-Error "File not found: $FilePath"
        return $false
    }

    # Get file info
    $fileItem = Get-Item $FilePath
    $fileName = $fileItem.Name

    # Generate prefix: YYYYMM/random_hex
    $datePrefix = Get-Date -Format "yyyyMM"
    $randomHex = Get-RandomHex -Length 6
    $prefix = "$datePrefix/$randomHex"

    # Construct R2 path
    $r2Path = "r2:blog/uploads/$prefix/$fileName"

    Write-Host "Uploading $fileName..." -ForegroundColor Cyan
    Write-Host "  Source: $FilePath" -ForegroundColor Gray
    Write-Host "  Destination: $r2Path" -ForegroundColor Gray

    # Upload with rclone
    $rcloneArgs = @(
        "copy",
        $FilePath,
        "r2:blog/uploads/$prefix/",
        "--progress",
        "--s3-no-check-bucket"
    )

    try {
        $result = & rclone @rcloneArgs 2>&1

        if ($LASTEXITCODE -eq 0) {
            # Generate public URL
            $publicUrl = "https://blog.iany.me/uploads/$prefix/$fileName"

            Write-Host ""
            Write-Host "✓ Upload successful!" -ForegroundColor Green
            Write-Host "  URL: $publicUrl" -ForegroundColor Green
            Write-Host ""

            return $true
        } else {
            Write-Host ""
            Write-Host "✗ Upload failed for $fileName" -ForegroundColor Red
            if ($result) {
                Write-Host "  Error details:" -ForegroundColor Red
                $result | ForEach-Object { Write-Host "    $_" -ForegroundColor Red }
            }
            Write-Host ""
            return $false
        }
    } catch {
        Write-Host ""
        Write-Host "✗ Error uploading $fileName : $_" -ForegroundColor Red
        Write-Host ""
        return $false
    }
}

# Main execution
Write-Host "=== R2 Upload Script ===" -ForegroundColor Yellow
Write-Host ""

# Check if rclone is available
if (-not (Get-Command rclone -ErrorAction SilentlyContinue)) {
    Write-Error "rclone is not installed or not in PATH"
    exit 1
}

$successCount = 0
$failCount = 0

foreach ($file in $Files) {
    if (Upload-ToR2 -FilePath $file) {
        $successCount++
    } else {
        $failCount++
    }
}

Write-Host "=== Summary ===" -ForegroundColor Yellow
Write-Host "  Successful: $successCount" -ForegroundColor Green
Write-Host "  Failed: $failCount" -ForegroundColor $(if ($failCount -gt 0) { "Red" } else { "Gray" })
Write-Host ""

exit $(if ($failCount -gt 0) { 1 } else { 0 })
