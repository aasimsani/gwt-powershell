function Write-GwtConfigFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Key,

        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Value,

        [Parameter(Mandatory)]
        [string]$Path,

        [switch]$KeepEmpty
    )

    # Sanitize value: strip backticks, dollar signs, backslashes, and quotes
    $Value = $Value -replace '[`$\\"'']', ''

    # Create parent directories if needed
    $parentDir = Split-Path $Path -Parent
    if (-not (Test-Path $parentDir)) {
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }

    # If file doesn't exist, create it
    if (-not (Test-Path $Path)) {
        New-Item -ItemType File -Path $Path -Force | Out-Null
    }

    $lines = @(Get-Content $Path -ErrorAction SilentlyContinue)

    # Remove existing line with this key
    $escapedKey = [regex]::Escape($Key)
    $newLines = @($lines | Where-Object { $_ -notmatch "^$escapedKey=" })

    # Add new line if value is non-empty OR KeepEmpty is set
    if (-not [string]::IsNullOrEmpty($Value)) {
        $newLines += "$Key=$Value"
    }
    elseif ($KeepEmpty) {
        $newLines += "$Key="
    }

    if ($newLines.Count -eq 0) {
        Set-Content $Path -Value ''
    }
    else {
        $newLines | Set-Content $Path
    }
}
