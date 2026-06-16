# Changelog

All notable changes to this project will be documented in this format.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial open-source release preparation
- Comprehensive README.md with usage documentation
- MIT License
- CONTRIBUTING.md guidelines
- .gitignore for backup outputs and logs
- This CHANGELOG.md

## [1.0.0] - 2026-06-16

### Added
- **safe_backup.ps1** - Main backup script
  - Scans C:\ and D:\ for personal files by extension
  - Excludes system folders (Windows, Program Files, Recycle Bin, etc.)
  - Pre-flight disk space check with 10% headroom warning
  - Interactive confirmation prompt
  - Incremental backup (skips identical files by size + timestamp)
  - Real-time progress bar
  - Timestamped log file with copy/skip/fail details
  - Configurable destination via `-Destination` parameter

- **restore_backup.ps1** - Restore script
  - Restores from flat backup folder to D:\ (configurable)
  - Preserves relative folder structure
  - `-DryRun` mode for safe testing
  - `-ForceHash` option for SHA-256 verification when timestamps match
  - Conflict resolution: skips if destination is newer
  - Full SHA-256 verification on every restored file
  - Detailed CSV report with per-file actions
  - Logs to `%TEMP%\RestoreLogs\`

- **run-backup.bat** - Double-click wrapper for backup
  - Bypasses execution policy
  - Pauses on completion for review

- **run_restore.bat** - Double-click wrapper for restore
  - Validates backup source exists (E:\ by default)
  - Validates destination drive (D:\ by default)
  - Color-coded output
  - Runs with `-ForceHash` for integrity

### Security
- No credentials stored or transmitted
- Only reads user files with known extensions
- No network access
- Runs locally with user permissions

### Known Limitations
- Windows only (PowerShell 5.1+)
- Requires read access to source folders
- Requires write access to destination
- Administrator recommended for full user profile access
- Hardcoded restore destination (D:\) - edit script to change