BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '../../GWT/GWT.psd1'
    Import-Module $modulePath -Force
    Import-Module (Join-Path $PSScriptRoot '../Helpers/TestHelper.psm1') -Force
}

Describe 'Repair-GwtConfig / Health Check' {
    BeforeEach {
        $script:ctx = New-GwtTestRepo
    }

    AfterEach {
        Remove-GwtTestRepo -TestContext $script:ctx
    }

    It 'Set-GwtMetadata writes core.bare=false to worktree config' {
        $wtPath = Join-Path $script:ctx.ParentDir 'test-repo-eng-defense-1'
        git worktree add -q -b 'test/eng-defense-1' $wtPath HEAD 2>$null
        Push-Location $wtPath

        InModuleScope GWT -Parameters @{ RepoDir = $script:ctx.RepoDir } {
            param($RepoDir)
            Set-GwtMetadata -BaseBranch 'feature/parent' -BaseWorktreePath $RepoDir
        }

        $bare = git config --worktree core.bare 2>$null
        Pop-Location
        $bare | Should -Be 'false'
    }

    It 'Set-GwtMetadata protects main worktree config.worktree' {
        $wtPath = Join-Path $script:ctx.ParentDir 'test-repo-eng-defense-2'
        git worktree add -q -b 'test/eng-defense-2' $wtPath HEAD 2>$null
        Push-Location $wtPath

        InModuleScope GWT -Parameters @{ RepoDir = $script:ctx.RepoDir } {
            param($RepoDir)
            Set-GwtMetadata -BaseBranch 'feature/parent' -BaseWorktreePath $RepoDir
        }

        Pop-Location

        $mainGitDir = Join-Path $script:ctx.RepoDir '.git'
        $configWorktree = Join-Path $mainGitDir 'config.worktree'
        $configWorktree | Should -Exist

        Push-Location $script:ctx.RepoDir
        $mainBare = git config --worktree core.bare 2>$null
        Pop-Location
        $mainBare | Should -Be 'false'
    }

    It 'repairs missing config.worktree' {
        $wtPath = Join-Path $script:ctx.ParentDir 'test-repo-eng-defense-3'
        git worktree add -q -b 'test/eng-defense-3' $wtPath HEAD 2>$null
        Push-Location $wtPath

        git config extensions.worktreeConfig true
        $gitDir = git rev-parse --git-dir 2>$null
        Remove-Item (Join-Path $gitDir 'config.worktree') -Force -ErrorAction SilentlyContinue

        InModuleScope GWT { Repair-GwtConfig }

        $configWorktree = Join-Path $gitDir 'config.worktree'
        Pop-Location
        $configWorktree | Should -Exist
    }

    It 'is no-op when worktreeConfig not enabled' {
        $output = InModuleScope GWT { Repair-GwtConfig 6>&1 }
        $output | Should -BeNullOrEmpty
    }

    It 'is no-op when config.worktree exists' {
        $wtPath = Join-Path $script:ctx.ParentDir 'test-repo-eng-defense-4'
        git worktree add -q -b 'test/eng-defense-4' $wtPath HEAD 2>$null
        Push-Location $wtPath

        InModuleScope GWT -Parameters @{ RepoDir = $script:ctx.RepoDir } {
            param($RepoDir)
            Set-GwtMetadata -BaseBranch 'feature/parent' -BaseWorktreePath $RepoDir
        }

        $output = InModuleScope GWT { Repair-GwtConfig 6>&1 }
        Pop-Location
        $output | Should -BeNullOrEmpty
    }
}
