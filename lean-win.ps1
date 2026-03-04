<#
.SYNOPSIS
  Script to uninstall components on Windows for all users.

.EXECUTION
  Must be run as administrator.
#>

#Requires -RunAsAdministrator

function Uninstall-OneDrive {
  Stop-Process -Name OneDrive -Force -ErrorAction SilentlyContinue -Verbose

  $paths = @(
      "$env:SystemRoot\System32\OneDriveSetup.exe",   # 64-bit
      "$env:SystemRoot\SysWOW64\OneDriveSetup.exe"    # 32-bit
  )

  foreach ($exe in $paths) {
      if (Test-Path $exe) {
          Write-Output "Launching uninstallation using: $exe"
          Start-Process $exe -ArgumentList "/uninstall" -Wait -Verb RunAs -WindowStyle Hidden
      }
  }

  $users = Get-ChildItem "C:\Users" -Directory | Where-Object {
    $_.Name -notin @("Default", "Default User", "Public", "All Users")
  }

  foreach ($user in $users) {
    $profile = $user.FullName
    $pathsToDelete = @(
      "$profile\OneDrive",
      "$profile\AppData\Local\Microsoft\OneDrive",
      "$profile\AppData\Roaming\Microsoft\OneDrive"
    )

    foreach ($path in $pathsToDelete) {
      if (Test-Path $path) {
        Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
      }
    }
  }

  $regKeys = @(
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"
  )

  foreach ($key in $regKeys) {
    if (Test-Path $key) {
      Remove-ItemProperty -Path $key -Name "OneDrive" -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $key -Name "OneDriveSetup" -ErrorAction SilentlyContinue
    }
  }

  $tasks = Get-ScheduledTask | Where-Object { $_.TaskName -like "*OneDrive*" }
  foreach ($task in $tasks) {
    Unregister-ScheduledTask -TaskName $task.TaskName -Confirm:$false -ErrorAction SilentlyContinue
  }
}

Uninstall-OneDrive
