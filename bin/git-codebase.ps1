$repos = zoxide query -l | ? {
  Test-Path -LiteralPath "$_/.git"
} | Select-Object -First 25

git-multistatus @repos
