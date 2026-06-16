#Requires -Version 5.1
param(
    [string]$Destination = $PSScriptRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Timestamp  = Get-Date -Format "yyyyMMdd_HHmmss"
$BackupRoot = Join-Path $Destination "SAFE_BACKUP_$Timestamp"
$LogFile    = Join-Path $Destination "SAFE_BACKUP_$Timestamp.log"

$Extensions = [System.Collections.Generic.HashSet[string]]@(
    ".doc", ".docx", ".xls", ".xlsx", ".ppt", ".pptx",
    ".pdf", ".csv", ".txt",
    ".jpg", ".jpeg", ".png", ".gif", ".webp", ".bmp", ".tif", ".tiff",
    ".mp4", ".mkv", ".mov", ".avi", ".wmv", ".webm",
    ".mp3", ".wav", ".flac", ".aac", ".m4a", ".ogg"
)

$SourceDrives = @( "C:\", "D:\" )

$ExcludedFolders = @(
    'C:\Windows',
    'C:\Program Files',
    'C:\Program Files (x86)',
    'C:\ProgramData',
    'C:\$Recycle.Bin',
    'C:\System Volume Information',
    'C:\Recovery',
    'C:\boot',
    'D:\$Recycle.Bin',
    'D:\System Volume Information'
)

function Write-Log {
    param([string]$Level, [string]$Message)
    $line = "{0}  [{1,-5}]  {2}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Level, $Message
    $line | Tee-Object -FilePath $LogFile -Append | Write-Host
}

function Format-Size {
    param([long]$Bytes)
    if ($Bytes -ge 1GB) {
        return "{0:N2} GB" -f ($Bytes / 1GB)
    } elseif ($Bytes -ge 1MB) {
        return "{0:N2} MB" -f ($Bytes / 1MB)
    } elseif ($Bytes -ge 1KB) {
        return "{0:N2} KB" -f ($Bytes / 1KB)
    } else {
        return "$Bytes B"
    }
}

function Is-Excluded {
    param([string]$Path)
    foreach ($Excluded in $ExcludedFolders) {
        if ($Path.StartsWith($Excluded, [System.StringComparison]::OrdinalIgnoreCase)) {
            return $true
        }
    }
    return $false
}

Write-Host ""
Write-Host "Scanning files across C:\ and D:\ ..." -ForegroundColor Cyan
Write-Host "This may take a few minutes." -ForegroundColor Gray

$AllFiles  = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
$TotalSize = 0L

foreach ($Drive in $SourceDrives) {
    if (-not (Test-Path $Drive)) {
        Write-Host "Drive not found, skipping: $Drive" -ForegroundColor Yellow
        continue
    }

    Get-ChildItem $Drive -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object {
            -not (Is-Excluded $_.FullName) -and
            $Extensions.Contains($_.Extension.ToLower())
        } |
        ForEach-Object {
            $AllFiles.Add($_)
            $TotalSize += $_.Length
        }
}

if ($AllFiles.Count -eq 0) {
    Write-Host "No matching files found. Exiting." -ForegroundColor Yellow
    exit 0
}

$DestDrive = Split-Path -Qualifier $Destination
$DiskInfo  = Get-PSDrive -Name $DestDrive.TrimEnd(':') -ErrorAction SilentlyContinue
if ($null -eq $DiskInfo) {
    $WmiDisk   = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='$DestDrive'" -ErrorAction SilentlyContinue
    $FreeSpace = if ($WmiDisk) { $WmiDisk.FreeSpace } else { $null }
} else {
    $FreeSpace = $DiskInfo.Free
}

Write-Host ""
Write-Host "+-----------------------------------------+" -ForegroundColor Cyan
Write-Host "|           BACKUP PRE-FLIGHT             |" -ForegroundColor Cyan
Write-Host "+-----------------------------------------+" -ForegroundColor Cyan
Write-Host "|  Files found   : $($AllFiles.Count.ToString().PadRight(22))|"
Write-Host "|  Total size    : $($(Format-Size $TotalSize).PadRight(22))|"

if ($null -ne $FreeSpace) {
    $FreeLabel = Format-Size $FreeSpace
    if ($FreeSpace -gt ($TotalSize * 1.1)) {
        Write-Host "|  Drive free    : $($FreeLabel.PadRight(22))|" -ForegroundColor Green
    } else {
        Write-Host "|  Drive free    : $($FreeLabel.PadRight(22))|" -ForegroundColor Red
    }

    if ($FreeSpace -le $TotalSize) {
        Write-Host "+-----------------------------------------+" -ForegroundColor Red
        Write-Host ""
        Write-Host "NOT ENOUGH SPACE. Backup aborted." -ForegroundColor Red
        Write-Host "Need : $(Format-Size $TotalSize)"
        Write-Host "Have : $(Format-Size $FreeSpace)"
        exit 1
    }

    if ($FreeSpace -lt ($TotalSize * 1.1)) {
        Write-Host "|  WARNING: Less than 10% headroom        |" -ForegroundColor Yellow
    }
} else {
    Write-Host "|  Drive free    : Could not determine     |" -ForegroundColor Yellow
}

Write-Host "+-----------------------------------------+" -ForegroundColor Cyan
Write-Host ""

$Confirm = Read-Host "Proceed with backup? (Y/N)"
if ($Confirm -notmatch '^[Yy]') {
    Write-Host "Aborted by user." -ForegroundColor Yellow
    exit 0
}

New-Item -ItemType Directory -Force -Path $BackupRoot | Out-Null
Write-Log INFO "Backup started  : $BackupRoot"
Write-Log INFO "Files to copy   : $($AllFiles.Count) ($(Format-Size $TotalSize))"

$Copied      = 0
$Skipped     = 0
$Failed      = 0
$BytesCopied = 0L
$i           = 0

foreach ($File in $AllFiles) {
    $i++
    $Pct = [math]::Round(($i / $AllFiles.Count) * 100)
    Write-Progress -Activity "Backing up files" -Status "$Pct% -- $($File.Name)" -PercentComplete $Pct

    $RelativePath = $File.FullName -replace '^[A-Za-z]:\\', ''
    $Target       = Join-Path $BackupRoot $RelativePath

    try {
        $TargetDir = Split-Path $Target
        if (-not (Test-Path $TargetDir)) {
            New-Item -ItemType Directory -Force -Path $TargetDir | Out-Null
        }

        if (Test-Path $Target) {
            $Existing = Get-Item $Target
            if ($Existing.Length -eq $File.Length -and $Existing.LastWriteTimeUtc -eq $File.LastWriteTimeUtc) {
                $Skipped++
                continue
            }
        }

        Copy-Item -LiteralPath $File.FullName -Destination $Target -Force
        $Copied++
        $BytesCopied += $File.Length
        Write-Log INFO "Copied: $($File.FullName)"
    } catch {
        $Failed++
        Write-Log FAIL "Failed [$($_.Exception.Message)]: $($File.FullName)"
    }
}

Write-Progress -Activity "Backing up files" -Completed

Write-Log INFO "-----------------------------------------"
Write-Log INFO "Done.  Copied: $Copied  Skipped: $Skipped  Failed: $Failed  ($(Format-Size $BytesCopied))"
Write-Log INFO "Backup root : $BackupRoot"
Write-Log INFO "Log file    : $LogFile"

if ($Failed -gt 0) {
    Write-Host ""
    Write-Host "$Failed file(s) failed -- check $LogFile" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "All done." -ForegroundColor Green
