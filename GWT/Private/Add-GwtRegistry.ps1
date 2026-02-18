function Add-GwtRegistry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$WorktreeName,

        [Parameter(Mandatory)]
        [string]$BaseBranch,

        [Parameter(Mandatory)]
        [string]$BasePath
    )

    git config "gwt.registry.$WorktreeName.baseBranch" $BaseBranch 2>$null
    git config "gwt.registry.$WorktreeName.basePath" $BasePath 2>$null
}
