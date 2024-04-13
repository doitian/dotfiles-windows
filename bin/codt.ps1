param([String]$taskLabel)

$tasks = (Get-Content .vscode\tasks.json | ConvertFrom-Json).tasks

function ancestors {
  param($task)

  $ancestors = @()
  if ($task.dependsOn -eq $null) {
    return $ancestors
  }

  foreach ($childLabel in $task.dependsOn) {
    $child = $tasks | ? { $_.label -eq $childLabel }
    $ancestors += ancestors $child
  }
  $ancestors += $task.dependsOn

  return $ancestors | Select-Object -Unique
}

function expandCommand {
  param([String]$command)
  $command -Replace '\${workspaceFolder}', "$pwd"
}

function runTask {
  param([String]$taskLabel)

  $task = $tasks | ? { $_.label -eq $taskLabel }
  foreach ($childLabel in (ancestors $task)) {
    $child = $tasks | ? { $_.label -eq $childLabel }
    $command = expandCommand $child.command
    $command | Out-Host
    if ($command) {
      Invoke-Expression $command &
    }
  }

  $command = $task.command -Replace '\${workspaceFolder}', "$pwd"
  $command | Out-Host
  # if ($command) {
  #   Invoke-Expression $command
  # }
}

if ($taskLabel) {
  runTask $taskLabel
} else {
  $tasks | % { "$($_.label): $(expandCommand $_.command)" }
}
