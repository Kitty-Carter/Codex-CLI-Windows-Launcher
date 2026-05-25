$ErrorActionPreference = "Continue"

$ProxyUrl = "http://127.0.0.1:7897"
$CurrentPath = (Get-Location).Path.TrimEnd("\")
$BaseDir = "C:\DIY\Codex CLI"

function Stop-InUnsafeDirectory {
    param([string]$Message)

    Write-Host $Message -ForegroundColor Red
    Write-Host $CurrentPath -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Please switch to a specific working folder first, for example:" -ForegroundColor Cyan
    Write-Host 'cd "C:\DIY\Codex CLI"' -ForegroundColor Cyan
    Write-Host "codex" -ForegroundColor Cyan
    exit 1
}

$blockedTrees = @(
    "C:\Windows",
    "C:\Program Files",
    "C:\Program Files (x86)"
)

foreach ($blocked in $blockedTrees) {
    $clean = $blocked.TrimEnd("\")
    if ($CurrentPath -ieq $clean -or $CurrentPath.StartsWith($clean + "\", [System.StringComparison]::OrdinalIgnoreCase)) {
        Stop-InUnsafeDirectory "Refusing to run Codex CLI in unsafe directory:"
    }
}

$blockedExactPaths = @(
    "C:\Users\zyp31"
)

foreach ($blocked in $blockedExactPaths) {
    $clean = $blocked.TrimEnd("\")
    if ($CurrentPath -ieq $clean) {
        Stop-InUnsafeDirectory "Refusing to run Codex CLI in broad user directory:"
    }
}

function Test-IsGitRepo {
    try {
        $out = git rev-parse --is-inside-work-tree 2>$null
        return ($LASTEXITCODE -eq 0 -and $out -eq "true")
    } catch {
        return $false
    }
}

function Get-CodexCommandPath {
    $cmd = Get-Command codex.cmd -CommandType Application -ErrorAction SilentlyContinue
    if ($cmd -and $cmd.Source) { return $cmd.Source }

    $exe = Get-Command codex.exe -CommandType Application -ErrorAction SilentlyContinue
    if ($exe -and $exe.Source) { return $exe.Source }

    return $null
}

$hadHttpProxy  = Test-Path Env:\HTTP_PROXY
$hadHttpsProxy = Test-Path Env:\HTTPS_PROXY
$hadAllProxy   = Test-Path Env:\ALL_PROXY
$hadNoProxy    = Test-Path Env:\NO_PROXY

$oldHttpProxy  = $env:HTTP_PROXY
$oldHttpsProxy = $env:HTTPS_PROXY
$oldAllProxy   = $env:ALL_PROXY
$oldNoProxy    = $env:NO_PROXY

$exitCode = 0

try {
    $env:HTTP_PROXY  = $ProxyUrl
    $env:HTTPS_PROXY = $ProxyUrl
    $env:ALL_PROXY   = $ProxyUrl
    $env:NO_PROXY    = "localhost,127.0.0.1,::1,.local,.lan,.cn"

    Write-Host "Codex CLI proxy enabled: $ProxyUrl" -ForegroundColor Green

    $codexCommand = Get-CodexCommandPath
    if (-not $codexCommand) {
        Write-Host "Cannot find codex.cmd or codex.exe. Please check Codex CLI installation." -ForegroundColor Red
        $exitCode = 1
        return
    }

    $finalArgs = @($args)

    if ($finalArgs.Count -gt 0 -and ($finalArgs[0] -eq "exec" -or $finalArgs[0] -eq "e")) {
        $hasSkip = $false
        foreach ($a in $finalArgs) {
            if ($a -eq "--skip-git-repo-check") { $hasSkip = $true }
        }

        if (-not $hasSkip -and -not (Test-IsGitRepo)) {
            Write-Host "Non-Git folder detected. Adding --skip-git-repo-check automatically." -ForegroundColor Yellow
            if ($finalArgs.Count -eq 1) {
                $finalArgs = @($finalArgs[0], "--skip-git-repo-check")
            } else {
                $finalArgs = @($finalArgs[0], "--skip-git-repo-check") + $finalArgs[1..($finalArgs.Count - 1)]
            }
        }
    }

    & $codexCommand @finalArgs
    $exitCode = if ($null -ne $LASTEXITCODE) { $LASTEXITCODE } else { 0 }
}
finally {
    if ($hadHttpProxy)  { $env:HTTP_PROXY = $oldHttpProxy }  else { Remove-Item Env:\HTTP_PROXY -ErrorAction SilentlyContinue }
    if ($hadHttpsProxy) { $env:HTTPS_PROXY = $oldHttpsProxy } else { Remove-Item Env:\HTTPS_PROXY -ErrorAction SilentlyContinue }
    if ($hadAllProxy)   { $env:ALL_PROXY = $oldAllProxy }     else { Remove-Item Env:\ALL_PROXY -ErrorAction SilentlyContinue }
    if ($hadNoProxy)    { $env:NO_PROXY = $oldNoProxy }       else { Remove-Item Env:\NO_PROXY -ErrorAction SilentlyContinue }

    Write-Host "Codex CLI proxy restored." -ForegroundColor Yellow
}

exit $exitCode
