$skip = 0
if ($args.Count -gt 0) {
  $skip = $args[0]
}

$dir = (Get-Location).Path
while ($dir -ne '' -and $skip -ge 0) {
  if (Test-Path -LiteralPath "$dir\.git") {
    $skip = $skip - 1
  }

  if ($skip -ge 0) {
    $dir = Split-Path $dir
  }
}

if ($dir -ne '') {
  cd $dir
}
