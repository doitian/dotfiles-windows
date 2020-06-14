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
Set-Alias -Name j -Value z
Set-Alias -Name grep -Value rg
Set-Alias -Name which -Value Get-Command
if (Get-Command -Name 'plink.exe' -ErrorAction SilentlyContinue) {
  function ssh {
    plink -batch @Args
  }
}

$cb = "$HOME/codebase"
$dcs = "$HOME/Documents"
$dsk = [Environment]::GetFolderPath("Desktop")
$dl = "$HOME/Downloads"
$kb = "$HOME/codebase/my/knowledge-base"

function fpass {
  pushd "~/.password-store"
  $selected = (fzf) -Replace '\.gpg$', ''
  popd
  gopass @Args $selected
}

function prompt {
  $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
  $principal = [Security.Principal.WindowsPrincipal] $identity
  $adminRole = [Security.Principal.WindowsBuiltInRole]::Administrator

  $cwd = (Get-Location).Path
  $parts = $cwd.Split([IO.Path]::DirectorySeparatorChar)
  if ($parts.Count -gt 4) {
    $cwd = $parts[0..1] + @("…") + $parts[-2..-1] -join '\'
  }
  Write-Host $cwd -NoNewline -ForegroundColor Blue

  $(if (Test-Path variable:/PSDebugContext) {
    "? "
  } elseif ($principal.IsInRole($adminRole)) {
    "# "
  } else {
    "$ "
  })
}

if (Get-Module -ListAvailable -Name z) {
  Import-Module z
}
if (Get-Module -ListAvailable -Name PSFzf) {
  Import-Module PSFzf
  Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
}

