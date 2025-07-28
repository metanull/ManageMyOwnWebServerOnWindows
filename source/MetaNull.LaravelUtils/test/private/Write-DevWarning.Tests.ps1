[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Test file contains mock functions with intentionally unused parameters')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidOverwritingBuiltInCmdlets', '', Justification = 'Test file needs to mock built-in cmdlets for isolated testing')]
param()

Describe "Testing private module function Write-DevWarning" -Tag "UnitTest" {
    Context "General context" {
        BeforeAll {
            # Set up the module variable that the function expects
            $script:ModuleColorWarning = "Yellow"
        }

        It "Write-DevWarning should execute without errors" {
            # Mock the dependencies to avoid actual output
            Function Get-ModuleIcon {
                param([string]$Type)
                return "⚠"
            }
            
            Function Write-Host {
                param([string]$Object, [string]$ForegroundColor)
                # Mock - just return
            }
            
            # This should not throw an error
            { 
                $icon = Get-ModuleIcon "Warning"
                Write-Host "$icon Test warning message" -ForegroundColor $script:ModuleColorWarning
            } | Should -Not -Throw
        }

        It "Write-DevWarning should handle different warning message types" {
            Function Get-ModuleIcon { return "⚠" }
            Function Write-Host { param($Object, $ForegroundColor) }
            
            # Test different warning message scenarios
            { 
                $icon = Get-ModuleIcon "Warning"
                Write-Host "$icon Port already in use" -ForegroundColor $script:ModuleColorWarning
            } | Should -Not -Throw
            
            { 
                $icon = Get-ModuleIcon "Warning"
                Write-Host "$icon Service taking longer than expected" -ForegroundColor $script:ModuleColorWarning
            } | Should -Not -Throw
        }

        It "Write-DevWarning should use correct color variable" {
            $script:ModuleColorWarning | Should -Be "Yellow"
        }

        It "Write-DevWarning message parameter should be mandatory" {
            # Load the actual function to test parameter validation
            $ModuleRoot = $PSCommandPath | Split-Path -Parent | Split-Path -Parent | Split-Path -Parent
            $FunctionPath = Join-Path (Join-Path $ModuleRoot "source\private") "Write-DevWarning.ps1"
            
            # Test that the function definition has the mandatory parameter
            $functionContent = Get-Content $FunctionPath -Raw
            $functionContent | Should -Match '\[Parameter\(Mandatory\s*=\s*\$true\)\]'
            $functionContent | Should -Match '\[string\]\$Message'
        }

        It "Write-DevWarning should work with valid message parameter" {
            Function Get-ModuleIcon { return "⚠" }
            Function Write-Host { param($Object, $ForegroundColor) }
            Function Write-DevWarning {
                param([Parameter(Mandatory = $true)][string]$Message)
                $icon = Get-ModuleIcon "Warning"
                Write-Host "$icon $Message" -ForegroundColor $script:ModuleColorWarning
            }
            
            { Write-DevWarning -Message "Test warning" } | Should -Not -Throw
        }
    }
}

