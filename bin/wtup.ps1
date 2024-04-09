if (Test-Path .wtup.ps1) {
  . .wtup.ps1
} else {
  wt -w 0 nt --title shell -p "PowerShell" `; ft -t 0
  nvim
}
