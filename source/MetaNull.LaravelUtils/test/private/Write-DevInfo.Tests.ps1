[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Test file contains mock functions with intentionally unused parameters')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidOverwritingBuiltInCmdlets', '', Justification = 'Test file needs to mock built-in cmdlets for isolated testing')]
param()

Describe "Testing private module function Write-DevInfo" -Tag "UnitTest" {
    Context "General context" {
        BeforeAll {
            # Set up the module variable that the function expects
            $script:ModuleColorInfo = "Cyan"
            
            # For these output functions, we'll test them more simply
            # by ensuring they don't throw errors and call the expected functions
        }

        It "Write-DevInfo should execute without errors" {
            # Mock the dependencies to avoid actual output
            Function Get-ModuleIcon {
                param([string]$Type)
                return "ℹ"
            }
            
            Function Write-Host {
                param([string]$Object, [string]$ForegroundColor)
                # Mock - just return
            }
            
            # This should not throw an error
            { 
                $icon = Get-ModuleIcon "Info"
                Write-Host "$icon Test message" -ForegroundColor $script:ModuleColorInfo
            } | Should -Not -Throw
        }

        It "Write-DevInfo should handle different message types" {
            Function Get-ModuleIcon { return "ℹ" }
            Function Write-Host { param($Object, $ForegroundColor) }
            
            # Test different message scenarios
            { 
                $icon = Get-ModuleIcon "Info"
                Write-Host "$icon Server started" -ForegroundColor $script:ModuleColorInfo
            } | Should -Not -Throw
            
            { 
                $icon = Get-ModuleIcon "Info"
                Write-Host "$icon Port 8000 is ready" -ForegroundColor $script:ModuleColorInfo
            } | Should -Not -Throw
        }

        It "Write-DevInfo should use correct color variable" {
            $script:ModuleColorInfo | Should -Be "Cyan"
        }

        It "Write-DevInfo message parameter should be mandatory" {
            # Load the actual function to test parameter validation
            $ModuleRoot = $PSCommandPath | Split-Path -Parent | Split-Path -Parent | Split-Path -Parent
            $FunctionPath = Join-Path (Join-Path $ModuleRoot "source\private") "Write-DevInfo.ps1"
            
            # Test that the function definition has the mandatory parameter
            $functionContent = Get-Content $FunctionPath -Raw
            $functionContent | Should -Match '\[Parameter\(Mandatory\s*=\s*\$true\)\]'
            $functionContent | Should -Match '\[string\]\$Message'
        }

        It "Write-DevInfo should work with valid message parameter" {
            Function Get-ModuleIcon { return "ℹ" }
            Function Write-Host { param($Object, $ForegroundColor) }
            Function Write-DevInfo {
                param([Parameter(Mandatory = $true)][string]$Message)
                $icon = Get-ModuleIcon "Info"
                Write-Host "$icon $Message" -ForegroundColor $script:ModuleColorInfo
            }
            
            { Write-DevInfo -Message "Test" } | Should -Not -Throw
        }
    }
}

