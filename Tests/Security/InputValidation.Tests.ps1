BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '../../GWT/GWT.psd1'
    Import-Module $modulePath -Force
    Import-Module (Join-Path $PSScriptRoot '../Helpers/TestHelper.psm1') -Force
}

Describe 'Security - CopyConfigDirs Input Validation' {
    BeforeEach {
        $script:ctx = New-GwtTestRepo
    }

    AfterEach {
        $env:GWT_COPY_DIRS = $null
        Remove-GwtTestRepo -TestContext $script:ctx
    }

    It 'rejects path traversal in --copy-config-dirs' {
        $err = $null
        New-GwtWorktree -BranchName 'test/eng-6000-traversal' -CopyConfigDirs @('../../../etc') -ErrorVariable err -ErrorAction SilentlyContinue *> $null

        $err | Should -Not -BeNullOrEmpty
    }

    It 'shows error for path traversal' {
        $err = $null
        New-GwtWorktree -BranchName 'test/eng-6000-traversal2' -CopyConfigDirs @('../../../etc') -ErrorVariable err -ErrorAction SilentlyContinue *> $null

        "$err" | Should -BeLike '*Invalid directory*'
    }

    It 'rejects absolute paths' {
        $err = $null
        New-GwtWorktree -BranchName 'test/eng-6001-absolute' -CopyConfigDirs @('/etc/passwd') -ErrorVariable err -ErrorAction SilentlyContinue *> $null

        $err | Should -Not -BeNullOrEmpty
    }

    It 'shows error for absolute path' {
        $err = $null
        New-GwtWorktree -BranchName 'test/eng-6001-absolute2' -CopyConfigDirs @('/etc/passwd') -ErrorVariable err -ErrorAction SilentlyContinue *> $null

        "$err" | Should -BeLike '*Invalid directory*'
    }

    It 'rejects shell metacharacters' {
        $err = $null
        New-GwtWorktree -BranchName 'test/eng-6002-injection' -CopyConfigDirs @('foo;rm -rf /') -ErrorVariable err -ErrorAction SilentlyContinue *> $null

        $err | Should -Not -BeNullOrEmpty
    }

    It 'shows error for metacharacters' {
        $err = $null
        New-GwtWorktree -BranchName 'test/eng-6002-injection2' -CopyConfigDirs @('foo;rm -rf /') -ErrorVariable err -ErrorAction SilentlyContinue *> $null

        "$err" | Should -BeLike '*Invalid directory*'
    }

    It 'GWT_COPY_DIRS with malicious content is filtered' {
        New-Item -ItemType Directory -Path (Join-Path $script:ctx.RepoDir 'serena') -Force | Out-Null
        'config' | Set-Content -Path (Join-Path $script:ctx.RepoDir 'serena/config.yml')
        $env:GWT_COPY_DIRS = '../../../etc,serena,/etc/passwd'

        $err = $null
        New-GwtWorktree -BranchName 'test/eng-9001-env-security' -ErrorVariable err -ErrorAction SilentlyContinue *> $null
        Set-Location $script:ctx.RepoDir

        # Should succeed (malicious dirs filtered out, serena is valid)
        $err | Should -BeNullOrEmpty
    }
}

Describe 'Security - Config Write Sanitization' {
    BeforeEach {
        $script:ctx = New-GwtTestRepo
        $script:configPath = Join-Path $script:ctx.TestDir 'test-config'
        '# test' | Set-Content -Path $script:configPath
    }

    AfterEach {
        Remove-GwtTestRepo -TestContext $script:ctx
    }

    It 'config write sanitizes backticks' {
        InModuleScope GWT -Parameters @{ ConfigPath = $script:configPath } {
            param($ConfigPath)
            Write-GwtConfigFile -Key 'GWT_COPY_DIRS' -Value 'serena`whoami`' -Path $ConfigPath
        }

        $content = Get-Content $script:configPath -Raw
        $content | Should -Not -BeLike '*``*'
    }

    It 'config write sanitizes dollar signs' {
        InModuleScope GWT -Parameters @{ ConfigPath = $script:configPath } {
            param($ConfigPath)
            Write-GwtConfigFile -Key 'GWT_COPY_DIRS' -Value 'serena$(whoami)' -Path $ConfigPath
        }

        $content = Get-Content $script:configPath -Raw
        $content | Should -Not -BeLike '*$(*'
    }

    It 'config write sanitizes quotes' {
        InModuleScope GWT -Parameters @{ ConfigPath = $script:configPath } {
            param($ConfigPath)
            Write-GwtConfigFile -Key 'GWT_COPY_DIRS' -Value 'serena"; echo "pwned' -Path $ConfigPath
        }

        $content = Get-Content $script:configPath -Raw
        # Quotes should be stripped - no injection possible
        $content | Should -Not -BeLike '*"*'
    }
}
