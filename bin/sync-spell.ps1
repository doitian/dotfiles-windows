$files = @(
  "$HOME\.vim-spell-en.utf-8.add"
  "$HOME\Dropbox\Apps\Harper\dictionary.txt"
)
$winFile = "$HOME\AppData\Roaming\Microsoft\Spelling\neutral\default.dic"

$existingFiles = ($files + $winFile) | ? { Test-Path $_ }
$merged =  Get-Content $existingFiles | % { $_.Trim() } | ? { $_ -ne "" }

$obsidianHarperSettingPath = "$HOME\Dropbox\Brain\.obsidian\plugins\harper\data.json"
$obsidianHarperSetting = $null

if (Test-Path $obsidianHarperSettingPath) {
  $obsidianHarperSetting = Get-Content $obsidianHarperSettingPath | ConvertFrom-Json
  $merged += $obsidianHarperSetting.userDictionary
}

$merged = $merged | Sort-Object -Unique -CaseSensitive

$outFiles = @()

if (Test-Path (Split-Path -Parent $winFile)) {
  $outFiles += Resolve-Path $winFile
  Set-Content -Path $winFile -Value $merged
}

if ($obsidianHarperSetting -ne $null) {
  $obsidianHarperSetting.userDictionary = $merged
  $obsidianHarperSettingJson = ($obsidianHarperSetting | ConvertTo-Json -Depth 2) -Replace "`r`n", "`n"
  $outFiles += Resolve-Path $obsidianHarperSettingPath
  Set-Content -NoNewline -Path $obsidianHarperSettingPath -Value $obsidianHarperSettingJson
}

$merged = ($merged | Join-String -Separator `n) + "`n"
foreach ($file in $files) {
  if (Test-Path (Split-Path -Parent $file)) {
    $outFiles += Resolve-Path $file
    Set-Content -NoNewline -Path $file -Value $merged
  }
}

$outFiles
