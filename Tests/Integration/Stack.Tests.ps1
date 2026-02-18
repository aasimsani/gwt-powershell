BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '../../GWT/GWT.psd1'
    Import-Module $modulePath -Force
    Import-Module (Join-Path $PSScriptRoot '../Helpers/TestHelper.psm1') -Force
}

Describe 'New-GwtWorktree --Stack' {
    BeforeEach {
        $script:ctx = New-GwtTestRepo
    }

    AfterEach {
        Remove-GwtTestRepo -TestContext $script:ctx
    }

    It 'creates worktree from current branch' {
        git checkout -q -b 'feature/parent-branch'
        'parent content' | Set-Content -Path (Join-Path $script:ctx.RepoDir 'parent.txt')
        git add parent.txt
        git commit -q -m 'Parent commit'

        New-GwtWorktree -BranchName 'test/eng-stack-1' -Stack *> $null
        $parentFile = Join-Path $script:ctx.ParentDir 'test-repo-eng-stack-1' 'parent.txt'
        Set-Location $script:ctx.RepoDir

        $parentFile | Should -Exist
    }

    It 'stores base branch metadata' {
        git checkout -q -b 'feature/meta-parent'
        'meta content' | Set-Content -Path (Join-Path $script:ctx.RepoDir 'meta.txt')
        git add meta.txt
        git commit -q -m 'Meta commit'

        New-GwtWorktree -BranchName 'test/eng-stack-3' -Stack *> $null
        $wtPath = Join-Path $script:ctx.ParentDir 'test-repo-eng-stack-3'
        Push-Location $wtPath
        $baseBranch = InModuleScope GWT { Get-GwtMetadata -Property 'baseBranch' }
        Pop-Location
        Set-Location $script:ctx.RepoDir

        $baseBranch | Should -Be 'feature/meta-parent'
    }

    It 'stores base worktree path metadata' {
        git checkout -q -b 'feature/path-parent'
        $parentPath = (Get-Location).Path

        New-GwtWorktree -BranchName 'test/eng-stack-4' -Stack *> $null
        $wtPath = Join-Path $script:ctx.ParentDir 'test-repo-eng-stack-4'
        Push-Location $wtPath
        $basePath = InModuleScope GWT { Get-GwtMetadata -Property 'baseWorktreePath' }
        Pop-Location
        Set-Location $script:ctx.RepoDir

        $basePath | Should -Be $parentPath
    }

    It 'adds entry to central registry' {
        git checkout -q -b 'feature/reg-parent'

        New-GwtWorktree -BranchName 'test/eng-stack-5' -Stack *> $null
        Set-Location $script:ctx.RepoDir

        $regBranch = git config 'gwt.registry.test-repo-eng-stack-5.baseBranch'
        $regBranch | Should -Be 'feature/reg-parent'
    }

    It 'shows error in detached HEAD' {
        git checkout -q --detach HEAD

        $err = $null
        New-GwtWorktree -BranchName 'test/eng-stack-detached' -Stack -ErrorVariable err -ErrorAction SilentlyContinue *> $null

        "$err" | Should -BeLike '*detached HEAD*'
    }

    It '--stack and --from together shows error' {
        $err = $null
        New-GwtWorktree -BranchName 'test/eng-conflict' -Stack -From 'main' -ErrorVariable err -ErrorAction SilentlyContinue *> $null

        "$err" | Should -BeLike '*Cannot*'
    }
}
