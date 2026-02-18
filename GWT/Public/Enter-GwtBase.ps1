function Enter-GwtBase {
    [CmdletBinding()]
    param()

    # Get base worktree path from metadata
    $basePath = Get-GwtMetadata -Property 'baseWorktreePath'

    if (-not $basePath) {
        Write-Error "No base worktree tracked for this worktree"
        return
    }

    # Check if base worktree still exists
    if (-not (Test-Path $basePath)) {
        $baseBranch = Get-GwtMetadata -Property 'baseBranch'
        Write-Error "Base worktree no longer exists (branch: $baseBranch, path: $basePath)"
        return
    }

    Set-Location $basePath
}
