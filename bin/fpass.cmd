@echo off
for /f "delims=" %%a in ('gopass list -f ^| fzf') do set "selected=%%a"
if [%selected%]==[] (
  exit /b 1
)
if [%1]==[] (
  gopass show -c %selected%
) else (
  gopass %* %selected%
)
