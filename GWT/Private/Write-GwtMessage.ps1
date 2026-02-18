function Write-GwtMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [ValidateSet('Green', 'Red', 'Yellow', 'Cyan', 'Gray', 'White')]
        [string]$Color = 'White',

        [string]$Symbol
    )

    $prefix = if ($Symbol) { "$Symbol " } else { '' }
    Write-Host "  ${prefix}${Message}" -ForegroundColor $Color
}
