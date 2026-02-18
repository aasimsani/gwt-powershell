# Test helper module for gwt-powershell Pester tests
# Port of gwt-zsh/tests/_support/bootstrap

$script:SafeTempBase = [System.IO.Path]::GetTempPath()

function New-GwtTestRepo {
    <#
    .SYNOPSIS
    Creates an isolated test git repository in a temp directory.
    Returns a hashtable with TestDir, RepoDir, ParentDir keys.
    #>
    $testDir = Join-Path $script:SafeTempBase "gwt-test-$([guid]::NewGuid().ToString('N').Substring(0, 8))"
    $repoDir = Join-Path $testDir 'test-repo'

    New-Item -ItemType Directory -Path $repoDir -Force | Out-Null

    Push-Location $repoDir
    git init -q -b main 2>$null
    git config user.email 'test@test.com'
    git config user.name 'Test User'

    'test' | Set-Content -Path (Join-Path $repoDir 'README.md')
    git add README.md
    git commit -q -m 'Initial commit' 2>$null

    # Isolate tests from user's real config
    $script:OriginalHome = $env:HOME
    $env:HOME = $testDir

    # Also set XDG to prevent leaking into real config
    $script:OriginalXdg = $env:XDG_CONFIG_HOME
    $env:XDG_CONFIG_HOME = $null

    return @{
        TestDir   = $testDir
        RepoDir   = $repoDir
        ParentDir = $testDir
    }
}

function Remove-GwtTestRepo {
    <#
    .SYNOPSIS
    Cleans up a test repository created by New-GwtTestRepo.
    #>
    param(
        [Parameter(Mandatory)]
        [hashtable]$TestContext
    )

    # Restore original HOME
    if ($script:OriginalHome) {
        $env:HOME = $script:OriginalHome
    }
    if ($script:OriginalXdg) {
        $env:XDG_CONFIG_HOME = $script:OriginalXdg
    }

    Pop-Location -ErrorAction SilentlyContinue

    # Prune worktrees before cleanup
    if ($TestContext.RepoDir -and (Test-Path $TestContext.RepoDir)) {
        Push-Location $TestContext.RepoDir
        git worktree prune 2>$null
        Pop-Location
    }

    # Safety: only remove from temp directory
    if ($TestContext.TestDir -and $TestContext.TestDir.StartsWith($script:SafeTempBase)) {
        Remove-Item $TestContext.TestDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Export-ModuleMember -Function New-GwtTestRepo, Remove-GwtTestRepo
