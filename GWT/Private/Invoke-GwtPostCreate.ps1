function Invoke-GwtPostCreate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$RepoRoot
    )

    # Option 1: Script file (.gwt/post-create.sh) takes precedence
    $scriptPath = Join-Path $RepoRoot '.gwt/post-create.sh'
    if (Test-Path $scriptPath) {
        # Check if executable (Unix only)
        if (-not $IsWindows) {
            $isExecutable = & test -x $scriptPath 2>$null
            if ($LASTEXITCODE -ne 0) {
                Write-GwtMessage -Message "post-create hook found but not executable: .gwt/post-create.sh" -Color 'Yellow' -Symbol '!'
                return
            }
        }

        Write-GwtMessage -Message "Running post-create hook: .gwt/post-create.sh" -Color 'Cyan' -Symbol '>'
        & $scriptPath 2>&1 | ForEach-Object { Write-Host $_ }
        if ($LASTEXITCODE -ne 0) {
            Write-GwtMessage -Message "post-create hook exited with code $LASTEXITCODE" -Color 'Yellow' -Symbol '!'
        }
        return
    }

    # Option 2: Environment variable / config command
    $postCreateCmd = Get-GwtConfig -Key 'GWT_POST_CREATE_CMD' -Default ''
    if ([string]::IsNullOrEmpty($postCreateCmd)) {
        return
    }

    Write-GwtMessage -Message "Running post-create hook: $postCreateCmd" -Color 'Cyan' -Symbol '>'
    $output = & pwsh -NoProfile -Command $postCreateCmd 2>&1
    $output | ForEach-Object { Write-Host $_ }
    if ($LASTEXITCODE -ne 0) {
        Write-GwtMessage -Message "post-create hook exited with code $LASTEXITCODE" -Color 'Yellow' -Symbol '!'
    }
}
