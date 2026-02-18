function Remove-GwtRegistry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$WorktreeName
    )

    git config --remove-section "gwt.registry.$WorktreeName" 2>$null
}
