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

$hexified = "00,00,00,00,00,00,00,00,02,00,00,00,1d,00,3a,00,00,00,00,00".Split(',') | % { "0x$_"};

$kbLayout = 'HKLM:\System\CurrentControlSet\Control\Keyboard Layout';

New-ItemProperty -Force -Path $kbLayout -Name "Scancode Map" -PropertyType Binary -Value ([byte[]]$hexified);

New-Item -ItemType SymbolicLink -Force -Value "$PublicRepoDir/default/.vimrc" -Path "~/_vimrc"
New-Item -ItemType SymbolicLink -Force -Value "$PublicRepoDir/default/.vimrc" -Path "~/.vimrc"
mkdir -Force "$HOME/AppData/Local/nvim"
New-Item -ItemType SymbolicLink -Force -Value "$PublicRepoDir/default/.config/nvim/init.vim" -Path "$HOME/AppData/Local/nvim/init.vim"

ForEach ($f in ".ignore", ".editorconfig", ".ctags") {
  New-Item -ItemType SymbolicLink -Force -Value "$PublicRepoDir/default/$f" -Path "~/$f"
}

$PSProfileDir = $(Split-Path -Parent $PROFILE)
ls -Force "$PSProfileDir/local" | % { New-Item -ItemType SymbolicLink -Force -Value ($_.FullName) -Path "~/$($_.Name)" }

New-Item -ItemType SymbolicLink -Force -Value "$(pwd)\settings.json" -Path "$HOME\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
mkdir -Force "$HOME/.config"
New-Item -ItemType SymbolicLink -Force -Value "$(pwd)\starship.toml" -Path "$HOME\.config\starship.toml"

mkdir -Force ~/.ssh
