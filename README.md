# Windows Dotfiles

## Setup

Save this repo as `Documents\PowerShell`.

┌ 1. Use English as Windows Display Language

┌ 2. Create Junctions if Using D:\ as data disk

```powershell
cd ~
New-Item -ItemType Junction -Path Documents -Value "D:\Documents"
New-Item -ItemType Junction -Path Desktop -Value "D:\Desktop"
New-Item -ItemType Junction -Path Downloads -Value D:\Downloads
New-Item -ItemType Junction -Path codebase -Value D:\codebase
```

┌ 3. Install scoop

Customize location

```powershell
$env:SCOOP = "D:\scoop"
# or use default $env:SCOOP = "$HOME\scoop"
[environment]::setEnvironmentVariable("SCOOP", $env:SCOOP, "User")
```

Install

```powershell
iwr -useb get.scoop.sh | iex
```

Install essential apps

```powershell
scoop bucket add extras
scoop install mingit gpg zoxide starship less wsl-ssh-pageant
Install-Module -Name PSFzf -Scope CurrentUser
Install-Module -Name cd-extras -Scope CurrentUser
```

Fix the gpg bug by creating a link

```powershell
New-Item -ItemType Junction -Path D:\scoop\persist\gpg\gnupg -Value D:\scoop\persist\gpg\home\
```

┌ 4. Run as user

```powershell
./pre-setup
```

Restart the terminal app and continue. The script requires [PowerShell 7](https://github.com/PowerShell/PowerShell/releases).

```powershell
./setup
```

┌ 5. Run as admin

```powershell
./admin-setup
```

Restart

## Proxy

Start proxy first. Then configure proxy in system settings and:

```
scoop config proxy 127.0.0.1:7890
git config --global http.proxy http://127.0.0.1:7890
```
