# Contributing to Safe Backup & Restore

Thank you for your interest in contributing! This project welcomes contributions from the community.

## How to Contribute

### Reporting Bugs

Before submitting a bug report:
1. Check existing issues to avoid duplicates
2. Test with the latest version
3. Include: OS version, PowerShell version, steps to reproduce, expected vs actual behavior

### Suggesting Features

Open an issue with:
- Clear description of the feature
- Use case / motivation
- Any implementation ideas

### Pull Requests

1. **Fork** the repository
2. **Create a branch** from `main`: `git checkout -b feature/your-feature-name`
3. **Make changes** following the guidelines below
4. **Test thoroughly** - run both backup and restore with `-DryRun` first
5. **Commit** with clear messages: `feat: add support for .heic images`
6. **Push** to your fork and open a PR

## Code Guidelines

### PowerShell Style

- Use `#Requires -Version 5.1` at top
- `Set-StrictMode -Version Latest`
- `$ErrorActionPreference = "Stop"` (or "Continue" with explicit try/catch)
- PascalCase for functions, parameters, variables
- Descriptive parameter names with `[Parameter(Mandatory)]` where needed
- Comment-based help (`.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, `.EXAMPLE`) for all public functions
- Use `Write-Host` for user output, `Write-Log` for file logging
- Prefer `[System.Collections.Generic.List[T]]` over `@()` for performance

### Script Structure

```
param()           # Parameters first
Set-StrictMode    # Strict mode
$ErrorActionPref  # Error handling

# Helper functions (Write-Log, Format-Size, etc.)

# Main logic
```

### Testing Checklist

Before submitting a PR, verify:
- [ ] `safe_backup.ps1` runs without errors (use `-Destination` to test folder)
- [ ] `restore_backup.ps1 -DryRun` works on a test backup
- [ ] `restore_backup.ps1 -ForceHash` verifies correctly
- [ ] Excluded folders are still excluded
- [ ] File extensions filter works
- [ ] Progress bar displays
- [ ] Logs are written correctly
- [ ] Exit codes are correct (0 = success, 1 = error)

### Adding File Extensions

Add to `$Extensions` HashSet in `safe_backup.ps1`:
```powershell
$Extensions = [System.Collections.Generic.HashSet[string]]@(
    ".doc", ".docx",
    ".heic", ".heif"   # Add new ones here
)
```

### Adding Excluded Folders

Add to `$ExcludedFolders` array in `safe_backup.ps1`:
```powershell
$ExcludedFolders = @(
    'C:\Windows',
    'C:\NewExclusion'  # Add here
)
```

### Adding Source Drives

Modify `$SourceDrives` in `safe_backup.ps1`:
```powershell
$SourceDrives = @( "C:\", "D:\", "E:\" )
```

## Commit Message Convention

Follow [Conventional Commits](https://www.conventionalcommits.org/):

| Type | Description |
|------|-------------|
| `feat:` | New feature |
| `fix:` | Bug fix |
| `docs:` | Documentation only |
| `style:` | Formatting, no logic change |
| `refactor:` | Code restructuring |
| `test:` | Adding tests |
| `chore:` | Maintenance |

Examples:
- `feat: add .webp and .heic image support`
- `fix: handle paths with special characters in restore`
- `docs: update README with new parameter examples`

## Code of Conduct

Be respectful, inclusive, and constructive. Harassment or discrimination will not be tolerated.

## Questions?

Open an issue with the `question` label or start a discussion.