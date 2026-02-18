BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '../../GWT/GWT.psd1'
    Import-Module $modulePath -Force
    Import-Module (Join-Path $PSScriptRoot '../Helpers/TestHelper.psm1') -Force
}

Describe 'Set-GwtConfiguration' {
    BeforeEach {
        $script:ctx = New-GwtTestRepo
        $script:configDir = Join-Path $script:ctx.TestDir '.config' 'gwt'
        New-Item -ItemType Directory -Path $script:configDir -Force | Out-Null
        '' | Set-Content -Path (Join-Path $script:configDir 'config')
        $script:configPath = Join-Path $script:configDir 'config'
    }

    AfterEach {
        Remove-GwtTestRepo -TestContext $script:ctx
    }

    It 'top-level menu shows all settings' {
        # Select 7 (Done) immediately
        Mock Read-Host { return '7' } -ModuleName GWT

        $output = Set-GwtConfiguration 6>&1 *>&1

        "$output" | Should -BeLike '*Copy directories*'
        "$output" | Should -BeLike '*Main branch*'
        "$output" | Should -BeLike '*alias*'
        "$output" | Should -BeLike '*fzf*'
        "$output" | Should -BeLike '*Post-create*'
        "$output" | Should -BeLike '*Done*'
    }

    It 'main branch setting via menu' {
        $script:readHostCallCount = 0
        Mock Read-Host {
            $script:readHostCallCount++
            if ($script:readHostCallCount -eq 1) { return '2' }      # Main branch
            if ($script:readHostCallCount -eq 2) { return 'develop' } # Enter name
            return '7'                                                  # Done
        } -ModuleName GWT

        Set-GwtConfiguration *> $null

        $result = InModuleScope GWT -Parameters @{ ConfigPath = $script:configPath } {
            param($ConfigPath)
            Read-GwtConfigFile -Key 'GWT_MAIN_BRANCH' -Path $ConfigPath
        }
        $result | Should -Be 'develop'
    }

    It 'main branch rejects invalid names' {
        $script:readHostCallCount = 0
        Mock Read-Host {
            $script:readHostCallCount++
            if ($script:readHostCallCount -eq 1) { return '2' }
            if ($script:readHostCallCount -eq 2) { return 'bad branch name' }
            return '7'
        } -ModuleName GWT

        $output = Set-GwtConfiguration 6>&1 *>&1

        "$output" | Should -BeLike '*Invalid*'
    }

    It 'main branch reset to default' {
        # Pre-populate with a value
        'GWT_MAIN_BRANCH=develop' | Set-Content -Path $script:configPath

        $script:readHostCallCount = 0
        Mock Read-Host {
            $script:readHostCallCount++
            if ($script:readHostCallCount -eq 1) { return '2' }
            if ($script:readHostCallCount -eq 2) { return '' }
            return '7'
        } -ModuleName GWT

        Set-GwtConfiguration *> $null

        $result = InModuleScope GWT -Parameters @{ ConfigPath = $script:configPath } {
            param($ConfigPath)
            Read-GwtConfigFile -Key 'GWT_MAIN_BRANCH' -Path $ConfigPath
        }
        $result | Should -BeNullOrEmpty
    }

    It 'alias set custom' {
        $script:readHostCallCount = 0
        Mock Read-Host {
            $script:readHostCallCount++
            if ($script:readHostCallCount -eq 1) { return '3' }  # Alias
            if ($script:readHostCallCount -eq 2) { return '1' }  # Set custom
            if ($script:readHostCallCount -eq 3) { return 'gw' } # Enter alias
            return '7'
        } -ModuleName GWT

        Set-GwtConfiguration *> $null

        $result = InModuleScope GWT -Parameters @{ ConfigPath = $script:configPath } {
            param($ConfigPath)
            Read-GwtConfigFile -Key 'GWT_ALIAS' -Path $ConfigPath
        }
        $result | Should -Be 'gw'
    }

    It 'alias disable' {
        'GWT_ALIAS=wt' | Set-Content -Path $script:configPath

        $script:readHostCallCount = 0
        Mock Read-Host {
            $script:readHostCallCount++
            if ($script:readHostCallCount -eq 1) { return '3' } # Alias
            if ($script:readHostCallCount -eq 2) { return '2' } # Disable
            return '7'
        } -ModuleName GWT

        Set-GwtConfiguration *> $null

        $content = Get-Content $script:configPath -Raw
        $content | Should -BeLike '*GWT_ALIAS=*'
    }

    It 'alias reset to default' {
        'GWT_ALIAS=gw' | Set-Content -Path $script:configPath

        $script:readHostCallCount = 0
        Mock Read-Host {
            $script:readHostCallCount++
            if ($script:readHostCallCount -eq 1) { return '3' } # Alias
            if ($script:readHostCallCount -eq 2) { return '3' } # Reset
            return '7'
        } -ModuleName GWT

        Set-GwtConfiguration *> $null

        $content = Get-Content $script:configPath -Raw
        $content | Should -Not -BeLike '*GWT_ALIAS*'
    }

    It 'no-fzf toggle on' {
        $script:readHostCallCount = 0
        Mock Read-Host {
            $script:readHostCallCount++
            if ($script:readHostCallCount -eq 1) { return '4' } # Toggle fzf
            return '7'
        } -ModuleName GWT

        Set-GwtConfiguration *> $null

        $content = Get-Content $script:configPath -Raw
        $content | Should -BeLike '*GWT_NO_FZF=1*'
    }

    It 'no-fzf toggle off' {
        'GWT_NO_FZF=1' | Set-Content -Path $script:configPath

        $script:readHostCallCount = 0
        Mock Read-Host {
            $script:readHostCallCount++
            if ($script:readHostCallCount -eq 1) { return '4' } # Toggle off
            return '7'
        } -ModuleName GWT

        Set-GwtConfiguration *> $null

        $content = Get-Content $script:configPath -Raw
        $content | Should -Not -BeLike '*GWT_NO_FZF*'
    }

    It 'post-create command set' {
        $script:readHostCallCount = 0
        Mock Read-Host {
            $script:readHostCallCount++
            if ($script:readHostCallCount -eq 1) { return '5' }            # Post-create
            if ($script:readHostCallCount -eq 2) { return '1' }            # Set
            if ($script:readHostCallCount -eq 3) { return 'npm install' }  # Command
            return '7'
        } -ModuleName GWT

        Set-GwtConfiguration *> $null

        $result = InModuleScope GWT -Parameters @{ ConfigPath = $script:configPath } {
            param($ConfigPath)
            Read-GwtConfigFile -Key 'GWT_POST_CREATE_CMD' -Path $ConfigPath
        }
        $result | Should -Be 'npm install'
    }

    It 'post-create command clear' {
        'GWT_POST_CREATE_CMD=npm install' | Set-Content -Path $script:configPath

        $script:readHostCallCount = 0
        Mock Read-Host {
            $script:readHostCallCount++
            if ($script:readHostCallCount -eq 1) { return '5' } # Post-create
            if ($script:readHostCallCount -eq 2) { return '2' } # Clear
            return '7'
        } -ModuleName GWT

        Set-GwtConfiguration *> $null

        $content = Get-Content $script:configPath -Raw
        $content | Should -Not -BeLike '*GWT_POST_CREATE_CMD*'
    }

    It 'scope toggle to local' {
        $script:readHostCallCount = 0
        Mock Read-Host {
            $script:readHostCallCount++
            if ($script:readHostCallCount -eq 1) { return '6' }          # Scope toggle
            if ($script:readHostCallCount -eq 2) { return '2' }          # Main branch
            if ($script:readHostCallCount -eq 3) { return 'staging' }    # Name
            return '7'
        } -ModuleName GWT

        Set-GwtConfiguration *> $null

        $localConfig = Join-Path $script:ctx.RepoDir '.gwt' 'config'
        $result = InModuleScope GWT -Parameters @{ ConfigPath = $localConfig } {
            param($ConfigPath)
            Read-GwtConfigFile -Key 'GWT_MAIN_BRANCH' -Path $ConfigPath
        }
        $result | Should -Be 'staging'
    }

    It 'copy-dirs sub-menu adds directory' {
        $script:readHostCallCount = 0
        Mock Read-Host {
            $script:readHostCallCount++
            if ($script:readHostCallCount -eq 1) { return '1' }      # Copy dirs
            if ($script:readHostCallCount -eq 2) { return '1' }      # Add
            if ($script:readHostCallCount -eq 3) { return 'serena' } # Dir name
            if ($script:readHostCallCount -eq 4) { return '4' }      # Back
            return '7'
        } -ModuleName GWT

        Set-GwtConfiguration *> $null

        $result = InModuleScope GWT -Parameters @{ ConfigPath = $script:configPath } {
            param($ConfigPath)
            Read-GwtConfigFile -Key 'GWT_COPY_DIRS' -Path $ConfigPath
        }
        $result | Should -Be 'serena'
    }

    It 'shows current values' {
        @'
GWT_MAIN_BRANCH=develop
GWT_ALIAS=gw
GWT_NO_FZF=1
'@ | Set-Content -Path $script:configPath

        Mock Read-Host { return '7' } -ModuleName GWT

        $output = Set-GwtConfiguration 6>&1 *>&1

        "$output" | Should -BeLike '*develop*'
        "$output" | Should -BeLike '*gw*'
        "$output" | Should -BeLike '*disabled*'
    }
}

Describe 'Config - Copy Dirs Sub-menu' {
    BeforeEach {
        $script:ctx = New-GwtTestRepo
        $script:configDir = Join-Path $script:ctx.TestDir '.config' 'gwt'
        New-Item -ItemType Directory -Path $script:configDir -Force | Out-Null
        '' | Set-Content -Path (Join-Path $script:configDir 'config')
        $script:configPath = Join-Path $script:configDir 'config'
    }

    AfterEach {
        Remove-GwtTestRepo -TestContext $script:ctx
    }

    It 'add directory to existing config' {
        'GWT_COPY_DIRS=serena' | Set-Content -Path $script:configPath

        $script:readHostCallCount = 0
        Mock Read-Host {
            $script:readHostCallCount++
            if ($script:readHostCallCount -eq 1) { return '1' }       # Copy dirs
            if ($script:readHostCallCount -eq 2) { return '1' }       # Add
            if ($script:readHostCallCount -eq 3) { return '.vscode' } # Dir
            if ($script:readHostCallCount -eq 4) { return '4' }       # Back
            return '7'
        } -ModuleName GWT

        Set-GwtConfiguration *> $null

        $result = InModuleScope GWT -Parameters @{ ConfigPath = $script:configPath } {
            param($ConfigPath)
            Read-GwtConfigFile -Key 'GWT_COPY_DIRS' -Path $ConfigPath
        }
        $result | Should -BeLike '*serena*'
        $result | Should -BeLike '*.vscode*'
    }

    It 'detects duplicate directory' {
        'GWT_COPY_DIRS=serena' | Set-Content -Path $script:configPath

        $script:readHostCallCount = 0
        Mock Read-Host {
            $script:readHostCallCount++
            if ($script:readHostCallCount -eq 1) { return '1' }      # Copy dirs
            if ($script:readHostCallCount -eq 2) { return '1' }      # Add
            if ($script:readHostCallCount -eq 3) { return 'serena' } # Duplicate
            if ($script:readHostCallCount -eq 4) { return '4' }      # Back
            return '7'
        } -ModuleName GWT

        $output = Set-GwtConfiguration 6>&1 *>&1

        "$output" | Should -BeLike '*already configured*'
    }

    It 'remove directory from config' {
        'GWT_COPY_DIRS=serena,.vscode' | Set-Content -Path $script:configPath

        $script:readHostCallCount = 0
        Mock Read-Host {
            $script:readHostCallCount++
            if ($script:readHostCallCount -eq 1) { return '1' }      # Copy dirs
            if ($script:readHostCallCount -eq 2) { return '2' }      # Remove
            if ($script:readHostCallCount -eq 3) { return 'serena' } # Dir to remove
            if ($script:readHostCallCount -eq 4) { return '4' }      # Back
            return '7'
        } -ModuleName GWT

        Set-GwtConfiguration *> $null

        $result = InModuleScope GWT -Parameters @{ ConfigPath = $script:configPath } {
            param($ConfigPath)
            Read-GwtConfigFile -Key 'GWT_COPY_DIRS' -Path $ConfigPath
        }
        $result | Should -Not -BeLike '*serena*'
        $result | Should -BeLike '*.vscode*'
    }

    It 'remove from empty shows message' {
        $script:readHostCallCount = 0
        Mock Read-Host {
            $script:readHostCallCount++
            if ($script:readHostCallCount -eq 1) { return '1' }      # Copy dirs
            if ($script:readHostCallCount -eq 2) { return '2' }      # Remove
            if ($script:readHostCallCount -eq 3) { return 'serena' } # Dir
            if ($script:readHostCallCount -eq 4) { return '4' }      # Back
            return '7'
        } -ModuleName GWT

        $output = Set-GwtConfiguration 6>&1 *>&1

        "$output" | Should -BeLike '*No directories configured*'
    }

    It 'list shows directories' {
        'GWT_COPY_DIRS=serena,.vscode' | Set-Content -Path $script:configPath

        $script:readHostCallCount = 0
        Mock Read-Host {
            $script:readHostCallCount++
            if ($script:readHostCallCount -eq 1) { return '1' } # Copy dirs
            if ($script:readHostCallCount -eq 2) { return '3' } # List
            if ($script:readHostCallCount -eq 3) { return '4' } # Back
            return '7'
        } -ModuleName GWT

        $output = Set-GwtConfiguration 6>&1 *>&1

        "$output" | Should -BeLike '*serena*'
        "$output" | Should -BeLike '*.vscode*'
    }

    It 'list empty shows no dirs message' {
        $script:readHostCallCount = 0
        Mock Read-Host {
            $script:readHostCallCount++
            if ($script:readHostCallCount -eq 1) { return '1' } # Copy dirs
            if ($script:readHostCallCount -eq 2) { return '3' } # List
            if ($script:readHostCallCount -eq 3) { return '4' } # Back
            return '7'
        } -ModuleName GWT

        $output = Set-GwtConfiguration 6>&1 *>&1

        "$output" | Should -BeLike '*No directories configured*'
    }
}

Describe 'Config outside git repo' {
    BeforeEach {
        $script:ctx = New-GwtTestRepo
        $script:configDir = Join-Path $script:ctx.TestDir '.config' 'gwt'
        New-Item -ItemType Directory -Path $script:configDir -Force | Out-Null
        '' | Set-Content -Path (Join-Path $script:configDir 'config')
    }

    AfterEach {
        Remove-GwtTestRepo -TestContext $script:ctx
    }

    It 'works outside git repo' {
        $notRepo = Join-Path $script:ctx.TestDir 'not-a-repo'
        New-Item -ItemType Directory -Path $notRepo -Force | Out-Null
        Push-Location $notRepo

        Mock Read-Host { return '7' } -ModuleName GWT

        $err = $null
        Set-GwtConfiguration -ErrorVariable err -ErrorAction SilentlyContinue *> $null
        Pop-Location

        $err | Should -BeNullOrEmpty
    }
}
