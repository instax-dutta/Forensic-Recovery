@echo off
title Safe Backup
color 0A

echo.
echo ==========================================
echo   SAFE BACKUP
echo   Scans C:\ and D:\ for personal files
echo   Output: %~dp0SAFE_BACKUP_YYYYMMDD_HHMMSS
echo ==========================================
echo.

powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%~dp0safe_backup.ps1"

echo.
if %ERRORLEVEL% EQU 0 (
    color 0A
    echo ==========================================
    echo   BACKUP FINISHED SUCCESSFULLY
    echo ==========================================
) else (
    color 0C
    echo ==========================================
    echo   BACKUP FINISHED WITH ERRORS
    echo   Check log file in backup folder
    echo ==========================================
)

echo.
pause