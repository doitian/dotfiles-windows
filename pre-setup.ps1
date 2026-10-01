mkdir -Force "$env:APPDATA\gnupg"
@(
  "default-cache-ttl 3600"
  "max-cache-ttl 14400"
  "enable-win32-openssh-support"
  "allow-preset-passphrase"
  ""
) -join "`n" | Set-Content -NoNewline -Path "$env:APPDATA\gnupg\gpg-agent.conf"
if (Get-Command gpgconf -ErrorAction SilentlyContinue) {
  gpgconf --reload gpg-agent
}

$SSHPath = (Get-Command -Name 'ssh.exe').Source
[Environment]::SetEnvironmentVariable('GIT_SSH', $SSHPath, 'User')
