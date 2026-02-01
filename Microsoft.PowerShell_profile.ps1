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

function dirs { (pwd -stack).ToArray().Path | fzf | cd }
function mx { mise x "--" @Args }
function mr { mise r @Args }
function zxx { zx x.mjs }
function mact {
  Invoke-Expression (& { (mise activate pwsh | Out-String) })
  Set-Item -LiteralPath "Function:Global:mise" -Value $Function:mise
}
function j {
  $selected = (cat "$HOME/.j.path" | fzf -0 -1 -q "$Args")
  if ($selected -ne $null) {
    pushd "$selected"
  } else {
    Write-Error "no matched directory found"
  }
}
function jadd {
  (pwd).Path.Replace("\", "/") | Add-Content "$HOME/.j.path"
}
function ycd {
	$tmp = (New-TemporaryFile).FullName
	yazi.exe $args --cwd-file="$tmp"
	$cwd = Get-Content -Path $tmp -Encoding UTF8
	if ($cwd -ne $PWD.Path -and (Test-Path -LiteralPath $cwd -PathType Container)) {
		Set-Location -LiteralPath (Resolve-Path -LiteralPath $cwd).Path
	}
	Remove-Item -Path $tmp
}

$hist = (Get-PSReadlineOption).HistorySavePath
$cb = "$HOME\codebase"
$dcs = "$HOME\Documents"
$dsk = [Environment]::GetFolderPath("Desktop")
$dl = "$HOME\Downloads"
$dotpub = "$HOME\.dotfiles\repos\public"
$dotbin = "$HOME\.dotfiles\repos\public\default\bin"

function .. { cd .. }
function ... { cd ../.. }
function .... { cd ../../.. }
function dotfiles { cd $PSProfileDir }

if ($env:WT_SESSION) {
  $env:LAZY = 1
}
$env:TERM_BACKGROUND = 'light'
$env:LANG = 'en_US.UTF-8'

if ($env:CURSOR_AGENT) {
  $env:GIT_PAGER = ''
}

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

function OnViModeChange {
  if ($args[0] -eq 'Insert') {
    Set-PSReadLineOption -EditMode Emacs
    Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete
    Set-PSReadlineKeyHandler -Chord "Alt+w" -Function KillRegion
    Set-PSReadlineKeyHandler -Chord "Ctrl+w" -Function BackwardKillWord
    Set-PSReadlineKeyHandler -Chord "Ctrl+x,Ctrl+f" -Function CharacterSearch
    Set-PSReadlineKeyHandler -Chord "Ctrl+x,Ctrl+b" -Function ViGotoBrace
    Set-PSReadlineKeyHandler -Chord "Ctrl+x,Ctrl+v" -ScriptBlock {
      Set-PSReadLineOption -EditMode Vi
      [Microsoft.PowerShell.PSConsoleReadLine]::ViCommandMode()
    }
    Remove-PSReadLineKeyHandler -Chord "Ctrl+]"
    Remove-PSReadLineKeyHandler -Chord "Ctrl+Alt+]"
  }
}
Set-PSReadLineOption -EditMode Emacs -ViModeIndicator Script -ViModeChangeHandler $Function:OnViModeChange
OnViModeChange Insert

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

# auto_cd
# https://github.com/nickcox/cd-extras/blob/master/cd-extras/private/AutoCd.ps1
$ExecutionContext.SessionState.InvokeCommand.CommandNotFoundAction = {
  param($CommandName, $CommandLookupEventArgs)

  # don't run unless invoked interactively
  if ($CommandLookupEventArgs.CommandOrigin -ne 'Runspace') { return }
  # don't run as part of pipeline
  if ($MyInvocation.Line -match "$([regex]::Escape($CommandName))\s*\|") { return }

  $path = if (Test-Path $CommandName) {
    $CommandName
  } elseif (
      ($candidate = Get-Variable $CommandName -ValueOnly -ErrorAction Ignore) -and
      (Test-Path $candidate)
      ) {
    $candidate
  }

  if ($path) {
    $CommandLookupEventArgs.CommandScriptBlock = {
      if ($args.Length -eq 0) { cd $path }
    }.GetNewClosure()
    $CommandLookupEventArgs.StopSearch = $true
  }
}.GetNewClosure()
