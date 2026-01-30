param(
    [Parameter(Mandatory=$true)]
    [string]$SessionName
)

$pwshCommand = "exec pwsh.exe -nologo"

# Check if session exists using exact name match
wsl tmux has-session -t "\=$SessionName" 2>$null

if ($LASTEXITCODE -ne 0) {
    wsl tmux new-session -d -s $SessionName $pwshCommand
    echo "set-option default-command `"$pwshCommand`"" | `
        wsl tmux -C attach -t "\=$SessionName" >$null
}
wsl tmux attach -t "\=$SessionName"