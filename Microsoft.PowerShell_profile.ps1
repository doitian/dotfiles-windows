using namespace System;
using namespace System.Management.Automation;

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$PSProfileDir = $(Split-Path -Parent $PROFILE)
$WindowsTerminalSettings = "$HOME\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

Set-Alias -Name g -Value git
Set-Alias -Name lg -Value lazygit
Set-Alias -Name grep -Value rg
Set-Alias -Name which -Value Get-Command
Set-Alias -Name l -Value Get-ChildItem
Set-Alias -Name ll -Value Get-ChildItem
Set-Alias -Name vi -Value nvim
Set-Alias -Name vim -Value nvim

$cb = "$HOME/codebase"
$dcs = "$HOME/Documents"
$dsk = [Environment]::GetFolderPath("Desktop")
$dl = "$HOME/Downloads"

function fpass {
  $selected = (gopass list -f | fzf)
  popd
  gopass @Args $selected
}
function .. { cd .. }
function ... { cd ../.. }
function .... { cd ../../.. }
function dotfiles { cd $PSProfileDir }

if ($env:WT_SESSION) {
  $env:LAZY = 1
}
$env:TERM_BACKGROUND = 'light'

if (-not [Environment]::Is64BitProcess) {
  return
}

if (Get-Command -ErrorAction SilentlyContinue starship) {
  $POWERSHELL_THEME_NEW_LINE_BEFORE_PROMPT = 0
  function Invoke-Starship-PreCommand {
    $cwd = $($executionContext.SessionState.Path.CurrentLocation)
    $host.ui.Write("$([char]27)]9;9;`"$cwd`"$([char]27)\")
    if ($POWERSHELL_THEME_NEW_LINE_BEFORE_PROMPT) {
      $host.ui.Write("`n")
    } else {
      $global:POWERSHELL_THEME_NEW_LINE_BEFORE_PROMPT = 1
    }
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

# Ensure init zoxide after prompt
if (Get-Command -ErrorAction SilentlyContinue zoxide) {
  Invoke-Expression (& { (zoxide init powershell --cmd j | Out-String) })
}

Set-PSReadLineOption -EditMode emacs
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadlineKeyHandler -Chord 'Ctrl+w' -Function BackwardKillWord

if (Get-Module -ListAvailable -Name PSFzf) {
  Import-Module PSFzf
  Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
}

function Find-NearestEnvrc {
  param (
    [Parameter(Mandatory=$true)]
    [string]$StartDir
  )

  $currentDir = Resolve-Path $StartDir
  while ($currentDir -ne "") {
      $envrcPath = Join-Path $currentDir ".envrc.ps1"
      if (Test-Path $envrcPath) {
          return $envrcPath
      }
      $currentDir = Split-Path $currentDir -Parent
  }

  return ""
}

$hook = [EventHandler[LocationChangedEventArgs]] {
  param([object] $source, [LocationChangedEventArgs] $eventArgs)
  end {
    $oldEnvrc = Find-NearestEnvrc $eventArgs.OldPath
    $newEnvrc = Find-NearestEnvrc $eventArgs.NewPath
    if ($oldEnvrc -ne $newEnvrc) {
      Get-Command down -ErrorAction SilentlyContinu
      if (Get-Command down -ErrorAction SilentlyContinu) {
        down
        Remove-Item Function:down
      }
      if ($newEnvrc -ne "") {
        . $newEnvrc
      }
    }
  }
};
$currentAction = $ExecutionContext.SessionState.InvokeCommand.LocationChangedAction;
if ($currentAction) {
  $ExecutionContext.SessionState.InvokeCommand.LocationChangedAction = [Delegate]::Combine($currentAction, $hook);
} else {
  $ExecutionContext.SessionState.InvokeCommand.LocationChangedAction = $hook;
};

if ($PSVersionTable.PSVersion.Major -lt 7) {
  return
}

Set-PSReadLineOption -Colors @{
  Command                = $PSStyle.Foreground.Blue
  Comment                = $PSStyle.Foreground.BrightWhite
  Default                = $PSStyle.Foreground.Black
  InlinePrediction       = $PSStyle.Foreground.BrightWhite
  Keyword                = $PSStyle.Foreground.FromRGB(0x8839EF)
  ListPredictionSelected = $PSStyle.Background.BrightWhite
  Member                 = $PSStyle.Foreground.Black
  Number                 = $PSStyle.Foreground.FromRGB(0xFE6406)
  Operator               = $PSStyle.Foreground.FromRGB(0x04A5E5)
  Parameter              = $PSStyle.Foreground.Cyan
  Selection              = $PSStyle.Background.BrightWhite
  String                 = $PSStyle.Foreground.Green
  Type                   = $PSStyle.Foreground.Black
  Variable               = $PSStyle.Foreground.FromRGB(0xDD7878)
}

$PSStyle.FileInfo.Directory    = "`e[36m"
$PSStyle.FileInfo.SymbolicLink = "`e[35m"
$PSStyle.FileInfo.Executable   = "`e[31m"
