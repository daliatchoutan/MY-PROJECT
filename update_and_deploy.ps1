# NOVARA Automated Multi-Platform Build & Deployment Script
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "   NOVARA - Automated Web & Android APK Deployment       " -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Cyan

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# 1. Build Flutter Web
Write-Host "`n[1/5] Building Flutter Web Release..." -ForegroundColor Yellow
Set-Location -Path "$scriptDir\FRONT END"
flutter build web --release
if ($LASTEXITCODE -ne 0) {
    Write-Error "Flutter web compilation failed."
    exit $LASTEXITCODE
}

# 2. Build Flutter APK
Write-Host "`n[2/5] Building Android Release APK..." -ForegroundColor Yellow
flutter build apk --release
if ($LASTEXITCODE -ne 0) {
    Write-Error "Flutter Android APK compilation failed."
    exit $LASTEXITCODE
}

# 3. Sync Artifacts to Backend Public Directory
Write-Host "`n[3/5] Syncing Web Artifacts & APK to Backend Public Folder..." -ForegroundColor Yellow
Set-Location -Path $scriptDir
$publicPath = "$scriptDir\BACK END\public"
if (-not (Test-Path $publicPath)) {
    New-Item -ItemType Directory -Force -Path $publicPath | Out-Null
}
Copy-Item -Recurse -Force "$scriptDir\FRONT END\build\web\*" $publicPath

$downloadPath = "$publicPath\download"
if (-not (Test-Path $downloadPath)) {
    New-Item -ItemType Directory -Force -Path $downloadPath | Out-Null
}
Copy-Item -Force "$scriptDir\FRONT END\build\app\outputs\flutter-apk\app-release.apk" "$downloadPath\novara-latest.apk"
Set-Content -Path "$publicPath\_redirects" -Value "/*    /index.html   200"

# 4. Commit to Git
Write-Host "`n[4/5] Staging and Committing Changes to Git..." -ForegroundColor Yellow
git add .
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
git commit -m "deploy: update Web & Android APK release [$timestamp]"

# 5. Push to GitHub
Write-Host "`n[5/5] Pushing to GitHub (Triggers Railway & Netlify Deployments)..." -ForegroundColor Yellow
git push origin main
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to push to GitHub."
    exit $LASTEXITCODE
}

Write-Host "`n========================================================" -ForegroundColor Cyan
Write-Host "   SUCCESS! NOVARA Multi-Platform Deployment Complete!    " -ForegroundColor Green
Write-Host "   - Netlify Web App:    https://novara-poultry.netlify.app/" -ForegroundColor White
Write-Host "   - Railway Web & API:  https://my-project-production-f607.up.railway.app/" -ForegroundColor White
Write-Host "   - Android APK Direct: https://my-project-production-f607.up.railway.app/download/novara-latest.apk" -ForegroundColor White
Write-Host "   - In-App OTA Update:  Active" -ForegroundColor White
Write-Host "========================================================" -ForegroundColor Cyan
