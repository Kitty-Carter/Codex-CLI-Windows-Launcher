$env:HTTP_PROXY = "http://127.0.0.1:7897"
$env:HTTPS_PROXY = "http://127.0.0.1:7897"
$env:ALL_PROXY = "http://127.0.0.1:7897"
$env:NO_PROXY = "localhost,127.0.0.1,::1,.local,.lan,.cn"

Set-Location "C:\DIY\Codex CLI"
Write-Host ""
Write-Host "Codex temporary proxy enabled: http://127.0.0.1:7897" -ForegroundColor Green
Write-Host "Please login with this ChatGPT account:" -ForegroundColor Yellow
Write-Host "pobjmvy666@outlook.com" -ForegroundColor Cyan
Write-Host ""
Write-Host "Running: codex login --device-auth" -ForegroundColor Yellow
Write-Host ""

& "C:\Users\zyp31\AppData\Roaming\npm\codex.cmd" login --device-auth

Write-Host ""
Write-Host "Login step finished." -ForegroundColor Green
Read-Host "Press Enter to close this login window"
