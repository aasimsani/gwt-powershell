BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '../../GWT/GWT.psd1'
    Import-Module $modulePath -Force
}

Describe 'Test-GwtBranch' {
    It 'accepts simple branch name' {
        InModuleScope GWT { Test-GwtBranch -Name 'feature-branch' } | Should -BeTrue
    }

    It 'accepts branch with slash' {
        InModuleScope GWT { Test-GwtBranch -Name 'feature/add-new-thing' } | Should -BeTrue
    }

    It 'accepts branch with multiple slashes' {
        InModuleScope GWT { Test-GwtBranch -Name 'user/team/eng-1234-feature' } | Should -BeTrue
    }

    It 'accepts main' {
        InModuleScope GWT { Test-GwtBranch -Name 'main' } | Should -BeTrue
    }

    It 'accepts master' {
        InModuleScope GWT { Test-GwtBranch -Name 'master' } | Should -BeTrue
    }

    It 'rejects empty string' {
        InModuleScope GWT { Test-GwtBranch -Name '' } | Should -BeFalse
    }

    It 'rejects path traversal' {
        InModuleScope GWT { Test-GwtBranch -Name '../etc/passwd' } | Should -BeFalse
    }

    It 'rejects semicolon' {
        InModuleScope GWT { Test-GwtBranch -Name 'branch;rm -rf /' } | Should -BeFalse
    }

    It 'rejects pipe' {
        InModuleScope GWT { Test-GwtBranch -Name 'branch|cat /etc/passwd' } | Should -BeFalse
    }

    It 'rejects backticks' {
        InModuleScope GWT { Test-GwtBranch -Name 'branch`whoami`' } | Should -BeFalse
    }

    It 'rejects dollar sign' {
        InModuleScope GWT { Test-GwtBranch -Name 'branch$(whoami)' } | Should -BeFalse
    }

    It 'rejects spaces' {
        InModuleScope GWT { Test-GwtBranch -Name 'branch with spaces' } | Should -BeFalse
    }

    It 'rejects newlines' {
        InModuleScope GWT { Test-GwtBranch -Name "branch`ninjection" } | Should -BeFalse
    }
}
