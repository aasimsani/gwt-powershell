BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '../../GWT/GWT.psd1'
    Import-Module $modulePath -Force
    Import-Module (Join-Path $PSScriptRoot '../Helpers/TestHelper.psm1') -Force
}

Describe 'New-GwtWorktree - CopyConfigDirs Flag' {
    BeforeEach {
        $script:ctx = New-GwtTestRepo
    }

    AfterEach {
        Remove-GwtTestRepo -TestContext $script:ctx
    }

    It 'creates worktree successfully with copy-config-dirs' {
        New-Item -ItemType Directory -Path (Join-Path $script:ctx.RepoDir 'serena') -Force | Out-Null
        'config' | Set-Content -Path (Join-Path $script:ctx.RepoDir 'serena/config.yml')

        $err = $null
        New-GwtWorktree -BranchName 'test/eng-5000-copy-test' -CopyConfigDirs @('serena') -ErrorVariable err -ErrorAction SilentlyContinue *> $null
        Set-Location $script:ctx.RepoDir

        $err | Should -BeNullOrEmpty
    }

    It 'copies config dir to worktree' {
        New-Item -ItemType Directory -Path (Join-Path $script:ctx.RepoDir 'serena') -Force | Out-Null
        'config' | Set-Content -Path (Join-Path $script:ctx.RepoDir 'serena/config.yml')

        New-GwtWorktree -BranchName 'test/eng-5000-copy-test2' -CopyConfigDirs @('serena') *> $null
        $copiedDir = Join-Path $script:ctx.ParentDir 'test-repo-eng-5000' 'serena'
        Set-Location $script:ctx.RepoDir

        $copiedDir | Should -Exist
    }

    It 'handles multiple dirs' {
        New-Item -ItemType Directory -Path (Join-Path $script:ctx.RepoDir 'serena') -Force | Out-Null
        'config' | Set-Content -Path (Join-Path $script:ctx.RepoDir 'serena/config.yml')
        New-Item -ItemType Directory -Path (Join-Path $script:ctx.RepoDir '.vscode') -Force | Out-Null
        'settings' | Set-Content -Path (Join-Path $script:ctx.RepoDir '.vscode/settings.json')

        $err = $null
        New-GwtWorktree -BranchName 'test/eng-5001-multi-copy' -CopyConfigDirs @('serena', '.vscode') -ErrorVariable err -ErrorAction SilentlyContinue *> $null
        Set-Location $script:ctx.RepoDir

        $err | Should -BeNullOrEmpty
    }

    It 'copies first dir' {
        New-Item -ItemType Directory -Path (Join-Path $script:ctx.RepoDir 'serena') -Force | Out-Null
        'config' | Set-Content -Path (Join-Path $script:ctx.RepoDir 'serena/config.yml')
        New-Item -ItemType Directory -Path (Join-Path $script:ctx.RepoDir '.vscode') -Force | Out-Null
        'settings' | Set-Content -Path (Join-Path $script:ctx.RepoDir '.vscode/settings.json')

        New-GwtWorktree -BranchName 'test/eng-5001-multi-copy2' -CopyConfigDirs @('serena', '.vscode') *> $null
        $copiedDir = Join-Path $script:ctx.ParentDir 'test-repo-eng-5001' 'serena'
        Set-Location $script:ctx.RepoDir

        $copiedDir | Should -Exist
    }

    It 'copies second dir' {
        New-Item -ItemType Directory -Path (Join-Path $script:ctx.RepoDir 'serena') -Force | Out-Null
        'config' | Set-Content -Path (Join-Path $script:ctx.RepoDir 'serena/config.yml')
        New-Item -ItemType Directory -Path (Join-Path $script:ctx.RepoDir '.vscode') -Force | Out-Null
        'settings' | Set-Content -Path (Join-Path $script:ctx.RepoDir '.vscode/settings.json')

        New-GwtWorktree -BranchName 'test/eng-5001-multi-copy3' -CopyConfigDirs @('serena', '.vscode') *> $null
        $copiedDir = Join-Path $script:ctx.ParentDir 'test-repo-eng-5001' '.vscode'
        Set-Location $script:ctx.RepoDir

        $copiedDir | Should -Exist
    }
}

Describe 'New-GwtWorktree - GWT_COPY_DIRS Env Var' {
    BeforeEach {
        $script:ctx = New-GwtTestRepo
    }

    AfterEach {
        $env:GWT_COPY_DIRS = $null
        Remove-GwtTestRepo -TestContext $script:ctx
    }

    It 'creates worktree successfully with env var' {
        New-Item -ItemType Directory -Path (Join-Path $script:ctx.RepoDir 'serena') -Force | Out-Null
        'config' | Set-Content -Path (Join-Path $script:ctx.RepoDir 'serena/config.yml')
        $env:GWT_COPY_DIRS = 'serena'

        $err = $null
        New-GwtWorktree -BranchName 'test/eng-5002-env-test' -ErrorVariable err -ErrorAction SilentlyContinue *> $null
        Set-Location $script:ctx.RepoDir

        $err | Should -BeNullOrEmpty
    }

    It 'copies config dir via env var' {
        New-Item -ItemType Directory -Path (Join-Path $script:ctx.RepoDir 'serena') -Force | Out-Null
        'config' | Set-Content -Path (Join-Path $script:ctx.RepoDir 'serena/config.yml')
        $env:GWT_COPY_DIRS = 'serena'

        New-GwtWorktree -BranchName 'test/eng-5002-env-test2' *> $null
        $copiedDir = Join-Path $script:ctx.ParentDir 'test-repo-eng-5002' 'serena'
        Set-Location $script:ctx.RepoDir

        $copiedDir | Should -Exist
    }

    It 'handles multiple dirs via env var' {
        New-Item -ItemType Directory -Path (Join-Path $script:ctx.RepoDir 'serena') -Force | Out-Null
        'config' | Set-Content -Path (Join-Path $script:ctx.RepoDir 'serena/config.yml')
        New-Item -ItemType Directory -Path (Join-Path $script:ctx.RepoDir '.vscode') -Force | Out-Null
        'settings' | Set-Content -Path (Join-Path $script:ctx.RepoDir '.vscode/settings.json')
        $env:GWT_COPY_DIRS = 'serena,.vscode'

        $err = $null
        New-GwtWorktree -BranchName 'test/eng-5003-env-multi' -ErrorVariable err -ErrorAction SilentlyContinue *> $null
        Set-Location $script:ctx.RepoDir

        $err | Should -BeNullOrEmpty
    }

    It 'copies first dir from env var list' {
        New-Item -ItemType Directory -Path (Join-Path $script:ctx.RepoDir 'serena') -Force | Out-Null
        'config' | Set-Content -Path (Join-Path $script:ctx.RepoDir 'serena/config.yml')
        New-Item -ItemType Directory -Path (Join-Path $script:ctx.RepoDir '.vscode') -Force | Out-Null
        'settings' | Set-Content -Path (Join-Path $script:ctx.RepoDir '.vscode/settings.json')
        $env:GWT_COPY_DIRS = 'serena,.vscode'

        New-GwtWorktree -BranchName 'test/eng-5003-env-multi2' *> $null
        $copiedDir = Join-Path $script:ctx.ParentDir 'test-repo-eng-5003' 'serena'
        Set-Location $script:ctx.RepoDir

        $copiedDir | Should -Exist
    }

    It 'copies second dir from env var list' {
        New-Item -ItemType Directory -Path (Join-Path $script:ctx.RepoDir 'serena') -Force | Out-Null
        'config' | Set-Content -Path (Join-Path $script:ctx.RepoDir 'serena/config.yml')
        New-Item -ItemType Directory -Path (Join-Path $script:ctx.RepoDir '.vscode') -Force | Out-Null
        'settings' | Set-Content -Path (Join-Path $script:ctx.RepoDir '.vscode/settings.json')
        $env:GWT_COPY_DIRS = 'serena,.vscode'

        New-GwtWorktree -BranchName 'test/eng-5003-env-multi3' *> $null
        $copiedDir = Join-Path $script:ctx.ParentDir 'test-repo-eng-5003' '.vscode'
        Set-Location $script:ctx.RepoDir

        $copiedDir | Should -Exist
    }
}

Describe 'New-GwtWorktree - Copy Dir Warnings' {
    BeforeEach {
        $script:ctx = New-GwtTestRepo
    }

    AfterEach {
        Remove-GwtTestRepo -TestContext $script:ctx
    }

    It 'non-existent dir still creates worktree' {
        New-GwtWorktree -BranchName 'test/eng-5004-warn-test' -CopyConfigDirs @('nonexistent') *> $null
        $wtPath = Join-Path $script:ctx.ParentDir 'test-repo-eng-5004'
        Set-Location $script:ctx.RepoDir

        $wtPath | Should -Exist
    }

    It 'non-existent dir shows warning' {
        $output = New-GwtWorktree -BranchName 'test/eng-5004-warn-test2' -CopyConfigDirs @('nonexistent') 6>&1 *>&1
        Set-Location $script:ctx.RepoDir

        "$output" | Should -BeLike '*Warning*'
    }

    It 'warning mentions directory name' {
        $output = New-GwtWorktree -BranchName 'test/eng-5004-warn-test3' -CopyConfigDirs @('nonexistent') 6>&1 *>&1
        Set-Location $script:ctx.RepoDir

        "$output" | Should -BeLike '*nonexistent*'
    }
}
