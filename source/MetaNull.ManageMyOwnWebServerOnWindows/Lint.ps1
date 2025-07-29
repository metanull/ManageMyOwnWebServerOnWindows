#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Custom lint script for MetaNull.LaravelUtils module

.DESCRIPTION
    Runs PSScriptAnalyzer with the project-specific settings that exclude rules
    appropriate for this development utility module.

.PARAMETER Scope
    Specifies which code to lint: Source, Test, or All (default: Source)

.PARAMETER Path
    Custom path to analyze (overrides Scope parameter)

.PARAMETER Recurse
    Analyze recursively (default: true)

.PARAMETER Fix
    Attempt to fix issues automatically

.PARAMETER Detailed
    Show detailed output including suppressed rules

.EXAMPLE
    .\Lint.ps1
    Run standard analysis on source code

.EXAMPLE
    .\Lint.ps1 -Scope All
    Analyze both source and test code

.EXAMPLE
    .\Lint.ps1 -Scope Test -Fix
    Analyze tests and attempt to auto-fix issues

.EXAMPLE
    .\Lint.ps1 -Path .\custom\ -Detailed
    Analyze custom path with detailed output
#>
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('Source', 'Test', 'All')]
    [string]$Scope = 'Source',
    
    [Parameter()]
    [string]$Path,
    
    [Parameter()]
    [switch]$Recurse,
    
    [Parameter()]
    [switch]$Fix,
    
    [Parameter()]
    [switch]$Detailed
)

# Ensure PSScriptAnalyzer is available
if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
    Write-Error "PSScriptAnalyzer module is not installed. Install it with: Install-Module PSScriptAnalyzer"
    exit 1
}

# Get the script directory to find the settings file
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SettingsFile = Join-Path $ScriptDir "PSScriptAnalyzerSettings.psd1"

# Verify settings file exists
if (-not (Test-Path $SettingsFile)) {
    Write-Error "PSScriptAnalyzer settings file not found: $SettingsFile"
    exit 1
}

# Determine paths to analyze
if ($Path) {
    # Use custom path if provided
    $AnalyzePaths = @($Path)
} else {
    # Use scope-based paths
    switch ($Scope) {
        'Source' { 
            $AnalyzePaths = @(".\source\")
        }
        'Test' { 
            $AnalyzePaths = @(".\test\")
        }
        'All' {
            $AnalyzePaths = @(".\source\", ".\test\")
        }
    }
}

# Verify paths exist
$ValidPaths = @()
foreach ($AnalyzePath in $AnalyzePaths) {
    if (Test-Path $AnalyzePath) {
        $ValidPaths += $AnalyzePath
    } else {
        Write-Warning "Path not found: $AnalyzePath"
    }
}

if ($ValidPaths.Count -eq 0) {
    Write-Error "No valid paths found to analyze"
    exit 1
}

# Run the analysis
Write-Host "🔍 Running PSScriptAnalyzer" -ForegroundColor Cyan
Write-Host "🎯 Scope: $Scope" -ForegroundColor Gray
Write-Host "📂 Paths: $($ValidPaths -join ', ')" -ForegroundColor Gray
Write-Host "⚙️  Settings: $SettingsFile" -ForegroundColor Gray

if ($Detailed) {
    Write-Host "⚠️  Excluded rules: PSAvoidUsingWMICmdlet, PSAvoidUsingWriteHost" -ForegroundColor Yellow
    Write-Host ""
}

$AllResults = @()
foreach ($ValidPath in $ValidPaths) {
    # Build parameters for each path
    $AnalyzerParams = @{
        Path = $ValidPath
        Settings = $SettingsFile
        Recurse = $true  # Default to recursive
    }

    if ($Fix) {
        $AnalyzerParams.Fix = $true
    }

    Write-Host "Analyzing: $ValidPath" -ForegroundColor Blue
    $Results = Invoke-ScriptAnalyzer @AnalyzerParams
    
    if ($Results) {
        $AllResults += $Results
    }
}

if ($AllResults) {
    Write-Host ""
    Write-Host "Found $($AllResults.Count) issue(s):" -ForegroundColor Yellow
    $AllResults | Format-Table -AutoSize
    
    # Group by severity
    $ErrorCount = ($AllResults | Where-Object Severity -eq 'Error').Count
    $WarningCount = ($AllResults | Where-Object Severity -eq 'Warning').Count
    $InfoCount = ($AllResults | Where-Object Severity -eq 'Information').Count
    
    Write-Host "📊 Summary:" -ForegroundColor Cyan
    if ($ErrorCount -gt 0) { Write-Host "  ❌ Errors: $ErrorCount" -ForegroundColor Red }
    if ($WarningCount -gt 0) { Write-Host "  ⚠️  Warnings: $WarningCount" -ForegroundColor Yellow }
    if ($InfoCount -gt 0) { Write-Host "  ℹ️  Information: $InfoCount" -ForegroundColor Blue }
    
    if ($ErrorCount -gt 0) {
        exit 1
    }
} else {
    Write-Host ""
    Write-Host "✅ No issues found! ✓" -ForegroundColor Green
}
