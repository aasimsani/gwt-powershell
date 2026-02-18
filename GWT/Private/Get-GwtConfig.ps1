function Get-GwtConfig {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Key,

        [string]$Default = ''
    )

    # Layer 1: Environment variable (highest priority)
    $envValue = [System.Environment]::GetEnvironmentVariable($Key)
    if (-not [string]::IsNullOrEmpty($envValue)) {
        return $envValue
    }

    # Layer 2: Local config (.gwt/config in repo root)
    $repoRoot = git rev-parse --show-toplevel 2>$null
    if ($repoRoot) {
        $localConfig = Join-Path $repoRoot '.gwt/config'
        $localValue = Read-GwtConfigFile -Key $Key -Path $localConfig
        if (-not [string]::IsNullOrEmpty($localValue)) {
            return $localValue
        }
    }

    # Layer 3: Global config (~/.config/gwt/config)
    $globalConfig = Join-Path $env:HOME '.config/gwt/config'
    $globalValue = Read-GwtConfigFile -Key $Key -Path $globalConfig
    if (-not [string]::IsNullOrEmpty($globalValue)) {
        return $globalValue
    }

    # Layer 4: Default
    return $Default
}

function Get-GwtMainBranch {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    return Get-GwtConfig -Key 'GWT_MAIN_BRANCH' -Default 'main'
}
