# Safe Backup & Restore

A robust PowerShell backup and restore solution for Windows. Designed to safely back up personal files (documents, photos, videos, music, etc.) from multiple drives while excluding system folders, and restore them with integrity verification.

## Features

- **Smart File Selection** - Targets personal files only (documents, images, videos, audio, spreadsheets, PDFs)
- **System Folder Exclusion** - Automatically excludes Windows, Program Files, ProgramData, Recycle Bin, System Volume Information
- **Pre-flight Checks** - Verifies destination has enough space (with 10% headroom warning) before starting
- **Incremental Backup** - Skips identical files (same size + timestamp) to save time and space
- **Progress Tracking** - Real-time progress bar during backup/restore operations
- **Detailed Logging** - Timestamped logs with success/failure details
- **Integrity Verification** - SHA-256 hash verification on restore to ensure file integrity
- **Dry-run Mode** - Test restore operations without writing files
- **Cross-drive Support** - Backs up from C:\ and D:\ by default (configurable)

## Requirements

- Windows 10/11 or Windows Server 2016+
- PowerShell 5.1+ (built into Windows)
- Administrator rights recommended (for accessing all user folders)

## Quick Start

### Backup

```powershell
# Run with default settings (backs up C:\ and D:\ to script directory)
.\safe_backup.ps1

# Backup to a specific destination
.\safe_backup.ps1 -Destination "E:\MyBackups"
```

Or use the batch wrapper (double-click to run):
```
run-backup.bat
```

### Restore

```powershell
# Dry run first (recommended) - shows what would be restored
.\restore_backup.ps1 -BackupRoot "E:\SAFE_BACKUP_20260613_131339" -DryRun

# Actual restore with hash verification
.\restore_backup.ps1 -BackupRoot "E:\SAFE_BACKUP_20260613_131339" -ForceHash
```

Or use the batch wrapper (edit the backup path first):
```
run_restore.bat
```

## Parameters

### safe_backup.ps1

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-Destination` | String | Script directory | Where to create the backup folder |

### restore_backup.ps1

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-BackupRoot` | String (Mandatory) | - | Path to the SAFE_BACKUP_* folder |
| `-DryRun` | Switch | False | Simulate only, no files written |
| `-ForceHash` | Switch | False | Compare SHA-256 when timestamps match |

## File Types Backed Up

| Category | Extensions |
|----------|------------|
| Documents | .doc, .docx, .xls, .xlsx, .ppt, .pptx, .pdf, .csv, .txt |
| Images | .jpg, .jpeg, .png, .gif, .webp, .bmp, .tif, .tiff |
| Video | .mp4, .mkv, .mov, .avi, .wmv, .webm |
| Audio | .mp3, .wav, .flac, .aac, .m4a, .ogg |

*To customize, edit the `$Extensions` HashSet in `safe_backup.ps1`*

## Excluded Folders

The following are automatically excluded:
- `C:\Windows`
- `C:\Program Files` / `C:\Program Files (x86)`
- `C:\ProgramData`
- `C:\$Recycle.Bin` / `D:\$Recycle.Bin`
- `C:\System Volume Information` / `D:\System Volume Information`
- `C:\Recovery`
- `C:\boot`

*To customize, edit the `$ExcludedFolders` array in `safe_backup.ps1`*

## Output Structure

```
SAFE_BACKUP_20260613_131339/          # Backup root (timestamped)
├── Users/
│   ├── username/
│   │   ├── Documents/
│   │   ├── Pictures/
│   │   └── ...
│   └── Public/
├── ACR 2023-24-block/               # Other folders from drive root
├── Information.xlsx                 # Files from drive root
└── SAFE_BACKUP_20260613_131339.log  # Detailed log file
```

## Log Files

- **Backup logs**: Created in the destination folder alongside the backup
- **Restore logs**: Created in `%TEMP%\RestoreLogs\` with timestamp
- **Restore CSV**: Detailed per-file report (action, reason, verification status)

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Error (insufficient space, drive not found, copy failures, etc.) |

## Safety Features

1. **No system files touched** - Only user files with known extensions
2. **Space check before starting** - Won't start if destination is full
3. **Confirmation prompt** - Requires explicit Y/N before backup
4. **Hash verification on restore** - Detects corruption silently
5. **Dry-run mode** - Test before committing
6. **Newer file protection** - Won't overwrite destination files that are newer

## Customization

### Add/Remove Source Drives
Edit `safe_backup.ps1` line 21:
```powershell
$SourceDrives = @( "C:\", "D:\", "E:\" )
```

### Add/Remove File Extensions
Edit `safe_backup.ps1` lines 13-19:
```powershell
$Extensions = [System.Collections.Generic.HashSet[string]]@(
    ".doc", ".docx", ".pdf",        # Add/remove here
    ".jpg", ".png", ".mp4", ".mp3"
)
```

### Add/Remove Excluded Folders
Edit `safe_backup.ps1` lines 23-34:
```powershell
$ExcludedFolders = @(
    'C:\Windows',
    'C:\Program Files',
    # Add your own:
    'C:\MyPrivateFolder',
    'D:\Temp'
)
```

### Change Default Restore Destination
Edit `restore_backup.ps1` line 45:
```powershell
$DestRoot = "E:"  # Change from D: to your preferred drive
```

## Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT License - see [LICENSE](LICENSE) for details.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history.

---

**⚠️ Disclaimer**: This script is provided as-is. Always test with `-DryRun` first. Verify backups manually before relying on them. The authors are not responsible for any data loss.