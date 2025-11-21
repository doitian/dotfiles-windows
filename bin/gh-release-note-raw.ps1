# 1. Get the date of the last tag (to filter logs)
param(
    [string]$LastTag
)

if (-not $LastTag) {
    $LastTag = git describe --tags --abbrev=0
}
if (-not $LastTag -or $LastTag.Length -eq 0) {
    $LastTag = "4b825dc642cb6eb9a060e54bf8d69288fbee4904"
}

$Since = git log -n 1 --format="%cI" "$LastTag"

# 2. Generate the data dump
echo "--- START RAW DATA ---"

echo "Since $LastTag at $Since"

echo "`n### GIT LOGS ###"
git log "$LastTag..HEAD" --pretty=format:"%h - %an: %s"

echo "`n`n### MERGED PRS ###"
gh pr list -L 1000 --state merged --search "merged:>$Since" --json number,title,author,labels,body

echo "`n`n### CLOSED ISSUES ###"
gh issue list -L 1000 --state closed --search "closed:>$Since" --json number,title,labels

echo "`n--- END RAW DATA ---"
