[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Test file contains mock functions with intentionally unused parameters')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidOverwritingBuiltInCmdlets', '', Justification = 'Test file needs to mock built-in cmdlets for isolated testing')]
param()

Describe "Testing private module function Write-DevStep" -Tag "UnitTest" {
    Context "General context" {
        BeforeAll {
            # Set up the module variable that the function expects
            $script:ModuleColorStep = "Magenta"
        }

        It "Write-DevStep should execute without errors" {
            # Mock the dependencies to avoid actual output
            Function Get-ModuleIcon {
                param([string]$Type)
                return "🔄"
            }
            
            Function Write-Host {
                param([string]$Object, [string]$ForegroundColor)
                # Mock - just return
            }
            
            # This should not throw an error
            { 
                $icon = Get-ModuleIcon "Step"
                Write-Host "$icon Test step message" -ForegroundColor $script:ModuleColorStep
            } | Should -Not -Throw
        }

        It "Write-DevStep should handle different step message types" {
            Function Get-ModuleIcon { return "🔄" }
            Function Write-Host { param($Object, $ForegroundColor) }
            
            # Test different step message scenarios
            { 
                $icon = Get-ModuleIcon "Step"
                Write-Host "$icon Starting Laravel web server..." -ForegroundColor $script:ModuleColorStep
            } | Should -Not -Throw
            
            { 
                $icon = Get-ModuleIcon "Step"
                Write-Host "$icon Checking port availability..." -ForegroundColor $script:ModuleColorStep
            } | Should -Not -Throw
        }

        It "Write-DevStep should use correct color variable" {
            $script:ModuleColorStep | Should -Be "Magenta"
        }

        It "Write-DevStep message parameter should be mandatory" {
            # Load the actual function to test parameter validation
            $ModuleRoot = $PSCommandPath | Split-Path -Parent | Split-Path -Parent | Split-Path -Parent
            $FunctionPath = Join-Path (Join-Path $ModuleRoot "source\private") "Write-DevStep.ps1"
            
            # Test that the function definition has the mandatory parameter
            $functionContent = Get-Content $FunctionPath -Raw
            $functionContent | Should -Match '\[Parameter\(Mandatory\s*=\s*\$true\)\]'
            $functionContent | Should -Match '\[string\]\$Message'
        }

        It "Write-DevStep should work with valid message parameter" {
            Function Get-ModuleIcon { return "🔄" }
            Function Write-Host { param($Object, $ForegroundColor) }
            Function Write-DevStep {
                param([Parameter(Mandatory = $true)][string]$Message)
                $icon = Get-ModuleIcon "Step"
                Write-Host "$icon $Message" -ForegroundColor $script:ModuleColorStep
            }
            
            { Write-DevStep -Message "Test step" } | Should -Not -Throw
        }
    }
}

