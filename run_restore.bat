@echo off
title Restore Backup
color 0A

:: ==========================================
:: CONFIGURATION - EDIT THESE VALUES
:: ==========================================
set BACKUP_SOURCE=E:\SAFE_BACKUP_20260613_131339
set DEST_DRIVE=D:
:: ==========================================

echo.
echo ==========================================
echo   RESTORE BACKUP
echo   Source : %BACKUP_SOURCE%
echo   Dest   : %DEST_DRIVE%\
echo ==========================================
echo.

:: Verify the backup folder exists before calling PowerShell
if not exist "%BACKUP_SOURCE%\" (
    color 0C
    echo ERROR: Backup folder not found: %BACKUP_SOURCE%
    echo Edit this batch file and set BACKUP_SOURCE to the correct path.
    echo.
    pause
    exit /b 1
)

:: Verify destination drive exists
if not exist "%DEST_DRIVE%\" (
    color 0C
    echo ERROR: Destination drive %DEST_DRIVE%\ not found.
    echo Edit this batch file and set DEST_DRIVE to the correct letter.
    echo.
    pause
    exit /b 1
)

:: Verify the script exists next to this bat file
if not exist "%~dp0restore_backup.ps1" (
    color 0C
    echo ERROR: restore_backup.ps1 not found in the same folder as this bat file.
    echo Expected: %~dp0restore_backup.ps1
    echo.
    pause
    exit /b 1
)

echo Starting restore...
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass ^
    -File "%~dp0restore_backup.ps1" ^
    -BackupRoot "%BACKUP_SOURCE%" ^
    -Destination "%DEST_DRIVE%" ^
    -ForceHash

echo.
if %ERRORLEVEL% EQU 0 (
    color 0A
    echo ==========================================
    echo   RESTORE FINISHED SUCCESSFULLY
    echo ==========================================
) else (
    color 0C
    echo ==========================================
    echo   RESTORE FINISHED WITH ERRORS
    echo   Check log in: %TEMP%\RestoreLogs\
    echo ==========================================
)

echo.
pause
