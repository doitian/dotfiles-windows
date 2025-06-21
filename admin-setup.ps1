$ReposDir = Get-Item "$HOME\.dotfiles\repos"
if ($ReposDir -eq $null) {
  echo "$HOME\.dotfiles\repos does not exist"
  return
}

if ($ReposDir.Target -ne $null) {
  $ReposDir = $ReposDir.Target
}
$PublicRepoDir = "$ReposDir\public"
$PrivateRepoDir = "$ReposDir\private"
$PSProfileDir = $(Split-Path -Parent $PROFILE)

mkdir -Force "$HOME/.config"
mkdir -Force ~/.ssh

New-Item -ItemType SymbolicLink -Force -Value "$PublicRepoDir/default/.vimrc" -Path "~/_vimrc"
New-Item -ItemType SymbolicLink -Force -Value "$PublicRepoDir/default/.vimrc" -Path "~/.vimrc"
New-Item -ItemType SymbolicLink -Force -Value "$PublicRepoDir/default/.ideavimrc" -Path "~/.ideavimrc"
ForEach ($f in ".ignore", ".editorconfig", ".ctags") {
  New-Item -ItemType SymbolicLink -Force -Value "$PublicRepoDir/default/$f" -Path "~/$f"
}
New-Item -ItemType SymbolicLink -Force -Value "$PublicRepoDir/nvim" -Path "$HOME/AppData/Local/nvim"
New-Item -ItemType SymbolicLink -Force -Value "$PublicRepoDir/nvim" -Path "$HOME/.config/nvim"


New-Item -ItemType SymbolicLink -Force -Value "$(pwd)\settings.json" -Path "$HOME\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
rm -Re -Force "$HOME/AppData/Roaming/lazygit"
New-Item -ItemType SymbolicLink -Force -Value "$PublicRepoDir/default/.config/lazygit" -Path "$HOME/AppData/Roaming/lazygit"

ls -Force "$PSProfileDir/local" | % { New-Item -ItemType SymbolicLink -Force -Value ($_.FullName) -Path "~/$($_.Name)" }

$DictionaryFile = "$HOME/Dropbox/Apps/Harper/dictionary.txt"
if (Test-Path $DictionaryFile) {
  $RoamingDictionaryFile = "$HOME/AppData/Roaming/harper-ls/dictionary.txt"
  mkdir -Force "$HOME"
  New-Item -ItemType SymbolicLink -Force -Value $DictionaryFile -Path $RoamingDictionaryFile
}
