# Windows Dotfiles

┌ 1. Use English as Windows Display Language

┌ 2. Create Junctions if Using D:\ as data disk

```
cd ~
New-Item -ItemType Junction -Path Documents -Value "D:\Documents"
New-Item -ItemType Junction -Path Desktop -Value "D:\Desktop"
mkdir -Fo .dotfiles
New-Item -ItemType Junction -Path .dotfiles\repos -Value D:\codebase\my\dotfiles\repos
New-Item -ItemType Junction -Path .vim -Value D:\codebase\my\dotfiles\vim
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
scoop install mingit gpg z putty
Install-Module -Name PSFzf -Scope CurrentUser
```

┌ 4. Run as user

```
./pre-setup
```

Restart the terminal app and continue.

```
./setup
```

┌ 5. Run as admin

```
./admin-setup
Win10-Initial-Setup-Script-master/Default.cmd
```

Restart

