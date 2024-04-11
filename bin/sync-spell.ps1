$files = @("$HOME\.vim-spell-en.utf-8.add", "$HOME\AppData\Roaming\Microsoft\Spelling\neutral\default.dic")
$existingFiles = $files | ? { Test-Path $_ }
$merged =  Get-Content $existingFiles | % { $_.Trim() } | ? { $_ -ne "" } | Sort-Object | Get-Unique
foreach ($file in $files) {
  echo "==> $file"
  Set-Content -Path $file -Value $merged
}
