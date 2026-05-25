param(
    [string]$ExpectedEmail = ""
)

$ErrorActionPreference = "Continue"

$BaseDir = "C:\DIY\Codex CLI"
$BackupDir = Join-Path $BaseDir "backup"
$CodexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $HOME ".codex" }
$AuthPath = Join-Path $CodexHome "auth.json"

function Convert-Base64UrlToString {
    param([string]$InputText)
    try {
        $s = $InputText.Replace("-", "+").Replace("_", "/")
        switch ($s.Length % 4) {
            2 { $s += "==" }
            3 { $s += "=" }
        }
        $bytes = [Convert]::FromBase64String($s)
        return [Text.Encoding]::UTF8.GetString($bytes)
    } catch {
        return $null
    }
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

function Get-CodexAccountFromFile {
    param([string]$Path)

    $result = [ordered]@{
        Path = $Path
        Exists = $false
        AuthMode = ""
        AccountId = ""
        Emails = @()
    }

    if (-not (Test-Path $Path)) { return [pscustomobject]$result }
    $result.Exists = $true
    $raw = Get-Content -Raw -Path $Path -ErrorAction SilentlyContinue
    if (-not $raw) { return [pscustomobject]$result }

    if ($raw -match '"auth_mode"\s*:\s*"([^"]+)"') { $result.AuthMode = $Matches[1] }
    if ($raw -match '"account_id"\s*:\s*"([^"]+)"') { $result.AccountId = $Matches[1] }

    $emails = New-Object System.Collections.Generic.List[string]
    $emailMatches = [regex]::Matches($raw, "[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}", "IgnoreCase")
    foreach ($m in $emailMatches) { Add-Unique $emails $m.Value }

    $jwtMatches = [regex]::Matches($raw, "[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+")
    foreach ($m in $jwtMatches) {
        $payload = Try-DecodeJwtPayload $m.Value
        if ($null -eq $payload) { continue }
        if ($payload.email) { Add-Unique $emails ([string]$payload.email) }
        if ($payload.preferred_username) { Add-Unique $emails ([string]$payload.preferred_username) }
        if ($payload.upn) { Add-Unique $emails ([string]$payload.upn) }
    }

    $result.Emails = @($emails)
    return [pscustomobject]$result
}

function Print-Account {
    param([string]$Title, [object]$Account)

    Write-Host ""
    Write-Host "===== $Title =====" -ForegroundColor Cyan
    if (-not $Account.Exists) {
        Write-Host "未找到 auth.json。" -ForegroundColor Yellow
        Write-Host "路径：$($Account.Path)"
        return
    }

    Write-Host "文件：$($Account.Path)"
    Write-Host "auth_mode：$($Account.AuthMode)"
    Write-Host "account_id：$($Account.AccountId)"

    if ($Account.Emails.Count -gt 0) {
        Write-Host "邮箱候选：" -ForegroundColor Green
        foreach ($email in $Account.Emails) { Write-Host " - $email" -ForegroundColor Green }
    } else {
        Write-Host "邮箱候选：未找到明文邮箱" -ForegroundColor Yellow
    }
}

Write-Host "=== Codex 账号检查工具 ===" -ForegroundColor Cyan
Write-Host "CodexHome: $CodexHome"
Write-Host "AuthPath:  $AuthPath"

$current = Get-CodexAccountFromFile -Path $AuthPath
Print-Account -Title "当前 Codex 账号" -Account $current

$latestOldAuth = $null
if (Test-Path $BackupDir) {
    $latestOldAuth = Get-ChildItem $BackupDir -Filter "auth.json.*" -File -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
}

if ($latestOldAuth) {
    $old = Get-CodexAccountFromFile -Path $latestOldAuth.FullName
    Print-Account -Title "最近一次备份的旧账号" -Account $old

    Write-Host ""
    Write-Host "===== 换号判断 =====" -ForegroundColor Cyan
    if ($current.AccountId -and $old.AccountId) {
        if ($current.AccountId -ne $old.AccountId) {
            Write-Host "结论：account_id 已变化，大概率换号成功。" -ForegroundColor Green
            Write-Host "旧 account_id：$($old.AccountId)"
            Write-Host "新 account_id：$($current.AccountId)"
        } else {
            Write-Host "结论：account_id 没变化，看起来还没有换号成功。" -ForegroundColor Yellow
            Write-Host "当前 account_id：$($current.AccountId)"
        }
    } else {
        Write-Host "结论：无法通过 account_id 判断。" -ForegroundColor Yellow
    }
} else {
    Write-Host ""
    Write-Host "没有找到旧 auth.json 备份，无法和旧账号对比。" -ForegroundColor Yellow
}

if ($ExpectedEmail) {
    Write-Host ""
    Write-Host "===== 目标邮箱判断 =====" -ForegroundColor Cyan
    if ($current.Emails -contains $ExpectedEmail) {
        Write-Host "结论：检测到目标邮箱。" -ForegroundColor Green
    } else {
        Write-Host "结论：没有在当前 auth.json 中检测到目标邮箱。" -ForegroundColor Yellow
        Write-Host "这不一定代表失败，因为 Codex 有时不会明文保存邮箱。"
        Write-Host "目标邮箱：$ExpectedEmail"
    }
}

Write-Host ""
Write-Host "注意：不要把 auth.json、access_token、refresh_token、API Key 发给任何人。" -ForegroundColor Yellow
