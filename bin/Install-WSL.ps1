param (
  [Parameter(Mandatory=$true, Position=0)]
  [ValidateScript({
    if(-Not (Test-Path $_)) {
      throw "File does not exist"
    }
    return $true
  })]
  [System.IO.FileInfo]
  $RootFsTar,

  [String]
  $Name,

  [String]
  $Target
)

$ErrorActionPreference = "Stop"

$DefaultName = ""
if ($RootFsTar.Name.StartsWith('alpine-')) {
  $DefaultName = 'Alpine'
} elseif ($RootFsTar.Name.StartsWith('fedora-')) {
  $DefaultName = 'Fedora'
}

if ($Name.Length -eq 0) {
  if ($DefaultName.Length -gt 0) {
    $Name = $DefaultName
  } else {
    $Name = (Get-Culture).TextInfo.ToTitleCase($RootFsTar.Name.Split('-')[0])
  }
}

if ($Target.Length -eq 0) {
  $Target = "$(Get-Location)\$Name"
}

wsl --import $Name "$Target" "$RootFsTar" --version 2
if ($LASTEXITCODE -ne 0) {
  throw "wsl --import failed."
}
