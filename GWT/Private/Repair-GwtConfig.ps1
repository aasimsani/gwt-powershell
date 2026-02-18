function Repair-GwtConfig {
    [CmdletBinding()]
    param()

    # Check if worktreeConfig is enabled
    $worktreeConfig = git config extensions.worktreeConfig 2>$null
    if ($worktreeConfig -ne 'true') {
        return
    }

    # Check if config.worktree exists
    $gitDir = git rev-parse --git-dir 2>$null
    if (-not $gitDir) {
        return
    }

    $configWorktree = Join-Path $gitDir 'config.worktree'
    if (Test-Path $configWorktree) {
        return
    }

    # Repair: create config.worktree with core.bare=false
    '[core]' | Set-Content $configWorktree
    "	bare = false" | Add-Content $configWorktree

    Write-GwtMessage -Message 'config.worktree repaired (core.bare=false)' -Color 'Yellow' -Symbol '!'
}
