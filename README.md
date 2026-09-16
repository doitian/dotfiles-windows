# Windows Dotfiles

## Scoop bucket

This repo also provides a [Scoop](https://scoop.sh/) bucket with manifests in [`bucket/`](bucket/).

To register a local checkout, commit the bucket files first, then run the following commands. Adjust the path if the repo is stored elsewhere.

```powershell
scoop bucket add doitian file:///C:/Users/me/Documents/PowerShell
scoop install doitian/tty7
```

Scoop creates a separate clone from the local repo, so uncommitted changes are not included. No GitHub push is required. If `doitian` is already registered, remove the existing registration with `scoop bucket rm doitian` before adding it again.

To register from GitHub instead:

```powershell
scoop bucket add doitian https://github.com/doitian/dotfiles-windows
```

[tty7](https://github.com/l0ng-ai/tty7) is available for 64-bit Windows, with the `tty7` and `tty7-app` commands and a Start menu shortcut. Its manifest is based on [dodorz/scoop](https://github.com/dodorz/scoop/blob/master/bucket/tty7.json).

After committing manifest updates to the local repo, refresh the bucket and update the installed copy:

```powershell
scoop update
scoop update tty7
```

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
scoop install git gpg4win less wsl-ssh-pageant
```

┌ 4. Run as user

```powershell
./pre-setup
```

Restart the terminal app and continue. The script requires [PowerShell 7](https://github.com/PowerShell/PowerShell/releases).

```powershell
./setup
```

## Proxy

Start proxy first. Then configure proxy in system settings and:

```
scoop config proxy 127.0.0.1:7890
git config --global http.proxy http://127.0.0.1:7890
```
