$selected = (gopass list -f | fzf)
if ($selected) {
  if ($Args.Count -eq 0) {
    gopass show -c $selected
  } else {
    gopass @Args $selected
  }
}
