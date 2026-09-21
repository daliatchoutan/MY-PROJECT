@echo off
setlocal enabledelayedexpansion

echo ========================================================
echo   NOVARA - Automated Web Build ^& Production Deployment
echo ========================================================
echo.

echo [1/4] Building Flutter Web Release...
cd /d "%~dp0FRONT END"
call flutter build web --release
if %errorlevel% neq 0 (
    echo [ERROR] Flutter web compilation failed.
    exit /b %errorlevel%
)

echo.
echo [2/4] Syncing Web Artifacts to Backend Public Folder...
cd /d "%~dp0"
if exist "BACK END\public" rmdir /s /q "BACK END\public"
xcopy /s /e /y /i "FRONT END\build\web" "BACK END\public"
if %errorlevel% neq 0 (
    echo [ERROR] Failed to copy web artifacts to BACK END\public.
    exit /b %errorlevel%
)

echo.
echo [3/4] Staging and Committing Changes to Git...
git add .
set COMMIT_MSG=deploy: update web version and production backend [%date% %time%]
git commit -m "%COMMIT_MSG%"

echo.
echo [4/4] Pushing to GitHub (Triggers Railway ^& GitHub Pages Auto-Deploy)...
git push origin main
if %errorlevel% neq 0 (
    echo [ERROR] Failed to push to GitHub. Check your network or credentials.
    exit /b %errorlevel%
)

echo.
echo ========================================================
echo   SUCCESS! Deployment Initiated Automatically!
echo   - Railway Backend ^& Web: https://my-project-production-f607.up.railway.app/
echo   - GitHub Actions CI/CD: https://github.com/daliatchoutan/MY-PROJECT/actions
echo   - GitHub Pages Web:     https://daliatchoutan.github.io/MY-PROJECT/
echo ========================================================
pause
