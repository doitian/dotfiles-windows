if ($args.Count -gt 0) {
  $env:http_proxy = 'http://127.0.0.1:7890'
  $env:https_proxy = $env:http_proxy
  $env:all_proxy = 'http://127.0.0.1:7890'
  $RemainingArgs = $args[1..($args.Count-1)]
  & $args[0] @RemainingArgs
} else {
  $env:http_proxy = 'http://127.0.0.1:7890'
  $env:https_proxy = $env:http_proxy
  $env:all_proxy = 'http://127.0.0.1:7890'
}
