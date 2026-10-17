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

function Resolve-LoginShellPath {
  param([string]$Path)
  $item = Get-Item -LiteralPath $Path
  while ($item.LinkType -or ($item.Directory -and $item.Directory.LinkType)) {
    if ($item.LinkType) {
      $target = @($item.Target)[0]
      if (-not [IO.Path]::IsPathRooted($target)) {
        $target = Join-Path $item.Directory.FullName $target
      }
      $item = Get-Item -LiteralPath $target
      continue
    }
    $target = @($item.Directory.Target)[0]
    if (-not [IO.Path]::IsPathRooted($target)) {
      $target = Join-Path $item.Directory.Parent.FullName $target
    }
    $item = Get-Item -LiteralPath (Join-Path $target $item.Name)
  }
  return $item.FullName
}

function Set-LoginShell {
  $pwsh = Resolve-LoginShellPath (Get-ToolPath 'pwsh' @(
    (Join-Path $env:USERPROFILE 'scoop\apps\pwsh\current\pwsh.exe')
  ))
  New-Item -Path 'HKLM:\SOFTWARE\OpenSSH' -Force | Out-Null
  New-ItemProperty -Path 'HKLM:\SOFTWARE\OpenSSH' -Name DefaultShell -Value $pwsh -PropertyType String -Force | Out-Null
  Write-Log "login shell: $pwsh"
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
  $startedForConfig = $false
  Wait-SshdConfig ([ref]$startedForConfig)
  Set-PubkeyOnly
  Enable-SshdFirewall
  Set-AuthorizedKeys
  Set-LoginShell
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
  $previousShell = (Get-ItemProperty 'HKLM:\SOFTWARE\OpenSSH' -ErrorAction SilentlyContinue).DefaultShell
  Set-LoginShell
  $shell = (Get-ItemProperty 'HKLM:\SOFTWARE\OpenSSH').DefaultShell
  if ((Get-Service sshd).Status -eq 'Running' -and $previousShell -ne $shell) {
    Restart-Service sshd
  } else {
    Start-Service sshd
  }
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
