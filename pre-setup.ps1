mkdir -Force "$env:APPDATA\gnupg"
@(
  "default-cache-ttl 3600"
  "max-cache-ttl 14400"
  "enable-win32-openssh-support"
) | Set-Content -Path "$env:APPDATA\gnupg\gpg-agent.conf"

$SSHPath = (Get-Command -Name 'ssh.exe').Source
[Environment]::SetEnvironmentVariable('GIT_SSH', $SSHPath, 'User')
