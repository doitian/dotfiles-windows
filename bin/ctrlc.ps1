if ($args.Count -gt 0) {
  Set-Clipboard -Value (Get-Content @args)
} else {
  $input | Set-Clipboard
}
