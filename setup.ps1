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
[Environment]::SetEnvironmentVariable('PAGER', 'less -R', 'User')
[Environment]::SetEnvironmentVariable('CLICOLOR', '0', 'User')
[Environment]::SetEnvironmentVariable('LSCOLORS', 'exfxcxdxbxegedabagacad', 'User')
[Environment]::SetEnvironmentVariable('LS_COLORS', 'no=00:fi=00:di=01;34:ln=00;36:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=41;33;01:ex=00;32:*.cmd=00;32:*.exe=01;32:*.com=01;32:*.bat=01;32:*.btm=01;32:*.dll=01;32:*.tar=00;31:*.tbz=00;31:*.tgz=00;31:*.rpm=00;31:*.deb=00;31:*.arj=00;31:*.taz=00;31:*.lzh=00;31:*.lzma=00;31:*.zip=00;31:*.zoo=00;31:*.z=00;31:*.Z=00;31:*.gz=00;31:*.bz2=00;31:*.tb2=00;31:*.tz2=00;31:*.tbz2=00;31:*.avi=01;35:*.bmp=01;35:*.fli=01;35:*.gif=01;35:*.jpg=01;35:*.jpeg=01;35:*.mng=01;35:*.mov=01;35:*.mpg=01;35:*.pcx=01;35:*.pbm=01;35:*.pgm=01;35:*.png=01;35:*.ppm=01;35:*.tga=01;35:*.tif=01;35:*.xbm=01;35:*.xpm=01;35:*.dl=01;35:*.gl=01;35:*.wmv=01;35:*.aiff=00;32:*.au=00;32:*.mid=00;32:*.mp3=00;32:*.ogg=00;32:*.voc=00;32:*.wav=00;32:', 'User')

$GitconfigTmpl = $(Get-Content "$PublicRepoDir/gitconfig.tmpl")
$GitconfigTmpl = $GitconfigTmpl -Replace "__NAME__", "ian"
$GitconfigTmpl = $GitconfigTmpl -Replace "__EMAIL__", "me@iany.me"
$GitconfigTmpl = $GitconfigTmpl -Replace "__HOME__", ("$HOME" -Replace "\\", "/")

$GitconfigTmpl | Set-Content "~/.gitconfig"
git config --global core.autocrlf input
git config --global --unset core.pager
git config --global gpg.program (Get-Command -Name 'gpg.exe').Source
git config --global http.proxy http://127.0.0.1:7890
git config --global alias.dotfiles '!powershell.exe -NoProfile -Command git-dotfiles'
git config --global alias.codebase '!powershell.exe -NoProfile -Command git-codebase'
git config --global alias.cryptape '!powershell.exe -NoProfile -Command git-cryptape'
git config --global alias.nervos '!powershell.exe -NoProfile -Command git-nervos'
if (Get-Command -ErrorAction SilentlyContinue delta) {
  git config --global pager.diff delta
  git config --global pager.show delta
  git config --global pager.log delta
  git config --global pager.reflog delta
  git config --global interactive.diffFilter 'delta --color-only --features=interactive'
}

mkdir -Force ~/.vim/scripts, ~/.vim/files/backup, ~/.vim/files/swap, ~/.vim/files/undo, ~/.vim/autoload

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

ls -Force "$PublicRepoDir\default\.vim\scripts" | % { cp -Force $_ "$HOME\.vim\scripts\" }
ls -Force "$PrivateRepoDir\default\.vim\scripts" | % { cp -Force $_ "$HOME\.vim\scripts\" }

cp -Force "$PublicRepoDir\default\.gnupg\gpg.conf" "$(scoop prefix gpg)\home\"
