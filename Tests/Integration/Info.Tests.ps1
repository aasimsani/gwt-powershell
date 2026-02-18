BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '../../GWT/GWT.psd1'
    Import-Module $modulePath -Force
    Import-Module (Join-Path $PSScriptRoot '../Helpers/TestHelper.psm1') -Force
}

Describe 'Show-GwtInfo (gwt --info)' {
    BeforeEach {
        $script:ctx = New-GwtTestRepo
    }

    AfterEach {
        Remove-GwtTestRepo -TestContext $script:ctx
    }

    It 'shows current worktree info' {
        $currentBranch = git branch --show-current

        $output = Show-GwtInfo 6>&1 *>&1

        "$output" | Should -BeLike "*$currentBranch*"
    }

    It 'shows base when tracked' {
        git checkout -q -b 'feature/info-parent'

        New-GwtWorktree -BranchName 'test/eng-info-1' -Stack *> $null

        $output = Show-GwtInfo 6>&1 *>&1
        Set-Location $script:ctx.RepoDir

        "$output" | Should -BeLike '*feature/info-parent*'
    }

    It 'shows not tracked when no base' {
        $output = Show-GwtInfo 6>&1 *>&1

        "$output" | Should -BeLike '*not tracked*'
    }

    It 'shows dependents list' {
        git checkout -q -b 'feature/info-parent-dep'
        $parentPath = (Get-Location).Path

        New-GwtWorktree -BranchName 'test/eng-8801-first-child' -Stack *> $null
        Set-Location $parentPath
        New-GwtWorktree -BranchName 'test/eng-8802-second-child' -Stack *> $null
        Set-Location $parentPath

        $output = Show-GwtInfo 6>&1 *>&1
        Set-Location $script:ctx.RepoDir

        "$output" | Should -BeLike '*eng-8801*'
        "$output" | Should -BeLike '*eng-8802*'
    }

    It 'indicates missing base worktree' {
        git checkout -q -b 'feature/info-missing'

        New-GwtWorktree -BranchName 'test/eng-info-missing' -Stack *> $null

        InModuleScope GWT {
            Set-GwtMetadata -BaseBranch 'feature/info-missing' -BaseWorktreePath '/nonexistent/path'
        }

        $output = Show-GwtInfo 6>&1 *>&1
        Set-Location $script:ctx.RepoDir

        "$output" | Should -BeLike '*missing*'
    }

    It 'shows no dependents when none exist' {
        $err = $null
        $output = Show-GwtInfo -ErrorVariable err -ErrorAction SilentlyContinue 6>&1 *>&1

        $err | Should -BeNullOrEmpty
    }

    It 'runs without error' {
        $err = $null
        Show-GwtInfo -ErrorVariable err -ErrorAction SilentlyContinue *> $null

        $err | Should -BeNullOrEmpty
    }
}
