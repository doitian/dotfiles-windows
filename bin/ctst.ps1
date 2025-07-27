$CheatsheetsDir = "$HOME/Dropbox/Brain/para/lets/c/Cheatsheets"

$selected = ls "$CheatsheetsDir" | ? { -Not $_.Name.StartsWith('♯ ') } | % { $_.FullName -Replace '\\', '/' } | fzf -d '/' --with-nth -1 -0 -1 -q "$Args"
if ($selected -ne $null) {
  cat $selected
}
