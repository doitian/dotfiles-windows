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

function Get-FolderSize {
  [CmdletBinding()]
  Param (
    [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
    $Path
  )
  if ( (Test-Path $Path) -and (Get-Item $Path).PSIsContainer ) {
    $Measure = Get-ChildItem $Path -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum
    $Sum = '{0:N2}' -f ($Measure.Sum / 1Gb)
    [PSCustomObject]@{
      "Path" = $Path
      "Size(Gb)" = $Sum
    }
  }
}
