param (
  [string]
  $User,

  [string[]]
  [Parameter(Position=1, ValueFromRemainingArguments)]
  $Remaining
)

$hosts = @{}
$currentHost = $null

foreach ($line in [System.IO.File]::ReadLines("$HOME\.ssh\config"))
{
  $chunks = $line.Trim().Split()
  if ($chunks.Count -eq 2) {
    $key = $chunks[0]
    $value = $chunks[1]

    switch ($key) {
      "Host" {
        $currentHost = @{
          "hostname" = $value
        }
        $hosts[$value] = $currentHost
      }
      default {
        $currentHost[$key] = $value
      }
    }
  }
}

$selected = ($hosts.Keys | Invoke-Fzf)
if ($selected -ne $null) {
  $entry = $hosts[$selected]
  $hostname = $entry["hostname"]
  if ($User.Length -gt 0) {
    $hostname = "$User@$hostname"
  } elseif ($entry["user"]) {
    $hostname = "$($entry["user"])@$hostname"
  }

  $args = $Remaining + @($hostname)

  & putty $args
}
