Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Continue"

$BaseDir = "C:\DIY\Codex CLI"
$CursorPathFile = Join-Path $BaseDir "cursor-path.txt"
$LastWorkspaceFile = Join-Path $BaseDir "cursor-last-workspace.txt"
$ProxyUrl = "http://127.0.0.1:7897"

New-Item -ItemType Directory -Force -Path $BaseDir | Out-Null

function Show-Info {
    param([string]$Message, [string]$Title = "Cursor Codex 启动器")
    [System.Windows.Forms.MessageBox]::Show($Message, $Title, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
}

function Show-Warning {
    param([string]$Message, [string]$Title = "Cursor Codex 启动器")
    [System.Windows.Forms.MessageBox]::Show($Message, $Title, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
}

function Ask-YesNoCancel {
    param([string]$Message, [string]$Title = "Cursor Codex 启动器")
    return [System.Windows.Forms.MessageBox]::Show($Message, $Title, [System.Windows.Forms.MessageBoxButtons]::YesNoCancel, [System.Windows.Forms.MessageBoxIcon]::Question)
}

function Select-CursorExe {
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Title = "请选择 Cursor.exe"
    $dialog.Filter = "Cursor.exe|Cursor.exe|EXE 文件 (*.exe)|*.exe|所有文件 (*.*)|*.*"

    $possibleDirs = @(
        "C:\cursor",
        "$env:LOCALAPPDATA\Programs\Cursor",
        "$env:LOCALAPPDATA\Programs\cursor",
        "$env:LOCALAPPDATA",
        "$env:ProgramFiles",
        "${env:ProgramFiles(x86)}"
    )

    foreach ($dir in $possibleDirs) {
        if ($dir -and (Test-Path $dir)) {
            $dialog.InitialDirectory = $dir
            break
        }
    }

    if ($dialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { return $null }
    return $dialog.FileName
}

function Get-CursorExe {
    if (Test-Path $CursorPathFile) {
        $saved = (Get-Content -Raw -Path $CursorPathFile -ErrorAction SilentlyContinue).Trim()
        if ($saved -and (Test-Path $saved)) { return $saved }
    }

    Show-Info "第一次使用需要选择 Cursor.exe。`n`n你当前常用路径可能是：`nC:\cursor\Cursor.exe"
    $selected = Select-CursorExe
    if (-not $selected) { return $null }
    if (-not (Test-Path $selected)) {
        Show-Warning "你选择的文件不存在：`n$selected"
        return $null
    }

    if ((Split-Path $selected -Leaf) -ne "Cursor.exe") {
        $confirm = [System.Windows.Forms.MessageBox]::Show(
            "你选择的文件不是 Cursor.exe：`n`n$selected`n`n仍然继续吗？",
            "Cursor Codex 启动器",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Question
        )
        if ($confirm -ne [System.Windows.Forms.DialogResult]::Yes) { return $null }
    }

    Set-Content -Encoding UTF8 -Path $CursorPathFile -Value $selected
    return $selected
}

function Select-WorkspaceFolder {
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = "请选择你真正想让 Cursor / Codex 读取的项目文件夹"
    $dialog.ShowNewFolderButton = $true

    $default = $BaseDir
    if (Test-Path $LastWorkspaceFile) {
        $last = (Get-Content -Raw -Path $LastWorkspaceFile -ErrorAction SilentlyContinue).Trim()
        if ($last -and (Test-Path $last)) { $default = $last }
    }
    $dialog.SelectedPath = $default

    if ($dialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { return $null }
    return $dialog.SelectedPath
}

$cursorExe = Get-CursorExe
if (-not $cursorExe) {
    Show-Warning "没有选择 Cursor.exe，启动已取消。"
    exit 1
}

$workspace = Select-WorkspaceFolder
if (-not $workspace) {
    Show-Warning "没有选择项目文件夹，启动已取消。"
    exit 1
}

if (-not (Test-Path $workspace)) {
    Show-Warning "选择的项目文件夹不存在：`n$workspace"
    exit 1
}

Set-Content -Encoding UTF8 -Path $LastWorkspaceFile -Value $workspace

$runningCursor = Get-Process -Name "Cursor" -ErrorAction SilentlyContinue
if ($runningCursor) {
    $choice = Ask-YesNoCancel "检测到 Cursor 已经在运行。`n`n为了让临时代理生效，建议关闭所有 Cursor 后重新打开。`n`n是 = 自动关闭旧 Cursor 后继续`n否 = 不关闭，直接继续`n取消 = 不启动"
    if ($choice -eq [System.Windows.Forms.DialogResult]::Cancel) { exit 0 }
    if ($choice -eq [System.Windows.Forms.DialogResult]::Yes) {
        Get-Process Cursor -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
    }
}

$env:HTTP_PROXY = $ProxyUrl
$env:HTTPS_PROXY = $ProxyUrl
$env:ALL_PROXY = $ProxyUrl
$env:NO_PROXY = "localhost,127.0.0.1,::1,.local,.lan,.cn"

Write-Host "Starting Cursor with temporary proxy for Codex..." -ForegroundColor Green
Write-Host "Cursor.exe:" -ForegroundColor Cyan
Write-Host $cursorExe
Write-Host "Workspace:" -ForegroundColor Cyan
Write-Host $workspace
Write-Host "Proxy:" -ForegroundColor Cyan
Write-Host $ProxyUrl

Start-Process -FilePath $cursorExe -ArgumentList "`"$workspace`""
Write-Host "Cursor started." -ForegroundColor Green
Start-Sleep -Seconds 2
