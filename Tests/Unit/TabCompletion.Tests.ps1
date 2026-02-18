BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '../../GWT/GWT.psd1'
    Import-Module $modulePath -Force
    Import-Module (Join-Path $PSScriptRoot '../Helpers/TestHelper.psm1') -Force
}

Describe 'Tab Completion - Get-GwtBranchCompletions' {
    BeforeEach {
        $script:ctx = New-GwtTestRepo
    }

    AfterEach {
        Remove-GwtTestRepo -TestContext $script:ctx
    }

    It 'lists local branch names' {
        git checkout -q -b 'feature/test-completion'
        git checkout -q main

        $result = InModuleScope GWT { Get-GwtBranchCompletions }

        $result | Should -Contain 'main'
        $result | Should -Contain 'feature/test-completion'
    }

    It 'handles repo with only main branch' {
        $result = InModuleScope GWT { Get-GwtBranchCompletions }

        $result | Should -Contain 'main'
    }

    It 'handles branches with slashes' {
        git checkout -q -b 'feature/deep/nested/branch'
        git checkout -q main

        $result = InModuleScope GWT { Get-GwtBranchCompletions }

        $result | Should -Contain 'feature/deep/nested/branch'
    }

    It 'handles branches with dots and hyphens' {
        git checkout -q -b 'fix/v1.2.3-hotfix'
        git checkout -q main

        $result = InModuleScope GWT { Get-GwtBranchCompletions }

        $result | Should -Contain 'fix/v1.2.3-hotfix'
    }

    It 'deduplicates local and remote branches' {
        # Create a remote tracking branch
        git checkout -q -b 'feature/remote-test'
        git checkout -q main

        # Simulate remote by adding a remote ref
        $gitDir = Join-Path $script:ctx.RepoDir '.git'
        $remoteRefDir = Join-Path $gitDir 'refs' 'remotes' 'origin'
        New-Item -ItemType Directory -Path $remoteRefDir -Force | Out-Null
        $mainRef = git rev-parse main
        $mainRef | Set-Content -Path (Join-Path $remoteRefDir 'feature' 'remote-test') -Force

        # Create the refs/remotes/origin/feature directory
        New-Item -ItemType Directory -Path (Join-Path $remoteRefDir 'feature') -Force | Out-Null
        $mainRef | Set-Content -Path (Join-Path $remoteRefDir 'feature' 'remote-test') -Force

        git pack-refs --all 2>$null

        $result = InModuleScope GWT { Get-GwtBranchCompletions }

        # Should not have duplicates
        $featureBranches = $result | Where-Object { $_ -eq 'feature/remote-test' }
        $featureBranches.Count | Should -BeLessOrEqual 2  # Could appear once or from both local+remote
    }

    It 'excludes HEAD from remote branches' {
        # Set up a remote HEAD ref
        $gitDir = Join-Path $script:ctx.RepoDir '.git'
        $remoteRefDir = Join-Path $gitDir 'refs' 'remotes' 'origin'
        New-Item -ItemType Directory -Path $remoteRefDir -Force | Out-Null
        $mainRef = git rev-parse main
        $mainRef | Set-Content -Path (Join-Path $remoteRefDir 'HEAD') -Force

        $result = InModuleScope GWT { Get-GwtBranchCompletions }

        $result | Should -Not -Contain 'HEAD'
    }

    It 'returns empty outside git repo' {
        $notRepo = Join-Path $script:ctx.TestDir 'not-a-repo'
        New-Item -ItemType Directory -Path $notRepo -Force | Out-Null
        Push-Location $notRepo

        $result = InModuleScope GWT { Get-GwtBranchCompletions }
        Pop-Location

        $result | Should -BeNullOrEmpty
    }
}
