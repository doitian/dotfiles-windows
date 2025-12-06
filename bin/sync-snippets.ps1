$scoopDir = $env:SCOOP
if (-not $scoopDir) {
    $scoopDir = "$HOME\scoop"
}

$vsSnippetsDir = "$scoopDir\persist\vscode\data\user-data\User\snippets"
$cursorSnippetsDir = "$scoopDir\persist\cursor\data\user-data\User\snippets"
$reposDir = Get-Item "$HOME\.dotfiles\repos"

cp -fo "$reposDir\public\nvim\snippets\global.code-snippets" "$reposDir\public\nvim\snippets\all.json"
foreach ($dir in @($vsSnippetsDir, $cursorSnippetsDir)) {
  if (Test-Path $dir) {
    $linkType = (Get-Item -Path $dir -Force).LinkType
    if ($linkType -ne "Junction") {
      Remove-Item -Path $dir -Force -Recurse
      New-Item -ItemType Junction -Path $dir -Value "$reposDir\public\nvim\snippets"
    }
  }
}

$privateSnippetsDir = "$reposDir\private\nvim\snippets"
if (Test-Path $privateSnippetsDir) {
  Get-ChildItem $privateSnippetsDir | Get-Content | jq -s 'reduce .[] as $item ({}; . * $item)' | Set-Content -Encoding utf-8 -Path "$reposDir\public\nvim\snippets\private-snippets.code-snippets"
}