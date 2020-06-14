cat "$HOME\.cdHistory" | sort -Desc | % {
  $_.SubString(25)
} | ? {
  Test-Path -LiteralPath $_
} | Resolve-Path
