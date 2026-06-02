@echo off
for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":8000 "') do taskkill /PID %%a /F >nul 2>&1
for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":8080 "') do taskkill /PID %%a /F >nul 2>&1
start "Backend" cmd /c "cd /d C:\dev\exercisematerials\01.test && python -m uvicorn backend.main:app --port 8000 --reload"
start "Frontend" python -m http.server 8080
timeout /t 2 >nul
start http://localhost:8080
