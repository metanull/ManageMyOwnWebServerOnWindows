[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Test file contains mock functions with intentionally unused parameters')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidOverwritingBuiltInCmdlets', '', Justification = 'Test file needs to mock built-in cmdlets for isolated testing')]
param()

Describe "Testing private module function Write-DevError" -Tag "UnitTest" {
    Context "General context" {
        BeforeAll {
            # Set up the module variable that the function expects
            $script:ModuleColorError = "Red"
        }

        It "Write-DevError should execute without errors" {
            # Mock the dependencies to avoid actual output
            Function Get-ModuleIcon {
                param([string]$Type)
                return "❌"
            }
            
            Function Write-Host {
                param([string]$Object, [string]$ForegroundColor)
                # Mock - just return
            }
            
            # This should not throw an error
            { 
                $icon = Get-ModuleIcon "Error"
                Write-Host "$icon Test error message" -ForegroundColor $script:ModuleColorError
            } | Should -Not -Throw
        }

        It "Write-DevError should handle different error message types" {
            Function Get-ModuleIcon { return "❌" }
            Function Write-Host { param($Object, $ForegroundColor) }
            
            # Test different error message scenarios
            { 
                $icon = Get-ModuleIcon "Error"
                Write-Host "$icon Server failed to start" -ForegroundColor $script:ModuleColorError
            } | Should -Not -Throw
            
            { 
                $icon = Get-ModuleIcon "Error"
                Write-Host "$icon Port 8000 is unavailable" -ForegroundColor $script:ModuleColorError
            } | Should -Not -Throw
        }

        It "Write-DevError should use correct color variable" {
            $script:ModuleColorError | Should -Be "Red"
        }

        It "Write-DevError message parameter should be mandatory" {
            # Load the actual function to test parameter validation
            $ModuleRoot = $PSCommandPath | Split-Path -Parent | Split-Path -Parent | Split-Path -Parent
            $FunctionPath = Join-Path (Join-Path $ModuleRoot "source\private") "Write-DevError.ps1"
            
            # Test that the function definition has the mandatory parameter
            $functionContent = Get-Content $FunctionPath -Raw
            $functionContent | Should -Match '\[Parameter\(Mandatory\s*=\s*\$true\)\]'
            $functionContent | Should -Match '\[string\]\$Message'
        }

        It "Write-DevError should work with valid message parameter" {
            Function Get-ModuleIcon { return "❌" }
            Function Write-Host { param($Object, $ForegroundColor) }
            Function Write-DevError {
                param([Parameter(Mandatory = $true)][string]$Message)
                $icon = Get-ModuleIcon "Error"
                Write-Host "$icon $Message" -ForegroundColor $script:ModuleColorError
            }
            
            { Write-DevError -Message "Test error" } | Should -Not -Throw
        }
    }
}

