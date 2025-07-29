<#
    .SYNOPSIS
    Runs all Pester tests for the MetaNull.LaravelUtils PowerShell module
    
    .DESCRIPTION
    This script runs all Pester tests located in the test directory structure.
    It provides options for different test scopes and output formats.
    
    .PARAMETER TestScope
    Specifies which tests to run: All, Public, Private, or UnitTest
    
    .PARAMETER OutputFormat
    Specifies the output format: Normal, Detailed, or Diagnostic
    
    .PARAMETER PassThru
    Returns the Pester test results object for further processing
    
    .PARAMETER Show
    Specifies what to show in the output: All, Passed, Failed, Pending, Skipped, Inconclusive, Describe, Context, Summary, Header, Fails, Errors
    
    .EXAMPLE
    .\Test.ps1
    Runs all tests with normal output
    
    .EXAMPLE
    .\Test.ps1 -TestScope UnitTest -OutputFormat Detailed
    Runs only unit tests with detailed output
    
    .EXAMPLE
    .\Test.ps1 -Show Failed,Errors
    Runs all tests but only shows failed tests and errors
#>
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('All', 'Public', 'Private', 'UnitTest')]
    [string]$TestScope = 'All',
    
    [Parameter()]
    [ValidateSet('Normal', 'Detailed', 'Diagnostic')]
    [string]$OutputFormat = 'Normal',
    
    [Parameter()]
    [switch]$PassThru,
    
    [Parameter()]
    [ValidateSet('All', 'Passed', 'Failed', 'Pending', 'Skipped', 'Inconclusive', 'Describe', 'Context', 'Summary', 'Header', 'Fails', 'Errors')]
    [string[]]$Show = @('All')
)

Begin {
    # Ensure Pester module is available
    if (-not (Get-Module -Name Pester -ListAvailable)) {
        Write-Error "Pester module is not installed. Please install it using: Install-Module -Name Pester -Force"
        exit 1
    }

    # Import Pester module
    Import-Module -Name Pester -Force

    # Get the module root directory
    $ModuleRoot = $PSScriptRoot
    $TestPath = Join-Path $ModuleRoot "test"
    
    if (-not (Test-Path $TestPath)) {
        Write-Error "Test directory not found at: $TestPath"
        exit 1
    }

    # Configure test paths based on scope
    $TestPaths = switch ($TestScope) {
        'All' { 
            @(
                (Join-Path $TestPath "public"),
                (Join-Path $TestPath "private")
            )
        }
        'Public' { 
            @(Join-Path $TestPath "public")
        }
        'Private' { 
            @(Join-Path $TestPath "private")
        }
        'UnitTest' {
            @(
                (Join-Path $TestPath "public"),
                (Join-Path $TestPath "private")
            )
        }
    }

    # Verify test paths exist
    $ValidTestPaths = @()
    foreach ($Path in $TestPaths) {
        if (Test-Path $Path) {
            $ValidTestPaths += $Path
        } else {
            Write-Warning "Test path not found: $Path"
        }
    }

    if ($ValidTestPaths.Count -eq 0) {
        Write-Error "No valid test paths found"
        exit 1
    }

    Write-Host "🧪 Running PowerShell Module Tests" -ForegroundColor Cyan
    Write-Host "📁 Module Root: $ModuleRoot" -ForegroundColor Gray
    Write-Host "🎯 Test Scope: $TestScope" -ForegroundColor Gray
    Write-Host "📊 Output Format: $OutputFormat" -ForegroundColor Gray
    Write-Host "📂 Test Paths: $($ValidTestPaths -join ', ')" -ForegroundColor Gray
    Write-Host ""

    # Configure Pester settings for v5
    $PesterConfiguration = New-PesterConfiguration
    $PesterConfiguration.Run.Path = $ValidTestPaths
    $PesterConfiguration.Run.PassThru = $true  # This ensures we get results back
    $PesterConfiguration.Should.ErrorAction = 'Continue'
    $PesterConfiguration.TestResult.Enabled = $true
    $PesterConfiguration.TestResult.OutputFormat = 'NUnitXml'
    $PesterConfiguration.TestResult.OutputPath = Join-Path $ModuleRoot "TestResults.xml"

    # Configure output verbosity
    switch ($OutputFormat) {
        'Normal' { $PesterConfiguration.Output.Verbosity = 'Normal' }
        'Detailed' { $PesterConfiguration.Output.Verbosity = 'Detailed' }
        'Diagnostic' { $PesterConfiguration.Output.Verbosity = 'Diagnostic' }
    }

    # Add tags filter for UnitTest scope
    if ($TestScope -eq 'UnitTest') {
        $PesterConfiguration.Filter.Tag = @('UnitTest')
    }
}

Process {
    try {
        # Run the tests
        $TestResults = Invoke-Pester -Configuration $PesterConfiguration

        # Display summary (check if properties exist)
        Write-Host ""
        Write-Host "📊 Test Summary" -ForegroundColor Cyan
        
        if ($TestResults) {
            $PassedCount = if ($TestResults.PSObject.Properties['PassedCount']) { $TestResults.PassedCount } else { $TestResults.Passed.Count }
            $FailedCount = if ($TestResults.PSObject.Properties['FailedCount']) { $TestResults.FailedCount } else { $TestResults.Failed.Count }
            $SkippedCount = if ($TestResults.PSObject.Properties['SkippedCount']) { $TestResults.SkippedCount } else { $TestResults.Skipped.Count }
            $TotalCount = if ($TestResults.PSObject.Properties['TotalCount']) { $TestResults.TotalCount } else { ($PassedCount + $FailedCount + $SkippedCount) }
            $Duration = if ($TestResults.PSObject.Properties['Duration']) { $TestResults.Duration } else { $TestResults.Time }
            
            Write-Host "✅ Passed: $PassedCount" -ForegroundColor Green
            Write-Host "❌ Failed: $FailedCount" -ForegroundColor Red
            Write-Host "⚠️  Skipped: $SkippedCount" -ForegroundColor Yellow
            Write-Host "📈 Total: $TotalCount" -ForegroundColor Blue
            Write-Host "⏱️  Duration: $($Duration.ToString('mm\:ss\.fff'))" -ForegroundColor Gray
            Write-Host ""

            # Exit with appropriate code
            if ($FailedCount -gt 0) {
                Write-Host "❌ Some tests failed!" -ForegroundColor Red
                if ($PassThru) {
                    return $TestResults
                }
                exit 1
            } else {
                Write-Host "✅ All tests passed!" -ForegroundColor Green
                if ($PassThru) {
                    return $TestResults
                }
                exit 0
            }
        } else {
            Write-Warning "No test results returned"
            exit 1
        }
    }
    catch {
        Write-Error "Error running tests: $_"
        exit 1
    }
}
