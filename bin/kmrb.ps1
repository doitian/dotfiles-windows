# Start komorebi (via komorebic) and the komorebi AHK hotkey script.
# Usage: kmrb.ps1 [-bar]
#   -bar  Start komorebi-bar as well (passes --bar to komorebic start).

param(
    [switch] $bar
)

$repoRoot = Split-Path $PSScriptRoot -Parent
$ahkScript = Join-Path $repoRoot 'AutoHotkey' 'komorebi.ahk'
$komorebiConfig = Join-Path $repoRoot 'komorebi' 'komorebi.json'

# Start komorebi WM directly so --config and path are separate args (avoids komorebic quoting bug)
$komorebiArgs = @('--config', $komorebiConfig)
if ($bar) {
    $komorebiArgs += '--bar'
}

# Start komorebi WM in background
Start-Process 'komorebi.exe' -ArgumentList $komorebiArgs -WindowStyle Hidden

# Start AHK hotkey script in background
Start-Process -FilePath $ahkScript -WindowStyle Hidden
