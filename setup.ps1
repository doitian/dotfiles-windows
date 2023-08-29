$GfwProxy = "127.0.0.1:7890"
if (Test-Path env:GFW_PROXY) {
  $GfwProxy = $env:GFW_PROXY
}
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
if (-Not ([Environment]::GetEnvironmentVariable("Path", "User")).Split(";").Contains($UserBinDir)) {
  [Environment]::SetEnvironmentVariable('Path', "$env:Path;$UserBinDir", 'User')
}
[Environment]::SetEnvironmentVariable('EDITOR', 'nvim', 'User')
[Environment]::SetEnvironmentVariable('FZF_DEFAULT_OPTS', '--prompt="❯ " --color light', 'User')
[Environment]::SetEnvironmentVariable('FZF_DEFAULT_COMMAND', 'fd --type f --hidden --follow --exclude ".git"', 'User')
[Environment]::SetEnvironmentVariable('FZF_CTRL_T_COMMAND', 'fd --type f --hidden --follow --exclude ".git"', 'User')
[Environment]::SetEnvironmentVariable('FZF_ALT_C_COMMAND', 'fd --type d --no-ignore --hidden --follow --exclude ".git"', 'User')
[Environment]::SetEnvironmentVariable('BAT_THEME', 'Coldark-Cold', 'User')
[Environment]::SetEnvironmentVariable('PAGER', 'less -R', 'User')
[Environment]::SetEnvironmentVariable('LSCOLORS', 'Gxfxcxdxbxegedabagacad', 'User')
[Environment]::SetEnvironmentVariable('LS_COLORS', 'di=1;36:ln=35:so=32:pi=33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43', 'User')

$GitconfigTmpl = $(Get-Content "$PublicRepoDir/gitconfig.tmpl")
$GitconfigTmpl = $GitconfigTmpl -Replace "__NAME__", "ian"
$GitconfigTmpl = $GitconfigTmpl -Replace "__EMAIL__", "me@iany.me"
$GitconfigTmpl = $GitconfigTmpl -Replace "__HOME__", ("$HOME" -Replace "\\", "/")

$GitconfigTmpl -join "`n" | Set-Content -NoNewLine "~/.gitconfig"
git config --global core.autocrlf input
git config --global --unset core.pager
git config --global gpg.program (Get-Command -Name 'gpg.exe').Source
git config --global http.proxy "http://$GfwProxy"
git config --global alias.dotfiles '!powershell.exe -NoProfile -Command git-dotfiles'
git config --global alias.codebase '!powershell.exe -NoProfile -Command git-codebase'
git config --global alias.cryptape '!powershell.exe -NoProfile -Command git-cryptape'
git config --global alias.nervos '!powershell.exe -NoProfile -Command git-nervos'
if (Get-Command -ErrorAction SilentlyContinue delta) {
  git config --global core.pager delta
  git config --global interactive.diffFilter 'delta --color-only'
}

mkdir -Force ~/.local/state/vim/backup, ~/.local/state/vim/swap, ~/.local/state/vim/undo, ~/.vim, ~/.config

Function ln ($value, $path) {
  if (Test-Path -LiteralPath $path) {
    rm -Re -Fo $path
  }
  New-Item -ItemType Junction -Force -Path $path -Value $value
}

if (Test-Path -LiteralPath "$DocumentsDir\PowerShell") {
  ln "$DocumentsDir\PowerShell" "$DocumentsDir\WindowsPowerShell"
}

cp -Force "$PublicRepoDir\default\.gnupg\gpg.conf" "$(scoop prefix gpg)\home\"
