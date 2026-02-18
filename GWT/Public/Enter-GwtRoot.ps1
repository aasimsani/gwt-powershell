function Enter-GwtRoot {
    [CmdletBinding()]
    param()

    $gitCommonDir = git rev-parse --git-common-dir 2>$null

    if (-not $gitCommonDir) {
        Write-Error "Not in a git repository"
        return
    }

    # If git-common-dir returns ".git", we're already in main worktree
    if ($gitCommonDir -eq '.git') {
        Write-Host "Already in main worktree"
        return
    }

    # Get parent directory of .git (the main worktree path)
    $mainWorktree = Split-Path $gitCommonDir -Parent

    if (-not (Test-Path $mainWorktree)) {
        Write-Error "Main worktree no longer exists (expected: $mainWorktree)"
        return
    }

    Set-Location $mainWorktree
}
