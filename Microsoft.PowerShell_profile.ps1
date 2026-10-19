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
Set-Alias -Name ta -Value tmux-fzf-session
Set-Alias -Name tu -Value tmux-up
Set-Alias -Name ab -Value agent-berth

function tl { tmux ls @Args }
function tmux-reload { tmux source-file "$HOME/.tmux.conf" }
function dirs { (pwd -stack).ToArray().Path | fzf | cd }
function fd { fd.exe --path-separator / @Args }
function oc { opencode @Args }
function foc { fa -a opencode @Args }
function fpi { fa -a pi @Args }
function mx { mise x "--" @Args }
function mr { mise r @Args }
function mact {
  Invoke-Expression (& { (mise activate pwsh | Out-String) })
  Set-Item -LiteralPath "Function:Global:mise" -Value $Function:mise
}
function j {
  if (-not (Test-Path -LiteralPath "$HOME/.j.path")) {
    Write-Error "~/.j.path not found, add directories with jadd"
    return
  }
  $selected = (cat "$HOME/.j.path" | fzf -0 -1 -q "$Args")
  if ($null -ne $selected) {
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

function gwtcd {
  $current = git rev-parse --show-toplevel 2>$null
  if ($LASTEXITCODE -ne 0) { return }
  $selected = git worktree list --porcelain |
    Where-Object { $_.StartsWith('worktree ') } |
    ForEach-Object { $_.Substring(9) } |
    Where-Object { $_ -cne $current } |
    fzf -0 -1 -q "$args"
  if ($selected) { cd $selected }
}

function tmux-up {
  if ($args -contains '--help' -or $args -contains '-h') {
    & tmux-up.exe @args
    return
  }
  $target = & tmux-up.exe --print-target @args
  if ($LASTEXITCODE -ne 0) { return }
  if ($args -contains '--print-target') {
    $target
  } elseif ($env:TMUX) {
    tmux switchc -t $target
  } else {
    tmux attach -t $target
  }
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

if ($env:WT_SESSION -and -not $env:LAZY) {
  $env:LAZY = 1
}
$env:TERM_BACKGROUND = 'light'
$env:LANG = 'en_US.UTF-8'
$env:OPENCODE_DISABLE_CLAUDE_CODE_SKILLS = '1'

if (-not [Environment]::Is64BitProcess) {
  return
}

$global:PromptChar = $null
$global:PromptHost = if ($env:SSH_CONNECTION -or $env:SSH_CLIENT -or $env:SSH_TTY) {
  "$([char]27)[32m@$($env:COMPUTERNAME.ToLower()):$([char]27)[0m"
} else {
  ""
}

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

  # OSC 9;9 records the pane directory for new tabs/panes, which only Windows
  # Terminal understands; kitty reads the same sequence as a notification.
  $cwdReport = if ($env:WT_SESSION) { "$([char]27)]9;9;`"$cwd`"$([char]27)\" } else { "" }
  @("`n$global:PromptHost$([char]27)[34;1m", $cwdDisplay, "$([char]27)[0m", $global:PromptChar, $cwdReport) -join ""
}

function OnViModeChange {
  if ($args[0] -eq 'Insert') {
    Set-PSReadLineOption -EditMode Emacs
    Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete
    Set-PSReadlineKeyHandler -Chord "Alt+w" -Function KillRegion
    Set-PSReadlineKeyHandler -Chord "Ctrl+w" -Function BackwardKillWord
    Set-PSReadlineKeyHandler -Chord "Ctrl+x,Ctrl+f" -Function CharacterSearch
    Set-PSReadlineKeyHandler -Chord "Ctrl+x,Ctrl+b" -Function ViGotoBrace
    Set-PSReadlineKeyHandler -Chord "Ctrl+x,v" -ScriptBlock {
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
  Command          = $PSStyle.Foreground.FromRGB(0x145FF5)
  Comment          = $PSStyle.Foreground.FromRGB(0x9CA0B0)
  Default          = $PSStyle.Foreground.FromRGB(0x4C4F69)
  Error            = $PSStyle.Foreground.FromRGB(0xD20F39)
  InlinePrediction = $PSStyle.Foreground.FromRGB(0x6C6F85)
  Number           = $PSStyle.Foreground.FromRGB(0xBC4501)
  Operator         = $PSStyle.Foreground.FromRGB(0xC71F9A)
  Parameter        = $PSStyle.Foreground.FromRGB(0x13797E)
  String           = $PSStyle.Foreground.FromRGB(0x327C21)
  Variable         = $PSStyle.Foreground.FromRGB(0x976014)
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

$PSStyle.FileInfo.Directory    = $PSStyle.Foreground.FromRGB(0x145FF5)
$PSStyle.FileInfo.SymbolicLink = $PSStyle.Foreground.FromRGB(0x8839EF)
$PSStyle.FileInfo.Executable   = $PSStyle.Foreground.FromRGB(0xD20F39)

$PSStyle.Formatting.Error       = $PSStyle.Foreground.FromRGB(0xD20F39)
$PSStyle.Formatting.TableHeader = $PSStyle.Foreground.FromRGB(0x8839EF)

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

if (
  ((Test-Path -LiteralPath .mise-auto -PathType Leaf) -or $env:__MISE_DIFF) -and
  (Get-Command mise -ErrorAction SilentlyContinue)
) {
  mact
}
