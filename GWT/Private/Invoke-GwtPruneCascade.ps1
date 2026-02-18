function Invoke-GwtPruneCascade {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$BranchName,

        [Parameter(Mandatory)]
        [string]$RepoRoot
    )

    $repoParent = Split-Path $RepoRoot -Parent
    $dependents = Get-GwtDependents -BranchName $BranchName

    if ($dependents) {
        foreach ($depName in $dependents) {
            if (-not $depName) { continue }

            $depPath = Join-Path $repoParent $depName
            if (Test-Path $depPath) {
                # Get the branch of this dependent for recursive cascade
                Push-Location $depPath
                $depBranch = git branch --show-current 2>$null
                Pop-Location

                if ($depBranch) {
                    Invoke-GwtPruneCascade -BranchName $depBranch -RepoRoot $RepoRoot
                }

                Invoke-GwtPruneWorktree -WorktreePath $depPath
            }
        }
    }
}
