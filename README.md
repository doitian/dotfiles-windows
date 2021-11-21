# Windows Dotfiles

┌ 1. Use English as Windows Display Language

┌ 2. Create Junctions if Using D:\ as data disk

```
cd ~
New-Item -ItemType Junction -Path Documents -Value "D:\Documents"
New-Item -ItemType Junction -Path Desktop -Value "D:\Desktop"
New-Item -ItemType Junction -Path Downloads -Value D:\Downloads
New-Item -ItemType Junction -Path codebase -Value D:\codebase
```

┌ 3. Install scoop

Customize location

```
$env:SCOOP='D:\scoop'
[environment]::setEnvironmentVariable('SCOOP',$env:SCOOP,'User')
```

Install

```
iwr -useb get.scoop.sh | iex
```

Install essential apps

```
scoop bucket add extras
scoop install mingit gpg z posh-git starship delta
Install-Module -Name PSFzf -Scope CurrentUser
```

Fix the gpg bug by creating a link

```
New-Item -ItemType Junction -Path D:\scoop\persist\gpg\gnupg -Value D:\scoop\persist\gpg\home\
```

┌ 4. Run as user

```
./pre-setup
```

Restart the terminal app and continue. The script requires [PowerShell 7](https://github.com/PowerShell/PowerShell/releases).

```
./setup
```

┌ 5. Run as admin

```
./admin-setup
```

Restart

## Proxy

Start proxy first. Then configure proxy in system settings and:

```
scoop config proxy 127.0.0.1:7890
git config --global http.proxy http://127.0.0.1:7890
```
