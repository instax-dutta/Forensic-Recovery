#Requires -Version 5.1
<#
.SYNOPSIS
    Restore files from a flat backup folder to a target drive

.DESCRIPTION
    Reads all files from BackupRoot and restores them to the target drive
    preserving the relative folder structure.

    Backup structure expected:
        SAFE_BACKUP_20260613_131339\
            Users\
            ACR 2023-24-block\
            Information.xlsx
            ... etc

    All files restore to target drive maintaining relative paths.

.PARAMETER BackupRoot
    Full path to the backup folder (e.g. the SAFE_BACKUP_... folder).

.PARAMETER Destination
    Target drive letter (e.g. "D:", "E:"). Default: "D:"

.PARAMETER DryRun
    Simulate only. No files written.

.PARAMETER ForceHash
    When timestamps match, compare SHA-256 to decide skip vs overwrite.

.EXAMPLE
    .\restore_backup.ps1 -BackupRoot "E:\SAFE_BACKUP_20260613_131339" -DryRun
    .\restore_backup.ps1 -BackupRoot "E:\SAFE_BACKUP_20260613_131339" -Destination "E:"
    .\restore_backup.ps1 -BackupRoot "E:\SAFE_BACKUP_20260613_131339" -ForceHash
#>

param(
    [Parameter(Mandatory)]
    [string]$BackupRoot,

    [string]$Destination = "D:",

    [switch]$DryRun,

    [switch]$ForceHash
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

$DestRoot = $Destination.TrimEnd(':')
if ($DestRoot -notmatch '^[A-Za-z]$') {
    Write-Host "Invalid destination drive: $Destination. Use a single letter like 'D:' or 'E:'." -ForegroundColor Red
    exit 1
}
$DestRoot = "${DestRoot}:"

# ---------------------------------------------------------------------------
# Validate
# ---------------------------------------------------------------------------
if (!(Test-Path $BackupRoot)) {
    Write-Host "Backup folder not found: $BackupRoot" -ForegroundColor Red
    exit 1
}

if (!(Test-Path "$DestRoot\")) {
    Write-Host "Destination drive $DestRoot not found on this machine." -ForegroundColor Red
    exit 1
}

$BackupRoot = (Resolve-Path $BackupRoot).Path.TrimEnd('\')

# ---------------------------------------------------------------------------
# Log to TEMP
# ---------------------------------------------------------------------------
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$LogDir    = Join-Path $env:TEMP "RestoreLogs"
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null

$LogFile = Join-Path $LogDir "restore_$Timestamp.log"
$CsvFile = Join-Path $LogDir "restore_$Timestamp.csv"

function Write-Log {
    param([string]$Text, [string]$Color = "White")
    $Line = "[$(Get-Date -Format 'HH:mm:ss')] $Text"
    Add-Content -Path $LogFile -Value $Line
    Write-Host $Line -ForegroundColor $Color
}

# ---------------------------------------------------------------------------
# Banner
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  RESTORE BACKUP -> $DestRoot\" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
if ($DryRun) {
    Write-Host "  !! DRY RUN -- no files will be written !!" -ForegroundColor Yellow
}
Write-Host ""

Write-Log "Restore started"
Write-Log "BackupRoot = $BackupRoot"
Write-Log "DestRoot   = $DestRoot\"
Write-Log "DryRun     = $DryRun"
Write-Log "ForceHash  = $ForceHash"

# ---------------------------------------------------------------------------
# Enumerate
# ---------------------------------------------------------------------------
Write-Log "Enumerating backup files..."

$Files = Get-ChildItem $BackupRoot -Recurse -File -ErrorAction SilentlyContinue
Write-Log "Files found: $($Files.Count)"

# ---------------------------------------------------------------------------
# Counters
# ---------------------------------------------------------------------------
$Restored   = 0
$Skipped    = 0
$Failed     = 0
$Verified   = 0
$VerifyFail = 0

$Results = [System.Collections.Generic.List[object]]::new()

# ---------------------------------------------------------------------------
# Restore loop
# ---------------------------------------------------------------------------
foreach ($File in $Files) {

    $Relative = $File.FullName.Substring($BackupRoot.Length).TrimStart('\')
    $Target   = Join-Path "$DestRoot\" $Relative

    $Entry = [PSCustomObject]@{
        Source   = $File.FullName
        Target   = $Target
        Action   = ""
        Reason   = ""
        Verified = ""
        SizeMB   = [math]::Round($File.Length / 1MB, 4)
    }

    try {

        $TargetDir = Split-Path $Target -Parent

        if (!(Test-Path $TargetDir)) {
            if (!$DryRun) {
                New-Item -ItemType Directory -Force -Path $TargetDir | Out-Null
            }
        }

        # Conflict resolution
        if (Test-Path $Target) {

            $Existing = Get-Item $Target

            if ($Existing.LastWriteTimeUtc -gt $File.LastWriteTimeUtc) {
                Write-Log "SKIP (dest newer): $Target" "DarkGray"
                $Entry.Action = "SKIP"
                $Entry.Reason = "Destination file is newer"
                $Skipped++
                $Results.Add($Entry)
                continue
            }

            if ($ForceHash -and ($Existing.LastWriteTimeUtc -eq $File.LastWriteTimeUtc)) {
                $HashSrc  = (Get-FileHash $File.FullName     -Algorithm SHA256).Hash
                $HashDest = (Get-FileHash $Existing.FullName -Algorithm SHA256).Hash

                if ($HashSrc -eq $HashDest) {
                    Write-Log "SKIP (identical): $Target" "DarkGray"
                    $Entry.Action = "SKIP"
                    $Entry.Reason = "Hash identical"
                    $Skipped++
                    $Results.Add($Entry)
                    continue
                }
            }
        }

        # Copy
        if ($DryRun) {
            Write-Log "WOULD RESTORE: $Target" "Cyan"
            $Entry.Action   = "WOULD_RESTORE"
            $Entry.Verified = "N/A"
            $Skipped++
        } else {
            Copy-Item -LiteralPath $File.FullName -Destination $Target -Force

            $HashSrc  = (Get-FileHash $File.FullName -Algorithm SHA256).Hash
            $HashDest = (Get-FileHash $Target        -Algorithm SHA256).Hash

            if ($HashSrc -eq $HashDest) {
                Write-Log "RESTORED + VERIFIED: $Target" "Green"
                $Entry.Action   = "RESTORED"
                $Entry.Verified = "OK"
                $Verified++
            } else {
                Write-Log "RESTORED but HASH MISMATCH: $Target" "Red"
                $Entry.Action   = "RESTORED"
                $Entry.Verified = "HASH_MISMATCH"
                $VerifyFail++
            }

            $Restored++
        }

    }
    catch {
        Write-Log "FAILED: $Target -- $($_.Exception.Message)" "Red"
        $Entry.Action = "FAILED"
        $Entry.Reason = $_.Exception.Message
        $Failed++
    }

    $Results.Add($Entry)
}

# ---------------------------------------------------------------------------
# CSV output
# ---------------------------------------------------------------------------
$Results | Export-Csv $CsvFile -NoTypeInformation

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
Write-Log ""
Write-Log "==========================================================="
Write-Log "COMPLETED"
Write-Log "==========================================================="
Write-Log "Restored    = $Restored"
if (!$DryRun) {
    Write-Log "  Verified  = $Verified"
    if ($VerifyFail -gt 0) {
        Write-Log "  !! Hash mismatches = $VerifyFail -- check CSV !!" "Red"
    }
}
Write-Log "Skipped     = $Skipped"
Write-Log "Failed      = $Failed"
Write-Log ""
Write-Log "Log : $LogFile"
Write-Log "CSV : $CsvFile"

Write-Host ""
if ($Failed -gt 0) {
    Write-Host "  $Failed file(s) failed -- review the log." -ForegroundColor Red
}
if ($VerifyFail -gt 0) {
    Write-Host "  $VerifyFail file(s) have hash mismatches -- backup may be corrupt." -ForegroundColor Red
}

Write-Host ""
Write-Host "Log : $LogFile" -ForegroundColor Green
Write-Host "CSV : $CsvFile" -ForegroundColor Green
Write-Host ""
