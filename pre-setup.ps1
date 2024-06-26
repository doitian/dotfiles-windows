@(
  "default-cache-ttl 3600"
  "max-cache-ttl 14400"
  "enable-putty-support"
) | Set-Content -Path "$(scoop prefix gpg)\home\gpg-agent.conf"

$SSHPath = (Get-Command -Name 'ssh.exe').Source
[Environment]::SetEnvironmentVariable('GIT_SSH', $SSHPath, 'User')

$UserBinDir = "$(Split-Path -Parent $PROFILE)\bin"
$SSHAgentLocation = "$(scoop prefix wsl-ssh-pageant)\wsl-ssh-pageant-gui.exe"
$SSHAgentShortcut = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\SSH Agent.lnk"

$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($SSHAgentShortcut)
$Shortcut.TargetPath = $SSHAgentLocation
$Shortcut.Arguments = "--systray --winssh ssh-pageant"
$Shortcut.WindowStyle = 4
$Shortcut.Save()
mkdir -Fo "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\SSH Agent"
cp -Fo "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\SSH Agent.lnk" "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\SSH Agent\SSH Agent.lnk"

[Environment]::SetEnvironmentVariable('SSH_AUTH_SOCK', '\\.\pipe\ssh-pageant', 'User')
