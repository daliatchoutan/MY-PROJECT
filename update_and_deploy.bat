@echo off
setlocal enabledelayedexpansion

echo ========================================================
echo   NOVARA - Automated Multi-Platform Build & Deploy
echo   (Web App, Android APK, Railway API, Netlify)
echo ========================================================
echo.

echo [1/5] Building Flutter Web Release...
cd /d "%~dp0FRONT END"
call flutter build web --release
if %errorlevel% neq 0 (
    echo [ERROR] Flutter web compilation failed.
    exit /b %errorlevel%
)

echo.
echo [2/5] Building Android Release APK...
call flutter build apk --release
if %errorlevel% neq 0 (
    echo [ERROR] Flutter Android APK compilation failed.
    exit /b %errorlevel%
)

echo.
echo [3/5] Syncing Web Artifacts & APK to Backend Public Folder...
cd /d "%~dp0"
if not exist "BACK END\public" mkdir "BACK END\public"
xcopy /s /e /y /i "FRONT END\build\web\*" "BACK END\public\"

if not exist "BACK END\public\download" mkdir "BACK END\public\download"
copy /y "FRONT END\build\app\outputs\flutter-apk\app-release.apk" "BACK END\public\download\novara-latest.apk"
echo /* /index.html 200 > "BACK END\public\_redirects"

echo.
echo [4/5] Staging and Committing Changes to Git...
git add .
set COMMIT_MSG=deploy: update Web & Android APK release [%date% %time%]
git commit -m "%COMMIT_MSG%"

echo.
echo [5/5] Pushing to GitHub (Triggers Railway & Netlify Deployments)...
git push origin main
if %errorlevel% neq 0 (
    echo [ERROR] Failed to push to GitHub. Check your network or credentials.
    exit /b %errorlevel%
)

echo.
echo ========================================================
echo   SUCCESS! NOVARA Multi-Platform Deployment Initiated!
echo   - Netlify Web App:    https://novara-poultry.netlify.app/
echo   - Railway API & Web:  https://my-project-production-f607.up.railway.app/
echo   - Android APK Direct: https://my-project-production-f607.up.railway.app/download/novara-latest.apk
echo   - In-App OTA Update:  Active (Users are automatically notified to update)
echo ========================================================
pause
