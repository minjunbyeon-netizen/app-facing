@echo off
start "" "http://localhost:8080/rehap2/index.html"
cd /d "%~dp0.."
start /b python -m http.server 8080
