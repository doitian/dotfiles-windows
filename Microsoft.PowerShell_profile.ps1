[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Set-PSReadLineOption -EditMode emacs -Colors @{
  "Command"            = "Magenta"
  "Member"             = "DarkGray"
  "Number"             = "DarkYellow"
  "ContinuationPrompt" = "#878787"
  "Default"            = "#878787"
  "Type"               = "#878787"
}
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete

$PSProfileDir = $(Split-Path -Parent $PROFILE)
$WindowsTerminalSettings = "$HOME\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

Set-Alias -Name g -Value git
Set-Alias -Name j -Value z
Set-Alias -Name grep -Value rg
Set-Alias -Name which -Value Get-Command

$cb = "$HOME/codebase"
$dcs = "$HOME/Documents"
$dsk = [Environment]::GetFolderPath("Desktop")
$dl = "$HOME/Downloads"

function fpass {
  $selected = (gopass list -f | fzf)
  popd
  gopass @Args $selected
}

if (Get-Command -ErrorAction SilentlyContinue starship) {
  function Invoke-Starship-PreCommand {
    $cwd = $($executionContext.SessionState.Path.CurrentLocation)
    $host.ui.Write("$([char]27)]9;9;`"$cwd`"$([char]27)\")
  }
  Invoke-Expression (&starship init powershell)
} else {
  $global:PromptChar = $null

  function prompt {
    $cwd = $($executionContext.SessionState.Path.CurrentLocation)
    $cwdDisplay = $cwd.ToString()
    $parts = $cwdDisplay.Split([IO.Path]::DirectorySeparatorChar)
    if ($parts.Count -gt 4) {
      $cwdDisplay = $parts[0..1] + @("…") + $parts[-2..-1] -join '\'
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

    @("$([char]27)[34;1m", $cwdDisplay, $promptColor, "$([char]27)[0m", $global:PromptChar, "$([char]27)]9;9;`"$cwd`"$([char]27)\") -join ""
  }
}

if (Get-Module -ListAvailable -Name z) {
  Import-Module z
}
if (Get-Module -ListAvailable -Name PSFzf) {
  Import-Module PSFzf
  Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
}
if (Get-Module -ListAvailable -Name posh-git) {
  Import-Module posh-git
}

if ($env:WT_SESSION) {
  $env:LAZY = 1
}
$env:TERM_BACKGROUND = 'light'
