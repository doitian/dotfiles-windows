# Get-Service -DisplayName Adobe* | Stop-Service
Get-Process -name "*adobe*" | Stop-Process -Force
Get-Process -name "*acrobat*" | Stop-Process -Force
