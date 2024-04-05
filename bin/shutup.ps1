Get-Service -DisplayName Adobe* | Stop-Service
Get-Process * | Where-Object { $_.CompanyName -match "Adobe" -or $_.Path -match "Adobe" } | Stop-Process -Force
