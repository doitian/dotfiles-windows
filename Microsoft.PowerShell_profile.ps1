Set-PSReadLineOption -EditMode emacs -Colors @{
  "Member" = "$([char]0x1b)[37m"
  "Number" = "$([char]0x1b)[37m"
}
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete

$PSProfileDir = $(Split-Path -Parent $PROFILE)
$WindowsTerminalSettings = 'C:\Users\me\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
$env:EDITOR = 'vim'
$env:FZF_DEFAULT_OPTS = '--color=light --color=fg:0'

Set-Alias -Name g -Value git
Set-Alias -Name grep -Value rg
Set-Alias -Name which -Value Get-Command

$cb = "$HOME/codebase"
$dcs = "$HOME/Documents"
$dsk = [Environment]::GetFolderPath("Desktop")
$dl = "$HOME/Downloads"
$kb = "$HOME/codebase/knowledge-base"

function fpass {
  pushd "~/.password-store"
  $selected = (fzf) -Replace '\.gpg$', ''
  popd
  gopass @Args $selected
}
