function Get-GwtMetadata {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('baseBranch', 'baseWorktreePath')]
        [string]$Property
    )

    $value = git config --worktree "gwt.$Property" 2>$null
    return $value
}
