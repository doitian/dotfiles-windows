ls "$HOME\Dropbox\Brain\para\lets\c\Cheatsheets" | ? { -not $_.Name.StartsWith('♯ ') } | % { $_.FullName } | fzf -d "`\" --with-nth -1 -1 -q "$Args" | % { gc $_ }
