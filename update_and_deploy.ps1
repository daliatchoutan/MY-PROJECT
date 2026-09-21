# NOVARA Automated Web Build & Deployment Script
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "   NOVARA - Automated Web Build & Production Deployment   " -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Cyan

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# 1. Build Flutter Web
Write-Host "`n[1/4] Building Flutter Web Release..." -ForegroundColor Yellow
Set-Location -Path "$scriptDir\FRONT END"
flutter build web --release
if ($LASTEXITCODE -ne 0) {
    Write-Error "Flutter web compilation failed."
    exit $LASTEXITCODE
}

# 2. Sync to Backend Public Directory
Write-Host "`n[2/4] Syncing Web Artifacts to Backend Public Folder..." -ForegroundColor Yellow
Set-Location -Path $scriptDir
$publicPath = "$scriptDir\BACK END\public"
if (Test-Path $publicPath) {
    Remove-Item -Recurse -Force $publicPath
}
Copy-Item -Recurse -Force "$scriptDir\FRONT END\build\web" $publicPath

# 3. Commit to Git
Write-Host "`n[3/4] Staging and Committing Changes to Git..." -ForegroundColor Yellow
git add .
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
git commit -m "deploy: update web version and production backend [$timestamp]"

# 4. Push to GitHub
Write-Host "`n[4/4] Pushing to GitHub (Triggers Railway & GitHub Pages Auto-Deploy)..." -ForegroundColor Yellow
git push origin main
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to push to GitHub."
    exit $LASTEXITCODE
}

Write-Host "`n========================================================" -ForegroundColor Cyan
Write-Host "   SUCCESS! Deployment Initiated Automatically!           " -ForegroundColor Green
Write-Host "   - Railway Web & API: https://my-project-production-f607.up.railway.app/" -ForegroundColor White
Write-Host "   - GitHub Pages Web:  https://daliatchoutan.github.io/MY-PROJECT/" -ForegroundColor White
Write-Host "========================================================" -ForegroundColor Cyan
