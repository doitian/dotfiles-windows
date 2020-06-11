$PublicRepoDir = "$HOME/.dotfiles/repos/public"
$PrivateRepoDir = "$HOME/.dotfiles/repos/private"

ForEach ($repo in $PublicRepoDir, $PrivateRepoDir) {
  if (Test-Path -LiteralPath $repo) {
    git -C $repo pull
  } else {
    git clone --depth 1 "git@github.com:doitian/dotfiles-$(Split-Path -Leaf $repo).git" $repo
  }
}

$SSHPath = (Get-Command -Name 'ssh.exe').Source
[Environment]::SetEnvironmentVariable('GIT_SSH', $SSHPath, 'User')

$GitconfigTmpl = $(Get-Content "$PublicRepoDir/gitconfig.tmpl")
$GitconfigTmpl = $GitconfigTmpl -Replace "__NAME__", "ian"
$GitconfigTmpl = $GitconfigTmpl -Replace "__EMAIL__", "me@iany.me"
$GitconfigTmpl = $GitconfigTmpl -Replace "__HOME__", ("$HOME" -Replace "\\", "/")

$GitconfigTmpl | Set-Content "~/.gitconfig"
Get-Content "$PublicRepoDir/gitconfig.common" | Add-Content "~/.gitconfig"
git config --global core.autocrlf input
git config --global --unset core.pager
git config --global gpg.program (Get-Command -Name 'gpg.exe').Source

cp -Force "$PublicRepoDir/default/.vimrc" "~/_vimrc"

ForEach ($f in ".ignore", ".editorconfig") {
  cp -Force "$PublicRepoDir/default/$f" "~/$f"
}

mkdir -Force ~/.vim/scripts, ~/.vim/projections, ~/.vim/backup, ~/.vim/swap, ~/.vim/undo, ~/.vim/autoload
cp -Force -Recurse "$PublicRepoDir/default/.vim/scripts/*" "~/.vim/scripts"
cp -Force -Recurse "$PublicRepoDir/default/.vim/projections/*" "~/.vim/projections"

mkdir -Force ~/vimfiles/autoload
Invoke-WebRequest -UseBasicParsing -OutFile ~/vimfiles/autoload/plug.vim "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
cp -Force ~/vimfiles/autoload/plug.vim ~/.vim/autoload/plug.vim

$PSProfileDir = $(Split-Path -Parent $PROFILE)
ls -Force "$PSProfileDir/local" | cp -Force -Destination ~/

cp -Force settings.json 'C:\Users\me\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'

mkdir -Force ~/.ssh
cp -Force "$PrivateRepoDir/default/.ssh/config" "~/.ssh/config"
