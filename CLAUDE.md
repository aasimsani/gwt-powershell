# GWT PowerShell Module

PowerShell port of [gwt-zsh](https://github.com/aasimsani/gwt-zsh) — stupidly simple git worktree management.

## Quick Start

```powershell
Import-Module ./GWT/GWT.psd1
gwt feature/my-branch        # Create worktree and cd into it
gwt -Stack feature/child     # Stack from current branch
gwt ..                        # Navigate to parent worktree
gwt ...                       # Navigate to main worktree
gwt -List                     # List all worktrees
gwt -Prune                    # Interactive cleanup
```

## Running Tests

```powershell
# Full suite (215 tests, ~2 min)
Invoke-Pester ./Tests -Output Detailed

# Unit tests only (~10s)
Invoke-Pester ./Tests/Unit -Output Detailed

# Single test file
Invoke-Pester ./Tests/Integration/NewWorktree.Tests.ps1 -Output Detailed
```

Requires **Pester 5.x**: `Install-Module -Name Pester -Force -Scope CurrentUser -SkipPublisherCheck`

## Project Structure

```
GWT/
  GWT.psd1                    # Module manifest (exports, metadata, PSGallery fields)
  GWT.psm1                    # Root module (dot-sources all files, registers aliases + tab completion)
  Private/                    # Internal functions (not exported)
    Test-GwtDirectory.ps1     # Validate directory names (rejects traversal, injection)
    Test-GwtBranch.ps1        # Validate branch names
    Get-GwtSuffix.ps1         # Branch name -> worktree suffix (eng-XXXX or first 3 words)
    Write-GwtMessage.ps1      # Colored output helper
    Read-GwtConfigFile.ps1    # Read KEY=VALUE config files
    Write-GwtConfigFile.ps1   # Write KEY=VALUE config files (with sanitization)
    Get-GwtConfig.ps1         # Layered config resolution (env > local > global > default)
                              #   Also contains Get-GwtMainBranch
    Set-GwtMetadata.ps1       # Store parent info in worktree-scoped git config
    Get-GwtMetadata.ps1       # Read parent info (param: -Property 'baseBranch'|'baseWorktreePath')
    Clear-GwtMetadata.ps1     # Remove gwt metadata from worktree config
    Add-GwtRegistry.ps1       # Register worktree relationship in shared git config
    Remove-GwtRegistry.ps1    # Unregister worktree (--remove-section)
    Get-GwtDependents.ps1     # Query children of a branch via registry
    Copy-GwtDirectories.ps1   # Copy dirs from main to new worktree
    Invoke-GwtPostCreate.ps1  # Run post-create hook (script file > env var command)
    Invoke-GwtPruneWorktree.ps1  # Remove single worktree + clean registry
    Invoke-GwtPruneCascade.ps1   # Recursive cascade delete of dependents
    Repair-GwtConfig.ps1      # Fix missing config.worktree (core.bare leak defense)
    Show-GwtMenu.ps1          # Interactive numbered menu helper
  Public/                     # Exported functions
    Invoke-Gwt.ps1            # Main entry point (gwt function) + Show-GwtHelp
    New-GwtWorktree.ps1       # Core worktree creation (handles -Stack, -From, -CopyConfigDirs)
    Enter-GwtBase.ps1         # Navigate to parent worktree (gwt ..)
    Enter-GwtRoot.ps1         # Navigate to main worktree (gwt ...)
    Show-GwtInfo.ps1          # Stack relationships display (gwt -Info)
    Show-GwtList.ps1          # List worktrees with hierarchy (gwt -List)
    Remove-GwtWorktree.ps1    # Interactive prune with confirmation (gwt -Prune)
    Set-GwtConfiguration.ps1  # Interactive config menu (gwt -Config)
Tests/
  Helpers/TestHelper.psm1     # New-GwtTestRepo / Remove-GwtTestRepo (isolated temp repos)
  Unit/                       # 10 files, 88 tests (validation, config, metadata, registry, completion)
  Integration/                # 11 files, 117 tests (worktree creation, stacking, navigation, prune, config)
  Security/                   # 1 file, 10 tests (path traversal, injection, sanitization)
build/
  Publish-GWT.ps1             # PSGallery publish script (runs tests first)
```

## Architecture Decisions

- **Set-Location shares caller's runspace** — `gwt feature/x` naturally changes the user's directory
- **Config format**: `KEY=VALUE` files, compatible with gwt-zsh for cross-shell repos
- **Config paths**: `~/.config/gwt/config` (global), `.gwt/config` (local per-repo)
- **Metadata**: `git config --worktree gwt.baseBranch` / `gwt.baseWorktreePath` (worktree-scoped)
- **Registry**: `git config gwt.registry.<name>.baseBranch` / `.basePath` (shared, in main .git/config)
- **Worktree suffix**: Extracts `eng-XXXX` from Linear branches, or first 3 hyphen-separated words
- **Security**: All config writes sanitize backticks, `$`, `\`, and quotes. Directory validation rejects `..`, absolute paths, semicolons, pipes, and other shell metacharacters
- **Target**: PowerShell 7.x (pwsh). The module manifest requires `PowerShellVersion = '7.0'`

## Testing Conventions

- **Private functions**: Wrap calls in `InModuleScope GWT { ... }` with `-Parameters @{ Key = $value }`
- **Test isolation**: Each test gets a fresh temp git repo via `New-GwtTestRepo` (BeforeEach/AfterEach)
- **Cleanup**: Always `Set-Location $script:ctx.RepoDir` before AfterEach to avoid locked dirs
- **Interactive mocking**: `Mock Read-Host { ... } -ModuleName GWT` with call counter pattern
- **macOS paths**: Use `/usr/bin/readlink -f` to resolve `/var` -> `/private/var` symlinks
- **Parameter names**: `Get-GwtMetadata -Property 'baseBranch'` (not `-Key`)
- **Output capture**: `$output = SomeFunction 6>&1 *>&1` to capture Write-Host output

## Key APIs

| Function | Purpose |
|----------|---------|
| `Get-GwtConfig -Key 'GWT_COPY_DIRS' -Default ''` | Layered config resolution |
| `Get-GwtMainBranch` | Returns configured main branch (default: 'main') |
| `Get-GwtMetadata -Property 'baseBranch'` | Read worktree-scoped metadata |
| `Set-GwtMetadata -BaseBranch $b -BaseWorktreePath $p` | Write worktree metadata + core.bare defense |
| `Get-GwtDependents -BranchName $branch` | Find child worktrees from registry |
| `Get-GwtSuffix -BranchName $branch` | Extract suffix for worktree directory name |

## Publishing

```powershell
# Dry run
pwsh ./build/Publish-GWT.ps1 -NuGetApiKey $key -WhatIf

# Publish to PSGallery
pwsh ./build/Publish-GWT.ps1 -NuGetApiKey $key
```

## Reference

- Original zsh implementation: `../gwt-zsh/gwt.plugin.zsh`
- Original test suite: `../gwt-zsh/tests/gwt.zunit` (~3400 lines, ~210 test cases)
- Test helper bootstrap: `../gwt-zsh/tests/_support/bootstrap`
