function Remove-GwtWorktree {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string[]]$WorktreePaths,

        [switch]$Force,

        [switch]$Cascade
    )

    $repoRoot = git rev-parse --show-toplevel 2>$null
    if (-not $repoRoot) {
        Write-Error "Not in a git repository"
        return
    }

    # Get list of worktrees (excluding main)
    $wtListOutput = git worktree list --porcelain 2>$null
    $allWorktrees = @()
    $currentPath = $null

    foreach ($line in $wtListOutput) {
        if ($line -match '^worktree (.+)$') {
            $currentPath = $Matches[1]
            if ($currentPath -ne $repoRoot) {
                $allWorktrees += $currentPath
            }
        }
    }

    if ($allWorktrees.Count -eq 0) {
        Write-Host ''
        Write-Host '  No worktrees to prune'
        Write-Host ''
        return
    }

    # If no paths specified, show interactive menu
    if (-not $WorktreePaths -or $WorktreePaths.Count -eq 0) {
        $worktreeDisplay = @()
        foreach ($wtPath in $allWorktrees) {
            if (Test-Path $wtPath) {
                Push-Location $wtPath
                $wtBranch = git branch --show-current 2>$null
                if (-not $wtBranch) { $wtBranch = 'detached' }
                Pop-Location
                $worktreeDisplay += "$wtPath ($wtBranch)"
            }
            else {
                $worktreeDisplay += "$wtPath (missing)"
            }
        }

        Write-Host ''
        Write-Host 'Select worktrees to prune:' -ForegroundColor White
        Write-Host ''
        for ($i = 0; $i -lt $worktreeDisplay.Count; $i++) {
            Write-Host "  $($i + 1)) $($worktreeDisplay[$i])"
        }
        Write-Host ''
        $maxNum = $worktreeDisplay.Count
        if ($maxNum -eq 1) {
            Write-Host "  Enter 1, all, or q to quit" -ForegroundColor DarkGray
        } else {
            Write-Host "  Space-separated numbers (e.g. 1 3), all, or q to quit" -ForegroundColor DarkGray
        }
        $selection = Read-Host "  >"

        if ($selection -eq 'q') { return }

        # Strip quotes if user typed 'all' with quotes
        $selection = $selection.Trim("'""")

        $toPrune = @()
        if ($selection -eq 'all') {
            $toPrune = $allWorktrees
        }
        else {
            foreach ($num in ($selection -split '\s+')) {
                if ($num -match '^\d+$') {
                    $idx = [int]$num - 1
                    if ($idx -ge 0 -and $idx -lt $allWorktrees.Count) {
                        $toPrune += $allWorktrees[$idx]
                    }
                }
            }
        }

        if ($toPrune.Count -eq 0) { return }

        # Check for uncommitted changes
        $hasChanges = @()
        foreach ($prunePath in $toPrune) {
            if (Test-Path $prunePath) {
                Push-Location $prunePath
                $status = git status --porcelain 2>$null
                Pop-Location
                if ($status) {
                    $hasChanges += $prunePath
                }
            }
        }

        # Show summary
        Write-Host ''
        Write-Host 'The following will be permanently deleted:' -ForegroundColor Red
        Write-Host ''
        foreach ($prunePath in $toPrune) {
            if (Test-Path $prunePath) {
                Push-Location $prunePath
                $wtBranch = git branch --show-current 2>$null
                if (-not $wtBranch) { $wtBranch = 'detached' }
                Pop-Location
                Write-Host "  $prunePath ($wtBranch)"
            }
            else {
                Write-Host "  $prunePath (missing)" -ForegroundColor Red
            }
        }

        if ($hasChanges.Count -gt 0) {
            Write-Host ''
            Write-Host 'WARNING: Uncommitted changes in:' -ForegroundColor Yellow
            foreach ($changePath in $hasChanges) {
                Write-Host "  $changePath" -ForegroundColor Yellow
            }
        }

        Write-Host ''
        Write-Host "  Total: $($toPrune.Count) worktree(s) to delete"
        Write-Host ''
        $confirm1 = Read-Host '  Confirm deletion? (y/N)'
        if ($confirm1 -ne 'y' -and $confirm1 -ne 'Y') {
            Write-Host '  Cancelled'
            return
        }

        $confirm2 = Read-Host "  Type 'DELETE' to confirm"
        if ($confirm2 -ne 'DELETE') {
            Write-Host '  Cancelled'
            return
        }

        # Delete
        Write-Host ''
        Write-Host 'Deleting...'
        foreach ($prunePath in $toPrune) {
            Set-Location $repoRoot

            if ($Cascade) {
                # Get branch name for cascade
                if (Test-Path $prunePath) {
                    Push-Location $prunePath
                    $pruneBranch = git branch --show-current 2>$null
                    Pop-Location
                    if ($pruneBranch) {
                        Invoke-GwtPruneCascade -BranchName $pruneBranch -RepoRoot $repoRoot
                    }
                }
            }

            Invoke-GwtPruneWorktree -WorktreePath $prunePath
            Write-Host "  $prunePath"
        }

        Set-Location $repoRoot
        git worktree prune 2>$null
        Write-Host ''
        Write-Host "Done! Removed $($toPrune.Count) worktree(s)"
    }
    else {
        # Non-interactive: prune specified paths
        foreach ($prunePath in $WorktreePaths) {
            if ($PSCmdlet.ShouldProcess($prunePath, 'Remove worktree')) {
                if ($Cascade) {
                    if (Test-Path $prunePath) {
                        Push-Location $prunePath
                        $pruneBranch = git branch --show-current 2>$null
                        Pop-Location
                        if ($pruneBranch) {
                            Invoke-GwtPruneCascade -BranchName $pruneBranch -RepoRoot $repoRoot
                        }
                    }
                }

                Invoke-GwtPruneWorktree -WorktreePath $prunePath
            }
        }
        Set-Location $repoRoot
        git worktree prune 2>$null
    }
}
