$ReposDir = Get-Item "$HOME\.dotfiles\repos"
if ($ReposDir.Target -ne $null) {
  $ReposDir = $ReposDir.Target
}
$PublicRepoDir = "$ReposDir\public"
$PrivateRepoDir = "$ReposDir\private"

git-multistatus $PublicRepoDir $PrivateRepoDir (Split-Path $PROFILE)
