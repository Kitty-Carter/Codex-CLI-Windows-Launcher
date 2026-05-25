@echo off
chcp 65001 >nul
set "BASE=C:\DIY\Codex CLI"
set "SCRIPT=C:\DIY\Codex CLI\CodexAccountSwitcherGUI.ps1"

if not exist "%SCRIPT%" (
  echo Cannot find:
  echo %SCRIPT%
  pause
  exit /b 1
)

powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File "%SCRIPT%"

if errorlevel 1 (
  echo.
  echo Codex account switcher failed.
  echo Please check logs under:
  echo %BASE%\logs
  echo.
  pause
)
