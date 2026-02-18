BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '../../GWT/GWT.psd1'
    Import-Module $modulePath -Force
    Import-Module (Join-Path $PSScriptRoot '../Helpers/TestHelper.psm1') -Force
}

Describe 'Show-GwtList --list-copy-dirs equivalent' {
    BeforeEach {
        $script:ctx = New-GwtTestRepo
        $script:origCopyDirs = $env:GWT_COPY_DIRS
        $env:GWT_COPY_DIRS = $null
    }

    AfterEach {
        $env:GWT_COPY_DIRS = $script:origCopyDirs
        Remove-GwtTestRepo -TestContext $script:ctx
    }

    It 'shows message when no config' {
        $output = InModuleScope GWT {
            $dirs = Get-GwtConfig -Key 'GWT_COPY_DIRS' -Default ''
            if ($dirs) {
                "Configured: $dirs"
            }
            else {
                'No directories configured'
            }
        }

        "$output" | Should -BeLike '*No directories configured*'
    }

    It 'shows configured dirs' {
        # Write to global config
        $configDir = Join-Path $script:ctx.TestDir '.config' 'gwt'
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
        'GWT_COPY_DIRS=serena,.vscode' | Set-Content -Path (Join-Path $configDir 'config')

        $output = InModuleScope GWT {
            $dirs = Get-GwtConfig -Key 'GWT_COPY_DIRS' -Default ''
            $dirs
        }

        "$output" | Should -BeLike '*serena*'
        "$output" | Should -BeLike '*.vscode*'
    }

    It 'works outside git repo' {
        $notRepo = Join-Path $script:ctx.TestDir 'not-a-repo'
        New-Item -ItemType Directory -Path $notRepo -Force | Out-Null
        Push-Location $notRepo

        # list-copy-dirs doesn't require a git repo
        $output = InModuleScope GWT {
            $dirs = Get-GwtConfig -Key 'GWT_COPY_DIRS' -Default ''
            if ($dirs) { $dirs } else { 'No directories configured' }
        }
        Pop-Location

        "$output" | Should -Not -BeNullOrEmpty
    }
}
