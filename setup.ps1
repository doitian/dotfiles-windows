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
$DocumentsDir = Split-Path -Parent (Split-Path -Parent $PROFILE)

git config --global core.autocrlf input

ForEach ($repo in $PublicRepoDir, $PrivateRepoDir) {
  if (Test-Path -LiteralPath $repo) {
    git -C $repo pull
  } else {
    git clone --depth 1 "git@github.com:doitian/dotfiles-$(Split-Path -Leaf $repo).git" $repo
  }
}

$UserBinDir = "$(Split-Path -Parent $PROFILE)\bin"
$UserPath = [Environment]::GetEnvironmentVariable('Path', 'User')
$UserPathList = $UserPath.Split(";")
if (-Not $UserPathList.Contains($UserBinDir)) {
  $UserPath = "$UserPath;$UserBinDir"
  [Environment]::SetEnvironmentVariable('Path', "$UserPath", 'User')
}
$PublicDistDir = "$PublicRepoDir\dist"
if (-Not $UserPathList.Contains($PublicDistDir)) {
  $UserPath = "$UserPath;$PublicDistDir"
  [Environment]::SetEnvironmentVariable('Path', "$UserPath", 'User')
}
$MasonBinDir = "$HOME\AppData\Local\nvim-data\mason\bin"
if (-Not $UserPathList.Contains($MasonBinDir)) {
  $UserPath = "$UserPath;$MasonBinDir"
  [Environment]::SetEnvironmentVariable('Path', "$UserPath", 'User')
}
[Environment]::SetEnvironmentVariable('EDITOR', 'nvim', 'User')
[Environment]::SetEnvironmentVariable('FZF_DEFAULT_OPTS', '--prompt="❯ " --color light', 'User')
[Environment]::SetEnvironmentVariable('FZF_DEFAULT_COMMAND', 'fd --type f --hidden --follow --exclude ".git" --path-separator /', 'User')
[Environment]::SetEnvironmentVariable('FZF_CTRL_T_COMMAND', 'fd --type f --hidden --follow --exclude ".git" --path-separator /', 'User')
[Environment]::SetEnvironmentVariable('FZF_ALT_C_COMMAND', 'fd --type d --no-ignore --hidden --follow --exclude ".git" --path-separator /', 'User')
[Environment]::SetEnvironmentVariable('BAT_THEME', 'OneHalfLight', 'User')
[Environment]::SetEnvironmentVariable('PAGER', 'less -R', 'User')
[Environment]::SetEnvironmentVariable('LSCOLORS', 'Gxfxcxdxbxegedabagacad', 'User')
[Environment]::SetEnvironmentVariable('LS_COLORS', 'di=1;36:ln=35:so=32:pi=33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43', 'User')

$GitconfigTmpl = $(Get-Content "$PublicRepoDir/gitconfig.tmpl")
$GitconfigTmpl = $GitconfigTmpl -Replace "__NAME__", "ian"
$GitconfigTmpl = $GitconfigTmpl -Replace "__EMAIL__", "me@iany.me"
$GitconfigTmpl = $GitconfigTmpl -Replace "__HOME__", ("$HOME" -Replace "\\", "/")

$GitconfigTmpl -join "`n" | Set-Content -NoNewLine "~/.gitconfig"
git config --global core.autocrlf input
git config --global core.hooksPath "$HOME/.githooks"
git config --global --unset core.pager
git config --global gpg.program (Get-Command -Name 'gpg.exe').Source
git config --global alias.dotfiles '!powershell.exe -NoProfile -Command git-dotfiles'

$PublicRepoDirPosix = $PublicRepoDir -replace "\\", "/"
git config --global alias.store-file "!f() { python3 `"$PublicRepoDirPosix/default/bin/git-store-file`" `"$@`"; }; f"
git config --global "alias.branch-tree" "!python3 `"$PublicRepoDirPosix/default/bin/git-branch-tree`""
git config --global alias.bt "!python3 `"$PublicRepoDirPosix/default/bin/git-branch-tree`""

mkdir -Force ~/.local/state/vim/backup, ~/.local/state/vim/swap, ~/.local/state/vim/undo, ~/.vim, ~/.config, ~/.ssh

Function ln ($value, $path) {
  if (Test-Path -LiteralPath $path) {
    rm -Re -Force $path
  }
  New-Item -ItemType SymbolicLink -Force -Path $path -Value $value
}

if (Test-Path -LiteralPath "$DocumentsDir\PowerShell") {
  ln "$DocumentsDir\PowerShell" "$DocumentsDir\WindowsPowerShell"
}

ln "$PublicRepoDir\mise" "$HOME\.config\mise"
Add-Content -Value $null "$HOME\.config\mise\config.toml"
ln "$PublicRepoDir\default\.githooks" "$HOME\.githooks"

mkdir -Force "$env:APPDATA\gnupg"
cp -Force "$PublicRepoDir\default\.gnupg\gpg.conf" "$env:APPDATA\gnupg"

mkdir -Force "$HOME\AppData\Roaming\yazi\config"
ls -Force "$PublicRepoDir\Windows\AppData\Roaming\yazi\config" | % { cp -Force -Path ($_.FullName) -Destination "$HOME\AppData\Roaming\yazi\config\$($_.Name)" }

ln "$PublicRepoDir/default/.vimrc" "~/_vimrc"
ForEach ($f in ".vimrc", ".ignore", ".editorconfig", ".ctags") {
  ln "$PublicRepoDir/default/$f" "~/$f"
}
ln "$PublicRepoDir/nvim" "$HOME/AppData/Local/nvim"
ln "$PublicRepoDir/nvim" "$HOME/.config/nvim"

ln "$(pwd)\settings.json" "$HOME\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
ln "$PublicRepoDir/default/.config/lazygit" "$HOME/AppData/Local/lazygit"

mkdir -Force "$HOME/AppData/Local/process-compose"
ln "$PublicRepoDir/default/.config/process-compose/settings.yaml" "$HOME/AppData/Local/process-compose/settings.yaml"

mkdir -Force "$HOME/.genimi"
mkdir -Force "$HOME/.config/opencode"
mkdir -Force "$HOME/.claude"
mkdir -Force "$HOME/.copilot"
ln "$PublicRepoDir/ai/skills" "$HOME/.claude/skills"
ln "$PublicRepoDir/ai/gemini/settings.json" "$HOME/.gemini/settings.json"
ln "$PublicRepoDir/ai/rules/windows.md" "$HOME/.gemini/AGENTS.md"
ln "$PublicRepoDir/ai/rules/windows.md" "$HOME/.claude/AGENTS.md"
ln "$PublicRepoDir/ai/rules/windows.md" "$HOME/.copilot/copilot-instructions.md"
ln "$PublicRepoDir/ai/rules/windows.md" "$HOME/.config/opencode/AGENTS.md"

ls -Force "$PSProfileDir/local" | % { ln $_.FullName "~/$($_.Name)" }

if (Get-Command mise -ErrorAction SilentlyContinue -CommandType Application -OutVariable miseCmd) {
  mise -C "$PublicRepoDir" run build
}

$DictionaryFile = "$HOME/Dropbox/Apps/Harper/dictionary.txt"
if (Test-Path $DictionaryFile) {
  $DictionaryDestination = "$HOME/AppData/Roaming/harper-ls"
  mkdir -Force $DictionaryDestination
  ln $DictionaryFile "$DictionaryDestination/dictionary.txt"
}
