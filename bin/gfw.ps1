function testport($hostname, $port=7890, $timeout=100) {
  $requestCallback = $state = $null
  $client = New-Object System.Net.Sockets.TcpClient
  $beginConnect = $client.BeginConnect($hostname,$port,$requestCallback,$state)
  Start-Sleep -milli $timeOut
  if ($client.Connected) { $open = $true } else { $open = $false }
  $client.Close()
  [pscustomobject]@{hostname=$hostname; port=$port; open=$open}
}

# Determine proxy URL
if (Test-Path env:GFW_PROXY) {
  $proxyUrl = $env:GFW_PROXY
} elseif ((testport 10.31.0.6).open) {
  $proxyUrl = 'http://10.31.0.6:7890'
} else {
  $proxyUrl = 'http://127.0.0.1:7890'
}

# Save original proxy settings
$originalHttpProxy = $env:HTTP_PROXY
$originalHttpsProxy = $env:HTTPS_PROXY
$originalAllProxy = $env:ALL_PROXY
$originalNoProxy = $env:NO_PROXY

# Set proxy environment variables
$env:HTTP_PROXY = $proxyUrl
$env:HTTPS_PROXY = $proxyUrl
$env:ALL_PROXY = $proxyUrl
$env:NO_PROXY = 'localhost, 127.0.0.1, ::1'

# Handle different modes
if ($args.Count -gt 0) {
  if ($args[0] -eq 'on') {
    # Enable proxy for current session
    return
  }
  
  if ($args[0] -eq 'off') {
    # Restore original settings and exit
    $env:HTTP_PROXY = $originalHttpProxy
    $env:HTTPS_PROXY = $originalHttpsProxy
    $env:ALL_PROXY = $originalAllProxy
    $env:NO_PROXY = $originalNoProxy
    return
  }
  
  # One-shot command execution with cleanup guarantee
  try {
    $stdinContent = $input
    if ($args[0] -eq 'ssh') {
      # Special SSH handling
      $remainingArgs = @("-o", "ProxyCommand=ncat --proxy-type socks5 --proxy $($proxyUrl -replace '.*://') %h %p")
      if ($args.Count -gt 1) {
        $remainingArgs += $args[1..($args.Count-1)]
      }
      if ($MyInvocation.ExpectingInput) {
        $input | & ssh @remainingArgs
      } else {
        & ssh @remainingArgs
      }
    } else {
      # Regular command execution with stdin forwarding
      $command = $args[0]
      $remainingArgs = @()
      if ($args.Count -gt 1) {
        $remainingArgs = $args[1..($args.Count-1)]
      }
      if ($MyInvocation.ExpectingInput) {
        # Forward stdin to the command
        $input | & $command @remainingArgs
      } else {
        & $command @remainingArgs
      }
    }
    
    # Preserve exit code from the command
    $exitCode = $LASTEXITCODE
  } finally {
    # Always restore original proxy settings, even on failure or Ctrl+C
    $env:HTTP_PROXY = $originalHttpProxy
    $env:HTTPS_PROXY = $originalHttpsProxy
    $env:ALL_PROXY = $originalAllProxy
    $env:NO_PROXY = $originalNoProxy
  }
  
  # Exit with the same code as the wrapped command
  if ($null -ne $exitCode) {
    exit $exitCode
  }
} else {
  # No arguments: enable proxy for current session
  return
}
