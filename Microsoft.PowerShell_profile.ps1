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

$cb = "$HOME\codebase"
$dcs = "$HOME\Documents"
$dsk = [Environment]::GetFolderPath("Desktop")
$dl = "$HOME\Downloads"

function .. { cd .. }
function ... { cd ../.. }
function .... { cd ../../.. }
function dotfiles { cd $PSProfileDir }
if ($env:WSLENV) {
  function tmux { wsl -d tmux tmux @Args }
}

if ($env:WT_SESSION) {
  $env:LAZY = 1
}
$env:TERM_BACKGROUND = 'light'
$env:LANG = 'en_US.UTF-8'

if (-not [Environment]::Is64BitProcess) {
  return
}

$global:PromptChar = $null

function prompt {
  $cwd = $($executionContext.SessionState.Path.CurrentLocation)
  $cwdProtocolParts = $cwd.ToString().Split("::\\")
  $cwdDisplay = $cwdProtocolParts[-1]
  $parts = $cwdDisplay.Split([IO.Path]::DirectorySeparatorChar)
  if ($parts.Count -gt 4) {
    $cwdDisplay = $parts[0..1] + @("…") + $parts[-2..-1] -join '\'
  }
  if ($cwdProtocolParts.Count -gt 1) {
    $cwdDisplay = "\\" + $cwdDisplay
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

  @("`n$([char]27)[34;1m", $cwdDisplay, $promptColor, "$([char]27)[0m", $global:PromptChar, "$([char]27)]9;9;`"$cwd`"$([char]27)\") -join ""
}

# Ensure init zoxide after prompt
if (Get-Command -ErrorAction Ignore zoxide) {
  Invoke-Expression (& { (zoxide init powershell --cmd j | Out-String) })
}

Set-PSReadLineOption -EditMode emacs
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadlineKeyHandler -Chord 'Ctrl+w' -Function BackwardKillWord

if ($PSVersionTable.PSVersion.Major -lt 7) {
  return
}

function Find-NearestEnvrc {
  param (
    [Parameter(Mandatory=$true)]
    [string]$StartDir
  )

  $currentDir = (Resolve-Path $StartDir).ToString()
  if ($currentDir -contains "::") {
      return ""
  }
  while ($currentDir -ne "" -and $currentDir -ne "$HOME") {
      $envrcPath = Join-Path $currentDir ".envrc.ps1"
      if (Test-Path $envrcPath) {
          return $envrcPath
      }
      $currentDir = Split-Path -Parent $currentDir
  }

  return ""
}

$thisEnvrc = Find-NearestEnvrc .
if ($thisEnvrc -ne "") {
  . $thisEnvrc
}

$hook = [EventHandler[LocationChangedEventArgs]] {
  param([object] $source, [LocationChangedEventArgs] $eventArgs)
  end {
    $oldEnvrc = Find-NearestEnvrc $eventArgs.OldPath
    $newEnvrc = Find-NearestEnvrc $eventArgs.NewPath
    if ($oldEnvrc -ne $newEnvrc) {
      if (Get-Command down -ErrorAction Ignore) {
        Write-Host ".= leave $oldEnvrc"
        down
        Remove-Item Function:down
      }
      if ($newEnvrc -ne "") {
        Write-Host ".= enter $newEnvrc"
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

Set-PSReadLineKeyHandler -Key Enter -ScriptBlock {
  $line = $null
  $cursor = $null
  [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
  if ($line.Length -eq 0) {
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert("g st")
  }
  [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}

$PSStyle.FileInfo.Directory    = "`e[36m"
$PSStyle.FileInfo.SymbolicLink = "`e[35m"
$PSStyle.FileInfo.Executable   = "`e[31m"
