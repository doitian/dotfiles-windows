@ECHO OFF
REM Without a command, leave the proxy set in the calling session
if not "%~1"=="" SETLOCAL
SET NO_PROXY=localhost, 127.0.0.1, ::1
if defined GFW_PROXY (
  SET HTTP_PROXY=http://%GFW_PROXY%
  SET HTTPS_PROXY=http://%GFW_PROXY%
  SET ALL_PROXY=http://%GFW_PROXY%
) else (
  SET HTTP_PROXY=http://127.0.0.1:7890
  SET HTTPS_PROXY=http://127.0.0.1:7890
  SET ALL_PROXY=http://127.0.0.1:7890
)
%*
