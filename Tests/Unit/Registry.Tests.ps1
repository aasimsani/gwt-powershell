BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '../../GWT/GWT.psd1'
    Import-Module $modulePath -Force
    Import-Module (Join-Path $PSScriptRoot '../Helpers/TestHelper.psm1') -Force
}

Describe 'Registry (Add/Remove/Get Dependents)' {
    BeforeEach {
        $script:ctx = New-GwtTestRepo
    }

    AfterEach {
        Remove-GwtTestRepo -TestContext $script:ctx
    }

    It 'stores worktree in central registry' {
        $wtPath = Join-Path $script:ctx.ParentDir 'test-repo-eng-reg-1'
        git worktree add -q -b 'test/eng-reg-1' $wtPath HEAD 2>$null

        InModuleScope GWT -Parameters @{ RepoDir = $script:ctx.RepoDir } {
            param($RepoDir)
            Add-GwtRegistry -WorktreeName 'test-repo-eng-reg-1' -BaseBranch 'feature/parent' -BasePath $RepoDir
        }

        $stored = git config 'gwt.registry.test-repo-eng-reg-1.baseBranch'
        $stored | Should -Be 'feature/parent'
    }

    It 'stores base path in registry' {
        $wtPath = Join-Path $script:ctx.ParentDir 'test-repo-eng-reg-2'
        git worktree add -q -b 'test/eng-reg-2' $wtPath HEAD 2>$null

        InModuleScope GWT -Parameters @{ RepoDir = $script:ctx.RepoDir } {
            param($RepoDir)
            Add-GwtRegistry -WorktreeName 'test-repo-eng-reg-2' -BaseBranch 'feature/parent' -BasePath $RepoDir
        }

        $stored = git config 'gwt.registry.test-repo-eng-reg-2.basePath'
        $stored | Should -Be $script:ctx.RepoDir
    }

    It 'remove clears worktree from registry' {
        git config 'gwt.registry.test-wt.baseBranch' 'feature/test'
        git config 'gwt.registry.test-wt.basePath' '/some/path'

        InModuleScope GWT { Remove-GwtRegistry -WorktreeName 'test-wt' }

        $branch = git config 'gwt.registry.test-wt.baseBranch' 2>$null
        $branch | Should -BeNullOrEmpty
    }

    It 'get dependents finds worktrees based on branch' {
        git config 'gwt.registry.child-wt-1.baseBranch' 'feature/parent'
        git config 'gwt.registry.child-wt-1.basePath' $script:ctx.RepoDir
        git config 'gwt.registry.child-wt-2.baseBranch' 'feature/parent'
        git config 'gwt.registry.child-wt-2.basePath' $script:ctx.RepoDir
        git config 'gwt.registry.other-wt.baseBranch' 'feature/other'
        git config 'gwt.registry.other-wt.basePath' $script:ctx.RepoDir

        $result = InModuleScope GWT { Get-GwtDependents -BranchName 'feature/parent' }

        $result | Should -Contain 'child-wt-1'
        $result | Should -Contain 'child-wt-2'
        $result | Should -Not -Contain 'other-wt'
    }

    It 'get dependents returns empty when no dependents' {
        git config 'gwt.registry.some-wt.baseBranch' 'feature/other'
        git config 'gwt.registry.some-wt.basePath' $script:ctx.RepoDir

        $result = InModuleScope GWT { Get-GwtDependents -BranchName 'feature/no-dependents' }

        $result | Should -BeNullOrEmpty
    }
}
