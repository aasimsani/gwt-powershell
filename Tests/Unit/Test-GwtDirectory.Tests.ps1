BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '../../GWT/GWT.psd1'
    Import-Module $modulePath -Force
}

Describe 'Test-GwtDirectory' {
    It 'accepts simple name' {
        InModuleScope GWT { Test-GwtDirectory -Name 'serena' } | Should -BeTrue
    }

    It 'accepts dotfile like .vscode' {
        InModuleScope GWT { Test-GwtDirectory -Name '.vscode' } | Should -BeTrue
    }

    It 'accepts relative path path/to/dir' {
        InModuleScope GWT { Test-GwtDirectory -Name 'path/to/dir' } | Should -BeTrue
    }

    It 'rejects path traversal ../etc' {
        InModuleScope GWT { Test-GwtDirectory -Name '../etc' } | Should -BeFalse
    }

    It 'rejects absolute path /etc/passwd' {
        InModuleScope GWT { Test-GwtDirectory -Name '/etc/passwd' } | Should -BeFalse
    }

    It 'rejects semicolon foo;rm' {
        InModuleScope GWT { Test-GwtDirectory -Name 'foo;rm' } | Should -BeFalse
    }

    It 'rejects pipe foo|bar' {
        InModuleScope GWT { Test-GwtDirectory -Name 'foo|bar' } | Should -BeFalse
    }

    It 'rejects empty string' {
        InModuleScope GWT { Test-GwtDirectory -Name '' } | Should -BeFalse
    }

    It 'rejects backticks' {
        InModuleScope GWT { Test-GwtDirectory -Name '`rm -rf /`' } | Should -BeFalse
    }

    It 'rejects dollar sign' {
        InModuleScope GWT { Test-GwtDirectory -Name '$(rm -rf /)' } | Should -BeFalse
    }

    It 'rejects newlines' {
        InModuleScope GWT { Test-GwtDirectory -Name "foo`nbar" } | Should -BeFalse
    }

    It 'rejects spaces' {
        InModuleScope GWT { Test-GwtDirectory -Name 'foo bar' } | Should -BeFalse
    }

    It 'rejects backslash' {
        InModuleScope GWT { Test-GwtDirectory -Name 'foo\bar' } | Should -BeFalse
    }

    It 'rejects ampersand' {
        InModuleScope GWT { Test-GwtDirectory -Name 'foo&bar' } | Should -BeFalse
    }

    It 'rejects curly braces (PS-specific)' {
        InModuleScope GWT { Test-GwtDirectory -Name '${env:PATH}' } | Should -BeFalse
    }

    It 'rejects parentheses (PS-specific)' {
        InModuleScope GWT { Test-GwtDirectory -Name 'foo()bar' } | Should -BeFalse
    }
}
