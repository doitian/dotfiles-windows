# Determine scoop's git bash path
if ($env:SCOOP) {
  $bashPath = "$env:SCOOP\apps\git\current\bin\bash.exe"
} else {
  $bashPath = "$env:USERPROFILE\scoop\apps\git\current\bin\bash.exe"
}

if (Test-Path $bashPath) {
  $shellPath = $bashPath
} else {
  $shellPath = "sh.exe"
}

bunx zx --shell $shellPath @args
