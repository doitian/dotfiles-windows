# PowerShell equivalent of the bash script

# Stop on error (equivalent to set -e)
$ErrorActionPreference = "Stop"

# Fetch all remotes and prune deleted remote branches
git fetch --all --prune

# Get all local branch names
$localBranches = git show-ref --heads | ForEach-Object {
    $_ -replace '^\w+\s+refs/heads/', ''
}

# Filter out protected branches (develop, master, main)
$protectedBranches = @('develop', 'master', 'main')
$branchesToDelete = $localBranches | Where-Object {
    $_ -notin $protectedBranches
}

# Delete branches with confirmation
if ($branchesToDelete.Count -gt 0) {
    foreach ($branch in $branchesToDelete) {
        $confirm = Read-Host "Delete branch '$branch'? (y/n)"
        if ($confirm -eq 'y') {
            git branch -d $branch
        }
    }
} else {
    Write-Host "No branches to delete."
}
