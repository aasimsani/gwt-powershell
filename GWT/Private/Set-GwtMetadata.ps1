function Set-GwtMetadata {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$BaseBranch,

        [Parameter(Mandatory)]
        [string]$BaseWorktreePath
    )

    # Enable worktree-specific config
    git config extensions.worktreeConfig true 2>$null

    # Ensure main worktree has config.worktree with core.bare=false
    $gitCommonDir = git rev-parse --git-common-dir 2>$null
    if ($gitCommonDir -and $gitCommonDir -ne '.git') {
        $mainConfigWorktree = Join-Path $gitCommonDir 'config.worktree'
        if (-not (Test-Path $mainConfigWorktree)) {
            '[core]' | Set-Content $mainConfigWorktree
            "	bare = false" | Add-Content $mainConfigWorktree
        }
    }
    else {
        # We're in the main worktree
        $mainConfigWorktree = Join-Path (git rev-parse --git-dir 2>$null) 'config.worktree'
        if (-not (Test-Path $mainConfigWorktree)) {
            '[core]' | Set-Content $mainConfigWorktree
            "	bare = false" | Add-Content $mainConfigWorktree
        }
    }

    # Ensure current worktree has config.worktree with core.bare=false
    $gitDir = git rev-parse --git-dir 2>$null
    $currentConfigWorktree = Join-Path $gitDir 'config.worktree'
    if (-not (Test-Path $currentConfigWorktree)) {
        '[core]' | Set-Content $currentConfigWorktree
        "	bare = false" | Add-Content $currentConfigWorktree
    }

    # Write core.bare=false to current worktree config
    git config --worktree core.bare false 2>$null

    # Store metadata in worktree-local config
    git config --worktree gwt.baseBranch $BaseBranch 2>$null
    git config --worktree gwt.baseWorktreePath $BaseWorktreePath 2>$null
}
