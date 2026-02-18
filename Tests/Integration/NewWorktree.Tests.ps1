BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '../../GWT/GWT.psd1'
    Import-Module $modulePath -Force
    Import-Module (Join-Path $PSScriptRoot '../Helpers/TestHelper.psm1') -Force
}

Describe 'New-GwtWorktree - Error Handling' {
    BeforeEach {
        $script:ctx = New-GwtTestRepo
    }

    AfterEach {
        Remove-GwtTestRepo -TestContext $script:ctx
    }

    It 'returns error when not in git repo' {
        $notRepo = Join-Path $script:ctx.TestDir 'not-a-repo'
        New-Item -ItemType Directory -Path $notRepo -Force | Out-Null
        Push-Location $notRepo

        $err = $null
        New-GwtWorktree -BranchName 'some-branch' -ErrorVariable err -ErrorAction SilentlyContinue
        Pop-Location

        $err | Should -Not -BeNullOrEmpty
    }

    It 'shows correct error message for non-repo' {
        $notRepo = Join-Path $script:ctx.TestDir 'not-a-repo'
        New-Item -ItemType Directory -Path $notRepo -Force | Out-Null
        Push-Location $notRepo

        $err = $null
        New-GwtWorktree -BranchName 'some-branch' -ErrorVariable err -ErrorAction SilentlyContinue
        Pop-Location

        "$err" | Should -BeLike '*Not in a git repository*'
    }
}

Describe 'New-GwtWorktree - Path Construction' {
    BeforeEach {
        $script:ctx = New-GwtTestRepo
    }

    AfterEach {
        Remove-GwtTestRepo -TestContext $script:ctx
    }

    It 'constructs correct path for Linear branch' {
        $output = New-GwtWorktree -BranchName 'aasim/eng-1045-test-branch' 6>&1 *>&1
        Set-Location $script:ctx.RepoDir
        "$output" | Should -BeLike '*test-repo-eng-1045*'
    }

    It 'constructs correct path for regular branch' {
        $output = New-GwtWorktree -BranchName 'feature/add-new-thing-here' 6>&1 *>&1
        Set-Location $script:ctx.RepoDir
        "$output" | Should -BeLike '*test-repo-add-new-thing*'
    }
}

Describe 'New-GwtWorktree - Creation' {
    BeforeEach {
        $script:ctx = New-GwtTestRepo
    }

    AfterEach {
        Remove-GwtTestRepo -TestContext $script:ctx
    }

    It 'creates new worktree successfully' {
        $err = $null
        New-GwtWorktree -BranchName 'test/eng-3000-new-feature' -ErrorVariable err -ErrorAction SilentlyContinue *> $null
        Set-Location $script:ctx.RepoDir

        $err | Should -BeNullOrEmpty
    }

    It 'shows success message' {
        $output = New-GwtWorktree -BranchName 'test/eng-3001-success-msg' 6>&1 *>&1
        Set-Location $script:ctx.RepoDir
        "$output" | Should -BeLike '*Worktree created successfully*'
    }

    It 'worktree directory exists after creation' {
        $expectedPath = Join-Path $script:ctx.ParentDir 'test-repo-eng-3002'
        New-GwtWorktree -BranchName 'test/eng-3002-dir-exists' *> $null
        Set-Location $script:ctx.RepoDir

        $expectedPath | Should -Exist
    }

    It 'worktree is on correct branch' {
        New-GwtWorktree -BranchName 'test/eng-4000-branch-check' *> $null
        $wtPath = Join-Path $script:ctx.ParentDir 'test-repo-eng-4000'
        Push-Location $wtPath
        $currentBranch = git rev-parse --abbrev-ref HEAD
        Pop-Location
        Set-Location $script:ctx.RepoDir

        $currentBranch | Should -Be 'test/eng-4000-branch-check'
    }

    It 'uses local branch when exists' {
        git branch 'test/eng-9000-local'
        $output = New-GwtWorktree -BranchName 'test/eng-9000-local' 6>&1 *>&1
        Set-Location $script:ctx.RepoDir

        "$output" | Should -BeLike '*Worktree created*'
    }

    It 'creates new branch when not found' {
        New-GwtWorktree -BranchName 'test/eng-9010-newbranch' *> $null
        $wtPath = Join-Path $script:ctx.ParentDir 'test-repo-eng-9010'
        Push-Location $wtPath
        $branch = git branch --show-current
        Pop-Location
        Set-Location $script:ctx.RepoDir

        $branch | Should -Be 'test/eng-9010-newbranch'
    }

    It 'handles branch with slash prefix correctly' {
        $output = New-GwtWorktree -BranchName 'feature/add-user-auth-flow' 6>&1 *>&1
        Set-Location $script:ctx.RepoDir

        "$output" | Should -BeLike '*test-repo-add-user-auth*'
    }
}

Describe 'New-GwtWorktree - Existing Worktree' {
    BeforeEach {
        $script:ctx = New-GwtTestRepo
    }

    AfterEach {
        Remove-GwtTestRepo -TestContext $script:ctx
    }

    It 'returns success for existing worktree' {
        $wtPath = Join-Path $script:ctx.ParentDir 'test-repo-eng-2000'
        git worktree add -q -b 'test/eng-2000-exists' $wtPath HEAD 2>$null

        $err = $null
        New-GwtWorktree -BranchName 'test/eng-2000-exists' -ErrorVariable err -ErrorAction SilentlyContinue *> $null
        Set-Location $script:ctx.RepoDir

        $err | Should -BeNullOrEmpty
    }

    It 'detects existing worktree' {
        $wtPath = Join-Path $script:ctx.ParentDir 'test-repo-eng-2001'
        git worktree add -q -b 'test/eng-2001-exists' $wtPath HEAD 2>$null

        $output = New-GwtWorktree -BranchName 'test/eng-2001-exists' 6>&1 *>&1
        Set-Location $script:ctx.RepoDir

        "$output" | Should -BeLike '*Worktree already exists*'
    }

    It 'shows cd message for existing worktree' {
        $wtPath = Join-Path $script:ctx.ParentDir 'test-repo-eng-2002'
        git worktree add -q -b 'test/eng-2002-exists' $wtPath HEAD 2>$null

        $output = New-GwtWorktree -BranchName 'test/eng-2002-exists' 6>&1 *>&1
        Set-Location $script:ctx.RepoDir

        "$output" | Should -BeLike '*Changing to existing worktree*'
    }
}

Describe 'New-GwtWorktree - Default Base Branch' {
    BeforeEach {
        $script:ctx = New-GwtTestRepo
    }

    AfterEach {
        # Clean up env vars
        $env:GWT_MAIN_BRANCH = $null
        Remove-GwtTestRepo -TestContext $script:ctx
    }

    It 'creates new branch from main by default' {
        # Create a feature branch with unique content
        git checkout -q -b 'feature/current-work'
        'feature work' | Set-Content -Path (Join-Path $script:ctx.RepoDir 'feature.txt')
        git add feature.txt
        git commit -q -m 'Feature commit'

        New-GwtWorktree -BranchName 'test/eng-base-1' *> $null
        $wtPath = Join-Path $script:ctx.ParentDir 'test-repo-eng-base-1'
        $featureFile = Join-Path $wtPath 'feature.txt'
        Set-Location $script:ctx.RepoDir

        $featureFile | Should -Not -Exist
    }

    It 'respects GWT_MAIN_BRANCH env var' {
        # Create develop branch with unique content
        git checkout -q -b develop
        'develop content' | Set-Content -Path (Join-Path $script:ctx.RepoDir 'develop.txt')
        git add develop.txt
        git commit -q -m 'Develop commit'
        git checkout -q main

        $env:GWT_MAIN_BRANCH = 'develop'

        New-GwtWorktree -BranchName 'test/eng-base-2' *> $null
        $developFile = Join-Path $script:ctx.ParentDir 'test-repo-eng-base-2' 'develop.txt'
        Set-Location $script:ctx.RepoDir

        $developFile | Should -Exist
    }

    It 'falls back to HEAD when main branch does not exist' {
        # Rename main to something else
        git branch -m main old-main
        git checkout -q -b 'current-branch'
        'current content' | Set-Content -Path (Join-Path $script:ctx.RepoDir 'current.txt')
        git add current.txt
        git commit -q -m 'Current commit'

        New-GwtWorktree -BranchName 'test/eng-base-3' *> $null
        $currentFile = Join-Path $script:ctx.ParentDir 'test-repo-eng-base-3' 'current.txt'
        Set-Location $script:ctx.RepoDir

        $currentFile | Should -Exist
    }
}
