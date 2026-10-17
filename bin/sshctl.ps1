#Requires -Version 7

<#
.SYNOPSIS
  Manage the Windows OpenSSH server.
.EXAMPLE
  sshctl.ps1 setup
  sshctl.ps1 start
  sshctl.ps1 stop
#>

[CmdletBinding()]
param(
  [Parameter(Position = 0)]
  [string]$Command,

  [string]$LogFile
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false

function Test-Administrator {
  $principal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
  $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Write-Log {
  param([string]$Message)
  if ($LogFile) {
    [IO.File]::AppendAllText($LogFile, "$Message`n", [Text.UTF8Encoding]::new($false))
  } else {
    Write-Host $Message
  }
}

function Read-NewLogText {
  param([string]$Path, [int]$Offset)
  if (-not (Test-Path -LiteralPath $Path)) {
    return $Offset, ''
  }
  try {
    $bytes = [IO.File]::ReadAllBytes($Path)
  } catch {
    return $Offset, ''
  }
  if ($bytes.Length -le $Offset) {
    return $Offset, ''
  }
  $text = [Text.Encoding]::UTF8.GetString($bytes, $Offset, $bytes.Length - $Offset)
  return $bytes.Length, $text
}

function Invoke-Elevated {
  $log = Join-Path ([IO.Path]::GetTempPath()) ('sshd-manage-{0}.log' -f [guid]::NewGuid().ToString('n'))
  New-Item -ItemType File -Path $log -Force | Out-Null
  $argString = '-NoProfile -ExecutionPolicy Bypass -File "{0}" {1} -LogFile "{2}"' -f $PSCommandPath, $Command, $log
  Write-Host 'elevation required'
  try {
    $proc = Start-ElevatedProcess $argString
  } catch {
    Write-Host "elevation failed: $($_.Exception.Message)"
    exit 1
  }
  $offset = 0
  while (-not $proc.HasExited) {
    $offset, $text = Read-NewLogText $log $offset
    if ($text) { Write-Host -NoNewline $text }
    Start-Sleep -Milliseconds 200
  }
  $null = $proc.WaitForExit()
  $offset, $text = Read-NewLogText $log $offset
  if ($text) { Write-Host -NoNewline $text }
  Remove-Item -LiteralPath $log -Force -ErrorAction SilentlyContinue
  if ($null -eq $proc.ExitCode) { exit 1 }
  exit $proc.ExitCode
}

function Start-ElevatedProcess {
  param([string]$Arguments)
  $info = [Diagnostics.ProcessStartInfo]::new()
  $info.FileName = (Get-Process -Id $PID).Path
  $info.Arguments = $Arguments
  $info.UseShellExecute = $true
  $info.Verb = 'runas'
  $info.WindowStyle = [Diagnostics.ProcessWindowStyle]::Hidden
  $proc = [Diagnostics.Process]::Start($info)
  if (-not $proc) { throw 'elevation was cancelled' }
  return $proc
}

function Get-ToolPath {
  param(
    [string]$Name,
    [string[]]$Fallbacks
  )
  $cmd = Get-Command $Name -ErrorAction SilentlyContinue
  if ($cmd -and $cmd.Source -and (Test-Path -LiteralPath $cmd.Source)) {
    return $cmd.Source
  }
  foreach ($path in $Fallbacks) {
    if (Test-Path -LiteralPath $path) { return $path }
  }
  throw "$Name not found"
}

function Get-GpgSshPublicKeys {
  $gpg = Get-ToolPath 'gpg' @(
    (Join-Path $env:USERPROFILE 'scoop\apps\gpg4win\current\GnuPG\bin\gpg.exe')
  )
  $ids = [System.Collections.Generic.List[string]]::new()
  foreach ($line in (& $gpg --batch --list-secret-keys --with-colons)) {
    $field = $line -split ':'
    if ($field.Length -gt 11 -and $field[0] -in @('pub', 'sec', 'sub', 'ssb') -and $field[11].Contains('a') -and $field[4]) {
      if (-not $ids.Contains($field[4])) { $ids.Add($field[4]) }
    }
  }
  if ($ids.Count -eq 0) { throw 'no GPG authentication key found' }

  $keys = [System.Collections.Generic.List[string]]::new()
  foreach ($id in $ids) {
    $exported = @(& $gpg --batch --export-ssh-key $id 2>$null | ForEach-Object { "$_".Trim() } | Where-Object { $_ -match '^ssh-' })
    if ($LASTEXITCODE -ne 0 -or $exported.Count -eq 0) {
      throw "failed to export SSH public key for $id"
    }
    foreach ($key in $exported) {
      if (-not $keys.Contains($key)) { $keys.Add($key) }
    }
  }
  return $keys
}

function Get-SshPublicKeyId {
  param([string]$Line)
  $parts = -split $Line.Trim()
  for ($i = 0; $i -lt ($parts.Length - 1); $i++) {
    if ($parts[$i] -like 'ssh-*' -or $parts[$i] -like 'ecdsa-*' -or $parts[$i] -like 'sk-*') {
      return "$($parts[$i]) $($parts[$i + 1])"
    }
  }
  return $Line.Trim()
}

function Set-AuthorizedKeys {
  $path = Join-Path $env:ProgramData 'ssh\administrators_authorized_keys'
  $keys = @(Get-GpgSshPublicKeys)
  $existing = @()
  if (Test-Path -LiteralPath $path) {
    $existing = @(
      Get-Content -LiteralPath $path |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ -and -not $_.StartsWith('#') }
    )
  }
  $seen = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
  $lines = [System.Collections.Generic.List[string]]::new()
  foreach ($line in @($existing + $keys)) {
    if ($seen.Add((Get-SshPublicKeyId $line))) { $lines.Add($line) }
  }
  $text = ($lines -join "`n") + "`n"
  [IO.File]::WriteAllText($path, $text, [Text.UTF8Encoding]::new($false))
  & icacls.exe $path /inheritance:r /grant '*S-1-5-32-544:F' /grant '*S-1-5-18:F' | Out-Null
  if ($LASTEXITCODE -ne 0) { throw "failed to set ACL on $path" }
  foreach ($key in $keys) {
    Write-Log "authorized key: $key"
  }
}

function Set-PubkeyOnly {
  $path = Join-Path $env:ProgramData 'ssh\sshd_config'
  if (-not (Test-Path -LiteralPath $path)) { throw "missing $path" }
  $text = [IO.File]::ReadAllText($path)
  $marker = '# pubkey-only'
  if ($text -notmatch [regex]::Escape($marker)) {
    $prefix = "# pubkey-only`nPubkeyAuthentication yes`nPasswordAuthentication no`nAuthenticationMethods publickey`nPermitEmptyPasswords no`n`n"
    $text = $prefix + $text
  }
  if ($text -notmatch '(?m)^Match Group administrators\s*$') {
    if (-not $text.EndsWith("`n")) { $text += "`n" }
    $text += "Match Group administrators`n       AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys`n"
  }
  $text = $text.Replace("`r`n", "`n").Replace("`r", "`n")
  if (-not $text.EndsWith("`n")) { $text += "`n" }
  [IO.File]::WriteAllText($path, $text, [Text.UTF8Encoding]::new($false))
}

# sshd logs administrators in with an unfiltered token. This wrapper is the
# DefaultShell and relaunches HKLM\SOFTWARE\OpenSSH\FilteredShell with a Safer
# NormalUser token at Medium integrity, attached to the same stdio/console.
# If Windows re-enables RedirectionGuard for sshd, user-created junctions such
# as Scoop's `current` cannot be traversed, so the wrapper resolves them from
# their reparse data instead. The raw argument tail is forwarded verbatim
# because sshd passes `-c <cmd>` escaped without a PTY and unescaped with one.
# The wrapper must outlive the child: sshd's job object kills the whole tree
# once the wrapper's job handle closes.
$ShellWrapperSource = @'
using System;
using System.ComponentModel;
using System.Collections.Generic;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;
using Microsoft.Win32;

static class FilteredShell
{
    const uint SAFER_SCOPEID_USER = 2;
    const uint SAFER_LEVELID_NORMALUSER = 0x20000;
    const uint SAFER_LEVEL_OPEN = 1;
    const int TokenIntegrityLevel = 25;
    const uint SE_GROUP_INTEGRITY = 0x20;
    const uint HANDLE_FLAG_INHERIT = 1;
    const int STARTF_USESTDHANDLES = 0x100;
    const uint EXTENDED_STARTUPINFO_PRESENT = 0x80000;
    const int PROC_THREAD_ATTRIBUTE_HANDLE_LIST = 0x20002;
    const uint INFINITE = 0xFFFFFFFF;

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    struct STARTUPINFO
    {
        public int cb;
        public string lpReserved, lpDesktop, lpTitle;
        public int dwX, dwY, dwXSize, dwYSize, dwXCountChars, dwYCountChars, dwFillAttribute, dwFlags;
        public short wShowWindow, cbReserved2;
        public IntPtr lpReserved2, hStdInput, hStdOutput, hStdError;
    }

    [StructLayout(LayoutKind.Sequential)]
    struct STARTUPINFOEX
    {
        public STARTUPINFO StartupInfo;
        public IntPtr lpAttributeList;
    }

    [StructLayout(LayoutKind.Sequential)]
    struct PROCESS_INFORMATION
    {
        public IntPtr hProcess, hThread;
        public int dwProcessId, dwThreadId;
    }

    [StructLayout(LayoutKind.Sequential)]
    struct TOKEN_MANDATORY_LABEL
    {
        public IntPtr Sid;
        public uint Attributes;
    }

    delegate bool ConsoleCtrlHandler(uint ctrlType);

    [DllImport("advapi32.dll", SetLastError = true)]
    static extern bool SaferCreateLevel(uint scopeId, uint levelId, uint openFlags, out IntPtr level, IntPtr reserved);
    [DllImport("advapi32.dll", SetLastError = true)]
    static extern bool SaferComputeTokenFromLevel(IntPtr level, IntPtr inToken, out IntPtr outToken, uint flags, IntPtr reserved);
    [DllImport("advapi32.dll", SetLastError = true)]
    static extern bool SaferCloseLevel(IntPtr level);
    [DllImport("advapi32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    static extern bool ConvertStringSidToSidW(string sid, out IntPtr psid);
    [DllImport("advapi32.dll")]
    static extern int GetLengthSid(IntPtr sid);
    [DllImport("advapi32.dll", SetLastError = true)]
    static extern bool SetTokenInformation(IntPtr token, int infoClass, ref TOKEN_MANDATORY_LABEL info, int length);
    [DllImport("advapi32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    static extern bool CreateProcessAsUserW(IntPtr token, string app, string cmdLine, IntPtr pa, IntPtr ta, bool inherit, uint flags, IntPtr env, string dir, ref STARTUPINFOEX si, out PROCESS_INFORMATION pi);
    [DllImport("kernel32.dll", SetLastError = true)]
    static extern bool InitializeProcThreadAttributeList(IntPtr list, int count, int flags, ref IntPtr size);
    [DllImport("kernel32.dll", SetLastError = true)]
    static extern bool UpdateProcThreadAttribute(IntPtr list, uint flags, IntPtr attr, IntPtr value, IntPtr size, IntPtr prev, IntPtr retSize);
    [DllImport("kernel32.dll")]
    static extern void DeleteProcThreadAttributeList(IntPtr list);
    [DllImport("kernel32.dll")]
    static extern IntPtr GetStdHandle(int n);
    [DllImport("kernel32.dll", SetLastError = true)]
    static extern bool SetHandleInformation(IntPtr h, uint mask, uint flags);
    [DllImport("kernel32.dll", SetLastError = true)]
    static extern bool SetConsoleCtrlHandler(ConsoleCtrlHandler handler, bool add);
    [DllImport("kernel32.dll", SetLastError = true)]
    static extern uint WaitForSingleObject(IntPtr h, uint ms);
    [DllImport("kernel32.dll", SetLastError = true)]
    static extern bool GetExitCodeProcess(IntPtr h, out uint code);
    [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    static extern IntPtr CreateFileW(string path, uint access, uint share, IntPtr sa, uint disposition, uint flags, IntPtr template);
    [DllImport("kernel32.dll", SetLastError = true)]
    static extern bool DeviceIoControl(IntPtr h, uint code, IntPtr inBuf, int inSize, byte[] outBuf, int outSize, out int returned, IntPtr overlapped);
    [DllImport("kernel32.dll")]
    static extern bool CloseHandle(IntPtr h);

    static readonly ConsoleCtrlHandler IgnoreCtrl = delegate { return true; };

    static int Main()
    {
        try
        {
            return Run();
        }
        catch (Exception e)
        {
            Console.Error.WriteLine("pwsh-filtered: " + e.Message);
            return 255;
        }
    }

    static int Run()
    {
        SetConsoleCtrlHandler(IgnoreCtrl, true);
        string target = ResolveLinks(ReadTarget());
        string cmdLine = "\"" + target + "\"" + ArgumentTail(Environment.CommandLine);
        IntPtr token = CreateFilteredToken();

        STARTUPINFOEX si = new STARTUPINFOEX();
        si.StartupInfo.cb = Marshal.SizeOf(typeof(STARTUPINFOEX));
        si.StartupInfo.dwFlags = STARTF_USESTDHANDLES;
        si.StartupInfo.hStdInput = GetStdHandle(-10);
        si.StartupInfo.hStdOutput = GetStdHandle(-11);
        si.StartupInfo.hStdError = GetStdHandle(-12);

        IntPtr[] handles = InheritableHandles(si.StartupInfo.hStdInput, si.StartupInfo.hStdOutput, si.StartupInfo.hStdError);
        IntPtr handleArray = Marshal.AllocHGlobal(IntPtr.Size * Math.Max(handles.Length, 1));
        Marshal.Copy(handles, 0, handleArray, handles.Length);
        uint flags = 0;
        if (handles.Length > 0)
        {
            IntPtr size = IntPtr.Zero;
            InitializeProcThreadAttributeList(IntPtr.Zero, 1, 0, ref size);
            si.lpAttributeList = Marshal.AllocHGlobal(size);
            if (!InitializeProcThreadAttributeList(si.lpAttributeList, 1, 0, ref size) ||
                !UpdateProcThreadAttribute(si.lpAttributeList, 0, (IntPtr)PROC_THREAD_ATTRIBUTE_HANDLE_LIST,
                    handleArray, (IntPtr)(IntPtr.Size * handles.Length), IntPtr.Zero, IntPtr.Zero))
                throw new Win32Exception();
            flags = EXTENDED_STARTUPINFO_PRESENT;
        }

        PROCESS_INFORMATION pi;
        if (!CreateProcessAsUserW(token, target, cmdLine, IntPtr.Zero, IntPtr.Zero, handles.Length > 0, flags, IntPtr.Zero, null, ref si, out pi))
            throw LastError(target);
        if (si.lpAttributeList != IntPtr.Zero)
            DeleteProcThreadAttributeList(si.lpAttributeList);

        WaitForSingleObject(pi.hProcess, INFINITE);
        uint code;
        GetExitCodeProcess(pi.hProcess, out code);
        return (int)code;
    }

    static string ReadTarget()
    {
        using (RegistryKey hklm = RegistryKey.OpenBaseKey(RegistryHive.LocalMachine, RegistryView.Registry64))
        using (RegistryKey key = hklm.OpenSubKey(@"SOFTWARE\OpenSSH"))
        {
            string target = key == null ? null : key.GetValue("FilteredShell") as string;
            if (string.IsNullOrEmpty(target))
                throw new InvalidOperationException(@"HKLM\SOFTWARE\OpenSSH\FilteredShell is not set");
            return target;
        }
    }

    static string ResolveLinks(string path)
    {
        for (int hops = 0; hops < 32; hops++)
        {
            string full = Path.GetFullPath(path);
            string current = Path.GetPathRoot(full);
            string[] parts = full.Substring(current.Length).Split(new[] { '\\' }, StringSplitOptions.RemoveEmptyEntries);
            string target = null;
            int i = 0;
            for (; i < parts.Length; i++)
            {
                string next = Path.Combine(current, parts[i]);
                target = ReadLinkTarget(next);
                if (target != null)
                    break;
                current = next;
            }
            if (target == null)
                return current;
            path = Path.Combine(current, target);
            for (i++; i < parts.Length; i++)
                path = Path.Combine(path, parts[i]);
        }
        throw new IOException("too many links: " + path);
    }

    static string ReadLinkTarget(string path)
    {
        const uint IO_REPARSE_TAG_MOUNT_POINT = 0xA0000003;
        const uint IO_REPARSE_TAG_SYMLINK = 0xA000000C;
        const uint FSCTL_GET_REPARSE_POINT = 0x900A8;
        const uint FILE_READ_ATTRIBUTES = 0x80;
        const uint FILE_SHARE_ALL = 7;
        const uint OPEN_EXISTING = 3;
        const uint FILE_FLAG_OPEN_REPARSE_POINT = 0x00200000;
        const uint FILE_FLAG_BACKUP_SEMANTICS = 0x02000000;

        FileAttributes attributes = File.GetAttributes(path);
        if ((attributes & FileAttributes.ReparsePoint) == 0)
            return null;
        IntPtr h = CreateFileW(path, FILE_READ_ATTRIBUTES, FILE_SHARE_ALL, IntPtr.Zero, OPEN_EXISTING,
            FILE_FLAG_OPEN_REPARSE_POINT | FILE_FLAG_BACKUP_SEMANTICS, IntPtr.Zero);
        if (h == (IntPtr)(-1))
            throw LastError(path);
        byte[] buf = new byte[16 * 1024];
        int returned;
        try
        {
            if (!DeviceIoControl(h, FSCTL_GET_REPARSE_POINT, IntPtr.Zero, 0, buf, buf.Length, out returned, IntPtr.Zero))
                throw LastError(path);
        }
        finally
        {
            CloseHandle(h);
        }

        uint tag = BitConverter.ToUInt32(buf, 0);
        int pathBuffer;
        if (tag == IO_REPARSE_TAG_MOUNT_POINT)
            pathBuffer = 16;
        else if (tag == IO_REPARSE_TAG_SYMLINK)
            pathBuffer = 20;
        else
            return null;
        int offset = BitConverter.ToUInt16(buf, 8);
        int length = BitConverter.ToUInt16(buf, 10);
        string target = Encoding.Unicode.GetString(buf, pathBuffer + offset, length);
        if (target.StartsWith(@"\??\UNC\"))
            return @"\\" + target.Substring(8);
        if (target.StartsWith(@"\??\"))
        {
            target = target.Substring(4);
            // Volume mount points (Volume{GUID}\) are traversed as plain directories.
            return target.Length > 1 && target[1] == ':' ? target : null;
        }
        return target;
    }

    static Win32Exception LastError(string context)
    {
        int error = Marshal.GetLastWin32Error();
        return new Win32Exception(error, context + ": " + new Win32Exception(error).Message);
    }

    static string ArgumentTail(string commandLine)
    {
        int i = 0;
        if (commandLine.StartsWith("\""))
        {
            i = commandLine.IndexOf('"', 1);
            i = i < 0 ? commandLine.Length : i + 1;
        }
        else
        {
            while (i < commandLine.Length && commandLine[i] != ' ' && commandLine[i] != '\t')
                i++;
        }
        return commandLine.Substring(i);
    }

    static IntPtr CreateFilteredToken()
    {
        IntPtr level, token, medium;
        if (!SaferCreateLevel(SAFER_SCOPEID_USER, SAFER_LEVELID_NORMALUSER, SAFER_LEVEL_OPEN, out level, IntPtr.Zero))
            throw new Win32Exception();
        try
        {
            if (!SaferComputeTokenFromLevel(level, IntPtr.Zero, out token, 0, IntPtr.Zero))
                throw new Win32Exception();
        }
        finally
        {
            SaferCloseLevel(level);
        }

        // Safer keeps the caller's High label, which makes process creation from the child fail.
        if (!ConvertStringSidToSidW("S-1-16-8192", out medium))
            throw new Win32Exception();
        TOKEN_MANDATORY_LABEL label = new TOKEN_MANDATORY_LABEL { Sid = medium, Attributes = SE_GROUP_INTEGRITY };
        if (!SetTokenInformation(token, TokenIntegrityLevel, ref label, Marshal.SizeOf(typeof(TOKEN_MANDATORY_LABEL)) + GetLengthSid(medium)))
            throw new Win32Exception();
        return token;
    }

    static IntPtr[] InheritableHandles(params IntPtr[] candidates)
    {
        List<IntPtr> handles = new List<IntPtr>();
        foreach (IntPtr h in candidates)
        {
            if (h == IntPtr.Zero || h == (IntPtr)(-1) || handles.Contains(h))
                continue;
            if (SetHandleInformation(h, HANDLE_FLAG_INHERIT, HANDLE_FLAG_INHERIT))
                handles.Add(h);
        }
        return handles.ToArray();
    }
}
'@

function Get-ShellWrapperPath {
  Join-Path $env:ProgramData 'ssh\pwsh-filtered.exe'
}

# Built inside the admin-only ssh directory so a non-elevated process cannot
# swap the source or binary that sshd later runs elevated.
function Install-ShellWrapper {
  $csc = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
  if (-not (Test-Path -LiteralPath $csc)) { throw "missing $csc" }
  $exe = Get-ShellWrapperPath
  $src = [IO.Path]::ChangeExtension($exe, '.cs')
  $new = "$exe.new"
  try {
    [IO.File]::WriteAllText($src, $ShellWrapperSource, [Text.UTF8Encoding]::new($false))
    $output = & $csc /nologo /target:exe /platform:anycpu /optimize+ "/out:$new" $src 2>&1
    if ($LASTEXITCODE -ne 0) { throw "failed to build shell wrapper:`n$($output -join "`n")" }
    # A running wrapper cannot be overwritten or deleted but can be renamed.
    $old = $null
    if (Test-Path -LiteralPath $exe) {
      $old = '{0}.{1}.old' -f $exe, [guid]::NewGuid().ToString('n')
      Move-Item -LiteralPath $exe -Destination $old
    }
    try {
      Move-Item -LiteralPath $new -Destination $exe
    } catch {
      if ($old) { Move-Item -LiteralPath $old -Destination $exe }
      throw
    }
  } finally {
    Remove-Item -LiteralPath $src, $new -Force -ErrorAction SilentlyContinue
  }
  Get-ChildItem -LiteralPath (Split-Path $exe) -Filter ((Split-Path $exe -Leaf) + '*.old') |
    Remove-Item -Force -ErrorAction SilentlyContinue
  Write-Log "shell wrapper: $exe"
}

function Set-LoginShell {
  $pwsh = Join-Path $PSHOME 'pwsh.exe'
  $wrapper = Get-ShellWrapperPath
  New-Item -Path 'HKLM:\SOFTWARE\OpenSSH' -Force | Out-Null
  New-ItemProperty -Path 'HKLM:\SOFTWARE\OpenSSH' -Name FilteredShell -Value $pwsh -PropertyType String -Force | Out-Null
  New-ItemProperty -Path 'HKLM:\SOFTWARE\OpenSSH' -Name DefaultShell -Value $wrapper -PropertyType String -Force | Out-Null
  Write-Log "login shell: $pwsh (filtered by $wrapper)"
}

# Windows opts sshd.exe into RedirectionGuard through IFEO, which blocks
# user-created junctions (Scoop's `current` and persist links) in every SSH
# session. Only the exact value Windows writes (a lone 0x10 in the last byte)
# is cleared, so other mitigations configured for sshd are left untouched.
function Disable-SshdRedirectionGuard {
  $key = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\sshd.exe'
  $bytes = (Get-ItemProperty -LiteralPath $key -Name MitigationOptions -ErrorAction SilentlyContinue).MitigationOptions
  if (-not $bytes -or -not ($bytes | Where-Object { $_ })) { return }
  $last = $bytes.Length - 1
  $others = [byte[]]$bytes.Clone()
  $others[$last] = 0
  if ($bytes[$last] -ne 0x10 -or ($others | Where-Object { $_ })) {
    Write-Log "unexpected sshd MitigationOptions $([Convert]::ToHexString($bytes)); RedirectionGuard left unchanged"
    return
  }
  Set-ItemProperty -LiteralPath $key -Name MitigationOptions -Value ([byte[]]::new($bytes.Length)) -Type Binary
  Write-Log 'sshd RedirectionGuard disabled'
}

function Install-SshdIfMissing {
  if (Get-Service sshd -ErrorAction SilentlyContinue) { return }
  Write-Log 'installing OpenSSH Server'
  $result = Add-WindowsCapability -Online -Name 'OpenSSH.Server~~~~0.0.1.0'
  Write-Log "capability: $($result.State)"
  if (-not (Get-Service sshd -ErrorAction SilentlyContinue)) {
    throw 'sshd service missing after install'
  }
}

function Enable-SshdFirewall {
  $name = 'OpenSSH-Server-In-TCP'
  $rule = Get-NetFirewallRule -Name $name -ErrorAction SilentlyContinue
  if (-not $rule) {
    New-NetFirewallRule -Name $name -DisplayName 'OpenSSH SSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 -Profile Any | Out-Null
    return
  }
  Set-NetFirewallRule -Name $name -Enabled True -Profile Any -Action Allow
}

function Wait-SshdConfig {
  param([ref]$StartedForConfig)
  $path = Join-Path $env:ProgramData 'ssh\sshd_config'
  if (Test-Path -LiteralPath $path) { return }
  Write-Log 'generating sshd host keys'
  Start-Service sshd
  $StartedForConfig.Value = $true
  $deadline = (Get-Date).AddSeconds(20)
  while (-not (Test-Path -LiteralPath $path) -and (Get-Date) -lt $deadline) {
    Start-Sleep -Milliseconds 200
  }
  if (-not (Test-Path -LiteralPath $path)) { throw 'sshd_config was not created' }
}

function Invoke-Setup {
  $wasRunning = (Get-Service sshd -ErrorAction SilentlyContinue).Status -eq 'Running'
  Install-SshdIfMissing
  Set-Service -Name sshd -StartupType Manual
  Disable-SshdRedirectionGuard
  $startedForConfig = $false
  Wait-SshdConfig ([ref]$startedForConfig)
  Install-ShellWrapper
  Set-LoginShell
  Set-PubkeyOnly
  Enable-SshdFirewall
  Set-AuthorizedKeys
  if ($wasRunning) {
    Restart-Service sshd
    Write-Log 'sshd restarted'
    return
  }
  if ((Get-Service sshd).Status -eq 'Running') {
    Stop-Service sshd
  }
  Write-Log 'sshd ready; start it on demand'
}

function Invoke-Start {
  if (-not (Get-Service sshd -ErrorAction SilentlyContinue)) {
    throw 'sshd is not installed. Run: sshctl.ps1 setup'
  }
  if ((Get-Service sshd).StartType -eq 'Disabled') {
    Set-Service -Name sshd -StartupType Manual
  }
  Start-Service sshd
  if ((Get-Service sshd).Status -ne 'Running') { throw 'sshd did not start' }
  Write-Log 'sshd started'
}

function Invoke-Stop {
  if (-not (Get-Service sshd -ErrorAction SilentlyContinue)) {
    throw 'sshd is not installed. Run: sshctl.ps1 setup'
  }
  Stop-Service sshd -Force
  Write-Log 'sshd stopped'
}

$known = @('setup', 'start', 'stop')
if ($Command -in @('-h', '--help', 'help')) {
  Write-Host 'usage: sshctl.ps1 <setup|start|stop>'
  exit 0
}
if ($Command -notin $known) {
  Write-Host 'usage: sshctl.ps1 <setup|start|stop>'
  exit 1
}

if (-not (Test-Administrator)) {
  Invoke-Elevated
}

try {
  switch ($Command) {
    'setup' { Invoke-Setup }
    'start' { Invoke-Start }
    'stop' { Invoke-Stop }
  }
} catch {
  Write-Log $_.Exception.Message
  exit 1
}
