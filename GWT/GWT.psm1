$script:GWT_VERSION = '0.1.0'

# Dot-source all private functions
$privatePath = Join-Path $PSScriptRoot 'Private'
if (Test-Path $privatePath) {
    Get-ChildItem -Path $privatePath -Filter '*.ps1' -Recurse | ForEach-Object {
        . $_.FullName
    }
}

# Dot-source all public functions
$publicPath = Join-Path $PSScriptRoot 'Public'
if (Test-Path $publicPath) {
    Get-ChildItem -Path $publicPath -Filter '*.ps1' -Recurse | ForEach-Object {
        . $_.FullName
    }
}

# Register aliases
Set-Alias -Name 'wt' -Value 'gwt' -Scope Global -Force

# Tab completion for branch names
function Get-GwtBranchCompletions {
    [CmdletBinding()]
    [OutputType([string[]])]
    param()

    $branches = @()

    # Local branches
    $localBranches = git branch --format='%(refname:short)' 2>$null
    if ($localBranches) {
        $branches += $localBranches
    }

    # Remote tracking branches (excluding HEAD)
    $remoteBranches = git branch -r --format='%(refname:short)' 2>$null
    if ($remoteBranches) {
        foreach ($rb in $remoteBranches) {
            if ($rb -notlike '*/HEAD') {
                $shortName = $rb -replace '^origin/', ''
                $branches += $shortName
            }
        }
    }

    # Deduplicate
    return ($branches | Select-Object -Unique | Sort-Object)
}

Register-ArgumentCompleter -CommandName gwt -ParameterName Command -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    Get-GwtBranchCompletions | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}

Register-ArgumentCompleter -CommandName New-GwtWorktree -ParameterName BranchName -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    Get-GwtBranchCompletions | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}
