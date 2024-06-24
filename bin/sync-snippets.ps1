$scoopDir = $env:SCOOP
if (-not $scoopDir) {
    $scoopDir = "$HOME\scoop"
}

$vsSnippetsDir = "$scoopDir\persist\vscode\data\user-data\User\snippets"
$reposDir = Get-Item "$HOME\.dotfiles\repos"

if (Test-Path $vsSnippetsDir) {
  $linkType = (Get-Item -Path $vsSnippetsDir -Force).LinkType
  if ($linkType -ne "Junction") {
    Remove-Item -Path $vsSnippetsDir -Force -Recurse
    New-Item -ItemType Junction -Path $vsSnippetsDir -Value "$reposDir\public\nvim\snippets"
  }
}

$privateSnippetsDir = "$reposDir\private\nvim\snippets"
if (Test-Path $privateSnippetsDir) {
  Get-ChildItem $privateSnippetsDir | Get-Content | jq -s 'reduce .[] as $item ({}; . * $item)' | Set-Content -Encoding utf-8 -Path "$reposDir\public\nvim\snippets\private-snippets.code-snippets"
}
