ForEach ($repo in $args) {
  if (Test-Path -LiteralPath "$repo") {
    Write-Host -NoNewline "$repo"
    pushd "$repo" | out-null
    git status --short --branch
    popd | out-null
  }
}
