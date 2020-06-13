$FZFArgs = $args.Count -gt 0 ? @('-1', '-q', ($args -join ' ')) : @()

cat "$HOME\.cdHistory" | sort -Desc | % {
  $_.SubString(25)
} | ? {
  Test-Path -LiteralPath "$_/.git"
} | fzf $FZFArgs | cd
