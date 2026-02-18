function Get-GwtSuffix {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$BranchName
    )

    # Try to extract eng-XXXX pattern (Linear ticket)
    if ($BranchName -match 'eng-\d+') {
        return $Matches[0]
    }

    # Strip prefix (everything before and including the first slash)
    $stripped = $BranchName -replace '^[^/]*/', ''

    # Split on hyphens and take first 3 words
    $words = $stripped -split '-'
    $taken = $words | Select-Object -First 3
    return ($taken -join '-')
}
