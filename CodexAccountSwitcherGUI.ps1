Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Continue"

$BaseDir = "C:\DIY\Codex CLI"
$BackupDir = Join-Path $BaseDir "backup"
$LogDir = Join-Path $BaseDir "logs"
$ProxyUrl = "http://127.0.0.1:7897"
$CodexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $HOME ".codex" }
$AuthPath = Join-Path $CodexHome "auth.json"

New-Item -ItemType Directory -Force -Path $BaseDir | Out-Null
New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null

$LogFile = Join-Path $LogDir ("CodexAccountSwitcher-" + (Get-Date -Format "yyyyMMdd-HHmmss") + ".log")

function Log {
    param([string]$Text)
    $line = "[" + (Get-Date -Format "HH:mm:ss") + "] " + $Text
    Add-Content -Encoding UTF8 -Path $LogFile -Value $line
    if ($script:LogBox) {
        $script:LogBox.AppendText($line + [Environment]::NewLine)
        $script:LogBox.SelectionStart = $script:LogBox.Text.Length
        $script:LogBox.ScrollToCaret()
        [System.Windows.Forms.Application]::DoEvents()
    }
}

function Convert-Base64UrlToString {
    param([string]$InputText)
    try {
        $s = $InputText.Replace("-", "+").Replace("_", "/")
        switch ($s.Length % 4) {
            2 { $s += "==" }
            3 { $s += "=" }
        }
        return [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($s))
    } catch { return $null }
}

function Try-DecodeJwtPayload {
    param([string]$Token)
    if (-not $Token) { return $null }
    $parts = $Token.Split(".")
    if ($parts.Count -ne 3) { return $null }
    $payloadJson = Convert-Base64UrlToString $parts[1]
    if (-not $payloadJson) { return $null }
    try { return $payloadJson | ConvertFrom-Json } catch { return $null }
}

function Add-Unique {
    param([System.Collections.Generic.List[string]]$List, [string]$Value)
    if ($Value -and -not $List.Contains($Value)) { $List.Add($Value) | Out-Null }
}

function Get-CodexAccountSummary {
    $result = [ordered]@{ AuthExists = $false; AuthMode = ""; AccountId = ""; Emails = @() }
    if (-not (Test-Path $AuthPath)) { return [pscustomobject]$result }
    $result.AuthExists = $true
    $raw = Get-Content -Raw -Path $AuthPath -ErrorAction SilentlyContinue
    if (-not $raw) { return [pscustomobject]$result }

    if ($raw -match '"auth_mode"\s*:\s*"([^"]+)"') { $result.AuthMode = $Matches[1] }
    if ($raw -match '"account_id"\s*:\s*"([^"]+)"') { $result.AccountId = $Matches[1] }

    $emails = New-Object System.Collections.Generic.List[string]
    [regex]::Matches($raw, "[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}", "IgnoreCase") | ForEach-Object { Add-Unique $emails $_.Value }
    [regex]::Matches($raw, "[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+") | ForEach-Object {
        $payload = Try-DecodeJwtPayload $_.Value
        if ($payload) {
            if ($payload.email) { Add-Unique $emails ([string]$payload.email) }
            if ($payload.preferred_username) { Add-Unique $emails ([string]$payload.preferred_username) }
            if ($payload.upn) { Add-Unique $emails ([string]$payload.upn) }
        }
    }
    $result.Emails = @($emails)
    return [pscustomobject]$result
}

function Show-CurrentAccount {
    Log "========== Current Codex Account =========="
    Log ("Codex home: " + $CodexHome)
    Log ("Auth file: " + $AuthPath)
    $summary = Get-CodexAccountSummary
    if (-not $summary.AuthExists) { Log "auth.json not found. Codex may be logged out."; return }
    Log ("auth_mode: " + $(if ($summary.AuthMode) { $summary.AuthMode } else { "<not found>" }))
    Log ("account_id: " + $(if ($summary.AccountId) { $summary.AccountId } else { "<not found>" }))
    if ($summary.Emails.Count -gt 0) { Log "email candidates:"; foreach ($e in $summary.Emails) { Log ("- " + $e) } } else { Log "email candidates: <not found>" }
    Log ""
}

function Switch-CodexAccount {
    $expectedEmail = $script:EmailBox.Text.Trim()
    if (-not $expectedEmail) {
        [System.Windows.Forms.MessageBox]::Show("请输入你想切换到的 ChatGPT 邮箱。", "Codex 换号", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
        return
    }

    $confirm = [System.Windows.Forms.MessageBox]::Show(
        "即将切换 Codex 到：" + [Environment]::NewLine + $expectedEmail + [Environment]::NewLine + [Environment]::NewLine +
        "脚本会备份旧 auth.json、清除旧登录，然后打开 device-auth 登录窗口。" + [Environment]::NewLine +
        "你仍然需要在浏览器里选择/登录这个 ChatGPT 账号。" + [Environment]::NewLine + [Environment]::NewLine + "继续吗？",
        "确认换号", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question
    )
    if ($confirm -ne [System.Windows.Forms.DialogResult]::Yes) { Log "Cancelled."; return }

    Log "========== Start Switching =========="
    Log ("Expected email: " + $expectedEmail)

    $codexCmd = Get-Command codex.cmd -CommandType Application -ErrorAction SilentlyContinue
    if (-not $codexCmd) {
        Log "ERROR: codex.cmd not found."
        [System.Windows.Forms.MessageBox]::Show("找不到 codex.cmd。请确认 Codex CLI 已安装。", "错误", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
        return
    }

    if (Test-Path $AuthPath) {
        $backupPath = Join-Path $BackupDir ("auth.json.backup-" + (Get-Date -Format "yyyyMMdd-HHmmss"))
        Copy-Item $AuthPath $backupPath -Force
        Log ("Backed up auth.json to: " + $backupPath)
    }

    Log "Running codex logout..."
    try { & $codexCmd.Source logout 2>&1 | ForEach-Object { Log ([string]$_) } } catch { Log ("codex logout error: " + $_.Exception.Message) }

    if (Test-Path $AuthPath) {
        $disabledPath = Join-Path $BackupDir ("auth.json.disabled-" + (Get-Date -Format "yyyyMMdd-HHmmss"))
        Move-Item $AuthPath $disabledPath -Force
        Log ("Moved old auth.json to: " + $disabledPath)
    }

    $loginScript = Join-Path $BaseDir "Run-CodexLoginOnce.ps1"
    $codexCmdPath = $codexCmd.Source
    $loginScriptText = @"
`$env:HTTP_PROXY = "$ProxyUrl"
`$env:HTTPS_PROXY = "$ProxyUrl"
`$env:ALL_PROXY = "$ProxyUrl"
`$env:NO_PROXY = "localhost,127.0.0.1,::1,.local,.lan,.cn"

Set-Location "$BaseDir"
Write-Host ""
Write-Host "Codex temporary proxy enabled: $ProxyUrl" -ForegroundColor Green
Write-Host "Please login with this ChatGPT account:" -ForegroundColor Yellow
Write-Host "$expectedEmail" -ForegroundColor Cyan
Write-Host ""
Write-Host "Running: codex login --device-auth" -ForegroundColor Yellow
Write-Host ""

& "$codexCmdPath" login --device-auth

Write-Host ""
Write-Host "Login step finished." -ForegroundColor Green
Read-Host "Press Enter to close this login window"
"@
    Set-Content -Encoding UTF8 -Path $loginScript -Value $loginScriptText

    Log ("Login helper script: " + $loginScript)
    $psExe = Join-Path $env:SystemRoot "System32\WindowsPowerShell\v1.0\powershell.exe"
    $psArgs = "-NoProfile -ExecutionPolicy Bypass -File `"$loginScript`""
    try {
        $p = Start-Process -FilePath $psExe -ArgumentList $psArgs -Wait -PassThru
        Log ("Login window exit code: " + $p.ExitCode)
    } catch { Log ("Failed to start login window: " + $_.Exception.Message) }

    Log "Checking new Codex account..."
    $newSummary = Get-CodexAccountSummary
    Log "========== New Codex Account =========="
    if (-not $newSummary.AuthExists) {
        Log "ERROR: auth.json still not found. Login may have failed."
        [System.Windows.Forms.MessageBox]::Show("登录后仍然没有找到 auth.json。可能登录失败，或者 Codex 使用了系统凭据存储。", "需要检查", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
        return
    }
    Log ("auth_mode: " + $(if ($newSummary.AuthMode) { $newSummary.AuthMode } else { "<not found>" }))
    Log ("account_id: " + $(if ($newSummary.AccountId) { $newSummary.AccountId } else { "<not found>" }))
    if ($newSummary.Emails.Count -gt 0) { Log "email candidates:"; foreach ($e in $newSummary.Emails) { Log ("- " + $e) } } else { Log "email candidates: <not found>" }

    if ($newSummary.Emails -contains $expectedEmail) {
        Log "SUCCESS: expected email detected."
        [System.Windows.Forms.MessageBox]::Show("换号成功，检测到邮箱：" + $expectedEmail, "Codex 换号成功", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
    } else {
        Log "WARNING: expected email was not detected from local cache."
        [System.Windows.Forms.MessageBox]::Show("登录流程已结束，但本地缓存没有明确检测到目标邮箱。`n这不一定代表失败，因为 Codex 可能不在 auth.json 中明文保存邮箱。", "需要人工确认", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
    }
    Log ""
}

try {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Codex 懒人换号工具"
    $form.Size = New-Object System.Drawing.Size(780, 570)
    $form.StartPosition = "CenterScreen"

    $title = New-Object System.Windows.Forms.Label
    $title.Text = "Codex 懒人换号工具"
    $title.Font = New-Object System.Drawing.Font("Microsoft YaHei UI", 16, [System.Drawing.FontStyle]::Bold)
    $title.Location = New-Object System.Drawing.Point(20, 15)
    $title.Size = New-Object System.Drawing.Size(700, 35)
    $form.Controls.Add($title)

    $desc = New-Object System.Windows.Forms.Label
    $desc.Text = "输入目标 ChatGPT 邮箱，点一键换号。密码和验证码仍然在浏览器里输入，脚本不会保存。"
    $desc.Location = New-Object System.Drawing.Point(22, 58)
    $desc.Size = New-Object System.Drawing.Size(720, 40)
    $form.Controls.Add($desc)

    $emailLabel = New-Object System.Windows.Forms.Label
    $emailLabel.Text = "目标邮箱："
    $emailLabel.Location = New-Object System.Drawing.Point(22, 112)
    $emailLabel.Size = New-Object System.Drawing.Size(100, 28)
    $form.Controls.Add($emailLabel)

    $script:EmailBox = New-Object System.Windows.Forms.TextBox
    $script:EmailBox.Location = New-Object System.Drawing.Point(125, 108)
    $script:EmailBox.Size = New-Object System.Drawing.Size(420, 28)
    $form.Controls.Add($script:EmailBox)

    $btnCurrent = New-Object System.Windows.Forms.Button
    $btnCurrent.Text = "查看当前账号"
    $btnCurrent.Location = New-Object System.Drawing.Point(565, 105)
    $btnCurrent.Size = New-Object System.Drawing.Size(150, 35)
    $btnCurrent.Add_Click({ Show-CurrentAccount })
    $form.Controls.Add($btnCurrent)

    $btnSwitch = New-Object System.Windows.Forms.Button
    $btnSwitch.Text = "一键换号"
    $btnSwitch.Font = New-Object System.Drawing.Font("Microsoft YaHei UI", 11, [System.Drawing.FontStyle]::Bold)
    $btnSwitch.Location = New-Object System.Drawing.Point(22, 155)
    $btnSwitch.Size = New-Object System.Drawing.Size(150, 42)
    $btnSwitch.Add_Click({ Switch-CodexAccount })
    $form.Controls.Add($btnSwitch)

    $btnFolder = New-Object System.Windows.Forms.Button
    $btnFolder.Text = "打开工具目录"
    $btnFolder.Location = New-Object System.Drawing.Point(190, 155)
    $btnFolder.Size = New-Object System.Drawing.Size(140, 42)
    $btnFolder.Add_Click({ Start-Process $BaseDir })
    $form.Controls.Add($btnFolder)

    $btnCodexHome = New-Object System.Windows.Forms.Button
    $btnCodexHome.Text = "打开 .codex"
    $btnCodexHome.Location = New-Object System.Drawing.Point(345, 155)
    $btnCodexHome.Size = New-Object System.Drawing.Size(130, 42)
    $btnCodexHome.Add_Click({ Start-Process $CodexHome })
    $form.Controls.Add($btnCodexHome)

    $btnLog = New-Object System.Windows.Forms.Button
    $btnLog.Text = "打开日志"
    $btnLog.Location = New-Object System.Drawing.Point(490, 155)
    $btnLog.Size = New-Object System.Drawing.Size(110, 42)
    $btnLog.Add_Click({ if (Test-Path $LogFile) { notepad $LogFile } })
    $form.Controls.Add($btnLog)

    $script:LogBox = New-Object System.Windows.Forms.TextBox
    $script:LogBox.Multiline = $true
    $script:LogBox.ScrollBars = "Vertical"
    $script:LogBox.ReadOnly = $true
    $script:LogBox.Font = New-Object System.Drawing.Font("Consolas", 10)
    $script:LogBox.Location = New-Object System.Drawing.Point(22, 215)
    $script:LogBox.Size = New-Object System.Drawing.Size(720, 300)
    $form.Controls.Add($script:LogBox)

    Log "Ready."
    Log ("BaseDir: " + $BaseDir)
    Log ("CodexHome: " + $CodexHome)
    Log ("AuthPath: " + $AuthPath)
    Log ("LogFile: " + $LogFile)
    Log ""

    [void]$form.ShowDialog()
} catch {
    $msg = $_.Exception.Message
    Add-Content -Encoding UTF8 -Path $LogFile -Value ("FATAL: " + $msg)
    [System.Windows.Forms.MessageBox]::Show("GUI 启动失败：`n$msg`n`n日志：$LogFile", "Codex 换号工具错误", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
    exit 1
}
