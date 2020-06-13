$repos = cat "$HOME\.cdHistory" | sort -Desc | % {
  $_.SubString(25)
} | ? {
  Test-Path -LiteralPath "$_/.git"
}

git-multistatus @repos
