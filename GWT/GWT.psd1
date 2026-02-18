@{
    RootModule        = 'GWT.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
    Author            = 'Aasim Sani'
    CompanyName       = 'Aasim Sani'
    Copyright         = '(c) 2026 Aasim Sani. All rights reserved.'
    Description       = 'Stupidly simple git worktree management. Simplifies git worktree add into a single command with stacking, navigation, and cleanup.'
    PowerShellVersion = '7.0'
    FunctionsToExport = @(
        'gwt'
        'New-GwtWorktree'
        'Enter-GwtBase'
        'Enter-GwtRoot'
        'Show-GwtInfo'
        'Show-GwtList'
        'Remove-GwtWorktree'
        'Set-GwtConfiguration'
        'Show-GwtHelp'
    )
    AliasesToExport   = @('wt')
    CmdletsToExport   = @()
    VariablesToExport  = @()
    PrivateData       = @{
        PSData = @{
            Tags         = @('git', 'worktree', 'workflow', 'productivity')
            LicenseUri   = 'https://github.com/aasimsani/gwt-powershell/blob/main/LICENSE'
            ProjectUri   = 'https://github.com/aasimsani/gwt-powershell'
            ReleaseNotes = 'Initial release - port of gwt-zsh to PowerShell'
        }
    }
}
