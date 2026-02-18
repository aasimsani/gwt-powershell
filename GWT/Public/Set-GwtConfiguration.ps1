function Set-GwtConfiguration {
    [CmdletBinding()]
    param()

    # Determine config path based on scope
    $scope = 'global'
    $globalConfigPath = Join-Path $env:HOME '.config' 'gwt' 'config'

    $repoRoot = git rev-parse --show-toplevel 2>$null
    $localConfigPath = if ($repoRoot) { Join-Path $repoRoot '.gwt' 'config' } else { '' }

    $configPath = $globalConfigPath

    $done = $false
    while (-not $done) {
        # Read current values
        $currentMainBranch = Read-GwtConfigFile -Key 'GWT_MAIN_BRANCH' -Path $configPath
        $currentAlias = Read-GwtConfigFile -Key 'GWT_ALIAS' -Path $configPath
        $currentNoFzf = Read-GwtConfigFile -Key 'GWT_NO_FZF' -Path $configPath
        $currentPostCreate = Read-GwtConfigFile -Key 'GWT_POST_CREATE_CMD' -Path $configPath
        $currentCopyDirs = Read-GwtConfigFile -Key 'GWT_COPY_DIRS' -Path $configPath

        $scopeLabel = if ($scope -eq 'local') { 'local (.gwt/config)' } else { 'global (~/.config/gwt/config)' }
        $fzfState = if ($currentNoFzf -eq '1') { 'disabled' } else { 'enabled' }
        $mainBranchDisplay = if ($currentMainBranch) { $currentMainBranch } else { 'main (default)' }
        $aliasDisplay = if ($null -ne $currentAlias -and $currentAlias -ne '') { $currentAlias } else { 'wt (default)' }
        $postCreateDisplay = if ($currentPostCreate) { $currentPostCreate } else { 'not set' }
        $copyDirsDisplay = if ($currentCopyDirs) { $currentCopyDirs } else { 'none' }

        $options = @(
            "Copy directories [$copyDirsDisplay]"
            "Main branch [$mainBranchDisplay]"
            "Command alias [$aliasDisplay]"
            "Toggle fzf menus [$fzfState]"
            "Post-create command [$postCreateDisplay]"
            "Scope: $scopeLabel"
            'Done'
        )

        $selection = Show-GwtMenu -Title "GWT Configuration ($scopeLabel)" -Options $options -Prompt 'Select option'

        switch ($selection) {
            '1' {
                # Copy directories sub-menu
                Set-GwtCopyDirsConfig -ConfigPath $configPath
            }
            '2' {
                # Main branch
                $newValue = Read-Host '  Enter main branch name (empty to reset)'
                if ([string]::IsNullOrEmpty($newValue)) {
                    Write-GwtConfigFile -Key 'GWT_MAIN_BRANCH' -Value '' -Path $configPath
                    Write-GwtMessage -Message 'Main branch reset to default (main)' -Color 'Green' -Symbol '*'
                }
                elseif (Test-GwtBranch -Name $newValue) {
                    Write-GwtConfigFile -Key 'GWT_MAIN_BRANCH' -Value $newValue -Path $configPath
                    Write-GwtMessage -Message "Main branch set to: $newValue" -Color 'Green' -Symbol '*'
                }
                else {
                    Write-GwtMessage -Message "Invalid branch name: $newValue" -Color 'Red' -Symbol '!'
                }
            }
            '3' {
                # Alias sub-menu
                $aliasOptions = @('Set custom alias', 'Disable alias', 'Reset to default (wt)')
                $aliasChoice = Show-GwtMenu -Title 'Alias Configuration' -Options $aliasOptions -Prompt 'Select'
                switch ($aliasChoice) {
                    '1' {
                        $newAlias = Read-Host '  Enter custom alias'
                        if ($newAlias) {
                            Write-GwtConfigFile -Key 'GWT_ALIAS' -Value $newAlias -Path $configPath
                            Write-GwtMessage -Message "Alias set to: $newAlias" -Color 'Green' -Symbol '*'
                        }
                    }
                    '2' {
                        Write-GwtConfigFile -Key 'GWT_ALIAS' -Value '' -Path $configPath -KeepEmpty
                        Write-GwtMessage -Message 'Alias disabled' -Color 'Yellow' -Symbol '!'
                    }
                    '3' {
                        Write-GwtConfigFile -Key 'GWT_ALIAS' -Value '' -Path $configPath
                        Write-GwtMessage -Message 'Alias reset to default (wt)' -Color 'Green' -Symbol '*'
                    }
                }
            }
            '4' {
                # Toggle fzf
                if ($currentNoFzf -eq '1') {
                    Write-GwtConfigFile -Key 'GWT_NO_FZF' -Value '' -Path $configPath
                    Write-GwtMessage -Message 'fzf menus enabled' -Color 'Green' -Symbol '*'
                }
                else {
                    Write-GwtConfigFile -Key 'GWT_NO_FZF' -Value '1' -Path $configPath
                    Write-GwtMessage -Message 'fzf menus disabled' -Color 'Yellow' -Symbol '!'
                }
            }
            '5' {
                # Post-create command
                $postOptions = @('Set command', 'Clear command')
                $postChoice = Show-GwtMenu -Title 'Post-Create Command' -Options $postOptions -Prompt 'Select'
                switch ($postChoice) {
                    '1' {
                        $newCmd = Read-Host '  Enter post-create command'
                        if ($newCmd) {
                            Write-GwtConfigFile -Key 'GWT_POST_CREATE_CMD' -Value $newCmd -Path $configPath
                            Write-GwtMessage -Message "Post-create command set to: $newCmd" -Color 'Green' -Symbol '*'
                        }
                    }
                    '2' {
                        Write-GwtConfigFile -Key 'GWT_POST_CREATE_CMD' -Value '' -Path $configPath
                        Write-GwtMessage -Message 'Post-create command cleared' -Color 'Green' -Symbol '*'
                    }
                }
            }
            '6' {
                # Toggle scope
                if ($scope -eq 'global' -and $localConfigPath) {
                    $scope = 'local'
                    $configPath = $localConfigPath
                    Write-GwtMessage -Message 'Switched to local scope (.gwt/config)' -Color 'Cyan' -Symbol '>'
                }
                else {
                    $scope = 'global'
                    $configPath = $globalConfigPath
                    Write-GwtMessage -Message 'Switched to global scope (~/.config/gwt/config)' -Color 'Cyan' -Symbol '>'
                }
            }
            '7' {
                $done = $true
            }
            default {
                Write-GwtMessage -Message "Invalid choice: $selection" -Color 'Red' -Symbol '!'
            }
        }
    }
}

function Set-GwtCopyDirsConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ConfigPath
    )

    $done = $false
    while (-not $done) {
        $currentDirs = Read-GwtConfigFile -Key 'GWT_COPY_DIRS' -Path $ConfigPath
        $dirsDisplay = if ($currentDirs) { $currentDirs } else { 'none' }

        $options = @(
            'Add directory'
            'Remove directory'
            "List directories [$dirsDisplay]"
            'Back'
        )

        $selection = Show-GwtMenu -Title "Copy Directories [$dirsDisplay]" -Options $options -Prompt 'Select'

        switch ($selection) {
            '1' {
                $newDir = Read-Host '  Enter directory name'
                if (-not $newDir -or -not (Test-GwtDirectory -Name $newDir)) {
                    Write-GwtMessage -Message "Invalid directory name" -Color 'Red' -Symbol '!'
                    continue
                }

                $existing = Read-GwtConfigFile -Key 'GWT_COPY_DIRS' -Path $ConfigPath
                if ($existing -and ($existing -split ',' | ForEach-Object { $_.Trim() }) -contains $newDir) {
                    Write-GwtMessage -Message "Directory already configured: $newDir" -Color 'Yellow' -Symbol '!'
                }
                else {
                    $newValue = if ($existing) { "$existing,$newDir" } else { $newDir }
                    Write-GwtConfigFile -Key 'GWT_COPY_DIRS' -Value $newValue -Path $ConfigPath
                    Write-GwtMessage -Message "Added: $newDir" -Color 'Green' -Symbol '+'
                }
            }
            '2' {
                $removeDir = Read-Host '  Enter directory name to remove'
                $existing = Read-GwtConfigFile -Key 'GWT_COPY_DIRS' -Path $ConfigPath
                if (-not $existing) {
                    Write-GwtMessage -Message 'No directories configured' -Color 'Yellow' -Symbol '!'
                    continue
                }

                $dirs = ($existing -split ',') | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne $removeDir }
                $newValue = $dirs -join ','
                Write-GwtConfigFile -Key 'GWT_COPY_DIRS' -Value $newValue -Path $ConfigPath
                Write-GwtMessage -Message "Removed: $removeDir" -Color 'Green' -Symbol '-'
            }
            '3' {
                $existing = Read-GwtConfigFile -Key 'GWT_COPY_DIRS' -Path $ConfigPath
                if ($existing) {
                    Write-Host 'Configured directories:'
                    foreach ($d in ($existing -split ',')) {
                        Write-Host "  - $($d.Trim())"
                    }
                }
                else {
                    Write-Host 'No directories configured'
                }
            }
            '4' {
                $done = $true
            }
        }
    }
}
