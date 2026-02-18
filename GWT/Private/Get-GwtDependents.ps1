function Get-GwtDependents {
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory)]
        [string]$BranchName
    )

    $registryEntries = git config --get-regexp '^gwt\.registry\..*\.basebranch$' 2>$null
    if (-not $registryEntries) {
        return @()
    }

    $dependents = @()
    foreach ($entry in $registryEntries) {
        # Format: gwt.registry.<name>.basebranch <value>
        if ($entry -match '^gwt\.registry\.(.+)\.basebranch\s+(.+)$') {
            $wtName = $Matches[1]
            $baseBranch = $Matches[2]
            if ($baseBranch -eq $BranchName) {
                $dependents += $wtName
            }
        }
    }

    return $dependents
}
