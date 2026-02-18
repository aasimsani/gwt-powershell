BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '../../GWT/GWT.psd1'
    Import-Module $modulePath -Force
    Import-Module (Join-Path $PSScriptRoot '../Helpers/TestHelper.psm1') -Force
}

Describe 'Remove-GwtWorktree (gwt --prune)' {
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
        Remove-GwtWorktree -ErrorVariable err -ErrorAction SilentlyContinue *> $null
        Pop-Location

        $err | Should -Not -BeNullOrEmpty
    }

    It 'shows message when no worktrees' {
        $output = Remove-GwtWorktree 6>&1 *>&1

        "$output" | Should -BeLike '*No worktrees to prune*'
    }

    It 'shows worktrees for selection' {
        $wtPath = Join-Path $script:ctx.ParentDir 'test-repo-eng-8000'
        git worktree add -q -b 'test/eng-8000-prune' $wtPath HEAD 2>$null

        # Mock Read-Host to return 'q' (quit)
        Mock Read-Host { return 'q' } -ModuleName GWT

        $output = Remove-GwtWorktree 6>&1 *>&1

        "$output" | Should -BeLike '*test-repo-eng-8000*'
    }

    It 'cancels on first confirmation' {
        $wtPath = Join-Path $script:ctx.ParentDir 'test-repo-eng-8103'
        git worktree add -q -b 'test/eng-8103-cancel1' $wtPath HEAD 2>$null

        # Mock: select 1, then 'n' at confirmation
        $script:readHostCallCount = 0
        Mock Read-Host {
            $script:readHostCallCount++
            if ($script:readHostCallCount -eq 1) { return '1' }
            return 'n'
        } -ModuleName GWT

        $output = Remove-GwtWorktree 6>&1 *>&1

        "$output" | Should -BeLike '*Cancelled*'
        $wtPath | Should -Exist
    }

    It 'cancels on DELETE confirmation' {
        $wtPath = Join-Path $script:ctx.ParentDir 'test-repo-eng-8104'
        git worktree add -q -b 'test/eng-8104-cancel2' $wtPath HEAD 2>$null

        $script:readHostCallCount = 0
        Mock Read-Host {
            $script:readHostCallCount++
            if ($script:readHostCallCount -eq 1) { return '1' }
            if ($script:readHostCallCount -eq 2) { return 'y' }
            return 'wrong'
        } -ModuleName GWT

        $output = Remove-GwtWorktree 6>&1 *>&1

        "$output" | Should -BeLike '*Cancelled*'
        $wtPath | Should -Exist
    }

    It 'deletes worktree on full confirmation' {
        $wtPath = Join-Path $script:ctx.ParentDir 'test-repo-eng-8105'
        git worktree add -q -b 'test/eng-8105-delete' $wtPath HEAD 2>$null

        $script:readHostCallCount = 0
        Mock Read-Host {
            $script:readHostCallCount++
            if ($script:readHostCallCount -eq 1) { return '1' }
            if ($script:readHostCallCount -eq 2) { return 'y' }
            return 'DELETE'
        } -ModuleName GWT

        $output = Remove-GwtWorktree 6>&1 *>&1

        "$output" | Should -BeLike '*Done*'
        $wtPath | Should -Not -Exist
    }

    It 'fallback selection with all then cancel' {
        $wtPath = Join-Path $script:ctx.ParentDir 'test-repo-eng-8101'
        git worktree add -q -b 'test/eng-8101-prune-all' $wtPath HEAD 2>$null

        $script:readHostCallCount = 0
        Mock Read-Host {
            $script:readHostCallCount++
            if ($script:readHostCallCount -eq 1) { return 'all' }
            return 'n'
        } -ModuleName GWT

        $output = Remove-GwtWorktree 6>&1 *>&1

        "$output" | Should -BeLike '*Cancelled*'
    }

    It 'shows uncommitted changes warning' {
        $wtPath = Join-Path $script:ctx.ParentDir 'test-repo-eng-8102'
        git worktree add -q -b 'test/eng-8102-uncommitted' $wtPath HEAD 2>$null

        # Create uncommitted change in worktree
        'uncommitted' | Set-Content -Path (Join-Path $wtPath 'uncommitted.txt')

        $script:readHostCallCount = 0
        Mock Read-Host {
            $script:readHostCallCount++
            if ($script:readHostCallCount -eq 1) { return '1' }
            return 'n'
        } -ModuleName GWT

        $output = Remove-GwtWorktree 6>&1 *>&1

        "$output" | Should -BeLike '*WARNING*'
        "$output" | Should -BeLike '*Uncommitted*'
    }
}

Describe 'Prune Helpers - Dependents Count' {
    BeforeEach {
        $script:ctx = New-GwtTestRepo
    }

    AfterEach {
        Remove-GwtTestRepo -TestContext $script:ctx
    }

    It 'returns correct dependents count' {
        git checkout -q -b 'feature/prune-parent-count'
        $parentPath = (Get-Location).Path

        New-GwtWorktree -BranchName 'test/eng-7701-dep1' -Stack *> $null
        Set-Location $parentPath
        New-GwtWorktree -BranchName 'test/eng-7702-dep2' -Stack *> $null
        Set-Location $script:ctx.RepoDir

        $result = InModuleScope GWT { Get-GwtDependents -BranchName 'feature/prune-parent-count' }
        $result.Count | Should -Be 2
    }

    It 'returns 0 when no dependents' {
        git checkout -q -b 'feature/prune-no-deps'

        $result = InModuleScope GWT { Get-GwtDependents -BranchName 'feature/prune-no-deps' }
        $result | Should -BeNullOrEmpty
    }
}

Describe 'Prune Helpers - Registry Cleanup' {
    BeforeEach {
        $script:ctx = New-GwtTestRepo
    }

    AfterEach {
        Remove-GwtTestRepo -TestContext $script:ctx
    }

    It 'prune worktree cleans up registry entry' {
        git checkout -q -b 'feature/prune-registry'

        New-GwtWorktree -BranchName 'test/eng-7703-cleanup' -Stack *> $null
        Set-Location $script:ctx.RepoDir

        # Verify registry entry exists
        $regBefore = git config 'gwt.registry.test-repo-eng-7703.baseBranch'
        $regBefore | Should -Be 'feature/prune-registry'

        # Prune the worktree
        $wtPath = Join-Path $script:ctx.ParentDir 'test-repo-eng-7703'
        InModuleScope GWT -Parameters @{ WtPath = $wtPath } {
            param($WtPath)
            Invoke-GwtPruneWorktree -WorktreePath $WtPath
        }

        # Registry entry should be cleaned up
        $regAfter = git config 'gwt.registry.test-repo-eng-7703.baseBranch' 2>$null
        $regAfter | Should -BeNullOrEmpty
    }

    It 'cascade removes worktree and all dependents' {
        git checkout -q -b 'feature/prune-cascade'

        New-GwtWorktree -BranchName 'test/eng-7704-cascade-child' -Stack *> $null
        Set-Location $script:ctx.RepoDir

        $childPath = Join-Path $script:ctx.ParentDir 'test-repo-eng-7704'
        $childPath | Should -Exist

        InModuleScope GWT -Parameters @{ RepoDir = $script:ctx.RepoDir } {
            param($RepoDir)
            Invoke-GwtPruneCascade -BranchName 'feature/prune-cascade' -RepoRoot $RepoDir
        }

        $childPath | Should -Not -Exist
    }
}
