function Clear-GwtMetadata {
    [CmdletBinding()]
    param()

    git config --worktree --unset gwt.baseBranch 2>$null
    git config --worktree --unset gwt.baseWorktreePath 2>$null
}
