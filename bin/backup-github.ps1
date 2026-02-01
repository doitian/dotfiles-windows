$dumpFile = "backup-github-remaining.txt"

# Check if resuming from a previous failed run
if (Test-Path $dumpFile) {
    Write-Host "Resuming from previous run..."
    $repos = Get-Content $dumpFile
    Remove-Item $dumpFile
} else {
    $query = @'
query($endCursor: String) {
  viewer {
    repositories(first: 100, after: $endCursor, ownerAffiliations: OWNER, isFork: false) {
      nodes {
        nameWithOwner
      }
      pageInfo {
        endCursor
        hasNextPage
      }
    }
  }
}
'@
    $repos = gh api graphql --paginate --slurp -f query="$query" | ConvertFrom-Json | % { $_.data.viewer.repositories.nodes | % { $_.nameWithOwner } }
}

$repos = @($repos)
$remainingRepos = [System.Collections.Generic.HashSet[string]]::new([string[]]$repos)

$hasError = $false

try {
    foreach ($repo in $repos) {
        $repoUrl = "git@github.com:$repo.git"

        if (Test-Path "$repo.ignore") {
            Write-Host "Skipping $repo"
            [void]$remainingRepos.Remove($repo)
            continue
        }
        Write-Host "Backing up $repo..."
        if (-not (Test-Path "$repo.git")) {
            # Shallow clone the default branch, saving only the latest snapshot
            git clone --bare --depth 1 $repoUrl "$repo.git"
            if ($LASTEXITCODE -ne 0) { throw "git clone failed with exit code $LASTEXITCODE" }
        } else {
            # Pull the latest changes to the default branch, keep history shallow
            git -C "$repo.git" -c safe.directory="*" fetch --depth 1
            if ($LASTEXITCODE -ne 0) { throw "git fetch failed with exit code $LASTEXITCODE" }
            git -C "$repo.git" -c safe.directory="*" update-ref HEAD FETCH_HEAD
            if ($LASTEXITCODE -ne 0) { throw "git update-ref failed with exit code $LASTEXITCODE" }
        }
        [void]$remainingRepos.Remove($repo)
    }
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    $hasError = $true
} finally {
    if ($remainingRepos.Count -gt 0) {
        Write-Host "Dumping $($remainingRepos.Count) remaining repos to $dumpFile" -ForegroundColor Yellow
        $remainingRepos | Set-Content $dumpFile
    }
}

if ($hasError) {
    Write-Error "Backup failed"
}
