BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '../../GWT/GWT.psd1'
    Import-Module $modulePath -Force
}

Describe 'Get-GwtSuffix' {
    Context 'Linear ticket extraction' {
        It 'extracts eng-XXXX from standard Linear branch' {
            InModuleScope GWT { Get-GwtSuffix -BranchName 'aasim/eng-1045-allow-changing-user-types' } | Should -Be 'eng-1045'
        }

        It 'extracts first eng-XXXX when multiple present' {
            InModuleScope GWT { Get-GwtSuffix -BranchName 'fix/eng-123-and-eng-456-related' } | Should -Be 'eng-123'
        }

        It 'handles large ticket numbers' {
            InModuleScope GWT { Get-GwtSuffix -BranchName 'user/eng-99999-big-ticket' } | Should -Be 'eng-99999'
        }

        It 'extracts from deeply nested prefixes' {
            InModuleScope GWT { Get-GwtSuffix -BranchName 'team/user/eng-6000-deep' } | Should -Be 'eng-6000'
        }
    }

    Context 'Regular branch name extraction' {
        It 'extracts first 3 words from regular branch' {
            InModuleScope GWT { Get-GwtSuffix -BranchName 'feature/add-new-dashboard-components-extra' } | Should -Be 'add-new-dashboard'
        }

        It 'handles branch with fewer than 3 words' {
            InModuleScope GWT { Get-GwtSuffix -BranchName 'fix/quick-patch' } | Should -Be 'quick-patch'
        }

        It 'strips common prefixes' {
            InModuleScope GWT { Get-GwtSuffix -BranchName 'hotfix/urgent-security-fix-now' } | Should -Be 'urgent-security-fix'
        }
    }
}
