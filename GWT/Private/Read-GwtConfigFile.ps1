function Read-GwtConfigFile {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Key,

        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path $Path)) {
        return $null
    }

    $lines = Get-Content $Path -ErrorAction SilentlyContinue
    foreach ($line in $lines) {
        # Skip comments and blank lines
        if ([string]::IsNullOrWhiteSpace($line) -or $line.TrimStart().StartsWith('#')) {
            continue
        }

        # Match KEY=VALUE pattern
        if ($line -match "^$([regex]::Escape($Key))=(.*)$") {
            $value = $Matches[1]
            # Strip surrounding quotes
            $value = $value -replace '^"(.*)"$', '$1'
            $value = $value -replace "^'(.*)'$", '$1'
            if ([string]::IsNullOrEmpty($value)) {
                return $null
            }
            return $value
        }
    }

    return $null
}
