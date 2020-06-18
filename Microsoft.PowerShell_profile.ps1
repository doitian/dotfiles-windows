[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Set-PSReadLineOption -EditMode emacs -Colors @{
  "Command" = "Magenta"
  "Member" = "DarkGray"
  "Number" = "DarkYellow"
}
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete

$PSProfileDir = $(Split-Path -Parent $PROFILE)
$WindowsTerminalSettings = 'C:\Users\me\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
$env:EDITOR = 'vim'
$env:FZF_DEFAULT_OPTS = '--color=light --color=fg:0'
$env:BAT_THEME = 'ansi-light'

Set-Alias -Name g -Value git
Set-Alias -Name j -Value z
Set-Alias -Name grep -Value rg
Set-Alias -Name which -Value Get-Command
if (Get-Command -Name 'plink.exe' -ErrorAction SilentlyContinue) {
  Set-Alias -Name ssh -Value plink
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

$global:PromptChar = $null

function prompt {
  $lastSuccess = $?
  $cwd = (Get-Location).Path
  $parts = $cwd.Split([IO.Path]::DirectorySeparatorChar)
  if ($parts.Count -gt 4) {
    $cwd = $parts[0..1] + @("…") + $parts[-2..-1] -join '\'
  }

  if ($global:PromptChar -eq $null) {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal] $identity
    $adminRole = [Security.Principal.WindowsBuiltInRole]::Administrator
    if ($principal.IsInRole($adminRole)) {
      $global:PromptChar = "# "
    } else {
      $global:PromptChar = "❯ "
    }
  }

  $promptColor = if ($lastSuccess) {
    if ($global:PromptChar -eq "#") { "`e[33m" } else { "`e[0m" }
  } else {
    "`e[31m"
  }

  @("`e[34;1m", $cwd, $promptColor, $global:PromptChar, "`e[0m") -join ""
}

if (Get-Module -ListAvailable -Name z) {
  Import-Module z
}
if (Get-Module -ListAvailable -Name PSFzf) {
  Import-Module PSFzf
  Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
}
