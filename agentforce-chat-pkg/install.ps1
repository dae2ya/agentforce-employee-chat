# =============================================================================
# Agentforce Employee Chat — Deployment Script (Windows PowerShell)
# =============================================================================
# Usage:
#   Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
#   .\install.ps1                         # 기본: 현재 default org에 배포
#   .\install.ps1 -TargetOrg MY_ALIAS     # 특정 org에 배포
#   .\install.ps1 -DryRun                 # 검증만
# =============================================================================
param(
    [string]$TargetOrg = "",
    [switch]$DryRun
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SourceDir = $ScriptDir

Write-Host ""
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host "  Agentforce Employee Chat — Installation" -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host ""

if (-not (Get-Command sf -ErrorAction SilentlyContinue)) {
    Write-Host "❌  Salesforce CLI(sf) 가 설치되어 있지 않습니다." -ForegroundColor Red
    Write-Host "    https://developer.salesforce.com/tools/salesforcecli" -ForegroundColor Yellow
    exit 1
}

$DeployTarget = if ($TargetOrg) { $TargetOrg } else { "(default)" }
Write-Host "✔  배포 대상 org  : $DeployTarget" -ForegroundColor Green

if ($DryRun) {
    Write-Host "ℹ️  Dry-run 모드" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "📦  배포 시작..." -ForegroundColor Yellow
Write-Host ""

$Args = @(
    "project", "deploy", "start",
    "--manifest", "$SourceDir\package.xml",
    "--source-dir", "$SourceDir\main",
    "--ignore-conflicts"
)
if ($TargetOrg) { $Args += @("--target-org", $TargetOrg) }
if ($DryRun)    { $Args += "--dry-run" }

& sf @Args
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "❌  배포 실패." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=======================================================" -ForegroundColor Green
Write-Host "  ✅  배포 완료!" -ForegroundColor Green
Write-Host "=======================================================" -ForegroundColor Green
Write-Host ""
Write-Host "다음 단계:"
Write-Host "  1. Setup > Custom Labels > Agentforce_Employee_Agent_ApiName 값 변경"
Write-Host "  2. App Builder에서 LWC 컴포넌트 배치"
Write-Host "  3. Account Quick Action 등록"
Write-Host ""
