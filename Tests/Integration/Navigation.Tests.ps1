BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '../../GWT/GWT.psd1'
    Import-Module $modulePath -Force
    Import-Module (Join-Path $PSScriptRoot '../Helpers/TestHelper.psm1') -Force

    function Resolve-RealPath {
        param([string]$Path)
        # Resolve symlinks (macOS /var -> /private/var)
        $resolved = & /usr/bin/readlink -f $Path 2>$null
        if (-not $resolved) { $resolved = $Path }
        return $resolved
    }
}

Describe 'Enter-GwtBase (gwt ..)' {
    BeforeEach {
        $script:ctx = New-GwtTestRepo
    }

    AfterEach {
        Remove-GwtTestRepo -TestContext $script:ctx
    }

    It 'navigates to base worktree' {
        git checkout -q -b 'feature/nav-parent'
        $parentPath = (Get-Location).Path

        New-GwtWorktree -BranchName 'test/eng-nav-1' -Stack *> $null

        Enter-GwtBase
        $currentPath = (Get-Location).Path
        Set-Location $script:ctx.RepoDir

        $currentPath | Should -Be $parentPath
    }

    It 'shows error when no base tracked' {
        $err = $null
        Enter-GwtBase -ErrorVariable err -ErrorAction SilentlyContinue

        "$err" | Should -BeLike '*No base*'
    }

    It 'shows error when base worktree deleted' {
        git checkout -q -b 'feature/deleted-parent'

        New-GwtWorktree -BranchName 'test/eng-nav-deleted' -Stack *> $null

        InModuleScope GWT {
            Set-GwtMetadata -BaseBranch 'feature/deleted-parent' -BaseWorktreePath '/nonexistent/path'
        }

        $err = $null
        Enter-GwtBase -ErrorVariable err -ErrorAction SilentlyContinue

        "$err" | Should -BeLike '*no longer exists*'
        Set-Location $script:ctx.RepoDir
    }

    It 'works after navigating away and back' {
        git checkout -q -b 'feature/nav-away-parent'
        $parentPath = (Get-Location).Path

        New-GwtWorktree -BranchName 'test/eng-nav-away' -Stack *> $null
        $childPath = (Get-Location).Path

        Set-Location $script:ctx.TestDir
        Set-Location $childPath

        Enter-GwtBase
        $currentPath = (Get-Location).Path
        Set-Location $script:ctx.RepoDir

        $currentPath | Should -Be $parentPath
    }
}

Describe 'Enter-GwtRoot (gwt ...)' {
    BeforeEach {
        $script:ctx = New-GwtTestRepo
    }

    AfterEach {
        Remove-GwtTestRepo -TestContext $script:ctx
    }

    It 'returns main worktree path from linked worktree' {
        $mainPath = Resolve-RealPath $script:ctx.RepoDir

        New-GwtWorktree -BranchName 'test/eng-root-1' *> $null

        Enter-GwtRoot
        $currentPath = Resolve-RealPath (Get-Location).Path
        Set-Location $script:ctx.RepoDir

        $currentPath | Should -Be $mainPath
    }

    It 'handles already being in main worktree' {
        $output = Enter-GwtRoot 6>&1 *>&1

        "$output" | Should -BeLike '*Already in main worktree*'
    }

    It 'works from deeply nested worktree' {
        $mainPath = Resolve-RealPath $script:ctx.RepoDir

        New-GwtWorktree -BranchName 'test/eng-5501-parent' *> $null

        New-GwtWorktree -BranchName 'test/eng-5502-child' -Stack *> $null

        Enter-GwtRoot
        $currentPath = Resolve-RealPath (Get-Location).Path
        Set-Location $script:ctx.RepoDir

        $currentPath | Should -Be $mainPath
    }

    It 'shows message when already in main worktree via --root' {
        $output = Enter-GwtRoot 6>&1 *>&1

        "$output" | Should -BeLike '*Already in main worktree*'
    }
}
