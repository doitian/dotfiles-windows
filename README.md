# Windows Dotfiles

┌ 1. Use English as Windows Display Language

┌ 2. Install OneDrive

┌ 3. Create Junctions

```
cd ~
New-Item -ItemType Junction -Path Documents -Value "$env:OneDrive\Documents"
New-Item -ItemType Junction -Path Desktop -Value "$env:OneDrive\桌面"
New-Item -ItemType Junction -Path .dotfiles -Value D:\dotfiles\dotfiles
New-Item -ItemType Junction -Path .vim -Value D:\dotfiles\vim
New-Item -ItemType Junction -Path Downloads -Value D:\Downloads
New-Item -ItemType Junction -Path codebase -Value D:\codebase
```

┌ 4. Install scoop

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
scoop install mingit gpg z
```

┌ 5. Run as admin

```
./admin-setup.ps1`
```

┌ 6. Run as user

```
./setup
```
