# Popup wrapper for fwin - ensures PATH and auto-closes when started by AHK
$env:Path = [Environment]::GetEnvironmentVariable("Path", "User") + ";" + $env:Path

Add-Type -Name Win32 -Namespace Popup -MemberDefinition @"
    [DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow();
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);
"@

# Capture our console window handle BEFORE fwin switches focus
$ourHwnd = [Popup.Win32]::GetConsoleWindow()

fwin -ExcludeTitle "fwin" --height=100% --layout=reverse

# Close our popup window directly (WM_CLOSE = 0x0010)
[Popup.Win32]::PostMessage($ourHwnd, 0x0010, [IntPtr]::Zero, [IntPtr]::Zero) | Out-Null