if (Test-Path env:GFW_PROXY) {
  $env:http_proxy = $env:GFW_PROXY
} else {
  $env:http_proxy = 'http://127.0.0.1:7890'
}
$env:https_proxy = $env:http_proxy
$env:all_proxy = $env:http_proxy
$env:no_proxy = 'localhost, 127.0.0.1, ::1'

if ($args.Count -gt 0) {
  if ($args[0] -eq 'on') {
    return
  }

  if ($args[0] -ne 'off') {
    if ($args.Count -eq 1) {
      & $args[0]
    } else {
      $RemainingArgs = $args[1..($args.Count-1)]
      & $args[0] @RemainingArgs
    }
  }
  rm env:http_proxy, env:https_proxy, env:all_proxy, env:no_proxy
}
