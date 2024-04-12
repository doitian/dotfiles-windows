$repos = resolve-path $args

ForEach ($repo in $repos) {
  if (git -C "$repo" rev-parse --is-inside-work-tree) {
    Write-Host -NoNewline "$(Split-Path -Leaf $repo.Path) "
    git -C "$repo" status --short --branch
  }
}
