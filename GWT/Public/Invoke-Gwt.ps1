function gwt {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$Command,

        [Parameter(Position = 1)]
        [string]$Argument,

        [Parameter(Position = 2)]
        [string]$Argument2,

        [switch]$Stack,

        [string]$From,

        [switch]$Info,

        [switch]$List,

        [switch]$Prune,

        [switch]$Config,

        [switch]$Repair,

        [switch]$Version,

        [switch]$Help,

        [string[]]$CopyConfigDirs,

        [switch]$ListCopyDirs,

        [switch]$Update
    )

    # Handle --help
    if ($Help) {
        Show-GwtHelp
        return
    }

    # Handle --version
    if ($Version) {
        Write-Host "gwt version $script:GWT_VERSION"
        return
    }

    # Handle --update
    if ($Update) {
        Write-Host "Updating GWT module from PSGallery..." -ForegroundColor Cyan
        Update-Module -Name GWT -Scope CurrentUser
        Write-Host "Done! Restart your shell to use the new version." -ForegroundColor Green
        return
    }

    # Handle --config (doesn't require git repo)
    if ($Config) {
        Set-GwtConfiguration
        return
    }

    # Handle --list-copy-dirs (doesn't require git repo)
    if ($ListCopyDirs) {
        $dirs = Get-GwtConfig -Key 'GWT_COPY_DIRS' -Default ''
        if ($dirs) {
            Write-Host 'Configured directories to copy:'
            foreach ($d in ($dirs -split ',')) {
                Write-Host "  - $($d.Trim())"
            }
        }
        else {
            Write-Host "No directories configured. Use 'gwt --config' to add."
        }
        return
    }

    # Handle --repair
    if ($Repair) {
        Repair-GwtConfig
        return
    }

    # Handle --info
    if ($Info) {
        Show-GwtInfo
        return
    }

    # Handle --list
    if ($List) {
        Show-GwtList
        return
    }

    # Handle --prune
    if ($Prune) {
        Remove-GwtWorktree
        return
    }

    # Handle unix-style double-dash flags (gwt --config, gwt --list, etc.)
    if ($Command -like '--*' -or ($Command -like '-?' -and $Command -ne '..')) {
        switch ($Command) {
            { $_ -in '--help', '-h' } {
                Show-GwtHelp; return
            }
            '--version' {
                Write-Host "gwt version $script:GWT_VERSION"; return
            }
            '--update' {
                Write-Host "Updating GWT module from PSGallery..." -ForegroundColor Cyan
                Update-Module -Name GWT -Scope CurrentUser
                Write-Host "Done! Restart your shell to use the new version." -ForegroundColor Green
                return
            }
            '--config' {
                Set-GwtConfiguration; return
            }
            '--list-copy-dirs' {
                $dirs = Get-GwtConfig -Key 'GWT_COPY_DIRS' -Default ''
                if ($dirs) {
                    Write-Host 'Configured directories to copy:'
                    foreach ($d in ($dirs -split ',')) {
                        Write-Host "  - $($d.Trim())"
                    }
                } else {
                    Write-Host "No directories configured. Use 'gwt --config' to add."
                }
                return
            }
            '--repair' {
                Repair-GwtConfig; return
            }
            { $_ -in '--info', '-i' } {
                Show-GwtInfo; return
            }
            '--list' {
                Show-GwtList; return
            }
            '--prune' {
                Remove-GwtWorktree; return
            }
            '--base' {
                Enter-GwtBase; return
            }
            '--root' {
                Enter-GwtRoot; return
            }
            { $_ -in '--stack', '-s' } {
                if (-not $Argument) {
                    Write-Error 'Branch name required: gwt --stack <branch>'
                    return
                }
                New-GwtWorktree -BranchName $Argument -Stack; return
            }
            { $_ -in '--from', '-f' } {
                if (-not $Argument -or -not $Argument2) {
                    Write-Error 'Usage: gwt --from <base-branch> <new-branch>'
                    return
                }
                New-GwtWorktree -BranchName $Argument2 -From $Argument; return
            }
            default {
                Write-Error "Unknown option: $Command"
                return
            }
        }
    }

    # Handle navigation shortcuts
    if ($Command -eq '..') {
        Enter-GwtBase
        return
    }
    if ($Command -eq '...') {
        Enter-GwtRoot
        return
    }

    # If no command, show help
    if (-not $Command) {
        Show-GwtHelp
        return
    }

    # Default: create worktree
    $params = @{
        BranchName = $Command
    }

    if ($Stack) {
        $params['Stack'] = $true
    }
    if ($From) {
        $params['From'] = $From
    }
    if ($CopyConfigDirs) {
        $params['CopyConfigDirs'] = $CopyConfigDirs
    }

    New-GwtWorktree @params
}

function Show-GwtHelp {
    [CmdletBinding()]
    param()

    $helpText = @"
gwt - Git Worktree helper for Linear tickets and regular branches

Usage: gwt [options] <branch-name>
       gwt <branch-name>              Create worktree from main branch (default)
       gwt --stack <branch-name>      Create worktree from current branch
       gwt --from <base> <branch>     Create worktree from specified branch
       gwt ..                         Navigate to parent worktree
       gwt ...                        Navigate to main worktree (ultimate root)

Both unix-style (--flag) and PowerShell-style (-Flag) work for all options.

Stacking Options:
  --stack, -s, -Stack       Create worktree from current branch (tracks parent)
  --from, -f, -From <base>  Create worktree from specified base branch
  --base, ..                Navigate to base/parent worktree
  --root, ...               Navigate to main worktree (ultimate root)
  --info, -i, -Info         Show stack info (base branch, dependents)

Worktree Management:
  --list, -List             List worktrees with hierarchy indicators
  --prune, -Prune           Interactive pruning (dependency-aware)
  --config, -Config         Configure default directories to copy
  -CopyConfigDirs <dir>     Copy directory to worktree (repeatable)
  --list-copy-dirs          List configured directories to copy

Other Options:
  --repair, -Repair         Fix broken worktree config (core.bare leak)
  --update, -Update         Update to latest version from PSGallery
  --version, -Version       Show version information
  --help, -h, -Help         Show this help message

Environment Variables:
  GWT_MAIN_BRANCH           Default base branch for new worktrees (default: main)
  GWT_COPY_DIRS             Comma-separated list of directories to always copy
  GWT_ALIAS                 Alias for gwt command (default: "wt", set "" to disable)
  GWT_NO_FZF                Set to 1 to disable fzf menus (use numbered fallback)
  GWT_POST_CREATE_CMD       Command to run after worktree creation (e.g. "npm install")

Config Files (local overrides global, env vars override both):
  Global: ~/.config/gwt/config
  Local:  .gwt/config (per-repo)

Examples:
  gwt feature/new-feature         Create worktree from main branch
  gwt --stack feature/child       Stack worktree from current branch
  gwt --from develop feature/x    Create worktree from develop branch
  gwt ..                          Navigate back to parent worktree
  gwt ...                         Navigate to main worktree (ultimate root)
  gwt --info                      Show current worktree's stack relationships
  gwt --list                      List all worktrees (shows hierarchy)
  gwt --prune                     Remove old worktrees (warns about dependents)
  gwt --config                    Configure all gwt settings interactively
"@
    Write-Host $helpText
}
