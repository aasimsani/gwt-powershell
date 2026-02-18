[CmdletBinding()]
param(
    [string]$NuGetApiKey = $env:NUGET_API_KEY,

    [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'

$modulePath = Join-Path $PSScriptRoot '../GWT'
$manifestPath = Join-Path $modulePath 'GWT.psd1'

if (-not (Test-Path $manifestPath)) {
    Write-Error "Module manifest not found at $manifestPath"
    return
}

# Validate manifest
$manifest = Import-PowerShellDataFile $manifestPath
Write-Host "Publishing GWT v$($manifest.ModuleVersion)" -ForegroundColor Cyan

# Run tests before publishing
Write-Host 'Running tests...' -ForegroundColor Yellow
$testResults = Invoke-Pester (Join-Path $PSScriptRoot '../Tests') -Output Minimal -PassThru

if ($testResults.FailedCount -gt 0) {
    Write-Error "Tests failed ($($testResults.FailedCount) failures). Fix tests before publishing."
    return
}

Write-Host "All $($testResults.PassedCount) tests passed." -ForegroundColor Green

# Check for API key
if (-not $NuGetApiKey) {
    Write-Error 'No NuGet API key provided. Set $env:NUGET_API_KEY or pass -NuGetApiKey.'
    return
}

# Publish
$publishParams = @{
    Path        = $modulePath
    NuGetApiKey = $NuGetApiKey
    Repository  = 'PSGallery'
}

if ($WhatIf) {
    Write-Host 'WhatIf: Would publish to PSGallery with:' -ForegroundColor Yellow
    Write-Host "  Path: $modulePath"
    Write-Host "  Version: $($manifest.ModuleVersion)"
    Write-Host "  Description: $($manifest.Description)"
}
else {
    Publish-Module @publishParams
    Write-Host "Successfully published GWT v$($manifest.ModuleVersion) to PSGallery!" -ForegroundColor Green
}
