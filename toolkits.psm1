function Disable-AcronisServices() {
  $services = Get-Service -DisplayName 'Acronis*'
  $services | Stop-Service
  $services | Set-Service -StartupType Disabled
  echo "Disable Active Protect manually"
  echo "Disable auto start programs in Task Manager"

  $startDir = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Acronis\True Image\Tools and Utilities"
  if (Test-Path -LiteralPath $startDir) {
    rm -Re -Fo $startDir
  }
}
