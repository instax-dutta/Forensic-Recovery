# Forensic Recovery

A Windows PowerShell tool for **forensically-sound digital evidence acquisition**. Designed to triage and extract user-generated files (documents, images, videos, audio) from multiple drives while excluding system artifacts, with SHA-256 chain-of-custody verification.

Built for incident responders, forensic examiners, and law enforcement who need a fast, scriptable, and verifiable method to collect relevant evidence from a Windows system.

## Forensics Features

- **Targeted Evidence Acquisition** — Collects only user-created files by extension (documents, images, videos, audio, spreadsheets, PDFs). No system binaries, no noise.
- **System Artifact Exclusion** — Automatically skips Windows, Program Files, ProgramData, Recycle Bin, System Volume Information — locations unlikely to contain user-generated evidence.
- **SHA-256 Chain of Custody** — Every acquired file is hash-verified on copy. Restore mode re-verifies and produces a CSV audit trail.
- **Audit-Grade Logging** — Timestamped logs record every action: acquired, skipped (with reason), or failed. CSV report includes per-file source, destination, action, reason, and verification hash status.
- **Dry-Run Mode** — Preview the full acquisition without touching the destination drive.
- **Space Pre-Flight** — Checks destination has sufficient capacity (with 10% headroom warning) before beginning acquisition.
- **Multi-Drive Triage** — Defaults to scanning C:\ and D:\. Easy to add more drives.

## Use Cases

| Scenario | Application |
|----------|------------|
| **Incident Response** | Rapidly collect user files from compromised workstations for offline analysis |
| **Digital Forensics** | Acquire evidentiary files from a suspect drive while preserving integrity |
| **eDiscovery** | Extract documents, spreadsheets, and communications from multiple drives |
| **Data Recovery** | Salvage user files from a failing or corrupt system before forensic imaging |
| **Triage Acquisition** | Quickly identify and copy high-value evidence without waiting for a full disk image |

## Requirements

- Windows 10/11 or Windows Server 2016+
- PowerShell 5.1+ (built into Windows)
- Administrator rights recommended for full user profile access

## Quick Start

### Acquire Evidence

```powershell
# Acquire from C:\ and D:\ to current directory
.\safe_backup.ps1

# Acquire to a specific external drive
.\safe_backup.ps1 -Destination "E:\Case_2026_001"
```

Or double-click `run-backup.bat`.

### Restore & Verify

```powershell
# Preview the restore operation (recommended first)
.\restore_backup.ps1 -BackupRoot "E:\SAFE_BACKUP_20260613_131339" -DryRun

# Full restore with SHA-256 verification
.\restore_backup.ps1 -BackupRoot "E:\SAFE_BACKUP_20260613_131339" -ForceHash

# Restore to a specific drive
.\restore_backup.ps1 -BackupRoot "E:\SAFE_BACKUP_20260613_131339" -Destination "F:" -ForceHash
```

Or edit and run `run_restore.bat`.

## Parameters

### Acquisition (safe_backup.ps1)

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-Destination` | String | Script directory | Where to write the acquisition output |

### Restore (restore_backup.ps1)

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-BackupRoot` | String (Mandatory) | — | Path to the acquired evidence folder |
| `-Destination` | String | `"D:"` | Target drive for restoration |
| `-DryRun` | Switch | False | Simulate only — no files written |
| `-ForceHash` | Switch | False | Compare SHA-256 when timestamps match |

## Evidence File Types Acquired

| Category | Extensions |
|----------|------------|
| Documents | .doc, .docx, .xls, .xlsx, .ppt, .pptx, .pdf, .csv, .txt |
| Images | .jpg, .jpeg, .png, .gif, .webp, .bmp, .tif, .tiff |
| Video | .mp4, .mkv, .mov, .avi, .wmv, .webm |
| Audio | .mp3, .wav, .flac, .aac, .m4a, .ogg |

*Edit the `$Extensions` HashSet in `safe_backup.ps1:13` to customize.*

## System Exclusions (Not Acquired)

The following are automatically excluded to avoid collecting irrelevant OS artifacts:
- `C:\Windows`
- `C:\Program Files` / `C:\Program Files (x86)`
- `C:\ProgramData`
- `C:\$Recycle.Bin` / `D:\$Recycle.Bin`
- `C:\System Volume Information` / `D:\System Volume Information`
- `C:\Recovery`
- `C:\boot`

*Edit the `$ExcludedFolders` array in `safe_backup.ps1:23` to customize.*

## Output Structure

```
SAFE_BACKUP_20260613_131339/          # Acquisition root (timestamped)
├── Users/
│   ├── username/
│   │   ├── Documents/
│   │   ├── Pictures/
│   │   └── ...
│   └── Public/
├── ACR 2023-24-block/               # Other source folders
├── Information.xlsx                 # Root-level files
└── SAFE_BACKUP_20260613_131339.log  # Detailed acquisition log
```

## Chain of Custody

The restore script produces two artifacts suitable for an evidence log:

| Artifact | Location | Contents |
|----------|----------|----------|
| **Log file** | `%TEMP%\RestoreLogs\restore_*.log` | Timestamped operations log |
| **CSV report** | `%TEMP%\RestoreLogs\restore_*.csv` | Per-file: source, target, action, reason, verification status |

The CSV is structured for import into case management tools or spreadsheet software for discovery production.

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Error — insufficient space, drive not found, copy failures |

## Safety & Integrity

1. **Read-only acquisition** — No source files are modified or deleted
2. **Pre-flight capacity check** — Aborts if destination lacks space
3. **SHA-256 verification** — Every restored file is hash-compared against source
4. **Hash mismatch alerting** — Corrupt transfers are flagged in CSV and console
5. **Dry-run mode** — Preview before committing
6. **Newer-file protection** — Will not overwrite a destination file that is newer than the source

## Customization

### Add Source Drives

Edit `safe_backup.ps1:21`:
```powershell
$SourceDrives = @( "C:\", "D:\", "E:\" )
```

### Add File Extensions

Edit `safe_backup.ps1:13`:
```powershell
$Extensions = [System.Collections.Generic.HashSet[string]]@(
    ".doc", ".docx", ".pdf",
    ".jpg", ".png", ".mp4", ".mp3"
)
```

### Add Excluded Folders

Edit `safe_backup.ps1:23`:
```powershell
$ExcludedFolders = @(
    'C:\Windows',
    'C:\Program Files',
    'C:\CustomApp'
)
```

### Change Default Restore Destination

Edit `restore_backup.ps1:41` or pass `-Destination`:
```powershell
.\restore_backup.ps1 -BackupRoot "E:\SAFE_BACKUP_*" -Destination "F:"
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT — see [LICENSE](LICENSE).

## Changelog

See [CHANGELOG.md](CHANGELOG.md).

---

**⚠️ Disclaimer**: This tool assists with evidence acquisition but does not replace a full forensic image when one is required by policy or law. Always validate acquisition integrity before relying on data in legal proceedings. Test with `-DryRun` first. The authors accept no liability for use in live investigations.