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
[Environment]::SetEnvironmentVariable('EDITOR', 'vim', 'User')
[Environment]::SetEnvironmentVariable('FZF_DEFAULT_OPTS', '--color light,fg:#3c3b3a', 'User')
[Environment]::SetEnvironmentVariable('FZF_DEFAULT_COMMAND', 'fd --type f --hidden --follow --exclude ".git"', 'User')
[Environment]::SetEnvironmentVariable('FZF_CTRL_T_COMMAND', 'fd --type f --hidden --follow --exclude ".git"', 'User')
[Environment]::SetEnvironmentVariable('FZF_ALT_C_COMMAND', 'fd --type d --no-ignore --hidden --follow --exclude ".git"', 'User')
[Environment]::SetEnvironmentVariable('BAT_THEME', 'Coldark-Cold', 'User')

$GitconfigTmpl = $(Get-Content "$PublicRepoDir/gitconfig.tmpl")
$GitconfigTmpl = $GitconfigTmpl -Replace "__NAME__", "ian"
$GitconfigTmpl = $GitconfigTmpl -Replace "__EMAIL__", "me@iany.me"
$GitconfigTmpl = $GitconfigTmpl -Replace "__HOME__", ("$HOME" -Replace "\\", "/")

$GitconfigTmpl | Set-Content "~/.gitconfig"
Get-Content "$PublicRepoDir/gitconfig.common" | Add-Content "~/.gitconfig"
git config --global core.autocrlf input
git config --global --unset core.pager
git config --global gpg.program (Get-Command -Name 'gpg.exe').Source
git config --global http.proxy http://127.0.0.1:7890
git config --global alias.dotfiles '!powershell.exe -NoProfile -Command git-dotfiles'
git config --global alias.codebase '!powershell.exe -NoProfile -Command git-codebase'
git config --global alias.cryptape '!powershell.exe -NoProfile -Command git-cryptape'
git config --global alias.nervos '!powershell.exe -NoProfile -Command git-nervos'

mkdir -Force ~/.vim/scripts, ~/.vim/projections, ~/.vim/backup, ~/.vim/swap, ~/.vim/undo, ~/.vim/nvim-undo, ~/.vim/autoload

Function ln ($value, $path) {
  if (Test-Path -LiteralPath $path) {
    rm -Re -Fo $path
  }
  New-Item -ItemType Junction -Force -Path $path -Value $value
}

if (Test-Path -LiteralPath "$DocumentsDir\PowerShell") {
  ln "$DocumentsDir\PowerShell" "$DocumentsDir\WindowsPowerShell"
}
ln "$PrivateRepoDir\UltiSnips" "$HOME\.vim\UltiSnips"

mkdir -Force ~/vimfiles/autoload
Invoke-WebRequest -Proxy 'http://127.0.0.1:7890' -UseBasicParsing -OutFile ~/vimfiles/autoload/plug.vim "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
cp -Force ~/vimfiles/autoload/plug.vim ~/.vim/autoload/plug.vim

ls -Force "$PublicRepoDir\default\.vim\projections" | % { cp -Force $_ "$HOME\.vim\projections\" }
ls -Force "$PublicRepoDir\default\.vim\scripts" | % { cp -Force $_ "$HOME\.vim\scripts\" }
ls -Force "$PrivateRepoDir\default\.vim\scripts" | % { cp -Force $_ "$HOME\.vim\scripts\" }

cp -Force "$PublicRepoDir\default\.gnupg\gpg.conf" "$(scoop prefix gpg)\home\"
