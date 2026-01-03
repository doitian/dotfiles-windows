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

foreach ($repo in $repos) {
    $repoUrl = "git@github.com:$repo.git"

    if (Test-Path "$repo.ignore") {
        Write-Host "Skipping $repo"
        continue
    }
    Write-Host "Backing up $repo..."
    if (-not (Test-Path "$repo.git")) {
        # Shallow clone the default branch, saving only the latest snapshot
        git clone --bare --depth 1 $repoUrl "$repo.git"
    } else {
        # Pull the latest changes to the default branch, keep history shallow
        git -C "$repo.git" fetch --depth 1
        git -C "$repo.git" update-ref HEAD FETCH_HEAD
    }
}
