function Invoke-GwtPruneWorktree {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$WorktreePath
    )

    $wtName = Split-Path $WorktreePath -Leaf

    # Remove from git worktree
    git worktree remove --force $WorktreePath 2>$null

    # If directory still exists, remove it
    if (Test-Path $WorktreePath) {
        Remove-Item $WorktreePath -Recurse -Force -ErrorAction SilentlyContinue
    }

    # Clean up registry entry
    Remove-GwtRegistry -WorktreeName $wtName
}
