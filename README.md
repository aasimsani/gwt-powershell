# gwt-powershell

**Stupidly simple git worktree management.**

Stop typing `git worktree add ../myrepo-feature ../myrepo-feature feature/branch` every time. Just type `gwt feature/branch` and get on with your life.

![gwt demo](assets/demo.gif)

## Features

- **Smart Worktree Creation** - Auto-names worktrees from branch names and cd's into them
- **Worktree Stacking** - Create worktrees from current branch and navigate back to parent
- **Root Navigation** - Jump to the main worktree from anywhere in the chain
- **Interactive Pruning** - Clean up old worktrees with numbered multi-select (dependency-aware)
- **List Worktrees** - See all worktrees at a glance with hierarchy indicators
- **Copy Config Dirs** - Automatically copy `.vscode/`, `.env`, etc. to new worktrees
- **Tab Completion** - Full PowerShell autocompletion for branch names
- **Cross-Platform** - Works on macOS (pwsh) and Windows

## Quick Start

```powershell
# Create worktree from main branch (default)
gwt feature/add-user-auth          # Creates ../myrepo-add-user-auth

# Create stacked worktree from current branch
gwt -Stack feature/child-branch    # Branches from current, tracks parent

# Navigate back to parent worktree
gwt ..                             # or: gwt -Base

# Navigate to main worktree (ultimate root)
gwt ...                            # or: gwt -Root

# List all worktrees with hierarchy
gwt -List

# Show stack info for current worktree
gwt -Info

# Prune old worktrees interactively
gwt -Prune

# Configure directories to copy to new worktrees
gwt -Config

# Help
gwt -Help
```

## How Naming Works

`gwt` creates worktrees in a sibling directory with automatic naming:

- **Linear branches** (`*/eng-XXXX-*`): Uses the ticket number
  ```
  gwt aasim/eng-1045-allow-changing-user-types
  # Creates: ../myrepo-eng-1045
  ```

- **Regular branches**: Uses first 3 words of the branch name
  ```
  gwt feature/add-new-dashboard-components
  # Creates: ../myrepo-add-new-dashboard
  ```

`gwt` always `cd`s into the worktree after creation. If the worktree already exists, it just `cd`s into it.

## Installation

### PSGallery (Recommended)

```powershell
Install-Module -Name GWT -Scope CurrentUser
```

Add to your `$PROFILE`:
```powershell
Import-Module GWT
```

### Manual Clone

```powershell
git clone https://github.com/aasimsani/gwt-powershell.git ~/gwt-powershell

# Add to your $PROFILE:
Import-Module ~/gwt-powershell/GWT/GWT.psd1
```

### Configuration

gwt uses a layered config system. Settings are resolved in priority order:

1. **Environment variables** (highest priority)
2. **Local config** (`.gwt/config` in repo root -- per-repo overrides)
3. **Global config** (`~/.config/gwt/config` on macOS/Linux, `$env:APPDATA/gwt/config` on Windows)
4. **Built-in defaults**

Run `gwt -Config` to interactively configure all settings.

**Config file format** (same for global and local):
```
GWT_MAIN_BRANCH=develop
GWT_COPY_DIRS=.vscode,.env
GWT_ALIAS=wt
# GWT_NO_FZF=1
# GWT_POST_CREATE_CMD=npm install
```

**Environment variables** (override config files):
```powershell
$env:GWT_MAIN_BRANCH = "main"              # Default base branch (default: "main")
$env:GWT_COPY_DIRS = ".vscode,.env"        # Directories to copy to new worktrees
$env:GWT_ALIAS = "wt"                      # Alias for gwt command (default: "wt", "" to disable)
$env:GWT_NO_FZF = "1"                      # Disable fzf menus
$env:GWT_POST_CREATE_CMD = "npm install"   # Command to run after worktree creation
```

By default, gwt creates a `wt` alias so you can use `wt` instead of `gwt`:
```powershell
wt feature/add-user-auth          # Same as: gwt feature/add-user-auth
wt -Stack feature/child-branch    # Same as: gwt -Stack feature/child-branch
```

## Uninstallation

### PSGallery
```powershell
Uninstall-Module -Name GWT
```

### Manual Clone
Remove the `Import-Module` line from your `$PROFILE` and delete the cloned directory.

### Note on Worktrees

Uninstalling gwt-powershell does **not** remove any git worktrees you created. Those are standard git worktrees and can be managed with:
```powershell
git worktree list              # See all worktrees
git worktree remove <path>     # Remove a specific worktree
git worktree prune             # Clean up stale references
```

## Usage

### Creating Worktrees

Create worktrees with automatic naming and instant navigation:

```powershell
# Create from main branch (default behavior)
gwt your-name/eng-1234-feature-description
gwt feature/add-new-dashboard

# Stack: create from current branch
gwt -Stack feature/child-feature

# Explicit base: create from specific branch
gwt -From develop feature/new
```

**Example workflow:**
```powershell
# You're working on main in ~/code/myapp
Set-Location ~/code/myapp

# Create a worktree for a new feature
gwt feature/user-auth
# Now you're in ~/code/myapp-user-auth on branch feature/user-auth

# The original repo is untouched
Get-ChildItem ~/code/myapp          # Still on main
Get-ChildItem ~/code/myapp-user-auth # Your new worktree
```

### Worktree Stacking

When you use `-Stack` or `-From`, gwt tracks the parent-child relationship. This is useful for dependent feature branches:

```powershell
# Start on main
gwt feature/parent           # Creates worktree from main

# Create child from parent
gwt -Stack feature/child     # Branches from feature/parent

# Navigate back to parent
gwt ..                       # or: gwt -Base

# See stack info
gwt -Info                    # Shows base branch and dependents
```

**Example - Building dependent features:**
```powershell
# Working on main
gwt feature/api-v2                    # Create API v2 feature

# Now in api-v2, create dependent UI work
gwt -Stack feature/api-v2-dashboard   # Stacked on api-v2

# Navigate up the chain
gwt ..                                # Back to api-v2
gwt ...                               # Back to main (ultimate root)
```

### Navigation Commands

Navigate between worktrees in a chain:

| Command | Shorthand | Description |
|---------|-----------|-------------|
| `gwt -Base` | `gwt ..` | Navigate to immediate parent worktree |
| `gwt -Root` | `gwt ...` | Navigate to main worktree (ultimate root) |

**Example - Deep worktree chain:**
```powershell
# Worktree chain: main -> feature/api -> feature/api-tests -> feature/api-tests-mocks
# Currently in: feature/api-tests-mocks

gwt ..    # Goes to feature/api-tests (immediate parent)
gwt ...   # Goes to main (ultimate root, skipping all intermediates)
```

**When to use each:**
- `gwt ..` - When you need to go back one level to the parent branch
- `gwt ...` - When you need to return to the original repo root, regardless of depth

### Listing Worktrees

```powershell
gwt -List
```

Shows all worktrees with status and hierarchy:
- Exists or missing indicators
- `^-- ` indicates a stacked worktree

**Example output:**
```
Worktrees:

  main                    ~/code/myapp             [main]
    ^-- feature/api       ~/code/myapp-api         [feature/api]
  feature/unrelated       ~/code/myapp-unrelated   [feature/unrelated]
```

### Worktree Info

```powershell
gwt -Info
```

Shows current worktree's stack relationships:
- Current branch and path
- Base worktree (if stacked)
- Dependent worktrees (children)

### Pruning Worktrees

```powershell
gwt -Prune
```

Interactive numbered menu to remove old worktrees. Shows uncommitted changes warnings and dependency counts before deletion.

**Features:**
- Numbered menu selection
- Shows uncommitted changes warning for each worktree
- Double confirmation for safety (y/N + type "DELETE")
- Cascade deletion of dependents

### Copy Config Directories

When creating worktrees, config files (`.vscode/`, `.serena/`, etc.) aren't automatically available. Use this to copy them:

```powershell
# Interactive config menu
gwt -Config

# Copy specific dirs when creating worktree
gwt -CopyConfigDirs .vscode feature/my-branch

# Or set via environment variable
$env:GWT_COPY_DIRS = ".vscode,.idea"
gwt feature/new-feature
# .vscode/ and .idea/ are automatically copied
```

### Post-Create Hooks

Run a command automatically after every worktree creation:

```powershell
# Via config (gwt -Config -> Post-create command)
# GWT_POST_CREATE_CMD=npm install

# Or via a script in the repo
New-Item -ItemType Directory -Path .gwt -Force
Set-Content .gwt/post-create.sh '#!/bin/sh
npm install'
```

The `.gwt/post-create.sh` script takes precedence over `GWT_POST_CREATE_CMD`. If the hook fails, worktree creation still succeeds (a warning is printed).

### Tab Completion

gwt includes PowerShell tab completion for branch names out of the box:

```powershell
gwt <TAB>              # Branch names (local + remote, deduplicated)
gwt -From <TAB> ...    # Branch names for the base branch
```

Completions are registered automatically for both `gwt` and `New-GwtWorktree`. No extra setup required.

## Command Reference

| Command | PowerShell | Description |
|---------|-----------|-------------|
| `gwt <branch>` | `gwt <branch>` | Create worktree from main branch |
| `gwt -Stack <branch>` | `-Stack` switch | Create worktree from current branch |
| `gwt -From <base> <branch>` | `-From <base>` param | Create worktree from specified branch |
| `gwt -Base` / `gwt ..` | `Enter-GwtBase` | Navigate to parent worktree |
| `gwt -Root` / `gwt ...` | `Enter-GwtRoot` | Navigate to main worktree |
| `gwt -Info` | `Show-GwtInfo` | Show stack info |
| `gwt -List` | `Show-GwtList` | List all worktrees |
| `gwt -Prune` | `Remove-GwtWorktree` | Interactive worktree cleanup |
| `gwt -Config` | `Set-GwtConfiguration` | Configure all gwt settings |
| `gwt -CopyConfigDirs <dir>` | `-CopyConfigDirs` param | Copy directory when creating worktree |
| `gwt -Version` | `--Version` flag | Show version |
| `gwt -Help` | `Show-GwtHelp` | Show help |

## Security

- **No network operations** - never pushes or contacts remotes
- **No code execution** - never runs scripts from repositories (except configured post-create hooks)
- **Input validation** - rejects path traversal, absolute paths, shell metacharacters
- **Config sanitization** - strips backticks, dollar signs, quotes from config values

## Development

```powershell
# Run all tests
Invoke-Pester ./Tests -Output Detailed

# Run specific test file
Invoke-Pester ./Tests/Unit/Get-GwtSuffix.Tests.ps1 -Output Detailed

# Run with coverage
Invoke-Pester ./Tests -Output Detailed -CodeCoverage ./GWT/**/*.ps1
```

### Requirements

- PowerShell 7.0+ (pwsh)
- [Pester](https://pester.dev/) 5.x for testing
- Git 2.20+ (for worktree features)

## Differences from gwt-zsh

| Feature | gwt-zsh | gwt-powershell |
|---------|---------|----------------|
| Shell | zsh only | PowerShell 7+ (cross-platform) |
| Install | Oh-My-Zsh / plugin managers | PSGallery / manual clone |
| Menus | fzf + numbered fallback | Numbered menus |
| Tab completion | Full zsh completion | Branch name completion |
| Self-update | `gwt --update` | `Update-Module GWT` |
| Config migration | Auto-migrates from zshrc | N/A (config files only) |
| AI skill | `gwt --setup-skill` | N/A |
| Aliases | `gwt`/`wt` (configurable) | `gwt`/`wt` (via module manifest) |
| Flag style | `--stack`, `-s` | `-Stack` (PowerShell native) |

## License

MIT
