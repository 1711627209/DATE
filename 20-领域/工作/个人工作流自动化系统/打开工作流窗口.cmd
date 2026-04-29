@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0launch-workflow-gui.ps1"
endlocal