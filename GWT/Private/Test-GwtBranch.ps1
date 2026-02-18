function Test-GwtBranch {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Name
    )

    if ([string]::IsNullOrEmpty($Name)) {
        return $false
    }

    # Reject path traversal
    if ($Name -match '\.\.') {
        return $false
    }

    # Reject dangerous characters: semicolon, pipe, backtick, dollar, newline,
    # space, backslash, ampersand
    # Note: slashes are allowed in branch names (feature/thing), dots are allowed (v1.2.3)
    if ($Name -match '[;|`$\s\\&]') {
        return $false
    }

    return $true
}
