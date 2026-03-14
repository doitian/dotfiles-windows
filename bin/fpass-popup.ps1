# Ensure gopass and fzf are found when run with -NoProfile (prepend User PATH)
# Gpg4win must come before Git's bundled GPG which has no secret keys
$env:Path = "$env:USERPROFILE\scoop\apps\gpg4win\current\GnuPG\bin;" +
  [Environment]::GetEnvironmentVariable("Path", "User") + ";" + $env:Path

$selected = gopass list -f | fzf --height=100% --layout=reverse
if ($selected) { gopass show -c $selected }

# Close the terminal window when the script exits
try {
  $parentId = (Get-CimInstance Win32_Process -Filter "ProcessId = $PID").ParentProcessId
  if ($parentId) { (Get-Process -Id $parentId).CloseMainWindow() | Out-Null }
} catch {}
