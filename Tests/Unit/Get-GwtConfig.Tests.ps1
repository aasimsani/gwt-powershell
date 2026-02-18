BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '../../GWT/GWT.psd1'
    Import-Module $modulePath -Force
}

Describe 'Get-GwtConfig (layered resolution)' {
    BeforeEach {
        $script:testDir = Join-Path ([System.IO.Path]::GetTempPath()) "gwt-cfg-$([guid]::NewGuid().ToString('N').Substring(0, 8))"
        New-Item -ItemType Directory -Path $script:testDir -Force | Out-Null
        $script:origHome = $env:HOME
    }

    AfterEach {
        $env:HOME = $script:origHome
        Remove-Item $script:testDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'returns default when nothing configured' {
        $env:HOME = $script:testDir
        # Ensure no env var
        $savedVal = $env:GWT_MAIN_BRANCH
        $env:GWT_MAIN_BRANCH = $null

        $result = InModuleScope GWT {
            Get-GwtConfig -Key 'GWT_MAIN_BRANCH' -Default 'main'
        }

        $env:GWT_MAIN_BRANCH = $savedVal
        $result | Should -Be 'main'
    }

    It 'reads from global config' {
        $env:HOME = $script:testDir
        $globalConfigDir = Join-Path $script:testDir '.config/gwt'
        New-Item -ItemType Directory -Path $globalConfigDir -Force | Out-Null
        'GWT_MAIN_BRANCH=develop' | Set-Content (Join-Path $globalConfigDir 'config')

        $savedVal = $env:GWT_MAIN_BRANCH
        $env:GWT_MAIN_BRANCH = $null

        $result = InModuleScope GWT {
            Get-GwtConfig -Key 'GWT_MAIN_BRANCH' -Default 'main'
        }

        $env:GWT_MAIN_BRANCH = $savedVal
        $result | Should -Be 'develop'
    }

    It 'local overrides global' {
        $env:HOME = $script:testDir
        # Global config
        $globalConfigDir = Join-Path $script:testDir '.config/gwt'
        New-Item -ItemType Directory -Path $globalConfigDir -Force | Out-Null
        'GWT_MAIN_BRANCH=develop' | Set-Content (Join-Path $globalConfigDir 'config')

        # Local config - need a git repo context
        $repoDir = Join-Path $script:testDir 'repo'
        New-Item -ItemType Directory -Path $repoDir -Force | Out-Null
        Push-Location $repoDir
        git init -q -b main 2>$null
        git config user.email 'test@test.com'
        git config user.name 'Test'
        'test' | Set-Content 'README.md'
        git add README.md
        git commit -q -m 'init' 2>$null

        $localConfigDir = Join-Path $repoDir '.gwt'
        New-Item -ItemType Directory -Path $localConfigDir -Force | Out-Null
        'GWT_MAIN_BRANCH=staging' | Set-Content (Join-Path $localConfigDir 'config')

        $savedVal = $env:GWT_MAIN_BRANCH
        $env:GWT_MAIN_BRANCH = $null

        $result = InModuleScope GWT {
            Get-GwtConfig -Key 'GWT_MAIN_BRANCH' -Default 'main'
        }

        $env:GWT_MAIN_BRANCH = $savedVal
        Pop-Location
        $result | Should -Be 'staging'
    }

    It 'env var overrides all' {
        $env:HOME = $script:testDir
        # Global config
        $globalConfigDir = Join-Path $script:testDir '.config/gwt'
        New-Item -ItemType Directory -Path $globalConfigDir -Force | Out-Null
        'GWT_MAIN_BRANCH=develop' | Set-Content (Join-Path $globalConfigDir 'config')

        $savedVal = $env:GWT_MAIN_BRANCH
        $env:GWT_MAIN_BRANCH = 'production'

        $result = InModuleScope GWT {
            Get-GwtConfig -Key 'GWT_MAIN_BRANCH' -Default 'main'
        }

        $env:GWT_MAIN_BRANCH = $savedVal
        $result | Should -Be 'production'
    }

    It 'falls through layers correctly' {
        $env:HOME = $script:testDir
        # Only global config set for alias, not main branch
        $globalConfigDir = Join-Path $script:testDir '.config/gwt'
        New-Item -ItemType Directory -Path $globalConfigDir -Force | Out-Null
        'GWT_ALIAS=gw' | Set-Content (Join-Path $globalConfigDir 'config')

        $savedAlias = $env:GWT_ALIAS
        $savedFzf = $env:GWT_NO_FZF
        $env:GWT_ALIAS = $null
        $env:GWT_NO_FZF = $null

        $resultAlias = InModuleScope GWT {
            Get-GwtConfig -Key 'GWT_ALIAS' -Default 'wt'
        }
        $resultFzf = InModuleScope GWT {
            Get-GwtConfig -Key 'GWT_NO_FZF' -Default ''
        }

        $env:GWT_ALIAS = $savedAlias
        $env:GWT_NO_FZF = $savedFzf

        $resultAlias | Should -Be 'gw'
        $resultFzf | Should -BeNullOrEmpty
    }
}
