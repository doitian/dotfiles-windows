# Fuzzy window selector - lists ALL visible windows and focuses the selected one
param([string]$ExcludeTitle)

Add-Type @"
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Text;

public class Win32Windows {
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

    [DllImport("user32.dll")]
    public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);

    [DllImport("user32.dll")]
    public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);

    [DllImport("user32.dll")]
    public static extern int GetWindowTextLength(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern bool IsWindowVisible(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint processId);

    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

    [DllImport("user32.dll")]
    public static extern bool IsIconic(IntPtr hWnd);

    public static List<Tuple<IntPtr, uint, string>> GetAllWindows() {
        var windows = new List<Tuple<IntPtr, uint, string>>();
        EnumWindows((hWnd, lParam) => {
            if (!IsWindowVisible(hWnd)) return true;
            int length = GetWindowTextLength(hWnd);
            if (length == 0) return true;
            var sb = new StringBuilder(length + 1);
            GetWindowText(hWnd, sb, sb.Capacity);
            uint pid;
            GetWindowThreadProcessId(hWnd, out pid);
            windows.Add(Tuple.Create(hWnd, pid, sb.ToString()));
            return true;
        }, IntPtr.Zero);
        return windows;
    }
}
"@

# Get all visible windows (optionally exclude by title)
$windows = [Win32Windows]::GetAllWindows() |
    Where-Object { -not $ExcludeTitle -or $_.Item3 -notlike "*$ExcludeTitle*" } |
    ForEach-Object {
        $procName = try { (Get-Process -Id $_.Item2 -ErrorAction Stop).ProcessName } catch { "unknown" }
        "$($_.Item1)`t$procName`t$($_.Item3)"
    }

$selected = $windows | fzf @args --delimiter="`t" --with-nth=2,3 --preview-window=hidden
if ($selected) {
    $hWnd = [IntPtr]($selected -split "`t")[0]
    if ([Win32Windows]::IsIconic($hWnd)) {
        [Win32Windows]::ShowWindow($hWnd, 9) | Out-Null  # SW_RESTORE only if minimized
    }
    [Win32Windows]::SetForegroundWindow($hWnd) | Out-Null
}
