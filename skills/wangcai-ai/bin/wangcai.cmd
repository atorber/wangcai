@echo off
REM Skill 入口（Windows）：调用同目录 wangcai-windows-x64.exe
setlocal
set "DIR=%~dp0"
if exist "%DIR%wangcai-windows-x64.exe" (
  "%DIR%wangcai-windows-x64.exe" %*
  exit /b %ERRORLEVEL%
)
echo 未找到 wangcai-windows-x64.exe，请从 CI 下载到本目录。 1>&2
exit /b 1
