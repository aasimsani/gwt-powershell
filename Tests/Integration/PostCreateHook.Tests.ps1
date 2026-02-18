BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '../../GWT/GWT.psd1'
    Import-Module $modulePath -Force
    Import-Module (Join-Path $PSScriptRoot '../Helpers/TestHelper.psm1') -Force
}

Describe 'Post-Create Hook - Script File' {
    BeforeEach {
        $script:ctx = New-GwtTestRepo
    }

    AfterEach {
        $env:GWT_POST_CREATE_CMD = $null
        Remove-GwtTestRepo -TestContext $script:ctx
    }

    It 'hook executes script file when present' {
        $gwtDir = Join-Path $script:ctx.RepoDir '.gwt'
        New-Item -ItemType Directory -Path $gwtDir -Force | Out-Null
        $hookScript = Join-Path $gwtDir 'post-create.sh'
        @'
#!/bin/bash
echo "Hook executed successfully"
'@ | Set-Content -Path $hookScript -NoNewline
        chmod +x $hookScript

        $output = New-GwtWorktree -BranchName 'test/eng-2001-hook-script' 6>&1 *>&1
        Set-Location $script:ctx.RepoDir

        "$output" | Should -BeLike '*Hook executed successfully*'
    }

    It 'hook script runs in worktree directory' {
        $gwtDir = Join-Path $script:ctx.RepoDir '.gwt'
        New-Item -ItemType Directory -Path $gwtDir -Force | Out-Null
        $hookScript = Join-Path $gwtDir 'post-create.sh'
        @'
#!/bin/bash
echo "HOOKPWD:$(pwd)"
'@ | Set-Content -Path $hookScript -NoNewline
        chmod +x $hookScript

        $output = New-GwtWorktree -BranchName 'test/eng-2002-hook-pwd' 6>&1 *>&1
        Set-Location $script:ctx.RepoDir

        "$output" | Should -BeLike '*HOOKPWD:*'
        "$output" | Should -BeLike '*test-repo-eng-2002*'
    }

    It 'hook script not executable shows warning' -Skip:$IsWindows {
        $gwtDir = Join-Path $script:ctx.RepoDir '.gwt'
        New-Item -ItemType Directory -Path $gwtDir -Force | Out-Null
        $hookScript = Join-Path $gwtDir 'post-create.sh'
        @'
#!/bin/bash
echo "Should not run"
'@ | Set-Content -Path $hookScript -NoNewline
        # Intentionally NOT chmod +x

        $output = New-GwtWorktree -BranchName 'test/eng-2003-hook-noexec' 6>&1 *>&1
        Set-Location $script:ctx.RepoDir

        "$output" | Should -BeLike '*not executable*'
        "$output" | Should -Not -BeLike '*Should not run*'
    }

    It 'script file takes precedence over env var' {
        $gwtDir = Join-Path $script:ctx.RepoDir '.gwt'
        New-Item -ItemType Directory -Path $gwtDir -Force | Out-Null
        $hookScript = Join-Path $gwtDir 'post-create.sh'
        @'
#!/bin/bash
echo "Script file wins"
'@ | Set-Content -Path $hookScript -NoNewline
        chmod +x $hookScript
        $env:GWT_POST_CREATE_CMD = "echo 'Env var loses'"

        $output = New-GwtWorktree -BranchName 'test/eng-2006-hook-precedence' 6>&1 *>&1
        Set-Location $script:ctx.RepoDir

        "$output" | Should -BeLike '*Script file wins*'
        "$output" | Should -Not -BeLike '*Env var loses*'
    }

    It 'hook failure does not abort worktree creation' {
        $gwtDir = Join-Path $script:ctx.RepoDir '.gwt'
        New-Item -ItemType Directory -Path $gwtDir -Force | Out-Null
        $hookScript = Join-Path $gwtDir 'post-create.sh'
        @'
#!/bin/bash
exit 1
'@ | Set-Content -Path $hookScript -NoNewline
        chmod +x $hookScript

        $output = New-GwtWorktree -BranchName 'test/eng-2007-hook-fail' 6>&1 *>&1
        Set-Location $script:ctx.RepoDir

        "$output" | Should -BeLike '*Worktree created successfully*'
    }

    It 'hook failure shows warning with exit code' {
        $gwtDir = Join-Path $script:ctx.RepoDir '.gwt'
        New-Item -ItemType Directory -Path $gwtDir -Force | Out-Null
        $hookScript = Join-Path $gwtDir 'post-create.sh'
        @'
#!/bin/bash
exit 42
'@ | Set-Content -Path $hookScript -NoNewline
        chmod +x $hookScript

        $output = New-GwtWorktree -BranchName 'test/eng-2008-hook-exitcode' 6>&1 *>&1
        Set-Location $script:ctx.RepoDir

        "$output" | Should -BeLike '*42*'
    }
}

Describe 'Post-Create Hook - Env Var Command' {
    BeforeEach {
        $script:ctx = New-GwtTestRepo
    }

    AfterEach {
        $env:GWT_POST_CREATE_CMD = $null
        Remove-GwtTestRepo -TestContext $script:ctx
    }

    It 'hook executes env var command when no script file' {
        $env:GWT_POST_CREATE_CMD = "echo 'Env var hook ran'"

        $output = New-GwtWorktree -BranchName 'test/eng-2004-hook-env' 6>&1 *>&1
        Set-Location $script:ctx.RepoDir

        "$output" | Should -BeLike '*Env var hook ran*'
    }

    It 'hook env var supports commands with arguments' {
        $env:GWT_POST_CREATE_CMD = 'echo arg1 arg2 arg3'

        $output = New-GwtWorktree -BranchName 'test/eng-2005-hook-args' 6>&1 *>&1
        Set-Location $script:ctx.RepoDir

        "$output" | Should -BeLike '*arg1 arg2 arg3*'
    }

    It 'non-existent command in env var still creates worktree' {
        $env:GWT_POST_CREATE_CMD = 'nonexistent_cmd_xyz_12345'

        $output = New-GwtWorktree -BranchName 'test/eng-2009-hook-badcmd' 6>&1 *>&1
        Set-Location $script:ctx.RepoDir

        "$output" | Should -BeLike '*Worktree created successfully*'
    }
}

Describe 'Post-Create Hook - No Hook' {
    BeforeEach {
        $script:ctx = New-GwtTestRepo
    }

    AfterEach {
        $env:GWT_POST_CREATE_CMD = $null
        Remove-GwtTestRepo -TestContext $script:ctx
    }

    It 'no hook configured has no hook output' {
        $output = New-GwtWorktree -BranchName 'test/eng-2010-hook-none' 6>&1 *>&1
        Set-Location $script:ctx.RepoDir

        "$output" | Should -BeLike '*Worktree created successfully*'
        "$output" | Should -Not -BeLike '*post-create*'
    }

    It 'empty env var treated as not configured' {
        $env:GWT_POST_CREATE_CMD = ''

        $output = New-GwtWorktree -BranchName 'test/eng-2011-hook-empty' 6>&1 *>&1
        Set-Location $script:ctx.RepoDir

        "$output" | Should -Not -BeLike '*post-create*'
    }
}
