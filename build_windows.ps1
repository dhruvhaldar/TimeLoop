# build_windows.ps1
# This script builds the TimeLoop Windows executable and organizes it into a timestamped directory.

Set-Location $PSScriptRoot

Write-Host "Starting Windows Build..." -ForegroundColor Cyan

# 1. Build the project
# Ensure flutter is in your PATH
flutter build windows --release

if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed! Please ensure Flutter is installed and in your PATH." -ForegroundColor Red
    exit $LASTEXITCODE
}

# 2. Create timestamped directory
$timestamp = Get-Date -Format "yyyyMMdd_HHmm"
$buildsDir = Join-Path $PSScriptRoot "windows_builds"
$targetDir = Join-Path $buildsDir $timestamp

Write-Host "Copying artifacts to $targetDir..." -ForegroundColor Cyan

if (!(Test-Path $buildsDir)) {
    New-Item -ItemType Directory -Path $buildsDir
}

New-Item -ItemType Directory -Path $targetDir

# 3. Copy artifacts
$sourceDir = Join-Path $PSScriptRoot "build\windows\x64\runner\Release"
Copy-Item -Path "$sourceDir\*" -Destination $targetDir -Recurse -Force

Write-Host "Build completed successfully!" -ForegroundColor Green
Write-Host "Artifacts located in: $targetDir" -ForegroundColor Yellow
