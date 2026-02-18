function Copy-GwtDirectories {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SourceRoot,

        [Parameter(Mandatory)]
        [string]$DestinationRoot,

        [Parameter(Mandatory)]
        [string[]]$Directories
    )

    foreach ($dir in $Directories) {
        $sourcePath = Join-Path $SourceRoot $dir
        $destPath = Join-Path $DestinationRoot $dir

        if (Test-Path $sourcePath) {
            Copy-Item -Path $sourcePath -Destination $destPath -Recurse -Force
        }
        else {
            Write-GwtMessage -Message "Warning: Directory '$dir' not found in source, skipping" -Color 'Yellow' -Symbol '!'
        }
    }
}
