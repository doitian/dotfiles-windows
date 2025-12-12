#Requires -Version 5.1

param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$RemainingArgs
)

$ErrorActionPreference = "Stop"

# Default values
$Branch = "_store"
$Remote = "origin"
$Help = $false
$subcommand = $null
$positionalArgs = @()

# Parse arguments
$i = 0
while ($i -lt $RemainingArgs.Length) {
    $arg = $RemainingArgs[$i]

    switch -Regex ($arg) {
        "^-b$|^--branch$" {
            if ($i + 1 -ge $RemainingArgs.Length) {
                Write-Error "Error: Option $arg requires an argument"
                exit 1
            }
            $Branch = $RemainingArgs[$i + 1]
            $i += 2
            continue
        }
        "^-r$|^--remote$" {
            if ($i + 1 -ge $RemainingArgs.Length) {
                Write-Error "Error: Option $arg requires an argument"
                exit 1
            }
            $Remote = $RemainingArgs[$i + 1]
            $i += 2
            continue
        }
        "^-h$|^-help$|^--help$" {
            $Help = $true
            $i++
            continue
        }
        "^--$" {
            # End of options
            $i++
            $positionalArgs += $RemainingArgs[$i..($RemainingArgs.Length - 1)]
            break
        }
        "^(store|status|restore|ls)$" {
            if (-not $subcommand) {
                $subcommand = $arg
            } else {
                $positionalArgs += $arg
            }
            $i++
            continue
        }
        default {
            # If we already have a subcommand, treat remaining args as positional
            # Otherwise, treat as files for default "store" command
            $positionalArgs += $arg
            $i++
            continue
        }
    }
}

function Show-Help {
    $scriptName = if ($MyInvocation.ScriptName) { Split-Path -Leaf $MyInvocation.ScriptName } else { "git-store-file.ps1" }
    Write-Host "Usage: $scriptName [OPTIONS] [COMMAND] [ARGS...]"
    Write-Host ""
    Write-Host "Commands:"
    Write-Host "  store [FILE...]        Store files to remote branch (default)"
    Write-Host "  status [OPTIONS]       Show git status for files in the remote branch"
    Write-Host "    -d, --diff           Show diff for modified files"
    Write-Host "  restore [FILE...]      Restore files from remote branch to working directory"
    Write-Host "                         (restores all files if none specified)"
    Write-Host "  ls                     List all files in the remote branch"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -Branch BRANCH         Branch name (default: _store)"
    Write-Host "  -Remote REMOTE         Remote name (default: origin)"
    Write-Host "  -Help                  Show this help message"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  $scriptName config.txt                    # store file (default command)"
    Write-Host "  $scriptName file1.txt file2.txt           # store multiple files"
    Write-Host "  $scriptName -Branch backup config.txt    # store with custom branch"
    Write-Host "  $scriptName status                        # check status"
    Write-Host "  $scriptName status -d                     # check status with diff"
    Write-Host "  $scriptName restore config.txt            # restore specific file"
    Write-Host "  $scriptName restore                       # restore all files from branch"
    Write-Host "  $scriptName ls                            # list all files in branch"
}

function Invoke-StatusSubcommand {
    param(
        [string]$Branch,
        [string]$Remote,
        [string[]]$RemainingArgs
    )

    $showDiff = $false
    $statusArgs = @()

    # Parse status-specific options
    for ($i = 0; $i -lt $RemainingArgs.Length; $i++) {
        switch ($RemainingArgs[$i]) {
            { $_ -eq "-d" -or $_ -eq "--diff" } {
                $showDiff = $true
            }
            { $_ -eq "-h" -or $_ -eq "--help" } {
                $scriptName = if ($MyInvocation.ScriptName) { Split-Path -Leaf $MyInvocation.ScriptName } else { "git-store-file.ps1" }
                Write-Host "Usage: $scriptName status [OPTIONS]"
                Write-Host ""
                Write-Host "Show git status for files in the remote branch."
                Write-Host ""
                Write-Host "Options:"
                Write-Host "  -d, --diff             Show diff for modified files"
                Write-Host "  -h, --help             Show this help message"
                exit 0
            }
            default {
                Write-Error "Error: Unknown option for status: $($RemainingArgs[$i])"
                Write-Host "Use '$scriptName status --help' for usage information" -ForegroundColor Red
                exit 1
            }
        }
    }

    # Check if branch exists
    $null = git rev-parse --verify "$Remote/$Branch" 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Branch $Remote/$Branch does not exist."
    }

    # Get list of files in the branch
    $branchFiles = git ls-tree -r --name-only "$Remote/$Branch" 2>$null
    if ([string]::IsNullOrWhiteSpace($branchFiles)) {
        Write-Host "No files in branch $Remote/$Branch"
        return
    }

    # Convert to array
    $filesArray = $branchFiles -split "`n" | Where-Object { $_ -ne "" }

    # Check status of each file compared to branch
    $modifiedFiles = @()
    $deletedFiles = @()

    foreach ($file in $filesArray) {
        # Check if file exists in working directory
        if (-not (Test-Path $file)) {
            $deletedFiles += $file
            continue
        }

        # Check if file differs from branch version
        $null = git --no-pager diff --quiet "$Remote/$Branch`:$file" $file 2>$null
        if ($LASTEXITCODE -ne 0) {
            $modifiedFiles += $file
        }
    }

    # Show status output
    $hasOutput = $false

    if ($modifiedFiles.Count -gt 0) {
        foreach ($file in $modifiedFiles) {
            Write-Host "  modified:   $file"
        }
        $hasOutput = $true
    }

    if ($deletedFiles.Count -gt 0) {
        foreach ($file in $deletedFiles) {
            Write-Host "  deleted:    $file"
        }
        $hasOutput = $true
    }

    if (-not $hasOutput) {
        Write-Host "Files in $Remote/$Branch are up to date."
    }

    # Show diff if requested
    if ($showDiff -and $modifiedFiles.Count -gt 0) {
        foreach ($file in $modifiedFiles) {
            Write-Host "--- $Remote/$Branch`:$file"
            Write-Host "+++ $file"
            git --no-pager diff "$Remote/$Branch`:$file" $file 2>$null
        }
    }
}

function Invoke-RestoreSubcommand {
    param(
        [string]$Branch,
        [string]$Remote,
        [string[]]$RemainingArgs
    )

    # Check if branch exists
    $null = git rev-parse --verify "$Remote/$Branch" 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Branch $Remote/$Branch does not exist."
    }

    # Use a temporary index to restore files
    $tempIndex = ".git\temp_restore_index"
    $env:GIT_INDEX_FILE = $tempIndex

    try {
        # Load the branch's tree into the temporary index
        $null = git read-tree "$Remote/$Branch" 2>$null
        if ($LASTEXITCODE -ne 0) {
            $null = git read-tree --empty
        }

        # Restore files from the temporary index to working directory
        if ($RemainingArgs.Count -gt 0) {
            git restore --worktree $RemainingArgs
        } else {
            # Restore all files if none specified
            $allFiles = git ls-tree -r --name-only "$Remote/$Branch" 2>$null
            if ($allFiles) {
                $filesArray = $allFiles -split "`n" | Where-Object { $_ -ne "" }
                git restore --worktree $filesArray
            }
        }
    }
    finally {
        # Cleanup
        if (Test-Path $tempIndex) {
            Remove-Item $tempIndex -Force
        }
        Remove-Item Env:\GIT_INDEX_FILE -ErrorAction SilentlyContinue
    }
}

function Invoke-LsSubcommand {
    param(
        [string]$Branch,
        [string]$Remote
    )

    # Check if branch exists
    $null = git rev-parse --verify "$Remote/$Branch" 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Branch $Remote/$Branch does not exist."
    }

    # List all files in the branch
    $branchFiles = git ls-tree -r --name-only "$Remote/$Branch" 2>$null

    if ([string]::IsNullOrWhiteSpace($branchFiles)) {
        Write-Host "No files in branch $Remote/$Branch"
        return
    }

    # Print files
    Write-Host $branchFiles
}

function Invoke-StoreSubcommand {
    param(
        [string]$Branch,
        [string]$Remote,
        [string[]]$RemainingArgs
    )

    if ($RemainingArgs.Count -eq 0) {
        Write-Error "At least one file is required."
        Write-Host "Use -Help for usage information" -ForegroundColor Red
        exit 1
    }

    # Use a temporary index to avoid messing with your current files
    $tempIndex = ".git\temp_backup_index"
    $env:GIT_INDEX_FILE = $tempIndex

    try {
        # Load the target branch's current state
        $null = git read-tree "$Remote/$Branch" 2>$null
        if ($LASTEXITCODE -ne 0) {
            $null = git read-tree --empty
        }

        # Add all files (forced, in case they are ignored)
        git add -f $RemainingArgs

        # Create a commit object
        $tree = git write-tree
        $parent = git rev-parse --verify "$Remote/$Branch" 2>$null
        $commitHash = $null

        # Create commit message listing all files
        $commitMsg = "Backup git add -f $($RemainingArgs -join ' ')"

        if ($parent) {
            $commitHash = $commitMsg | git commit-tree $tree -p $parent
        } else {
            $commitHash = $commitMsg | git commit-tree $tree
        }

        # Show stats of the commit before pushing
        Write-Host "Commit stats:"
        if ($parent) {
            git --no-pager show --format= --stat $commitHash 2>$null
            if ($LASTEXITCODE -ne 0) {
                git --no-pager diff-tree --stat $parent $commitHash 2>$null
            }
        } else {
            git --no-pager show --format= --stat $commitHash 2>$null
        }
        Write-Host ""

        # Ask for confirmation before pushing
        $response = Read-Host "Push to $Remote/$Branch? [y/N]"
        if ($response -notmatch "^[Yy]$") {
            Write-Host "Push cancelled."
            exit 1
        }

        # Update the remote branch to point to the new commit
        git push $Remote "$commitHash`:refs/heads/$Branch"

        Write-Host "✅ Saved git add -f $($RemainingArgs -join ' ') to remote branch '$Remote/$Branch'"
    }
    finally {
        # Cleanup
        if (Test-Path $tempIndex) {
            Remove-Item $tempIndex -Force
        }
        Remove-Item Env:\GIT_INDEX_FILE -ErrorAction SilentlyContinue
    }
}

# Main execution
if ($Help) {
    Show-Help
    exit 0
}

# Default to store if no subcommand specified
if (-not $subcommand) {
    $subcommand = "store"
    # If no subcommand was found, all positional args are files
    # (they were already added to $positionalArgs in the default case)
} else {
    # If subcommand was found, any args after it should be in $positionalArgs
    # This is already handled in the parsing loop
}

# Debug: Uncomment to see what's being captured
# Write-Host "DEBUG: subcommand=$subcommand, positionalArgs=$($positionalArgs -join ', '), RemainingArgs=$($RemainingArgs -join ', ')" -ForegroundColor Yellow

# Execute subcommand
switch ($subcommand) {
    "store" {
        Invoke-StoreSubcommand -Branch $Branch -Remote $Remote -RemainingArgs $positionalArgs
    }
    "status" {
        Invoke-StatusSubcommand -Branch $Branch -Remote $Remote -RemainingArgs $positionalArgs
    }
    "restore" {
        Invoke-RestoreSubcommand -Branch $Branch -Remote $Remote -RemainingArgs $positionalArgs
    }
    "ls" {
        Invoke-LsSubcommand -Branch $Branch -Remote $Remote
    }
    default {
        Write-Error "Error: Unknown subcommand: $subcommand"
        exit 1
    }
}

