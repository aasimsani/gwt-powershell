BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '../../GWT/GWT.psd1'
    Import-Module $modulePath -Force
    Import-Module (Join-Path $PSScriptRoot '../Helpers/TestHelper.psm1') -Force
}

Describe 'New-GwtWorktree --From' {
    BeforeEach {
        $script:ctx = New-GwtTestRepo
    }

    AfterEach {
        Remove-GwtTestRepo -TestContext $script:ctx
    }

    It 'creates worktree from specified branch' {
        git checkout -q -b 'feature/specific-base'
        'specific content' | Set-Content -Path (Join-Path $script:ctx.RepoDir 'specific.txt')
        git add specific.txt
        git commit -q -m 'Specific commit'
        git checkout -q main

        New-GwtWorktree -BranchName 'test/eng-from-1' -From 'feature/specific-base' *> $null
        $specificFile = Join-Path $script:ctx.ParentDir 'test-repo-eng-from-1' 'specific.txt'
        Set-Location $script:ctx.RepoDir

        $specificFile | Should -Exist
    }

    It 'stores base branch metadata' {
        git checkout -q -b 'feature/from-meta'
        git checkout -q main

        New-GwtWorktree -BranchName 'test/eng-from-3' -From 'feature/from-meta' *> $null
        $wtPath = Join-Path $script:ctx.ParentDir 'test-repo-eng-from-3'
        Push-Location $wtPath
        $baseBranch = InModuleScope GWT { Get-GwtMetadata -Property 'baseBranch' }
        Pop-Location
        Set-Location $script:ctx.RepoDir

        $baseBranch | Should -Be 'feature/from-meta'
    }

    It 'shows error when base branch does not exist' {
        $err = $null
        New-GwtWorktree -BranchName 'test/eng-from-notfound' -From 'nonexistent/branch' -ErrorVariable err -ErrorAction SilentlyContinue *> $null

        "$err" | Should -BeLike '*not found*'
    }

    It 'validates branch name for From' {
        $err = $null
        New-GwtWorktree -BranchName 'test/eng-from-invalid' -From 'invalid;branch' -ErrorVariable err -ErrorAction SilentlyContinue *> $null

        "$err" | Should -BeLike '*Invalid*'
    }
}
