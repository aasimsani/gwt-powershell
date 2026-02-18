function New-GwtWorktree {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$BranchName,

        [switch]$Stack,

        [string]$From,

        [string[]]$CopyConfigDirs
    )

    # Validate we're in a git repo
    $repoRoot = git rev-parse --show-toplevel 2>$null
    if (-not $repoRoot) {
        Write-Error "Not in a git repository"
        return
    }

    # Validate branch name
    if (-not (Test-GwtBranch -Name $BranchName)) {
        Write-Error "Invalid branch name: $BranchName"
        return
    }

    # --stack and --from are mutually exclusive
    if ($Stack -and $From) {
        Write-Error "Cannot use --stack and --from together"
        return
    }

    # --stack requires non-detached HEAD
    if ($Stack) {
        $currentHead = git symbolic-ref --short HEAD 2>$null
        if (-not $currentHead) {
            Write-Error "Cannot use --stack in detached HEAD state"
            return
        }
    }

    # --from requires base branch to exist
    if ($From) {
        if (-not (Test-GwtBranch -Name $From)) {
            Write-Error "Invalid base branch name: $From"
            return
        }
        $localExists = git rev-parse --verify $From 2>$null
        $remoteExists = git rev-parse --verify "origin/$From" 2>$null
        if (-not $localExists -and -not $remoteExists) {
            Write-Error "Base branch '$From' not found"
            return
        }
    }

    $repoName = Split-Path $repoRoot -Leaf
    $repoParent = Split-Path $repoRoot -Parent

    # Build worktree suffix
    $worktreeSuffix = Get-GwtSuffix -BranchName $BranchName
    $worktreePath = Join-Path $repoParent "$repoName-$worktreeSuffix"

    # Check if worktree already exists
    if (Test-Path $worktreePath) {
        Write-Host "Worktree already exists at $worktreePath"
        Write-Host "Changing to existing worktree..."
        Set-Location $worktreePath
        return
    }

    Write-Host "Creating worktree..."
    Write-Host "  Branch: $BranchName"
    Write-Host "  Path: $worktreePath"

    # Fetch latest if origin exists (best effort)
    git fetch origin 2>$null | Out-Null

    # Collect copy directories from config
    $allCopyDirs = @()
    if ($CopyConfigDirs) {
        foreach ($dir in $CopyConfigDirs) {
            if (Test-GwtDirectory -Name $dir) {
                $allCopyDirs += $dir
            }
            else {
                Write-Error "Invalid directory name: $dir"
                return
            }
        }
    }

    # Add dirs from config (env var > local > global)
    $resolvedCopyDirs = Get-GwtConfig -Key 'GWT_COPY_DIRS' -Default ''
    if ($resolvedCopyDirs) {
        foreach ($dir in ($resolvedCopyDirs -split ',')) {
            $dir = $dir.Trim()
            if ($dir -and (Test-GwtDirectory -Name $dir)) {
                $allCopyDirs += $dir
            }
        }
    }

    # Determine base branch and path for metadata
    $baseBranch = ''
    $baseWorktreePath = ''
    $currentWorktreePath = (Get-Location).Path

    if ($From) {
        $baseBranch = $From
        # Find worktree path for this branch
        $wtListOutput = git worktree list --porcelain 2>$null
        $foundPath = $null
        $currentPath = $null
        foreach ($line in $wtListOutput) {
            if ($line -match '^worktree (.+)$') {
                $currentPath = $Matches[1]
            }
            if ($line -match "^branch refs/heads/$([regex]::Escape($From))$") {
                $foundPath = $currentPath
                break
            }
        }
        $baseWorktreePath = if ($foundPath) { $foundPath } else { $repoRoot }
    }
    elseif ($Stack) {
        $baseBranch = git branch --show-current 2>$null
        $baseWorktreePath = $currentWorktreePath
    }
    else {
        # Default: use main branch as base
        $mainBranch = Get-GwtMainBranch
        $mainExists = git rev-parse --verify $mainBranch 2>$null
        $mainRemoteExists = git rev-parse --verify "origin/$mainBranch" 2>$null
        if ($mainExists -or $mainRemoteExists) {
            $baseBranch = $mainBranch
            $baseWorktreePath = $repoRoot
        }
    }

    # Create the worktree
    $worktreeCreated = $false
    $gitError = ''

    # Try 1: Branch exists locally
    $localBranchExists = git rev-parse --verify $BranchName 2>$null
    if ($localBranchExists) {
        $gitError = git worktree add $worktreePath $BranchName 2>&1
        if ($LASTEXITCODE -eq 0) { $worktreeCreated = $true }
    }
    else {
        # Try 2: Branch exists on origin
        $remoteBranchExists = git rev-parse --verify "origin/$BranchName" 2>$null
        if ($remoteBranchExists) {
            $gitError = git worktree add $worktreePath $BranchName 2>&1
            if ($LASTEXITCODE -eq 0) { $worktreeCreated = $true }
        }
        else {
            # Try 3: New branch — determine base ref
            $baseRef = if ($baseBranch) { $baseBranch } else { 'HEAD' }
            $gitError = git worktree add -b $BranchName $worktreePath $baseRef 2>&1
            if ($LASTEXITCODE -eq 0) { $worktreeCreated = $true }
        }
    }

    if ($worktreeCreated) {
        # Copy configured directories
        if ($allCopyDirs.Count -gt 0) {
            Copy-GwtDirectories -SourceRoot $repoRoot -DestinationRoot $worktreePath -Directories $allCopyDirs
        }

        # Store metadata if we have a base branch (--stack or --from was used, or default main)
        if ($baseBranch) {
            Push-Location $worktreePath
            Set-GwtMetadata -BaseBranch $baseBranch -BaseWorktreePath $baseWorktreePath
            Pop-Location

            Push-Location $repoRoot
            Add-GwtRegistry -WorktreeName "$repoName-$worktreeSuffix" -BaseBranch $baseBranch -BasePath $baseWorktreePath
            Pop-Location
        }

        Write-Host ''
        Write-Host 'Worktree created successfully!'
        Set-Location $worktreePath

        # Run post-create hook
        Invoke-GwtPostCreate -RepoRoot $repoRoot
    }
    else {
        Write-Error "Failed to create worktree"
        if ($gitError) {
            Write-Error "Git error: $gitError"
        }
    }
}
