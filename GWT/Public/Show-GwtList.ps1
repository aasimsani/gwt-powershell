function Show-GwtList {
    [CmdletBinding()]
    param()

    $repoRoot = git rev-parse --show-toplevel 2>$null
    if (-not $repoRoot) {
        Write-Error "Not in a git repository"
        return
    }

    Write-Host ''

    $wtListOutput = git worktree list --porcelain 2>$null
    $worktrees = @()
    $currentPath = $null

    foreach ($line in $wtListOutput) {
        if ($line -match '^worktree (.+)$') {
            $currentPath = $Matches[1]
            if ($currentPath -ne $repoRoot) {
                $worktrees += $currentPath
            }
        }
    }

    if ($worktrees.Count -eq 0) {
        Write-Host '  No worktrees found'
        Write-Host ''
        return
    }

    foreach ($wtPath in $worktrees) {
        if (Test-Path $wtPath) {
            Push-Location $wtPath
            $wtBranch = git branch --show-current 2>$null
            if (-not $wtBranch) { $wtBranch = 'detached' }
            $wtBase = git config --worktree 'gwt.baseBranch' 2>$null
            Pop-Location

            if ($wtBase) {
                Write-Host "  └─ $wtPath ($wtBranch)"
            }
            else {
                Write-Host "  $wtPath ($wtBranch)"
            }
        }
        else {
            Write-Host "  $wtPath (missing)" -ForegroundColor Red
        }
    }

    Write-Host ''
}
