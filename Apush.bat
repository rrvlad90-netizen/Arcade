@echo off
cd /d D:\Git\Arcade

echo ========================================
echo  send changes on GitHub
echo ========================================
echo.

echo [1/3] check changes...
git status

echo.
echo [2/3] add all files...
git add .

echo.
echo [3/3] cave and send...
set /p commit_msg="commnet for commit: "
git commit -m "%commit_msg%"
git push

echo.
echo ========================================
echo  Done! Check GitHub
echo ========================================
pause