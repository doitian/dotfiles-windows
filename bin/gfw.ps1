function testport($hostname, $port=7890, $timeout=100) {
  $requestCallback = $state = $null
  $client = New-Object System.Net.Sockets.TcpClient
  $beginConnect = $client.BeginConnect($hostname,$port,$requestCallback,$state)
  Start-Sleep -milli $timeOut
  if ($client.Connected) { $open = $true } else { $open = $false }
  $client.Close()
  [pscustomobject]@{hostname=$hostname; port=$port; open=$open}
}

if (Test-Path env:GFW_PROXY) {
  $env:HTTP_PROXY = $env:GFW_PROXY
} elseif ((testport 192.168.2.6).open) {
  $env:HTTP_PROXY = 'http://192.168.2.6:7890'
} else {
  $env:HTTP_PROXY = 'http://127.0.0.1:7890'
}
$env:HTTPS_PROXY = $env:HTTP_PROXY
$env:ALL_PROXY = $env:HTTP_PROXY
$env:NO_PROXY = 'localhost, 127.0.0.1, ::1'

if ($args.Count -gt 0) {
  if ($args[0] -eq 'on') {
    return
  }

  if ($args[0] -eq 'ssh') {
    $RemainingArgs = $args[1..($args.Count-1)]
    & ssh -o ProxyCommand="ncat --proxy-type socks5 --proxy $($env:HTTP_PROXY -replace '.*://') %h %p" @RemainingArgs
  } elseif ($args[0] -ne 'off') {
    if ($args.Count -eq 1) {
      & $args[0]
    } else {
      $RemainingArgs = $args[1..($args.Count-1)]
      & $args[0] @RemainingArgs
    }
  }
  rm env:HTTP_PROXY, env:HTTPS_PROXY, env:ALL_PROXY, env:NO_PROXY
}
