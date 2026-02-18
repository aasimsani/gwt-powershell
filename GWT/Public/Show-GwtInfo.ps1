function Show-GwtInfo {
    [CmdletBinding()]
    param()

    $currentBranch = git branch --show-current 2>$null
    $worktreePath = (Get-Location).Path

    Write-Host ''
    Write-Host 'Worktree Info' -ForegroundColor Cyan
    Write-Host ''
    Write-Host "  Branch: $currentBranch"
    Write-Host "  Path: $worktreePath"
    Write-Host ''

    # Main worktree info
    $gitCommonDir = git rev-parse --git-common-dir 2>$null
    if ($gitCommonDir -and $gitCommonDir -ne '.git') {
        $mainWorktree = Split-Path $gitCommonDir -Parent
        Write-Host 'Main Worktree (use gwt ... or Enter-GwtRoot to navigate)' -ForegroundColor Cyan
        Write-Host ''
        Write-Host "  Path: $mainWorktree"
        Write-Host ''
    }

    # Base worktree info
    $baseBranch = Get-GwtMetadata -Property 'baseBranch'
    $basePath = Get-GwtMetadata -Property 'baseWorktreePath'

    if ($baseBranch) {
        Write-Host 'Base Worktree (use gwt .. or Enter-GwtBase to navigate)' -ForegroundColor Cyan
        Write-Host ''
        if (Test-Path $basePath) {
            Write-Host "  Branch: $baseBranch"
            Write-Host "  Path: $basePath"
        }
        else {
            Write-Host "  Branch: $baseBranch (missing)" -ForegroundColor Red
            Write-Host "  Path: $basePath (not found)"
        }
        Write-Host ''
    }
    else {
        Write-Host '  Base: not tracked (worktree was not created with --stack or --from)'
        Write-Host ''
    }

    # Dependents
    $dependents = Get-GwtDependents -BranchName $currentBranch
    if ($dependents) {
        Write-Host 'Dependents (worktrees based on this branch)' -ForegroundColor Cyan
        Write-Host ''
        foreach ($dep in $dependents) {
            if ($dep) {
                Write-Host "  ├─ $dep"
            }
        }
        Write-Host ''
    }
}
