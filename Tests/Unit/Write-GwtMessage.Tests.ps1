BeforeAll {
    $modulePath = Join-Path $PSScriptRoot '../../GWT/GWT.psd1'
    Import-Module $modulePath -Force
}

Describe 'Write-GwtMessage' {
    It 'outputs message' {
        $output = InModuleScope GWT { Write-GwtMessage -Message 'Test message' 6>&1 }
        "$output" | Should -BeLike '*Test message*'
    }

    It 'outputs message with color' {
        $output = InModuleScope GWT { Write-GwtMessage -Message 'Colored message' -Color 'Green' 6>&1 }
        "$output" | Should -BeLike '*Colored message*'
    }

    It 'outputs message with prefix symbol' {
        $output = InModuleScope GWT { Write-GwtMessage -Message 'Symbol message' -Color 'Green' -Symbol '✓' 6>&1 }
        $text = "$output"
        $text | Should -BeLike '*Symbol message*'
        $text | Should -BeLike '*✓*'
    }
}
