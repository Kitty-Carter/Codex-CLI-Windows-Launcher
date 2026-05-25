@echo off
chcp 65001 >nul
cd /d "C:\DIY\Codex CLI"

echo Codex device login helper
echo.
echo This window uses temporary proxy only.
echo.

set "HTTP_PROXY=http://127.0.0.1:7897"
set "HTTPS_PROXY=http://127.0.0.1:7897"
set "ALL_PROXY=http://127.0.0.1:7897"
set "NO_PROXY=localhost,127.0.0.1,::1,.local,.lan,.cn"

echo Running:
echo codex login --device-auth
echo.

where codex.cmd >nul 2>nul
if errorlevel 1 (
  echo Cannot find codex.cmd. Trying codex...
  codex login --device-auth
) else (
  codex.cmd login --device-auth
)

echo.
echo Login command finished.
echo.
pause
