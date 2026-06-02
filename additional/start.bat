@echo off
start "Backend" python -m uvicorn backend.main:app --port 8000 --reload
start "Frontend" python -m http.server 8080
timeout /t 2 >nul
start http://localhost:8080
