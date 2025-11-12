# PowerShell script to extract OWNER/REPO from a given Git remote name
# Usage: .\ghrr.ps1 -RemoteName "origin"
# Or: .\ghrr.ps1 "origin"

param(
    [Parameter(Mandatory=$false, Position=0)]
    [string]$RemoteName = "origin"
)

try {
    # Get the remote URL
    $remoteUrl = git config --get "remote.$RemoteName.url"

    if (-not $remoteUrl) {
        Write-Error "Remote '$RemoteName' not found or has no URL configured."
        exit 1
    }

    # Extract OWNER/REPO from various Git URL formats
    # Supports: https://github.com/OWNER/REPO.git, git@github.com:OWNER/REPO.git, etc.
    $ownerRepo = $null

    # Pattern for HTTPS URLs: https://github.com/OWNER/REPO.git or https://github.com/OWNER/REPO
    if ($remoteUrl -match 'https?://[^/]+/(.+?)/(.+?)(?:\.git)?/?$') {
        $ownerRepo = "$($matches[1])/$($matches[2])"
    }
    # Pattern for SSH URLs: git@github.com:OWNER/REPO.git
    elseif ($remoteUrl -match 'git@[^:]+:(.+?)/(.+?)(?:\.git)?/?$') {
        $ownerRepo = "$($matches[1])/$($matches[2])"
    }

    if ($ownerRepo) {
        Write-Output $ownerRepo
    } else {
        Write-Error "Could not parse OWNER/REPO from URL: $remoteUrl"
        exit 1
    }
}
catch {
    Write-Error "Error executing git command: $_"
    exit 1
}
