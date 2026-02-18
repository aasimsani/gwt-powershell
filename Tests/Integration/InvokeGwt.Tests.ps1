BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '../../GWT/GWT.psd1'
    Import-Module $modulePath -Force
    Import-Module (Join-Path $PSScriptRoot '../Helpers/TestHelper.psm1') -Force
}

Describe 'gwt Entry Point' {
    BeforeEach {
        $script:ctx = New-GwtTestRepo
    }

    AfterEach {
        Remove-GwtTestRepo -TestContext $script:ctx
    }

    It 'rejects unknown option' {
        $err = $null
        gwt -Command '--unknown-flag' -ErrorVariable err -ErrorAction SilentlyContinue *> $null

        "$err" | Should -BeLike '*Unknown option*'
    }

    It '--help shows help message' {
        $output = gwt -Help 6>&1 *>&1

        "$output" | Should -BeLike '*Usage:*'
    }

    It '--help shows options' {
        $output = gwt -Help 6>&1 *>&1

        "$output" | Should -BeLike '*Stack*'
    }

    It '--help works outside git repo' {
        $notRepo = Join-Path $script:ctx.TestDir 'not-a-repo'
        New-Item -ItemType Directory -Path $notRepo -Force | Out-Null
        Push-Location $notRepo

        $output = gwt -Help 6>&1 *>&1
        Pop-Location

        "$output" | Should -BeLike '*gwt*'
    }

    It '--version shows version' {
        $output = gwt -Version 6>&1 *>&1

        "$output" | Should -BeLike '*gwt version*'
    }

    It '--version works outside git repo' {
        $notRepo = Join-Path $script:ctx.TestDir 'not-a-repo'
        New-Item -ItemType Directory -Path $notRepo -Force | Out-Null
        Push-Location $notRepo

        $output = gwt -Version 6>&1 *>&1
        Pop-Location

        "$output" | Should -BeLike '*gwt version*'
    }

    It '--help mentions GWT_ALIAS' {
        $output = gwt -Help 6>&1 *>&1

        "$output" | Should -BeLike '*GWT_ALIAS*'
    }

    It '--help mentions --repair' {
        $output = gwt -Help 6>&1 *>&1

        "$output" | Should -BeLike '*Repair*'
    }

    It '--repair fixes broken config.worktree' {
        $wtPath = Join-Path $script:ctx.ParentDir 'test-repo-eng-repair-1'
        git worktree add -q -b 'test/eng-repair-1' $wtPath HEAD 2>$null
        Push-Location $wtPath

        git config extensions.worktreeConfig true
        $gitDir = git rev-parse --git-dir 2>$null
        Remove-Item (Join-Path $gitDir 'config.worktree') -Force -ErrorAction SilentlyContinue

        gwt -Repair *> $null
        $configWorktree = Join-Path $gitDir 'config.worktree'
        Pop-Location

        $configWorktree | Should -Exist
    }

    It '--repair is safe when nothing is broken' {
        $err = $null
        gwt -Repair -ErrorVariable err -ErrorAction SilentlyContinue *> $null

        $err | Should -BeNullOrEmpty
    }
}

Describe 'gwt Unix-Style Flags' {
    BeforeEach {
        $script:ctx = New-GwtTestRepo
    }

    AfterEach {
        Remove-GwtTestRepo -TestContext $script:ctx
    }

    It 'gwt --help shows help message' {
        $output = gwt '--help' 6>&1 *>&1

        "$output" | Should -BeLike '*Usage:*'
    }

    It 'gwt --version shows version' {
        $output = gwt '--version' 6>&1 *>&1

        "$output" | Should -BeLike '*gwt version*'
    }

    It 'gwt --list shows worktrees' {
        $output = gwt '--list' 6>&1 *>&1

        # Should not error — empty or showing main worktree
        $output | Should -Not -BeNullOrEmpty
    }

    It 'gwt --info shows worktree info' {
        $output = gwt '--info' 6>&1 *>&1

        "$output" | Should -BeLike '*Worktree Info*'
    }

    It 'gwt --prune shows prune menu' {
        Mock Read-Host { return '' } -ModuleName GWT

        $output = gwt '--prune' 6>&1 *>&1

        # Should run without error (no worktrees to prune or shows menu)
        $? | Should -BeTrue
    }

    It 'gwt --repair is safe' {
        $err = $null
        gwt '--repair' -ErrorVariable err -ErrorAction SilentlyContinue *> $null

        $err | Should -BeNullOrEmpty
    }

    It 'gwt --stack creates stacked worktree' {
        $output = gwt '--stack' 'feature/unix-stack-test' 6>&1 *>&1

        "$output" | Should -BeLike '*created*'
        $branch = git branch --show-current
        $branch | Should -Be 'feature/unix-stack-test'
    }

    It 'gwt --from creates worktree from base' {
        git checkout -q -b 'feature/unix-base'
        git checkout -q main

        $output = gwt '--from' 'feature/unix-base' 'feature/unix-from-test' 6>&1 *>&1

        "$output" | Should -BeLike '*created*'
        $branch = git branch --show-current
        $branch | Should -Be 'feature/unix-from-test'
    }

    It 'gwt --list-copy-dirs works' {
        $output = gwt '--list-copy-dirs' 6>&1 *>&1

        # Should show either configured dirs or "no dirs" message
        "$output" | Should -BeLike '*director*'
    }

    It 'gwt -h shows help (short flag)' {
        $output = gwt '-h' 6>&1 *>&1

        "$output" | Should -BeLike '*Usage:*'
    }

    It 'gwt -s creates stacked worktree (short flag)' {
        $output = gwt '-s' 'feature/unix-short-stack' 6>&1 *>&1

        "$output" | Should -BeLike '*created*'
        $branch = git branch --show-current
        $branch | Should -Be 'feature/unix-short-stack'
    }

    It 'gwt -f creates worktree from base (short flag)' {
        git checkout -q -b 'feature/unix-short-base'
        git checkout -q main

        $output = gwt '-f' 'feature/unix-short-base' 'feature/unix-short-from' 6>&1 *>&1

        "$output" | Should -BeLike '*created*'
        $branch = git branch --show-current
        $branch | Should -Be 'feature/unix-short-from'
    }

    It 'gwt -i shows info (short flag)' {
        $output = gwt '-i' 6>&1 *>&1

        "$output" | Should -BeLike '*Worktree Info*'
    }

    It 'gwt --update calls Update-Module' {
        Mock Update-Module { Write-Host 'Update-Module called' } -ModuleName GWT

        $output = gwt '--update' 6>&1 *>&1

        "$output" | Should -BeLike '*Updating*'
    }

    It 'gwt -Update calls Update-Module (PS style)' {
        Mock Update-Module { Write-Host 'Update-Module called' } -ModuleName GWT

        $output = gwt -Update 6>&1 *>&1

        "$output" | Should -BeLike '*Updating*'
    }

    It 'gwt --help mentions update' {
        $output = gwt '--help' 6>&1 *>&1

        "$output" | Should -BeLike '*update*'
    }
}
