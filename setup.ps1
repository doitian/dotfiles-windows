$PublicRepoDir = "$HOME/.dotfiles/repos/public"
$PrivateRepoDir = "$HOME/.dotfiles/repos/private"
$DocumentsDir = Split-Path -Parent (Split-Path -Parent $PROFILE)

git config --global core.autocrlf input
$SSHPath = (Get-Command -Name 'plink.exe').Source
[Environment]::SetEnvironmentVariable('GIT_SSH', $SSHPath, 'User')

ForEach ($repo in $PublicRepoDir, $PrivateRepoDir) {
  if (Test-Path -LiteralPath $repo) {
    git -C $repo pull
  } else {
    git clone --depth 1 "git@github.com:doitian/dotfiles-$(Split-Path -Leaf $repo).git" $repo
  }
}

$UserBinDir = "$(Split-Path -Parent $PROFILE)\bin"
if (-Not ($env:Path).Split(";").Contains($UserBinDir)) {
  [Environment]::SetEnvironmentVariable('Path', "$env:Path;$UserBinDir", 'User')
}

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

mkdir -Force ~/.vim/scripts, ~/.vim/projections, ~/.vim/backup, ~/.vim/swap, ~/.vim/undo, ~/.vim/autoload

Function ln ($value, $path) {
  if (Test-Path -LiteralPath $path) {
    rm -Re -Fo $path
  }
  New-Item -ItemType Junction -Force -Path $path -Value $value
}

if (Test-Path -LiteralPath "$DocumentsDir\PowerShell") {
  ln "$DocumentsDir\PowerShell" "$DocumentsDir\WindowsPowerShell"
}
ln "$PublicRepoDir\default\.vim\projections" "$HOME\.vim\projections"
ln "$PrivateRepoDir\default\.vim\scripts" "$HOME\.vim\scripts"
ln "$PrivateRepoDir\UltiSnips" "$HOME\.vim\UltiSnips"

mkdir -Force ~/vimfiles/autoload
Invoke-WebRequest -UseBasicParsing -OutFile ~/vimfiles/autoload/plug.vim "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
cp -Force ~/vimfiles/autoload/plug.vim ~/.vim/autoload/plug.vim

cp -Force "$PublicRepoDir\default\.gnupg\gpg.conf" "$(scoop prefix gpg)\home\"
@(
  "default-cache-ttl 600"
  "max-cache-ttl 7200"
  "enable-putty-support"
) | Set-Content -Path "$(scoop prefix gpg)\home\gpg-agent.conf"
