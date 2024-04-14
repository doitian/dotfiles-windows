$files = @(
  "$HOME\.vim-spell-en.utf-8.add"
  "$HOME\Dropbox\Backups\General\spell.txt"
)
$winFile = "$HOME\AppData\Roaming\Microsoft\Spelling\neutral\default.dic"

$existingFiles = ($files + $winFile) | ? { Test-Path $_ }
$merged =  Get-Content $existingFiles | % { $_.Trim() } | ? { $_ -ne "" }

$obsidianAppSettingPath = "$HOME\Dropbox\Brain\.obsidian\app.json"
$obsidianAppSetting = $null

if (Test-Path $obsidianAppSettingPath) {
  $obsidianAppSetting = Get-Content $obsidianAppSettingPath | ConvertFrom-Json
  $merged += $obsidianAppSetting.spellcheckDictionary
}

$merged = $merged | Sort-Object -Unique -CaseSensitive

$outFiles = @()

if (Test-Path (Split-Path -Parent $winFile)) {
  $outFiles += Resolve-Path $winFile
  Set-Content -Path $winFile -Value $merged
}

if ($obsidianAppSetting -ne $null) {
  $obsidianAppSetting.spellcheckDictionary = $merged
  $obsidianAppSettingJson = ($obsidianAppSetting | ConvertTo-Json -Depth 2) -Replace "`r`n", "`n"
  $outFiles += Resolve-Path $obsidianAppSettingPath
  Set-Content -NoNewline -Path $obsidianAppSettingPath -Value $obsidianAppSettingJson
}

# LF newline
$merged = $merged | Join-String -Separator `n
foreach ($file in $files) {
  if (Test-Path (Split-Path -Parent $file)) {
    $outFiles += Resolve-Path $file
    Set-Content -NoNewline -Path $file -Value $merged
  }
}

$outFiles
