@echo off
chcp 65001 >nul
cd /d "C:\DIY\Codex CLI"
echo.
echo ===============================
echo Checking current Codex account
echo ===============================
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\DIY\Codex CLI\Check-CodexAccount.ps1"
echo.
echo ===============================
echo Finished
echo ===============================
echo.
pause
