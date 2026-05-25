@echo off
chcp 65001 >nul
set "SCRIPT=C:\DIY\Codex CLI\Launch-Cursor-Codex.ps1"

if not exist "%SCRIPT%" (
  echo Cannot find:
  echo %SCRIPT%
  echo.
  pause
  exit /b 1
)

powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File "%SCRIPT%"

if errorlevel 1 (
  echo.
  echo Cursor Codex launcher failed.
  echo.
  pause
)
