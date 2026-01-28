@echo off
setlocal

set "filepath=%~1"
set "linenum=%~2"

if not defined NVIM goto :eof

REM Convert backslashes to forward slashes for vim
set "vimpath=%filepath:\=/%"

if defined linenum (
    start /b "" nvim --server "%NVIM%" --remote-send "<C-\><C-N>:bd!<CR>:drop %vimpath%|%linenum%<CR>"
) else (
    start /b "" nvim --server "%NVIM%" --remote-send "<C-\><C-N>:bd!<CR>:drop %vimpath%<CR>"
)