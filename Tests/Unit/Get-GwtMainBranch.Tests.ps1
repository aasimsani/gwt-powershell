BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '../../GWT/GWT.psd1'
    Import-Module $modulePath -Force
}

Describe 'Get-GwtMainBranch' {
    BeforeEach {
        $script:testDir = Join-Path ([System.IO.Path]::GetTempPath()) "gwt-mb-$([guid]::NewGuid().ToString('N').Substring(0, 8))"
        New-Item -ItemType Directory -Path $script:testDir -Force | Out-Null
        $script:origHome = $env:HOME
        $script:origMainBranch = $env:GWT_MAIN_BRANCH
    }

    AfterEach {
        $env:HOME = $script:origHome
        $env:GWT_MAIN_BRANCH = $script:origMainBranch
        Remove-Item $script:testDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'returns GWT_MAIN_BRANCH when set' {
        $env:HOME = $script:testDir
        $env:GWT_MAIN_BRANCH = 'develop'

        $result = InModuleScope GWT { Get-GwtMainBranch }

        $result | Should -Be 'develop'
    }

    It 'defaults to main when not set' {
        $env:HOME = $script:testDir
        $env:GWT_MAIN_BRANCH = $null

        $result = InModuleScope GWT { Get-GwtMainBranch }

        $result | Should -Be 'main'
    }

    It 'reads from global config file' {
        $env:HOME = $script:testDir
        $env:GWT_MAIN_BRANCH = $null
        $globalConfigDir = Join-Path $script:testDir '.config/gwt'
        New-Item -ItemType Directory -Path $globalConfigDir -Force | Out-Null
        'GWT_MAIN_BRANCH=develop' | Set-Content (Join-Path $globalConfigDir 'config')

        $result = InModuleScope GWT { Get-GwtMainBranch }

        $result | Should -Be 'develop'
    }

    It 'local config overrides global' {
        $env:HOME = $script:testDir
        $env:GWT_MAIN_BRANCH = $null

        # Global config
        $globalConfigDir = Join-Path $script:testDir '.config/gwt'
        New-Item -ItemType Directory -Path $globalConfigDir -Force | Out-Null
        'GWT_MAIN_BRANCH=develop' | Set-Content (Join-Path $globalConfigDir 'config')

        # Local repo config
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

        $result = InModuleScope GWT { Get-GwtMainBranch }

        Pop-Location
        $result | Should -Be 'staging'
    }

    It 'env var still wins over config files' {
        $env:HOME = $script:testDir
        $env:GWT_MAIN_BRANCH = 'production'

        # Global config
        $globalConfigDir = Join-Path $script:testDir '.config/gwt'
        New-Item -ItemType Directory -Path $globalConfigDir -Force | Out-Null
        'GWT_MAIN_BRANCH=develop' | Set-Content (Join-Path $globalConfigDir 'config')

        $result = InModuleScope GWT { Get-GwtMainBranch }

        $result | Should -Be 'production'
    }
}
