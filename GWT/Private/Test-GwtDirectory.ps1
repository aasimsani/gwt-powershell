function Test-GwtDirectory {
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

    # Reject absolute paths (Unix and Windows)
    if ($Name -match '^/' -or $Name -match '^[A-Za-z]:') {
        return $false
    }

    # Reject dangerous characters: semicolon, pipe, backtick, dollar, newline,
    # space, backslash, ampersand, curly braces, parentheses
    if ($Name -match '[;|`$\s\\&\{\}\(\)]') {
        return $false
    }

    return $true
}
