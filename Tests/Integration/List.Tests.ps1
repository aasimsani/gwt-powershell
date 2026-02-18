BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '../../GWT/GWT.psd1'
    Import-Module $modulePath -Force
    Import-Module (Join-Path $PSScriptRoot '../Helpers/TestHelper.psm1') -Force
}

Describe 'Show-GwtList (gwt --list)' {
    BeforeEach {
        $script:ctx = New-GwtTestRepo
    }

    AfterEach {
        Remove-GwtTestRepo -TestContext $script:ctx
    }

    It 'requires git repo' {
        $notRepo = Join-Path $script:ctx.TestDir 'not-a-repo'
        New-Item -ItemType Directory -Path $notRepo -Force | Out-Null
        Push-Location $notRepo

        $err = $null
        Show-GwtList -ErrorVariable err -ErrorAction SilentlyContinue *> $null
        Pop-Location

        $err | Should -Not -BeNullOrEmpty
    }

    It 'shows message when no worktrees' {
        $output = Show-GwtList 6>&1 *>&1

        "$output" | Should -BeLike '*No worktrees*'
    }

    It 'shows worktrees when they exist' {
        $wtPath = Join-Path $script:ctx.ParentDir 'test-repo-eng-7000'
        git worktree add -q -b 'test/eng-7000-list' $wtPath HEAD 2>$null

        $output = Show-GwtList 6>&1 *>&1

        "$output" | Should -BeLike '*test-repo-eng-7000*'
    }

    It 'shows branch name' {
        $wtPath = Join-Path $script:ctx.ParentDir 'test-repo-eng-7001'
        git worktree add -q -b 'test/eng-7001-list-branch' $wtPath HEAD 2>$null

        $output = Show-GwtList 6>&1 *>&1

        "$output" | Should -BeLike '*test/eng-7001-list-branch*'
    }

    It 'shows stack relationships with tree structure' {
        git checkout -q -b 'feature/list-parent'

        New-GwtWorktree -BranchName 'test/eng-9901-list-child' -Stack *> $null
        Set-Location $script:ctx.RepoDir

        $output = Show-GwtList 6>&1 *>&1

        "$output" | Should -BeLike '*eng-9901*'
        # Tree indicator for stacked worktree
        "$output" | Should -Match '└─'
    }

    It 'shows multiple levels of hierarchy' {
        git checkout -q -b 'feature/list-level1'

        New-GwtWorktree -BranchName 'test/eng-9902-level2' -Stack *> $null
        $level2Path = (Get-Location).Path

        New-GwtWorktree -BranchName 'test/eng-9903-level3' -Stack *> $null
        Set-Location $script:ctx.RepoDir

        $output = Show-GwtList 6>&1 *>&1

        "$output" | Should -BeLike '*eng-9902*'
        "$output" | Should -BeLike '*eng-9903*'
    }

    It 'works with flat worktrees (no stacking)' {
        New-GwtWorktree -BranchName 'test/eng-9904-flat' *> $null
        Set-Location $script:ctx.RepoDir

        $output = Show-GwtList 6>&1 *>&1

        "$output" | Should -BeLike '*eng-9904*'
    }

    It 'handles orphaned children gracefully' {
        git checkout -q -b 'feature/orphan-parent'

        New-GwtWorktree -BranchName 'test/eng-9905-orphan' -Stack *> $null

        # Overwrite metadata to simulate orphaned worktree
        InModuleScope GWT {
            Set-GwtMetadata -BaseBranch 'nonexistent/branch' -BaseWorktreePath '/nonexistent/path'
        }
        Set-Location $script:ctx.RepoDir

        $err = $null
        $output = Show-GwtList -ErrorVariable err -ErrorAction SilentlyContinue 6>&1 *>&1

        $err | Should -BeNullOrEmpty
        "$output" | Should -BeLike '*eng-9905*'
    }
}
