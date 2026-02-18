BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '../../GWT/GWT.psd1'
    Import-Module $modulePath -Force
    Import-Module (Join-Path $PSScriptRoot '../Helpers/TestHelper.psm1') -Force
}

Describe 'Metadata (Set/Get/Clear)' {
    BeforeEach {
        $script:ctx = New-GwtTestRepo
        $script:wtPath = Join-Path $script:ctx.ParentDir 'test-repo-eng-meta'
        git worktree add -q -b 'test/eng-meta' $script:wtPath HEAD 2>$null
        Push-Location $script:wtPath
    }

    AfterEach {
        Pop-Location -ErrorAction SilentlyContinue
        Remove-GwtTestRepo -TestContext $script:ctx
    }

    It 'stores base branch in worktree config' {
        InModuleScope GWT -Parameters @{ RepoDir = $script:ctx.RepoDir } {
            param($RepoDir)
            Set-GwtMetadata -BaseBranch 'feature/parent-branch' -BaseWorktreePath $RepoDir
        }

        $stored = git config --worktree gwt.baseBranch 2>$null
        $stored | Should -Be 'feature/parent-branch'
    }

    It 'stores base worktree path' {
        InModuleScope GWT -Parameters @{ RepoDir = $script:ctx.RepoDir } {
            param($RepoDir)
            Set-GwtMetadata -BaseBranch 'feature/parent' -BaseWorktreePath $RepoDir
        }

        $stored = git config --worktree gwt.baseWorktreePath 2>$null
        $stored | Should -Be $script:ctx.RepoDir
    }

    It 'retrieves base branch' {
        git config extensions.worktreeConfig true
        git config --worktree gwt.baseBranch 'feature/stored-branch'

        $result = InModuleScope GWT { Get-GwtMetadata -Property 'baseBranch' }
        $result | Should -Be 'feature/stored-branch'
    }

    It 'retrieves base worktree path' {
        git config extensions.worktreeConfig true
        git config --worktree gwt.baseWorktreePath '/some/path/to/worktree'

        $result = InModuleScope GWT { Get-GwtMetadata -Property 'baseWorktreePath' }
        $result | Should -Be '/some/path/to/worktree'
    }

    It 'returns empty when no metadata' {
        $result = InModuleScope GWT { Get-GwtMetadata -Property 'baseBranch' }
        $result | Should -BeNullOrEmpty
    }

    It 'clear removes all metadata' {
        git config extensions.worktreeConfig true
        git config --worktree gwt.baseBranch 'feature/to-remove'
        git config --worktree gwt.baseWorktreePath '/some/path'

        InModuleScope GWT { Clear-GwtMetadata }

        $branch = git config --worktree gwt.baseBranch 2>$null
        $path = git config --worktree gwt.baseWorktreePath 2>$null
        $branch | Should -BeNullOrEmpty
        $path | Should -BeNullOrEmpty
    }
}
