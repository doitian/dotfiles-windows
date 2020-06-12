$PublicRepoDir = "$HOME/.dotfiles/repos/public"
$PrivateRepoDir = "$HOME/.dotfiles/repos/private"

git config --global core.autocrlf input
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

mkdir -Force ~/.vim/scripts, ~/.vim/projections, ~/.vim/backup, ~/.vim/swap, ~/.vim/undo, ~/.vim/autoload

Function ln ($value, $path) {
  if (Test-Path -LiteralPath $path) {
    [io.directory]::Delete($path)
  }
  New-Item -ItemType Junction -Force -Path $path -Value $value
}
ln "$PublicRepoDir\default\.vim\projections" "$HOME\.vim\projections"
ln "$PrivateRepoDir\default\.vim\scripts" "$HOME\.vim\scripts"
ln "$PrivateRepoDir\UltiSnips" "$HOME\.vim\UltiSnips"

mkdir -Force ~/vimfiles/autoload
Invoke-WebRequest -UseBasicParsing -OutFile ~/vimfiles/autoload/plug.vim "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
cp -Force ~/vimfiles/autoload/plug.vim ~/.vim/autoload/plug.vim
