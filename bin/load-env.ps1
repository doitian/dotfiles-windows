[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$EnvFilePath,

    [Parameter(Mandatory=$false)]
    [switch]$ForCmd
)

if (-not (Test-Path $EnvFilePath)) {
    Write-Error "Error: .env file not found at '$EnvFilePath'"
    exit 1
}

$commands = Get-Content $EnvFilePath | ForEach-Object {
    $line = $_.Trim()
    if (-not [string]::IsNullOrWhiteSpace($line) -and -not $line.StartsWith("#")) {
        $parts = $line.Split('=', 2)
        if ($parts.Length -eq 2) {
            $key = $parts[0].Trim()
            $value = $parts[1].Trim()

            # Remove surrounding quotes if present
            if (($value.StartsWith('"') -and $value.EndsWith('"')) -or ($value.StartsWith("'") -and $value.EndsWith("'"))) {
                $value = $value.Substring(1, $value.Length - 2)
            }
            
            # For cmd.exe, we need to handle special characters
            if ($ForCmd) {
                $escapedValue = $value.Replace('%', '%%').Replace('^', '^^').Replace('&', '^&').Replace('<', '^<').Replace('>', '^>').Replace('|', '^|')
                "SET ""$key=$escapedValue"""
            } else {
                @{ Key = $key; Value = $value }
            }
        }
    }
}

if ($ForCmd) {
    $tempBatchFile = [System.IO.Path]::GetTempFileName() + ".bat"
    $commands | Out-File -FilePath $tempBatchFile -Encoding oem
    Write-Output $tempBatchFile
} else {
    foreach ($command in $commands) {
        Set-Content -Path "Env:\$($command.Key)" -Value $command.Value
        Write-Verbose "Set environment variable: $($command.Key)"
    }
}