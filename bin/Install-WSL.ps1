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
  $Name

  [String]
  $Target
)

$ErrorActionPreference = "Stop"

$DefaultName = ""
$ExtractDir = "."
if ($RootFsTar.Name.StartsWith('alpine-')) {
  $DefaultName = 'Alpine'
} elseif ($RootFsTar.Name.StartsWith('fedora-')) {
  $DefaultName = 'Alpine'
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

lxrunoffline.exe i -n $Name -f $RootFsTar -d "$WSLRoot\$Name" -v 2 -r "$ExtractDir"

if (-Not (Test-Path -LiteralPath "$Target\ext4.vhdx")) {
  wsl --set-version $Name 2
  rm -Re -Fo "$Target\temp"
}
