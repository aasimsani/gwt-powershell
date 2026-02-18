function Show-GwtMenu {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Title,

        [Parameter(Mandatory)]
        [string[]]$Options,

        [string]$Prompt = 'Select'
    )

    Write-Host ''
    Write-Host $Title -ForegroundColor Cyan
    Write-Host ''

    for ($i = 0; $i -lt $Options.Count; $i++) {
        Write-Host "  $($i + 1)) $($Options[$i])"
    }

    Write-Host ''
    $selection = Read-Host "  $Prompt"
    return $selection
}
